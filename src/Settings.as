enum RWT {
	Normal,
	Once,
	Never,
}
enum PROGRESSTYPE {
	NormalLerp,
	BarDisplayLerp,
	FirstMedalColor,
    NextMedalColor,
    AchievedBarDisplayColor,
    SolidColor,
}
enum CONFLICTHANDLE {
    DoNothing,
	Move,
    Scale,
}
namespace SettingHandler {

dictionary jsonSettings = {};
dictionary tempSettings = {};
dictionary icons = Icons::GetAll();

UI::Texture@ exampleBarDisplay = UI::LoadTexture("ExampleBarDisplay.png");

[Setting name="Bar Enabled" category="Display" description="Hides the bar, but not the customization part of the bar."]
bool Enabled = true;

[Setting name="Customization Buttons Enabled" category="Display" description="Hides the customization buttons on the sides of the bar."]
bool CustomizationEnabled = true;

[Setting name="Hide Customization In Menu" category="Display"]
bool HideCustInMenu = true;

[Setting name="High Contrast Text Display" category="Display" description="Makes the text easier to read."]
bool AccessableText = true;

[Setting name="Unbeaten AT Display" category="Display"]
bool UATDisplay = false;

[Setting name="Reload WR Time" category="Display"]
RWT ReloadWRTime = RWT::Normal;

[Setting name="YPosition" category="Display"]
int YPosition = 60;

[Setting name="Display Icon Autofill" category="Display" hidden]
bool IconAutofill = true;


[Setting name="XSize" category="Display"]
int XSize = 100;

[Setting name="Progress Bar Color" category="Display"]
PROGRESSTYPE ProgressBarColor = PROGRESSTYPE::NormalLerp;

[Setting name="Bar Medal Display Size" category="Display" description="Size of the bars from the Bar Display setting in Medals."]
int DisplayBarSize = 5;

[Setting name="Bar Medal Display Overlap Handling" category="Display" description="Handle visual display conflicts."]
CONFLICTHANDLE OverlapHandling = CONFLICTHANDLE::DoNothing;

[Setting name="Bar Medal Display Make Achieved Faint" category="Display" description="Makes achieved times from the Bar Display show more faint then non-achieved."]
bool DisplayBarTA = true;

string GetIconForName(const string name) {
    if (icons.Exists(name)) {
        return string(icons[name]);
    } else {
        return name;
    }
}

void LoadSettings() {
    jsonSettings = JsonLoader::JsonToDictionary("Settings.json");
}

void SaveSettings() {
    JsonLoader::SaveDictionaryToFile("Settings.json", jsonSettings);
}

void ClampSettings() {
    int width = Display::GetWidth();
    int height = Display::GetHeight();
    if (height > 0) {
		YPosition = Math::Clamp(YPosition, 0, height);
	}
	if (width > 0) {
		XSize = Math::Clamp(XSize, -1, width/2-65);
	}
    DisplayBarSize = Math::Max(0, DisplayBarSize);
}

void ResetSettings(const string&in contains = "") {
    auto keys = jsonSettings.GetKeys();
    for (uint i = 0; i < keys.Length; i++) {
         auto itemName = keys[i];
        if (itemName.Contains(contains) || contains == "") {
            jsonSettings.Delete(itemName);
        }
    }
    SaveSettings();
}

void UsePreset(const dictionary preset) {
    ResetSettings("mdl_");
    auto keys = preset.GetKeys();
    for (uint i = 0; i < keys.Length; i++) {
        auto itemName = keys[i];
        auto item = preset[itemName];
        jsonSettings[itemName] = int(item);
    }
    SaveSettings();
}

void RenderButtonSetting(const string settingName, const string name, const int num, const float color, const int&in overrideHighlight = -1) {
    float b0 = ((int(jsonSettings[settingName]) == ((overrideHighlight != -1) ? overrideHighlight : num)) ? (0.3) : (0));
    UI::PushID(settingName+name);
    if (UI::ButtonColored(name, color, b0, b0)) {
        jsonSettings[settingName] = num;
        SaveSettings();
    }
    UI::PopID();
}

[SettingsTab name="Medals"]
void RenderMedalSelection() {
    if (UI::Button("Reset display to default")) {
        ResetSettings("mdl_");
    }
    UI::SameLine();
    if (UI::Button("Reset icons to default")) {
        ResetSettings("txt_");
        StatHandler::UpdatePossibleMedals();
    }
    for (uint i = 0; i < StatHandler::possibleMedals.GetKeys().Length; i++) {
        // INIT
		auto itemName = StatHandler::possibleMedals.GetKeys()[i];
		auto item = string(StatHandler::possibleMedals[itemName]);
        if (! jsonSettings.Exists("mdl_"+itemName)) {
            jsonSettings["mdl_"+itemName] = 0;
            if (string(itemName) == "Worst Time") {
                jsonSettings["mdl_"+itemName] = 2;
            }
        }
        if (! jsonSettings.Exists("mdl_"+itemName+"_bar")) {
            jsonSettings["mdl_"+itemName+"_bar"] = 0;
        }
        if (! jsonSettings.Exists("txt_"+itemName)) {
            jsonSettings["txt_"+itemName] = "";
        }
         if (! jsonSettings.Exists("txt_"+itemName+"_clr")) {
            jsonSettings["txt_"+itemName+"_clr"] = "";
        }
        string settingName = "mdl_"+itemName;
        string iconText = string(jsonSettings["txt_"+itemName]);
        int setting = int(jsonSettings[settingName]);
        int barSetting = int(jsonSettings[settingName+"_bar"]);

        // RENDER OPTIONS FOR BAR DISPLAY AND VISIBILITY
        RenderButtonSetting(settingName, "\\$0f0Enabled", 0, 0.4f);
        UI::SameLine();
        RenderButtonSetting(settingName, "\\$f00Disabled", 1, 0);
        UI::SameLine();
        RenderButtonSetting(settingName, "\\$990Ahead", 2, 0.15f);
        UI::SetItemTooltip("Only shows if you have \\$0f0already\\$fff achieved the medal.");
        UI::SameLine();
        RenderButtonSetting(settingName, "\\$990Behind", 3, 0.15f);
        UI::SetItemTooltip("Only shows if you have \\$f00not\\$fff achieved the medal.");
         UI::SameLine();

        RenderButtonSetting(settingName+"_bar", "\\$0ffBar Display", (barSetting == 0) ? 1 : 0, 0.55f, 1);

        UI::SetItemTooltip("Only works if the time is in between the two visible times. For this to happen, it can not be enabled.");
        UI::SameLine();
        if (iconText != "") {
            UI::Text(string(StatHandler::possibleMedals[itemName]));
        } else {
            UI::Text(item);
        }
        UI::SameLine();
        UI::Text(itemName);
        
        // EDIT ICON COLOR AND NAME
        UI::SameLine();
        UI::PushID(settingName+"_pncl");
        bool hsEditOpen = bool(tempSettings[settingName+"_edit"]);
        if (UI::ButtonColored(Icons::Pencil, 0.7f, hsEditOpen ? 0.5 : 0, 0.13)) {
            tempSettings[settingName+"_edit"] = !bool(tempSettings[settingName+"_edit"]);
        }
        UI::PopID();
        if (hsEditOpen) {
            bool changedName = false;
            bool changedClr = false;
            UI::Text(Icons::Pencil+" Input custom icon for " + itemName + " \\$999(i.e. Circle)");
            UI::PushID(settingName+"_edit");
            jsonSettings["txt_"+itemName] = UI::InputText("", iconText, changedName);
            UI::PopID();
            UI::PushID(settingName+"_btnSel");
            UI::PopID();
            if (IconAutofill) {
                UI::BeginChild(settingName+"_editChoices", vec2(600,45), UI::ChildFlags::AlwaysAutoResize | UI::ChildFlags::AutoResizeX, UI::WindowFlags::AlwaysHorizontalScrollbar);
                auto iKeys = icons.GetKeys();
                for (uint iconIndex = 0; iconIndex < iKeys.Length; iconIndex++) {
                    string iconName = iKeys[iconIndex];
                    if (iconName.Contains(iconText)) {
                        string icon = string(icons[iconName]);
                        if (UI::Button(icon)) {
                            jsonSettings["txt_"+itemName] = iconName;
                            changedName = true;
                        }
                        UI::SameLine();
                     }
                }
                UI::EndChild();
            }
            UI::Text(Icons::Pencil+" Input custom icon color for " + itemName + " \\$999(i.e. 19f)");
            string iconColor = string(jsonSettings["txt_"+itemName+"_clr"]);
            UI::PushID(settingName+"_editClr");
            jsonSettings["txt_"+itemName+"_clr"] = UI::InputText("", iconColor, changedClr).SubStr(0,3);
            UI::PopID();
            if (changedName || changedClr) {
                SaveSettings();
                StatHandler::UpdatePossibleMedals();
            }
        }
	}
    // PRESETS AND OTHER EXPLAINING
    UI::Text("\\$999" + Icons::InfoCircle + " Get Champion Medals, Warrior Medals, and Map Info for all times.");
     UI::Text("\\$999" + Icons::InfoCircle + " Bar Display is used when the time is in between the two visible times. For this to happen, it can not be enabled.");
    UI::Separator();
     UI::Text("\\$0f0" + Icons::Bolt + " Preset: AT Hunting + Bar Display Example");
    UI::Image(exampleBarDisplay);
    if (UI::Button("Load Preset")) {
        UsePreset({
            {"mdl_Silver",1},
            {"mdl_Gold",1},
            {"mdl_Warrior",1},
            {"mdl_Worst Time",2},
            {"mdl_World Record",1},
            {"mdl_Champion",1},
            {"mdl_Silver_bar",1},
            {"mdl_Gold_bar",1},
            {"mdl_Warrior_bar",1},
            {"mdl_World Record_bar",1},
            {"mdl_Champion_bar",1}
        });
    }
    UI::Separator();
    IconAutofill = UI::Checkbox("Display Icon Autofill", IconAutofill);

}

}
