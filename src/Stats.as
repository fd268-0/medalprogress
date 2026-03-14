class PMedal {

    int Time;
    string Description;
    string Name;
    string Icon;
}

namespace StatHandler {
    dictionary possibleMedals = {
        {"Bronze",("\\$900" + Icons::CircleO)},
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
        {"Worst Time",("\\$000" + Icons::Minus)},
#endif
        {"World Record",("\\$00f" + Icons::Trophy)}
    };


    int getTimeAtPos(const int position) {
        if (position > 10000) {
            return -1;
        }

        auto app = cast<CTrackMania>(GetApp());
        auto track = app.RootMap;


        NadeoServices::AddAudience("NadeoLiveServices");

        while (! NadeoServices::IsAuthenticated("NadeoLiveServices")) {
            sleep(100);
        }

        auto request = NadeoServices::Get("NadeoLiveServices", 'https://live-services.trackmania.nadeo.live/api/token/leaderboard/group/Personal_Best/map/' + track.MapInfo.MapUid + '/top?length=1&onlyWorld=true&offset=' + (position-1) );
        request.Start();

        while (! request.Finished()) {
            sleep(100);
        }
        int time = -1;
        if (app.RootMap is null) {
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
        auto network = cast<CTrackManiaNetwork>(app.Network);
        if (network.ClientManiaAppPlayground !is null && track !is null) {
            auto scoreMgr = network.ClientManiaAppPlayground.ScoreMgr;
            auto userMgr = network.ClientManiaAppPlayground.UserMgr;
            MwId userId;
            if (userMgr.Users.Length > 0) {
                userId = userMgr.Users[0].Id;
            } else {
                userId.Value = uint(-1);
            }
                
            auto score = scoreMgr.Map_GetRecord_v2(userId, track.MapInfo.MapUid, "PersonalBest", "", "TimeAttack", "");
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
        int fixedCurPb = (currentPb <= 0) ? 999999999 : currentPb;
        int settingForName = int(SettingHandler::jsonSettings["mdl_"+name]);
        if (settingForName == 1) {
            return;
        }
        if (settingForName == 2 && fixedCurPb > time) {
            return;
        }
        if (settingForName == 3 && fixedCurPb <= time) {
            return;
        }
        PMedal item;
        item.Time = time;
        item.Name = name;
        item.Icon = string(possibleMedals[name]);
        times.InsertLast(item);
    }



    void UpdateMedals() {
        auto app = cast<CTrackMania>(GetApp());
        auto track = app.RootMap;
        if (track !is null) {
            if ((wr_time == -2 && ((SettingHandler::ReloadWRTime == RWT::Normal) || (SettingHandler::ReloadWRTime == RWT::Once))) || (Time::get_Now()-lastWrUpdate > 120000 && SettingHandler::ReloadWRTime == RWT::Normal)) {
                wr_time = getTimeAtPos(1);
                lastWrUpdate = Time::get_Now();
            } 
            auto mapInfo = track.MapInfo;
            times = {};
            if (wr_time > 0) {
                //times.InsertLast({{"Icon", "\\$00f" + Icons::Trophy},{"Time", wr_time}});
                AddItemToTime("World Record", wr_time);
            }
            AddItemToTime("Bronze", mapInfo.TMObjective_BronzeTime);
            AddItemToTime("Silver", mapInfo.TMObjective_SilverTime);
            AddItemToTime("Gold", mapInfo.TMObjective_GoldTime);
            AddItemToTime("Author", mapInfo.TMObjective_AuthorTime);
#if DEPENDENCY_WARRIORMEDALS
            AddItemToTime("Warrior", WarriorMedals::GetWMTime());
#endif
#if DEPENDENCY_CHAMPIONMEDALS
            AddItemToTime("Champion", ChampionMedals::GetCMTime());
#endif
#if DEPENDENCY_MAPINFO
            auto mapInfoPlg = MapInfo::GetCurrentMapInfo();
            AddItemToTime("Worst Time", mapInfoPlg.WorstTime);
#endif

        } else {
            wr_time = -2;
            unbeatenAt = false;
            lastPb = -2;
            times = {};
        }
    }

    array<PMedal> GetCurPbMedal() {
        PMedal curPbMedal;
        curPbMedal.Time = 999999999;
        curPbMedal.Icon = "\\$000";
        PMedal nextPbMedal;
        nextPbMedal.Time = 0;
        nextPbMedal.Icon = "\\$000";
        int fixedCurPb = (currentPb <= 0) ? 999999999 : currentPb;
        for (uint i = 0; i < times.Length; i++) {
            if (fixedCurPb <= int(times[i].Time)) {
                if (int(times[i].Time) <= int(curPbMedal.Time)) {
                    curPbMedal = times[i];
                }
            }
            if (fixedCurPb > int(times[i].Time)) {
                if (int(times[i].Time) > int(nextPbMedal.Time)) {
                    nextPbMedal = times[i];
                }
            }
        }
        return {curPbMedal, nextPbMedal};
    }
}
