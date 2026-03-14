enum RWT {
	Normal,
	Once,
	Never,
}
namespace SettingHandler {

dictionary jsonSettings = {};

[Setting name="Enabled Topbar" category="Display"]
bool Enabled = true;

[Setting name="Hide Customization In Menu" category="Display"]
bool HideCustInMenu = true;

[Setting name="Unbeaten AT Display" category="Display"]
bool UATDisplay = false;

[Setting name="Reload WR Time" category="Display"]
RWT ReloadWRTime = RWT::Normal;

[Setting name="YPosition" category="Display"]
int YPosition = 60;

[Setting name="XSize" category="Display"]
int XSize = 100;

void InitSettings() {
    
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
}

void RenderButtonSetting(const string settingName, const string name, const int num, const float color) {
    float b0 = ((int(jsonSettings[settingName]) == num) ? (0.3) : (0));
    UI::PushID(settingName+name);
    if (UI::ButtonColored(name, color, b0, b0)) {
        jsonSettings[settingName] = num;
        SaveSettings();
    }
    UI::PopID();
}

[SettingsTab name="Medals"]
void RenderMedalSelection() {
    if (UI::Button("Reset to default")) {
        auto keys = jsonSettings.GetKeys();
        for (uint i = 0; i < keys.Length; i++) {
            auto itemName = keys[i];
            if (itemName.Contains("mdl_")) {
                jsonSettings.Delete(itemName);
            }
        }
        SaveSettings();
    }
    for (uint i = 0; i < StatHandler::possibleMedals.GetKeys().Length; i++) {

		auto itemName = StatHandler::possibleMedals.GetKeys()[i];
		auto item = string(StatHandler::possibleMedals[itemName]);
        if (! jsonSettings.Exists("mdl_"+itemName)) {
            jsonSettings["mdl_"+itemName] = 0;
            if (string(itemName) == "Worst Time") {
                jsonSettings["mdl_"+itemName] = 2;
            }
        }
        string settingName = "mdl_"+itemName;
        int setting = int(jsonSettings[settingName]);
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
        UI::Text(item);
        UI::SameLine();
        UI::Text(itemName);
	}
    UI::Text("\\$999" + Icons::InfoCircle + " Get Champion Medals, Warrior Medals, and Map Info for all times.");
}

}
