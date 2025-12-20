import QtQuick 2.12
import NERvGear.Templates 1.0 as T
import NERvGear.Preferences 1.0 as P

T.Data {
    id: root
    title: qsTr("Steam Profile Data")
    description: qsTr("Data available only if the user has set their Steam profile to public.")

    // https://partner.steamgames.com/documentation/community_data
    // https://developer.valvesoftware.com/wiki/Steam_Web_API

    // ============================================================
    //  1. 核心缓存与网络逻辑
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

    // 缓存控制
    property real lastFetchTime: 0
    property string lastFetchID: ""

    function requestUpdate(steamId, timeoutMs) {
        if (!steamId) return;

        var now = new Date().getTime();
        // 如果未提供参数，默认 5 分钟
        var duration = (timeoutMs !== undefined) ? timeoutMs : 300000;

        if (steamId !== lastFetchID || (now - lastFetchTime > duration)) {
            fetchFromNet(steamId);
            lastFetchTime = now;
            lastFetchID = steamId;
        }
    }

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

        // 更新数据
        root.cacheData = newData;
        
        // 更新游戏下拉框列表
        if (newGameNames.length === 0) {
            root.gameListModel = [qsTr("No games found")];
        } else {
            root.gameListModel = newGameNames;
        }
    }

    function fetchFromNet(steamId) {
        var xhr = new XMLHttpRequest();
        var url = "https://steamcommunity.com/profiles/" + steamId + "/?xml=1";
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    if(typeof parseXML === "function")
                        parseXML(xhr.responseText);
                }
            }
        }
        xhr.open("GET", url);
        xhr.send();
    }

    // ============================================================
    //  2. 聚合数据项 (T.Value)
    // ============================================================

    // --- A. 个人资料聚合 (Profile Info) ---
    T.Value {
        id: valProfile
        name: "profileInfo"
        title: qsTr("Profile Info")
        interval: 1000

        update.preference: P.PreferenceGroup {
            P.TextFieldPreference {
                name: "steamId"; label: qsTr("SteamID64"); hint: "e.g. 76561198xxxxxxxxx"; display: P.TextFieldPreference.ExpandControl
            }
            P.SelectPreference {
                name: "fieldType"
                label: qsTr("Data Field")
                defaultValue: 0
                model: [
                    qsTr("Nickname"),                // 0
                    qsTr("Real Name"),               // 1
                    qsTr("Summary"),                 // 2
                    qsTr("Location"),                // 3
                    qsTr("State Message"),           // 4
                    qsTr("Online State"),            // 5
                    qsTr("Member Since"),            // 6
                    qsTr("Hours Played (2 Wk)"),     // 7
                    qsTr("Steam Rating"),            // 8
                    qsTr("Custom URL"),              // 9
                    qsTr("Headline"),                // 10
                    qsTr("VAC Banned (0/1)"),        // 11
                    qsTr("Trade Ban State"),         // 12
                    qsTr("Limited Account (0/1)"),   // 13
                    qsTr("Privacy State"),           // 14
                    qsTr("Visibility State")         // 15
                ]
            }
            P.SpinPreference {
                name: "cacheTime"
                label: qsTr("Cache Duration (min)")
                defaultValue: 5
                from: 1
                to: 1440
                editable: true
                display: P.TextFieldPreference.ExpandLabel
            }
        }

        update.execute: function() {
            var cfg = update.configuration;
            if (cfg && cfg.steamId) {
                var duration = (cfg.cacheTime ?? 5) * 60000;
                root.requestUpdate(cfg.steamId, duration);
                
                var d = root.cacheData;
                var type = cfg.fieldType || 0;
                
                switch(type) {
                    case 0: current = d.steamID; break;
                    case 1: current = d.realname; break;
                    case 2: current = d.summary; break;
                    case 3: current = d.location; break;
                    case 4: current = d.stateMessage; break;
                    case 5: current = d.onlineState; break;
                    case 6: current = d.memberSince; break;
                    case 7: current = d.hoursPlayed2Wk; break;
                    case 8: current = d.steamRating; break;
                    case 9: current = d.customURL; break;
                    case 10: current = d.headline; break;
                    case 11: current = d.vacBanned; break;
                    case 12: current = d.tradeBanState; break;
                    case 13: current = d.isLimitedAccount; break;
                    case 14: current = d.privacyState; break;
                    case 15: current = d.visibilityState; break;
                    default: current = "";
                }
                status = T.Value.Ready;
            } else { status = T.Value.Null; }
        }
    }

    // --- B. 头像聚合 (Avatar) ---
    T.Value {
        id: valAvatar
        name: "avatar"
        title: qsTr("Avatar")
        interval: 1000

        update.preference: P.PreferenceGroup {
            P.TextFieldPreference {
                name: "steamId"; label: qsTr("SteamID64"); hint: "e.g. 76561198xxxxxxxxx"; display: P.TextFieldPreference.ExpandControl
            }
            P.SelectPreference {
                name: "sizeType"
                label: qsTr("Avatar Size")
                defaultValue: 0
                model: [
                    qsTr("Full (184px)"),   // 0
                    qsTr("Medium (64px)"),  // 1
                    qsTr("Icon (32px)")     // 2
                ]
            }
            P.SpinPreference {
                name: "cacheTime"
                label: qsTr("Cache Duration (min)")
                defaultValue: 5
                from: 1
                to: 1440
                editable: true
                display: P.TextFieldPreference.ExpandLabel
            }
        }

        update.execute: function() {
            var cfg = update.configuration;
            if (cfg && cfg.steamId) {
                var duration = (cfg.cacheTime ?? 5) * 60000;
                root.requestUpdate(cfg.steamId, duration);
                
                var type = cfg.sizeType || 0;
                if (type === 1) current = root.cacheData.avatarMedium;
                else if (type === 2) current = root.cacheData.avatarIcon;
                else current = root.cacheData.avatarFull;
                
                status = T.Value.Ready;
            } else { status = T.Value.Null; }
        }
    }

    // --- C. 游戏信息聚合 (Game Info) ---
    T.Value {
        id: valGame
        name: "gameInfo"
        title: qsTr("Game Info")
        interval: 1000

        update.preference: P.PreferenceGroup {
            P.TextFieldPreference {
                name: "steamId"; label: qsTr("SteamID64"); hint: "e.g. 76561198xxxxxxxxx"; display: P.TextFieldPreference.ExpandControl
            }
            // 1. 选择游戏 (动态列表)
            P.SelectPreference {
                name: "gameIndex"
                label: qsTr("Select Game")
                model: root.gameListModel
                defaultValue: 0
            }
            // 2. 选择属性 (包含XML中所有游戏相关字段)
            P.SelectPreference {
                name: "infoType"
                label: qsTr("Data Field")
                defaultValue: 0
                model: [
                    qsTr("Game Name"),           // 0
                    qsTr("Hours Played (2 Wk)"), // 1
                    qsTr("Hours Total"),         // 2
                    qsTr("Cover Logo (184x69)"), // 3
                    qsTr("Cover Small"),         // 4
                    qsTr("Icon URL"),            // 5
                    qsTr("Store Link"),          // 6
                    qsTr("Stats Name")           // 7
                ]
            }
            P.SpinPreference {
                name: "cacheTime"
                label: qsTr("Cache Duration (min)")
                defaultValue: 5
                from: 1
                to: 1440
                editable: true
                display: P.TextFieldPreference.ExpandLabel
            }
        }

        update.execute: function() {
            var cfg = update.configuration;
            if (cfg && cfg.steamId) {
                var duration = (cfg.cacheTime ?? 5) * 60000;
                root.requestUpdate(cfg.steamId, duration);

                var idx = cfg.gameIndex || 0;
                var type = cfg.infoType || 0;
                var games = root.cacheData.games;

                if (games && idx >= 0 && idx < games.length) {
                    var g = games[idx];
                    switch(type) {
                        case 0: current = g.gameName; break;
                        case 1: current = g.hoursPlayed; break;
                        case 2: current = g.hoursOnRecord; break;
                        case 3: current = g.gameLogo; break;
                        case 4: current = g.gameLogoSmall; break;
                        case 5: current = g.gameIcon; break;
                        case 6: current = g.gameLink; break;
                        case 7: current = g.statsName; break;
                        default: current = "";
                    }
                } else {
                    current = ""; // 无数据或索引越界
                }
                status = T.Value.Ready;
            } else { status = T.Value.Null; }
        }
    }
}