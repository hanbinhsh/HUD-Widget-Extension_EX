pragma Singleton
import QtQuick 2.12

QtObject {
    id: service

    // ============================================================
    //  1. 数据存储与状态
    // ============================================================

    // 缓存解析后的完整数据对象
    property var cacheData: ({
        // 基础信息
        steamID64: "",
        steamID: "",            // 昵称
        onlineState: "",        // 在线状态 (offline, online, in-game)
        stateMessage: "",       // 状态描述
        privacyState: "",       // public/private
        visibilityState: "",    // 3 = public
        vacBanned: "0",
        tradeBanState: "",
        isLimitedAccount: "0",
        customURL: "",
        memberSince: "",
        steamRating: "",
        hoursPlayed2Wk: "",
        headline: "",
        location: "",
        realname: "",
        summary: "",
        
        // 头像
        avatarIcon: "",
        avatarMedium: "",
        avatarFull: "",

        // 游戏列表
        games: [] 
    })

    // 游戏名称列表（用于下拉框模型）
    property var gameListModel: [qsTr("Loading...")]

    // 使用 Map 记录每个 ID 的最后刷新时间
    // 结构: { "76561198...": 1690000000000 }
    property var fetchHistory: ({}) 

    // 记录当前正在请求的 ID，防止并发重复请求
    // 结构: { "76561198...": true }
    property var activeRequests: ({}) 

    // ============================================================
    //  2. 对外接口
    // ============================================================

    function requestUpdate(steamId, timeoutMs) {
        if (!steamId) return;

        var now = new Date().getTime();
        // 如果未提供参数，默认 5 分钟
        var duration = (timeoutMs !== undefined) ? timeoutMs : 300000;

        // 获取该 ID 上次的刷新时间 (如果不存在则为 0)
        var lastTime = fetchHistory[steamId] || 0;
        
        // 检查是否正在请求中 (防抖)
        if (activeRequests[steamId]) {
            return;
        }

        // 只有超时才刷新
        if (now - lastTime > duration) {
            console.log("[SteamService] Fetching data for:", steamId);
            // 标记为正在请求
            activeRequests[steamId] = true;
            // 立即更新时间戳，防止其他组件在毫秒级差距内再次触发
            fetchHistory[steamId] = now;
            fetchFromNet(steamId);
        }
    }

    // ============================================================
    //  3. 内部逻辑 (解析与网络)
    // ============================================================

    function parseXML(xml) {
        var newData = { games: [] };
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

        // 更新单例的数据属性
        service.cacheData = newData;
        
        // 更新游戏下拉框列表
        if (newGameNames.length === 0) {
            service.gameListModel = ["No games found"];
        } else {
            service.gameListModel = newGameNames;
        }
    }

    // 内部网络请求逻辑
    function fetchFromNet(steamId) {
        var xhr = new XMLHttpRequest();
        var url = "https://steamcommunity.com/profiles/" + steamId + "/?xml=1";
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                
                // 请求结束，无论成功失败，移除“正在请求”标记
                delete activeRequests[steamId];
                // 强制刷新绑定 (QML 有时对 delete 操作不敏感，重新赋值触发信号)
                activeRequests = activeRequests; 

                if (xhr.status === 200) {
                    parseXML(xhr.responseText);
                } else {
                    console.warn("[SteamService] Network error:", xhr.status, xhr.statusText);
                    // 失败时不重置 fetchHistory，防止因网络问题导致的死循环请求
                }
            }
        }
        xhr.open("GET", url);
        xhr.send();
    }
}