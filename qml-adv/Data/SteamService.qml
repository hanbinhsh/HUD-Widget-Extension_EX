pragma Singleton
import QtQuick 2.12

QtObject {
    id: service

    // ============================================================
    //  全局唯一的缓存与网络逻辑
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
    property var gameListModel: ["Loading..."]

    // 缓存控制
    property real lastFetchTime: 0
    property string lastFetchID: ""

    // 暴露给外部调用的请求函数
    function requestUpdate(steamId, timeoutMs) {
        if (!steamId) return;

        var now = new Date().getTime();
        // 如果未提供参数，默认 5 分钟
        var duration = (timeoutMs !== undefined) ? timeoutMs : 300000;

        // 只有当 ID 变了，或者缓存过期了，才真正发起网络请求
        if (steamId !== lastFetchID || (now - lastFetchTime > duration)) {
            console.log("[SteamService] Fetching data for:", steamId);
            console.log("[SteamService] duration (ms):", duration);
            fetchFromNet(steamId);
            lastFetchTime = now;
            lastFetchID = steamId;
        }
    }

    // 内部解析逻辑 (完全保留你的原逻辑)
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
                if (xhr.status === 200) {
                    // 解析响应
                    parseXML(xhr.responseText);
                } else {
                    console.warn("[SteamService] Network error:", xhr.status, xhr.statusText);
                }
            }
        }
        xhr.open("GET", url);
        xhr.send();
    }
}