array<PMedal> times = {};
array<PMedal> allTimes = {};
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

vec2 RenderTextBoxCentered(const vec2 pos, const string text, vec4 txCol, vec4 bgCol) {
	vec2 tbounds = nvg::TextBounds(text);
	vec2 boxBounds = vec2(tbounds.x+6,24);

	if (SettingHandler::AccessableText == true) {
		bgCol = vec4(Math::Abs(txCol.x-1),Math::Abs(txCol.y-1),Math::Abs(txCol.z-1),bgCol.w);
	}

	vec3 txColBg = UI::ToHSV(txCol.x, txCol.y, txCol.z);
	vec3 hsvBg = UI::ToHSV(bgCol.x, bgCol.y, bgCol.z);
	if (SettingHandler::AccessableText == false) {
		if (txColBg.z < 0.3 && hsvBg.z < 0.3) {
			hsvBg.z += 0.7;
		}
	}
	float alpha = bgCol.w;
	bgCol = UI::HSV(hsvBg.x, hsvBg.y, hsvBg.z);
	bgCol.w = alpha;
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
	vec4 c1 = medalGoals[0].GetColorOfMedal();
	vec4 c2 = medalGoals[1].GetColorOfMedal();
	float delta = float(currentPb) - float(medalGoals[1].Time);
	float l = ((float(currentPb) - float(medalGoals[0].Time)) / (float(medalGoals[1].Time) - float(medalGoals[0].Time)));
	if (currentPb <= 0) {
		l = 0;
	}
	int cpos = 0;
	vec4 lerpVec = Math::Lerp(c1,c2,l);
	vec2 firstLoc = vec2(width/2-(SettingHandler::XSize+18),yPos);
	vec2 secondLoc = vec2(width/2+(SettingHandler::XSize+18),yPos);

	if (UI::IsOverlayShown() == true && SettingHandler::CustomizationEnabled) {
		bool rbY = RenderBoxCentered(secondLoc + vec2(25,0), vec2(14,30), vec4(1,1,1,1));
		if (rbY && UI::IsMouseClicked()) {
			yDragStarted = true;
		}
		if ((rbY || yDragStarted == true) && UI::IsMouseDown() && xDragStarted == false) {
			if (startYDrag == -1) {
				startYDrag = SettingHandler::YPosition;
			}
			SettingHandler::YPosition = startYDrag+int(UI::GetMouseDragDelta().y);
			if (Math::Abs(startYDrag-60) > 8 && Math::Abs(SettingHandler::YPosition-60) < 4) {
				SettingHandler::YPosition = 60;
			}
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
			if (Math::Abs(startXDrag-100) > 8 && Math::Abs(SettingHandler::XSize-100) < 4) {
				SettingHandler::XSize = 100;
			}
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
	SettingHandler::ClampSettings();
	if (xDragStarted) {
		RenderTextBoxCentered(vec2(width/2,yPos + 30 + cpos), Icons::CaretLeft+" "+SettingHandler::XSize, vec4(0,0,0,1), vec4(1,1,1,1));
		cpos += 24;
	}
	if (yDragStarted) {
		RenderTextBoxCentered(vec2(width/2,yPos + 30 + cpos), Icons::CaretDown+" "+SettingHandler::YPosition, vec4(0,0,0,1), vec4(1,1,1,1));
		cpos += 24;
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
	if (bs1 && int(medalGoals[1].Time) <= 0 && int(medalGoals[0].Time) != 999999999) {
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
	array<PMedal> visiblePMedals = StatHandler::GetVisiblePMedals();
	int actualDBS = Math::Min(SettingHandler::DisplayBarSize, SettingHandler::XSize);
	if (actualDBS > 0 && visiblePMedals.Length > 0) {
		if (SettingHandler::DisplayPreventOverlap) {
			for (int i = 0; i < int(visiblePMedals.Length); i++) {
				
				if (i > 0 && (visiblePMedals[i-1].GetBarPosition()-visiblePMedals[i].GetBarPosition()) < actualDBS) {
					visiblePMedals[i].SetBarPosition(int(visiblePMedals[i-1].GetBarPosition())-actualDBS);
				}
			}
		}
		for (int i = visiblePMedals.Length-1; i >= 0; i--) {
			int xPosition = visiblePMedals[i].GetBarPosition();
			vec4 vcol = visiblePMedals[i].GetColorOfMedal();
			vec2 vpos = vec2(width/2-SettingHandler::XSize+xPosition,yPos);
			vcol.w = 0.5;
			if (currentPb < visiblePMedals[i].Time && SettingHandler::DisplayBarTA) {
				vcol.w = 0.1;
			}
			if (actualDBS >= 20) {
				vec4 vtcol = vcol;
				vtcol.w = vtcol.w * 2;
				RenderTextCentered(vpos, Text::StripOpenplanetFormatCodes(string(visiblePMedals[i].Icon)), vtcol);
			}
			if (RenderBoxCentered(vpos, vec2(actualDBS,30), vcol)) {
				RenderTextBoxCentered(vec2(width/2,yPos + 30 + cpos), Time::Format(int(visiblePMedals[i].Time), true), visiblePMedals[i].GetColorOfMedal(), vec4(0,0,0,0.5));
				cpos += 24;
				RenderTextBoxCentered(vec2(width/2,yPos + 30 + cpos), (currentPb-visiblePMedals[i].Time > 0 ? "+" : "") + Time::Format(int(currentPb-visiblePMedals[i].Time), true), visiblePMedals[i].GetColorOfMedal(), vec4(0,0,0,0.5));
				cpos += 24;
			}
		}
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
