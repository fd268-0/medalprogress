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
	if (SettingHandler::HideCustInMenu && track is null) {
		return;
	}

	int width = Display::GetWidth();
	int yPos = SettingHandler::YPosition;
	auto font = nvg::LoadFont("Montserrat-Regular.ttf");
	nvg::FontFace(font);
	nvg::FontSize(20);
	array<dictionary> medalGoals = StatHandler::GetCurPbMedal();
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
				startDrag = SettingHandler::YPosition;
			}
			SettingHandler::YPosition = startDrag+int(UI::GetMouseDragDelta().y);
		} else {
			startDrag = -1;
		}
		RenderBoxCentered(secondLoc + vec2(25,0), vec2(10,3), vec4(0,0,0,1));
		RenderBoxCentered(secondLoc + vec2(25,6), vec2(10,3), vec4(0,0,0,1));
		RenderBoxCentered(secondLoc + vec2(25,-6), vec2(10,3), vec4(0,0,0,1));
		vec4 opColor = vec4(0,1,0,1);
		if (! SettingHandler::Enabled) {
			opColor = vec4(1,0,0,1);
		}
		if ((RenderBoxCentered(secondLoc + vec2(39,0), vec2(14,30), opColor)) && UI::IsMouseClicked()) {
			SettingHandler::Enabled = ! SettingHandler::Enabled;
		}
		RenderBoxCentered(secondLoc + vec2(39,0), vec2(10,3), vec4(0,0,0,1));
		if (! SettingHandler::Enabled) {
			RenderBoxCentered(secondLoc + vec2(39,0), vec2(3,10), vec4(0,0,0,1));
		}
		if ((RenderBoxCentered(firstLoc - vec2(25,0), vec2(14,30), vec4(0,1,1,1))) && UI::IsMouseClicked()) {
			Meta::OpenSettings();
		}
		RenderBoxCentered(firstLoc - vec2(25,0), vec2(10,3), vec4(0,0,0,1));
		RenderBoxCentered(firstLoc - vec2(25,-6), vec2(10,3), vec4(0,0,0,1));
		RenderBoxCentered(firstLoc - vec2(25,6), vec2(10,3), vec4(0,0,0,1));
		RenderBoxCentered(firstLoc - vec2(28.5,3), vec2(3,5), vec4(0,0,0,1));
		RenderBoxCentered(firstLoc - vec2(21.5,-3), vec2(3,5), vec4(0,0,0,1));
	}
	if (Display::GetHeight() > 0) {
		SettingHandler::YPosition = Math::Clamp(SettingHandler::YPosition, 0, Display::GetHeight());
	}


	if ((track !is null || UI::IsOverlayShown() == true) && SettingHandler::Enabled == true) {
		if (track !is null) {
			auto challengeParams = track.ChallengeParameters;
			if (! string(challengeParams.MapType).Contains('TM_Race')) {
				if (SettingHandler::Enabled == true && UI::IsOverlayShown() == true) {
					RenderBoxCentered(vec2(width/2,yPos), vec2(272,36), vec4(0,0,0,0.5));
				}
				return;
			}
		}
		RenderBoxCentered(vec2(width/2,yPos), vec2(272,36), vec4(0,0,0,0.5));
	}
	if (track is null || SettingHandler::Enabled == false) {
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
	if (unbeatenAt == true && SettingHandler::UATDisplay) {
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



void Main() {
	SettingHandler::LoadSettings();
	
	while (true) {
		if (! Permissions::ViewRecords()) {
			UI::ShowNotification("Medal Progress", "You can't use Medal Progress because you don't have Standard or Club Access.");
			return;
		}
		yield();
		StatHandler::UpdateMedals();
		StatHandler::UpdateCurrentPb();
	}
}

void Render() {
	if (! Permissions::ViewRecords()) {
		return;
	}
	displayPbBar();
}
