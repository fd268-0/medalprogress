enum SCORETYPE {
    TimeAttack,
    Stunt,
    Platform,
}

class PMedal {

    vec4 GetColorOfMedal() {
        return Text::ParseHexColor("#" + string(Icon).SubStr(2,1) + "0" + string(Icon).SubStr(3,1) + "0" + string(Icon).SubStr(4,1) + "0ff");;
    }

    int GetBarPosition() {
        int actualDBS = Math::Min(SettingHandler::DisplayBarSize, SettingHandler::XSize);
        float anchor = StatHandler::GetAnchor();
        int xPosition = int(Math::Min(Math::Max(int(SettingHandler::XSize*2*BarDisplayPosition+float(actualDBS*anchor)), actualDBS/2), SettingHandler::XSize*2-actualDBS/2));
        return xPosition;
    }

    void SetBarPosition(const int position) {
        float xPosition = float(position)/2/SettingHandler::XSize;
        BarDisplayPosition = xPosition;
    }

    bool BeenUpdated;
    int Time;
    string Name;
    string Icon;
    bool BarDisplay;
    float BarDisplayPosition;
    bool Visible;
}

namespace StatHandler {
    const dictionary possibleMedalsDefault = {
        {"Bronze",("\\$911" + Icons::CircleO)},
        {"Silver",("\\$999" + Icons::CircleO)},
        {"Gold",("\\$fc0" + Icons::DotCircleO)},
        {"Author",("\\$090" + Icons::Circle)},
#if DEPENDENCY_WARRIORMEDALS
        {"Warrior",("\\$0af" + Icons::PlusCircle)},
#endif
#if DEPENDENCY_CHAMPIONMEDALS
        {"Champion",("\\$f05" + Icons::PlusCircle)},
#endif
#if DEPENDENCY_MAPINFO
        {"Worst Time",("\\$333" + Icons::Minus)},
#endif
        {"World Record",("\\$00f" + Icons::Trophy)}
    };

    dictionary possibleMedals = {};

    string FormatInt(const int num, const SCORETYPE type) {
        if (type == SCORETYPE::TimeAttack) {
            return Time::Format(num, true);
        } else if (type == SCORETYPE::Stunt) {
            return ""+num;
        } else if (type == SCORETYPE::Platform) {
            return ""+num;
        }
        return "";
    }

    float GetAnchor() {
        float anchor = 0;
        if (SettingHandler::DisplayBarAnchor == BARANCHOR::Left) {
            anchor = 0.5;
        }
        if (SettingHandler::DisplayBarAnchor == BARANCHOR::Right) {
            anchor = -0.5;
        }
        return anchor;
    }

    void UpdatePossibleMedals() {
        possibleMedals = {};
        for (uint i = 0; i < possibleMedalsDefault.GetKeys().Length; i++) {
            string itemName = possibleMedalsDefault.GetKeys()[i];
            string item = string(possibleMedalsDefault[itemName]);
            string subColor = item.SubStr(0,5);
            string subIcon = item.SubStr(5);
            string iconText = string(SettingHandler::jsonSettings["txt_"+itemName]);
             string iconColor = string(SettingHandler::jsonSettings["txt_"+itemName+"_clr"]);
            if (iconText != "") {
                subIcon = SettingHandler::GetIconForName(iconText);
            }
            if (iconColor != "" && iconColor.Length == 3) {
                subColor = "\\$" + iconColor;
            }
            possibleMedals[itemName] = subColor + subIcon;
        }
    }

    int getTimeAtPos(const int position) {
        if (position > 10000 || position < 1) {
            warn("Position invalid for request.");
            return -1;
        }


        NadeoServices::AddAudience("NadeoLiveServices");

        while (! NadeoServices::IsAuthenticated("NadeoLiveServices")) {
            sleep(100);
        }

        auto app = cast<CTrackMania>(GetApp());
        auto track = app.RootMap;

        if (app.RootMap is null) {
            warn("Tried to get a time when no map was avaliable.");
            return -2;
        }

        auto request = NadeoServices::Get("NadeoLiveServices", 'https://live-services.trackmania.nadeo.live/api/token/leaderboard/group/Personal_Best/map/' + track.MapInfo.MapUid + '/top?length=1&onlyWorld=true&offset=' + (position-1) );
        request.Start();

        while (! request.Finished()) {
            sleep(100);
        }
        int time = -1;
        if (app.RootMap is null) {
            warn("No map is avaliable to update the record for.");
            return -2;
        }
        auto mapInfo = track.MapInfo;
        if (request.Finished()) {
            auto reques = request.Json();
            if (reques.HasKey("tops")) {
                auto tops = reques.Get("tops");
                if ((tops.Length > 0 ) ? tops[0].HasKey("top") : false) {
                    auto top = tops[0].Get("top");
                    if ((top.Length > 0 ) ? top[0].HasKey("score") : false) {
                        auto keys = top[0].Get("score");
                        time = keys;
                    } else {
                        unbeatenAt = true;
                    }
            }
            }
        }
        if (time > int(mapInfo.TMObjective_AuthorTime)) {
            unbeatenAt = true;
        }
        return time;
    }

    bool UpdateCurrentPb() {
        auto app = cast<CTrackMania>(GetApp());
        auto track = app.RootMap;
        auto editor = app.Editor;
        auto network = cast<CTrackManiaNetwork>(app.Network);
        if (network.ClientManiaAppPlayground !is null && track !is null && editor is null) {
            auto challengeParams = track.ChallengeParameters;
            string mapTypeStr = string(challengeParams.MapType);
            auto scoreMgr = network.ClientManiaAppPlayground.ScoreMgr;
            auto userMgr = network.ClientManiaAppPlayground.UserMgr;
            MwId userId;
            if (userMgr.Users.Length > 0) {
                userId = userMgr.Users[0].Id;
            } else {
                userId.Value = uint(-1);
            }
            mapType = SCORETYPE::TimeAttack;
            string scope = "TimeAttack";
            if (track.MapInfo.TMObjective_NbClones > 0) {
                scope = "TimeAttackClone";
            }
            if (mapTypeStr.Contains("TM_Stunt")) {
                mapType = SCORETYPE::Stunt;
                scope = "Stunt";
            }
            if (mapTypeStr.Contains("TM_Platform")) {
                mapType = SCORETYPE::Platform;
                scope = "Platform";
            }
            auto score = scoreMgr.Map_GetRecord_v2(userId, track.MapInfo.MapUid, "PersonalBest", "", scope, "");
            if (int(score) != lastPb) {
                lastPbUpdate = Time::get_Now();
                lastPb = score;
            }
            currentPb = score;
            return true;
        }
        return false;
    }

    void AddItemToTime(const string name, const int time) {
        if (! possibleMedals.Exists(name)) {
            return;
        }
         int fixedCurPb = (currentPb < 0) ? 999999999 : currentPb;
        int settingForName = int(SettingHandler::jsonSettings["mdl_"+name]);
        int barDispSetting = int(SettingHandler::jsonSettings["mdl_"+name+"_bar"]);
        PMedal item;
        item.Time = time;
        if (mapType == SCORETYPE::Stunt) {
            item.Time = 0-time;
        }
        item.Name = name;
        item.Visible = true;
        item.BarDisplay = (barDispSetting == 0) ? false : true;
        item.Icon = string(possibleMedals[name]);
        if (settingForName == 1) {
            item.Visible = false;
        }
        if (settingForName == 2 && fixedCurPb > time) {
            item.Visible = false;
        }
        if (settingForName == 3 && fixedCurPb <= time) {
            item.Visible = false;
        }
        allTimes.InsertLast(item);
    }



    void UpdateMedals() {
        auto app = cast<CTrackMania>(GetApp());
        auto track = app.RootMap;
        auto editor = app.Editor;
        if (track !is null && editor is null) {
            if (((wr_time == -2 && ((SettingHandler::ReloadWRTime == RWT::Normal) || (SettingHandler::ReloadWRTime == RWT::Once))) || (Time::get_Now()-lastWrUpdate > 120000 && SettingHandler::ReloadWRTime == RWT::Normal)) && mapType != SCORETYPE::Platform) {
                wr_time = getTimeAtPos(1);
                lastWrUpdate = Time::get_Now();
            } 
            auto mapInfo = track.MapInfo;
            allTimes = {};
            if (wr_time > 0  && mapType != SCORETYPE::Platform) {
                //times.InsertLast({{"Icon", "\\$00f" + Icons::Trophy},{"Time", wr_time}});
                AddItemToTime("World Record", wr_time);
            }
            AddItemToTime("Bronze", mapInfo.TMObjective_BronzeTime);
            AddItemToTime("Silver", mapInfo.TMObjective_SilverTime);
            AddItemToTime("Gold", mapInfo.TMObjective_GoldTime);
            AddItemToTime("Author", mapInfo.TMObjective_AuthorTime);
#if DEPENDENCY_WARRIORMEDALS
            int warriorTime = WarriorMedals::GetWMTime();
            if (warriorTime > 0) {
                AddItemToTime("Warrior", warriorTime);
            }
#endif
#if DEPENDENCY_CHAMPIONMEDALS
            int championTime = ChampionMedals::GetCMTime();
            if (championTime > 0) {
                AddItemToTime("Champion", championTime);
            }
#endif
#if DEPENDENCY_MAPINFO
            auto mapInfoPlg = MapInfo::GetCurrentMapInfo();
            if (mapType == SCORETYPE::TimeAttack) {
                AddItemToTime("Worst Time", mapInfoPlg.WorstTime);
            }
#endif

            allTimes.Sort(function(a,b) {
                return a.Time < b.Time;
            });

        } else {
            wr_time = -2;
            unbeatenAt = false;
            lastPb = -2;
            allTimes = {};
        }
    }

    array<PMedal> GetVisiblePMedals() {
        array<PMedal> visiblePMedals = {};
        array<PMedal> curPMedals = GetCurPbMedal();
        if (curPMedals[1].Time < 0) {
            return {};
        }
        for (uint i = 0; i < allTimes.Length; i++) {
            int barDispSetting = int(SettingHandler::jsonSettings["mdl_"+allTimes[i].Name+"_bar"]);
            bool isInBounds = allTimes[i].Time < curPMedals[0].Time && allTimes[i].Time > curPMedals[1].Time;
            if (isInBounds && barDispSetting == 1) {
                allTimes[i].BarDisplayPosition = float(allTimes[i].Time - curPMedals[0].Time) / float(curPMedals[1].Time - curPMedals[0].Time);
                visiblePMedals.InsertLast(allTimes[i]);
            }
        }
        return visiblePMedals;
    }
    array<PMedal> GetCurPbMedal(const bool&in countInvisible = false) {
        PMedal curPbMedal;
        curPbMedal.Time = 999999999;
        curPbMedal.Icon = "\\$000";
        PMedal nextPbMedal;
        nextPbMedal.Time = -1;
        nextPbMedal.Icon = "\\$000";
        int fixedCurPb = (currentPb < 0) ? 999999999 : currentPb;
        for (uint i = 0; i < allTimes.Length; i++) {
            if (allTimes[i].Visible == false && countInvisible == false) {
                continue;
            }
            if (fixedCurPb <= int(allTimes[i].Time)) {
                if (int(allTimes[i].Time) <= int(curPbMedal.Time)) {
                    curPbMedal = allTimes[i];
                }
            }
            if (fixedCurPb > int(allTimes[i].Time)) {
                if (int(allTimes[i].Time) > int(nextPbMedal.Time)) {
                    nextPbMedal = allTimes[i];
                }
            }
        }
        array<PMedal> medalReturns = {curPbMedal, nextPbMedal};
        return medalReturns;
    }
}
