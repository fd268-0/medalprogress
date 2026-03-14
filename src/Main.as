array<PMedal> times = {};
int currentPb = 0;
int wr_time = -2;
int lastPbUpdate = -1000;
int lastWrUpdate = -1000;
int lastPb = 0;

int startYDrag = -1;
bool yDragStarted = false;

int startXDrag = -1;
bool xDragStarted = false;

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

vec2 RenderTextBoxCentered(const vec2 pos, const string text, const vec4 txCol, const vec4 bgCol) {
	vec2 tbounds = nvg::TextBounds(text);
	vec2 boxBounds = vec2(tbounds.x+6,24);
	RenderBoxCentered(pos, boxBounds, bgCol);
	RenderTextCentered(pos, text, txCol);
	return boxBounds;
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
	array<PMedal> medalGoals = StatHandler::GetCurPbMedal();
	vec4 c1 = Text::ParseHexColor("#" + string(medalGoals[0].Icon).SubStr(2,1) + "0" + string(medalGoals[0].Icon).SubStr(3,1) + "0" + string(medalGoals[0].Icon).SubStr(4,1) + "0ff");
	vec4 c2 = Text::ParseHexColor("#" + string(medalGoals[1].Icon).SubStr(2,1) + "0" + string(medalGoals[1].Icon).SubStr(3,1) + "0" + string(medalGoals[1].Icon).SubStr(4,1) + "0ff");
	float delta = float(currentPb) - float(medalGoals[1].Time);
	float l = ((float(currentPb) - float(medalGoals[0].Time)) / (float(medalGoals[1].Time) - float(medalGoals[0].Time)));
	if (currentPb <= 0) {
		l = 0;
	}
	int cpos = 0;
	vec4 lerpVec = Math::Lerp(c1,c2,l);
	vec2 firstLoc = vec2(width/2-(SettingHandler::XSize+18),yPos);
	vec2 secondLoc = vec2(width/2+(SettingHandler::XSize+18),yPos);

	if (UI::IsOverlayShown() == true) {
		bool rbY = RenderBoxCentered(secondLoc + vec2(25,0), vec2(14,30), vec4(1,1,1,1));
		if (rbY && UI::IsMouseClicked()) {
			yDragStarted = true;
		}
		if ((rbY || yDragStarted == true) && UI::IsMouseDown() && xDragStarted == false) {
			if (startYDrag == -1) {
				startYDrag = SettingHandler::YPosition;
			}
			SettingHandler::YPosition = startYDrag+int(UI::GetMouseDragDelta().y);
		} else {
			startYDrag = -1;
			yDragStarted = false;
		}
		bool rbX = RenderBoxCentered(firstLoc - vec2(25,0), vec2(14,30), vec4(1,1,1,1));
		if (rbX && UI::IsMouseClicked()) {
			xDragStarted = true;
		}
		if ((rbX || xDragStarted == true) && UI::IsMouseDown() && yDragStarted == false) {
			if (startXDrag == -2) {
				startXDrag = SettingHandler::XSize;
			}
			SettingHandler::XSize = startXDrag-int(UI::GetMouseDragDelta().x);
		} else {
			startXDrag = -2;
			xDragStarted = false;
		}
		RenderBoxCentered(secondLoc + vec2(25,0), vec2(10,3), vec4(0,0,0,1));
		RenderBoxCentered(secondLoc + vec2(25,6), vec2(10,3), vec4(0,0,0,1));
		RenderBoxCentered(firstLoc - vec2(28,0), vec2(3,18), vec4(0,0,0,1));
		RenderBoxCentered(firstLoc - vec2(22,0), vec2(3,18), vec4(0,0,0,1));
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
		if ((RenderBoxCentered(firstLoc - vec2(39,0), vec2(14,30), vec4(0,1,1,1))) && UI::IsMouseClicked()) {
			Meta::OpenSettings();
		}
		RenderBoxCentered(firstLoc - vec2(39,0), vec2(10,3), vec4(0,0,0,1));
		RenderBoxCentered(firstLoc - vec2(39,-6), vec2(10,3), vec4(0,0,0,1));
		RenderBoxCentered(firstLoc - vec2(39,6), vec2(10,3), vec4(0,0,0,1));
		RenderBoxCentered(firstLoc - vec2(42.5,3), vec2(3,5), vec4(0,0,0,1));
		RenderBoxCentered(firstLoc - vec2(35.5,-3), vec2(3,5), vec4(0,0,0,1));
	}
	if (Display::GetHeight() > 0) {
		SettingHandler::YPosition = Math::Clamp(SettingHandler::YPosition, 0, Display::GetHeight());
	}
	if (width > 0) {
		SettingHandler::XSize = Math::Clamp(SettingHandler::XSize, -1, width/2-65);
	}

	

	if ((track !is null || UI::IsOverlayShown() == true) && SettingHandler::Enabled == true) {
		if (track !is null) {
			auto challengeParams = track.ChallengeParameters;
			if (! string(challengeParams.MapType).Contains('TM_Race')) {
				if (SettingHandler::Enabled == true && UI::IsOverlayShown() == true) {
					RenderBoxCentered(vec2(width/2,yPos), vec2((SettingHandler::XSize*2)+72,36), vec4(0,0,0,0.5));
				}
				return;
			}
		}
		RenderBoxCentered(vec2(width/2,yPos), vec2((SettingHandler::XSize*2)+72,36), vec4(0,0,0,0.5));
	}
	if (track is null || SettingHandler::Enabled == false) {
		return;
	}
	vec2 firstSize = vec2(30,30);
	if (int(medalGoals[1].Time) <= 0) {
		firstLoc = vec2(width/2,yPos);
		firstSize = vec2((SettingHandler::XSize*2)+66,30);
	}
	bool bs1 = RenderBoxCentered(firstLoc, firstSize, vec4(c1.x,c1.y,c1.z,0.5));
	if (bs1 && int(medalGoals[0].Time) != 999999999) {
		RenderTextBoxCentered(vec2(width/2,yPos + 30 + cpos), Time::Format(int(medalGoals[0].Time), true), c1, vec4(0,0,0,0.5));
		cpos += 24;
	}
	if (bs1 && int(medalGoals[1].Time) <= 0) {
		RenderTextBoxCentered(vec2(width/2,yPos + 30 + cpos), Time::Format(currentPb - int(medalGoals[0].Time), true), c1, vec4(0,0,0,0.5));
		cpos += 24;
	}
	RenderTextCentered(firstLoc, Text::StripOpenplanetFormatCodes(string(medalGoals[0].Icon)),  c1);
	if (int(medalGoals[1].Time) > 0) {
		if (RenderBoxCentered(secondLoc, vec2(30,30), vec4(c2.x,c2.y,c2.z,0.5))) {
			RenderTextBoxCentered(vec2(width/2,yPos + 30 + cpos), Time::Format(int(medalGoals[1].Time), true), c2, vec4(0,0,0,0.5));
			cpos += 24;
		}
	}
	RenderTextCentered(secondLoc, Text::StripOpenplanetFormatCodes(string(medalGoals[1].Icon)),  c2);
	if (int(medalGoals[1].Time) > 0) {
		if (l*(SettingHandler::XSize*2) > 1) {
			RenderBoxCentered(vec2(width/2-SettingHandler::XSize+l*SettingHandler::XSize,yPos), vec2(l*(SettingHandler::XSize*2),30), vec4(lerpVec.x,lerpVec.y,lerpVec.z,0.5));
		}
	}
	bool bsr = RenderBoxCentered(vec2(width/2,yPos), vec2((SettingHandler::XSize*2),30), vec4(1,1,1,0));
	if (bsr && currentPb > 0 && int(medalGoals[1].Time) > 0) {
		RenderTextBoxCentered(vec2(width/2,yPos + 30 + cpos), "+" + Time::Format(int(delta), true), lerpVec, vec4(0,0,0,0.5));
		cpos += 24;
	}
	if (unbeatenAt == true && SettingHandler::UATDisplay) {
		string text = "Unbeaten AT";
		float difr = (float(Time::get_Now()) % 1000)/1000;
		float difr2 = float(Time::get_Now()) % 5000;
		vec4 hsc = UI::HSV(float(Time::get_Now())/5000, 1, 1);
		vec2 pos = vec2(width/2,yPos + 30 + cpos);
		vec2 sizeOfTxt = RenderTextBoxCentered(pos, text, hsc, vec4(0,0,0,0.5));
		cpos += 24;
		if (difr2 < 1000) {
			RenderBoxCentered(pos, sizeOfTxt + vec2(10*(1-difr)+1,0), hsc - vec4(0,0,0,0.5+(difr/2)));
		}
	}
	auto cdelta = Time::get_Now()-lastPbUpdate;
	if (cdelta < 1000) {
		RenderBoxCentered(vec2(width/2,yPos), vec2((SettingHandler::XSize*2)+72,36) + vec2(10*(1-float(cdelta)/1000)+1,0), vec4(1,1,1,0.5-(float(cdelta)/1000/2)));
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
