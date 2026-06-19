pragma Singleton
import QtQuick 2.12

QtObject {
    id: service

    // ============================================================
    //  1. 数据存储与状态
    // ============================================================

    // 按 SteamID64 分键缓存解析后的数据对象，支持多账号互不串数据。
    // 结构: { "76561198...": { steamID:"", games:[...], ... } }
    property var cacheStore: ({})

    // 按 SteamID64 分键的游戏名称列表（用于下拉框模型）
    // 结构: { "76561198...": ["DOTA2", ...] }
    property var gameListStore: ({})

    // 使用 Map 记录每个 ID 的最后刷新时间
    // 结构: { "76561198...": 1690000000000 }
    property var fetchHistory: ({})

    // 记录当前正在请求的 ID（值为请求开始时间戳），防止并发重复请求；
    // 同时用时间戳实现「自愈」：若请求卡死（永不返回 DONE，xhr.timeout 不一定生效），
    // 超过 netTimeoutMs 后允许放行重试，避免该 ID 永久锁死。
    // 结构: { "76561198...": 1690000000000 }
    property var activeRequests: ({})

    // 失败/超时后允许重试的短窗口（毫秒）——避免失败后要等满整个缓存窗口才重试
    property int failRetryMs: 30000
    // 单次网络请求超时（毫秒）——防止请求卡死导致 activeRequests[id] 永久占用、再也不刷新
    property int netTimeoutMs: 15000

    // 空数据模板（无缓存时返回，保证读取方字段齐全不报 undefined）
    function emptyData() {
        return {
            steamID64: "", steamID: "", onlineState: "", stateMessage: "", privacyState: "",
            visibilityState: "", vacBanned: "0", tradeBanState: "", isLimitedAccount: "0",
            customURL: "", memberSince: "", steamRating: "", hoursPlayed2Wk: "", headline: "",
            location: "", realname: "", summary: "",
            avatarIcon: "", avatarMedium: "", avatarFull: "",
            games: []
        };
    }

    // ============================================================
    //  2. 对外接口
    // ============================================================

    // 读取某 ID 的缓存数据（读取方按自己的 steamId 取，互不影响）
    function getData(steamId) {
        return (steamId && cacheStore[steamId]) ? cacheStore[steamId] : emptyData();
    }

    // 读取某 ID 的游戏名称列表（下拉框模型用）
    function getGames(steamId) {
        return (steamId && gameListStore[steamId]) ? gameListStore[steamId] : [qsTr("Loading...")];
    }

    function requestUpdate(steamId, timeoutMs) {
        if (!steamId) return;

        var now = new Date().getTime();
        // 如果未提供参数，默认 5 分钟
        var duration = (timeoutMs !== undefined) ? timeoutMs : 300000;

        // 获取该 ID 上次的刷新时间 (如果不存在则为 0)
        var lastTime = fetchHistory[steamId] || 0;

        // 检查是否正在请求中 (防抖/防并发)
        var startedAt = activeRequests[steamId];
        // 在途请求若超过 netTimeoutMs 仍未结束，视为卡死，可放行重试（自愈）
        var stale = startedAt && (now - startedAt >= netTimeoutMs);
        if (startedAt && !stale) {
            return;
        }

        // 发起条件：缓存已过期，或在途请求已卡死（卡死时优先重试，忽略缓存窗口）
        if (stale || (now - lastTime > duration)) {
            console.log("[SteamService] Fetching data for:", steamId);
            // 标记为正在请求（记录开始时间用于自愈）
            activeRequests[steamId] = now;
            // 立即更新时间戳，防止其他组件在毫秒级差距内再次触发
            fetchHistory[steamId] = now;
            fetchFromNet(steamId, duration);
        }
    }

    // ============================================================
    //  3. 内部逻辑 (解析与网络)
    // ============================================================

    function parseXML(steamId, xml) {
        var newData = emptyData();
        var newGameNames = [];

        // 通用提取函数 (兼容换行和CDATA)
        var getValue = function(tag, context) {
            var searchIn = context ? context : xml;
            // 匹配 <tag>...</tag>，中间可能包含 <![CDATA[...]]>
            var pattern = "<" + tag + ">(?:<!\\[CDATA\\[)?([\\s\\S]*?)(?:\\]\\]>)?<\\/" + tag + ">";
            var regex = new RegExp(pattern, "i");
            var match = searchIn.match(regex);
            return match ? match[1].trim() : "";
        }

        // --- 1. 解析所有个人资料字段 ---
        var tags = [
            "steamID64", "steamID", "onlineState", "stateMessage", "privacyState", "visibilityState",
            "avatarIcon", "avatarMedium", "avatarFull", "vacBanned", "tradeBanState", "isLimitedAccount",
            "customURL", "memberSince", "steamRating", "hoursPlayed2Wk", "headline", "location", "realname", "summary"
        ];

        for (var i = 0; i < tags.length; i++) {
            newData[tags[i]] = getValue(tags[i]);
        }

        // --- 2. 解析所有游戏信息 ---
        var gamesBlockMatch = xml.match(/<mostPlayedGames>([\s\S]*?)<\/mostPlayedGames>/i);
        if (gamesBlockMatch) {
            var gamesContent = gamesBlockMatch[1];
            var gameRegex = /<mostPlayedGame>([\s\S]*?)<\/mostPlayedGame>/gi;
            var gameMatch;

            while ((gameMatch = gameRegex.exec(gamesContent)) !== null) {
                var gStr = gameMatch[1];
                var gName = getValue("gameName", gStr);

                newData.games.push({
                    gameName: gName,
                    gameLink: getValue("gameLink", gStr),
                    gameIcon: getValue("gameIcon", gStr),
                    gameLogo: getValue("gameLogo", gStr),
                    gameLogoSmall: getValue("gameLogoSmall", gStr),
                    hoursPlayed: getValue("hoursPlayed", gStr),
                    hoursOnRecord: getValue("hoursOnRecord", gStr),
                    statsName: getValue("statsName", gStr)
                });

                newGameNames.push(gName);
            }
        }

        // 按 ID 写入缓存（重新赋值整个 store 以触发绑定刷新）
        var store = service.cacheStore;
        store[steamId] = newData;
        service.cacheStore = store;

        var games = service.gameListStore;
        games[steamId] = (newGameNames.length === 0) ? [qsTr("No games found")] : newGameNames;
        service.gameListStore = games;
    }

    // 失败/超时统一处理：清在途锁，并把上次刷新时间回拨，使 failRetryMs 后即可重试
    // （而非等满整个缓存窗口）。
    function markFailure(steamId, duration) {
        delete activeRequests[steamId];
        activeRequests = activeRequests; // 触发绑定刷新

        var now = new Date().getTime();
        var d = (duration !== undefined) ? duration : 300000;
        // 令未来某刻满足 (futureNow - fetchHistory) > d 恰好在 failRetryMs 之后成立
        fetchHistory[steamId] = now - Math.max(0, d - failRetryMs);
    }

    // 内部网络请求逻辑
    function fetchFromNet(steamId, duration) {
        var xhr = new XMLHttpRequest();
        var url = "https://steamcommunity.com/profiles/" + steamId + "/?xml=1";
        xhr.timeout = netTimeoutMs; // 防止卡死永久占用 activeRequests
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    // 成功：清在途锁后解析
                    delete activeRequests[steamId];
                    activeRequests = activeRequests;
                    parseXML(steamId, xhr.responseText);
                } else {
                    console.warn("[SteamService] Network error:", xhr.status, xhr.statusText);
                    markFailure(steamId, duration);
                }
            }
        }
        xhr.ontimeout = function() {
            console.warn("[SteamService] Request timeout for:", steamId);
            markFailure(steamId, duration);
        }
        xhr.onerror = function() {
            console.warn("[SteamService] Request error for:", steamId);
            markFailure(steamId, duration);
        }
        xhr.open("GET", url);
        xhr.send();
    }
}
