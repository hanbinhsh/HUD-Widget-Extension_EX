import QtQuick 2.12
import NERvGear.Templates 1.0 as T
import NERvGear.Preferences 1.0 as P

import "." 

T.Data {
    id: root
    title: qsTr("Steam Profile Data")
    description: qsTr("Data available only if the user has set their Steam profile to public.")

    // ============================================================
    //  2. 聚合数据项 (T.Value)
    // ============================================================

    // --- A. 个人资料聚合 (Profile Info) ---
    T.Value {
        id: valProfile
        name: "profileInfo"
        title: qsTr("Profile Info")
        interval: 3000

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
                
                // [修改] 调用单例的方法
                SteamService.requestUpdate(cfg.steamId, duration);
                
                // [修改] 从单例读取数据
                var d = SteamService.cacheData;
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
        interval: 3000

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
                
                // [修改] 调用单例
                SteamService.requestUpdate(cfg.steamId, duration);
                
                var type = cfg.sizeType || 0;
                // [修改] 读取单例
                if (type === 1) current = SteamService.cacheData.avatarMedium;
                else if (type === 2) current = SteamService.cacheData.avatarIcon;
                else current = SteamService.cacheData.avatarFull;
                
                status = T.Value.Ready;
            } else { status = T.Value.Null; }
        }
    }

    // --- C. 游戏信息聚合 (Game Info) ---
    T.Value {
        id: valGame
        name: "gameInfo"
        title: qsTr("Game Info")
        interval: 3000

        update.preference: P.PreferenceGroup {
            P.TextFieldPreference {
                name: "steamId"; label: qsTr("SteamID64"); hint: "e.g. 76561198xxxxxxxxx"; display: P.TextFieldPreference.ExpandControl
            }
            // 1. 选择游戏 (动态列表)
            P.SelectPreference {
                name: "gameIndex"
                label: qsTr("Select Game")
                // [修改] 读取单例的模型
                model: SteamService.gameListModel
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
                // [修改] 调用单例
                SteamService.requestUpdate(cfg.steamId, duration);

                var idx = cfg.gameIndex || 0;
                var type = cfg.infoType || 0;
                // [修改] 读取单例
                var games = SteamService.cacheData.games;

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
                    current = ""; 
                }
                status = T.Value.Ready;
            } else { status = T.Value.Null; }
        }
    }
}