enum RWT {
	Normal,
	Once,
	Never,
}

[Setting name="Enabled Topbar"]
bool Enabled = true;

[Setting name="Unbeaten AT Display"]
bool UATDisplay = false;

[Setting name="Reload WR Time"]
RWT ReloadWRTime = RWT::Normal;

[Setting name="YPosition"]
int YPosition = 60;

array<dictionary> times = {};
int currentPb = 0;
int wr_time = -2;
int lastPbUpdate = -1000;
int lastWrUpdate = -1000;
int lastPb = 0;
int startDrag = -1;
bool unbeatenAt = false;

vec2 RenderTextCentered(const vec2 pos, const string text, const vec4 color) {
	nvg::FillColor(color);
	vec2 bounds = nvg::TextBounds(text);
	nvg::Text(pos.x-(bounds.x/2)+1,pos.y+(bounds.y/3)+1, text);
	return bounds;
}
bool RenderBoxCentered(const vec2 pos, const vec2 size, const vec4 color, const bool&in appColor = true) {
	nvg::BeginPath();
	if (appColor == true) {
		nvg::FillColor(color);
	}
	nvg::Rect(pos-(size/2), size);
	nvg::Fill();
	nvg::ClosePath();
	return UI::IsMouseHoveringRect(pos-(size/2), pos+(size/2), false);
}

void displayPbBar() {
	auto app = cast<CTrackMania>(GetApp());
	auto track = app.RootMap;

	int width = Display::GetWidth();
	int yPos = YPosition;
	auto font = nvg::LoadFont("Montserrat-Regular.ttf");
	nvg::FontFace(font);
	nvg::FontSize(20);
	array<dictionary> medalGoals = GetCurPbMedal();
	vec4 c1 = Text::ParseHexColor("#" + string(medalGoals[0]["Icon"]).SubStr(2,1) + "0" + string(medalGoals[0]["Icon"]).SubStr(3,1) + "0" + string(medalGoals[0]["Icon"]).SubStr(4,1) + "0ff");
	vec4 c2 = Text::ParseHexColor("#" + string(medalGoals[1]["Icon"]).SubStr(2,1) + "0" + string(medalGoals[1]["Icon"]).SubStr(3,1) + "0" + string(medalGoals[1]["Icon"]).SubStr(4,1) + "0ff");
	vec2 firstLoc = vec2(width/2-118,yPos);
	vec2 secondLoc = vec2(width/2+118,yPos);
	float delta = float(currentPb) - float(medalGoals[1]["Time"]);
	float l = ((float(currentPb) - float(medalGoals[0]["Time"])) / (float(medalGoals[1]["Time"]) - float(medalGoals[0]["Time"])));
	if (currentPb <= 0) {
		l = 0;
	}
	int cpos = 0;
	vec4 lerpVec = Math::Lerp(c1,c2,l);

	if (UI::IsOverlayShown() == true) {
		if ((RenderBoxCentered(secondLoc + vec2(25,0), vec2(14,30), vec4(1,1,1,1)) || startDrag != -1) && UI::IsMouseDown()) {
			if (startDrag == -1) {
				startDrag = YPosition;
			}
			YPosition = startDrag+int(UI::GetMouseDragDelta().y);
		} else {
			startDrag = -1;
		}
		RenderBoxCentered(secondLoc + vec2(25,0), vec2(10,3), vec4(0,0,0,1));
		RenderBoxCentered(secondLoc + vec2(25,6), vec2(10,3), vec4(0,0,0,1));
		RenderBoxCentered(secondLoc + vec2(25,-6), vec2(10,3), vec4(0,0,0,1));
		vec4 opColor = vec4(0,1,0,1);
		if (! Enabled) {
			opColor = vec4(1,0,0,1);
		}
		if ((RenderBoxCentered(secondLoc + vec2(39,0), vec2(14,30), opColor)) && UI::IsMouseClicked()) {
			Enabled = ! Enabled;
		}
		RenderBoxCentered(secondLoc + vec2(39,0), vec2(10,3), vec4(0,0,0,1));
		if (! Enabled) {
			RenderBoxCentered(secondLoc + vec2(39,0), vec2(3,10), vec4(0,0,0,1));
		}
	}
	YPosition = Math::Clamp(YPosition, 0, Display::GetHeight());


	if ((track !is null || UI::IsOverlayShown() == true) && Enabled == true) {
		if (track !is null) {
			auto challengeParams = track.ChallengeParameters;
			if (! string(challengeParams.MapType).Contains('TM_Race')) {
				if (Enabled == true && UI::IsOverlayShown() == true) {
					RenderBoxCentered(vec2(width/2,yPos), vec2(272,36), vec4(0,0,0,0.5));
				}
				return;
			}
		}
		RenderBoxCentered(vec2(width/2,yPos), vec2(272,36), vec4(0,0,0,0.5));
	}
	if (track is null || Enabled == false) {
		return;
	}
	vec2 firstSize = vec2(30,30);
	if (int(medalGoals[1]["Time"]) <= 0) {
		firstLoc = vec2(width/2,yPos);
		firstSize = vec2(266,30);
	}
	bool bs1 = RenderBoxCentered(firstLoc, firstSize, vec4(c1.x,c1.y,c1.z,0.5));
	if (bs1 && int(medalGoals[0]["Time"]) != 999999999) {
		string text = Time::Format(int(medalGoals[0]["Time"]), true);
		vec2 tbounds = nvg::TextBounds(text);
		RenderBoxCentered(vec2(width/2,yPos + 30 + cpos), vec2(tbounds.x+6,24), vec4(0,0,0,0.5));
		RenderTextCentered(vec2(width/2,yPos + 30 + cpos), text, c1);
		cpos += 24;
	}
	if (bs1 && int(medalGoals[1]["Time"]) <= 0) {
		string text = Time::Format(currentPb - int(medalGoals[0]["Time"]), true);
		vec2 tbounds = nvg::TextBounds(text);
		RenderBoxCentered(vec2(width/2,yPos + 30 + cpos), vec2(tbounds.x+6,24), vec4(0,0,0,0.5));
		RenderTextCentered(vec2(width/2,yPos + 30 + cpos), text, c1);
		cpos += 24;
	}
	RenderTextCentered(firstLoc, Text::StripOpenplanetFormatCodes(string(medalGoals[0]["Icon"])),  c1);
	if (int(medalGoals[1]["Time"]) > 0) {
		if (RenderBoxCentered(secondLoc, vec2(30,30), vec4(c2.x,c2.y,c2.z,0.5))) {
			string text = Time::Format(int(medalGoals[1]["Time"]), true);
			vec2 tbounds = nvg::TextBounds(text);
			RenderBoxCentered(vec2(width/2,yPos + 30 + cpos), vec2(tbounds.x+6,24), vec4(0,0,0,0.5));
			RenderTextCentered(vec2(width/2,yPos + 30 + cpos), text, c2);
			cpos += 24;
		}
	}
	RenderTextCentered(secondLoc, Text::StripOpenplanetFormatCodes(string(medalGoals[1]["Icon"])),  c2);
	if (int(medalGoals[1]["Time"]) > 0) {
		RenderBoxCentered(vec2(width/2-100+l*100,yPos), vec2(l*200,30), vec4(lerpVec.x,lerpVec.y,lerpVec.z,0.5));
	}
	bool bsr = RenderBoxCentered(vec2(width/2,yPos), vec2(200,30), vec4(1,1,1,0));
	if (bsr && currentPb > 0 && int(medalGoals[1]["Time"]) > 0) {
		string text = "+" + Time::Format(int(delta), true);
		vec2 tbounds = nvg::TextBounds(text);
		RenderBoxCentered(vec2(width/2,yPos + 30 + cpos), vec2(tbounds.x+6,24), vec4(0,0,0,0.5));
		RenderTextCentered(vec2(width/2,yPos + 30 + cpos), text, lerpVec);
		cpos += 24;
	}
	if (unbeatenAt == true && UATDisplay) {
		string text = "Unbeaten AT";
		vec2 tbounds = nvg::TextBounds(text);
		vec2 sz = vec2(tbounds.x+6,24);
		float difr = (float(Time::get_Now()) % 1000)/1000;
		float difr2 = float(Time::get_Now()) % 5000;
		vec4 hsc = UI::HSV(float(Time::get_Now())/5000, 1, 1);
		RenderBoxCentered(vec2(width/2,yPos + 30 + cpos), sz, vec4(0,0,0,0.5));
		if (difr2 < 1000) {
			RenderBoxCentered(vec2(width/2,yPos + 30 + cpos), sz + vec2(10*(1-difr)+1,0), hsc - vec4(0,0,0,0.5+(difr/2)));
		}
		RenderTextCentered(vec2(width/2,yPos + 30 + cpos), text, hsc);
		cpos += 24;
	}
	auto cdelta = Time::get_Now()-lastPbUpdate;
	if (cdelta < 1000) {
		RenderBoxCentered(vec2(width/2,yPos), vec2(272,36) + vec2(10*(1-float(cdelta)/1000)+1,0), vec4(1,1,1,0.5-(float(cdelta)/1000/2)));
	}
}

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

void UpdateMedals() {
	auto app = cast<CTrackMania>(GetApp());
	auto track = app.RootMap;
	if (track !is null) {
		if ((wr_time == -2 && ((ReloadWRTime == RWT::Normal) || (ReloadWRTime == RWT::Once))) || (Time::get_Now()-lastWrUpdate > 120000 && ReloadWRTime == RWT::Normal)) {
			wr_time = getTimeAtPos(1);
			lastWrUpdate = Time::get_Now();
		} else if (wr_time > 0) {
			times.InsertLast({{"Icon", "\\$00f" + Icons::Trophy},{"Time", wr_time}});
		}
		auto mapInfo = track.MapInfo;
		times = {};
		times.InsertLast({{"Icon", "\\$900" + Icons::CircleO},{"Time", mapInfo.TMObjective_BronzeTime}});
		times.InsertLast({{"Icon", "\\$999" + Icons::CircleO},{"Time", mapInfo.TMObjective_SilverTime}});
		times.InsertLast({{"Icon", "\\$fc0" + Icons::DotCircleO},{"Time", mapInfo.TMObjective_GoldTime}});
		times.InsertLast({{"Icon", "\\$090" + Icons::Circle},{"Time", mapInfo.TMObjective_AuthorTime}});
#if DEPENDENCY_WARRIORMEDALS
		times.InsertLast({{"Icon", "\\$0af" + Icons::PlusCircle},{"Time", WarriorMedals::GetWMTime()}});
#endif
#if DEPENDENCY_CHAMPIONMEDALS
		times.InsertLast({{"Icon", "\\$f05" + Icons::PlusCircle},{"Time", ChampionMedals::GetCMTime()}});
#endif

	} else {
		wr_time = -2;
		unbeatenAt = false;
		lastPb = -2;
		times = {};
	}
}

array<dictionary> GetCurPbMedal() {
	dictionary curPbMedal = {{"Icon","\\$000"},{"Time",999999999}};
	dictionary nextPbMedal = {{"Icon","\\$000"},{"Time",0}};
	int fixedCurPb = (currentPb <= 0) ? 999999999 : currentPb;
	for (uint i = 0; i < times.Length; i++) {
		if (fixedCurPb <= int(times[i]["Time"])) {
			if (int(times[i]["Time"]) <= int(curPbMedal["Time"])) {
				curPbMedal = times[i];
			}
		}
		if (fixedCurPb > int(times[i]["Time"])) {
			if (int(times[i]["Time"]) > int(nextPbMedal["Time"])) {
				nextPbMedal = times[i];
			}
		}
	}
	return {curPbMedal, nextPbMedal};
}

void Main() {
	while (true) {
		if (! Permissions::ViewRecords()) {
			UI::ShowNotification("Medal Progress", "You can't use Medal Progress because you don't have Standard or Club Access.");
			return;
		}
		yield();
		UpdateMedals();
		UpdateCurrentPb();
	}
}

void Render() {
	if (! Permissions::ViewRecords()) {
		return;
	}
	displayPbBar();
}
