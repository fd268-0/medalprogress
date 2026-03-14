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
        int setting = int(jsonSettings["mdl_"+itemName]);
        float b0 = ((setting == 0) ? (0.3) : (0));
        float b1 = ((setting == 1) ? (0.3) : (0));
        float b2 = ((setting == 2) ? (0.3) : (0));
        float b3 = ((setting == 3) ? (0.3) : (0));
        UI::PushID("E"+i);
        if (UI::ButtonColored("\\$0f0Enabled", 0.4f, b0, b0)) {
           jsonSettings["mdl_"+itemName] = 0;
           SaveSettings();
        }
        UI::PopID();
        UI::PushID("D"+i);
        UI::SameLine();
        if (UI::ButtonColored("\\$f00Disabled", 0, b1, b1)) {
            jsonSettings["mdl_"+itemName] = 1;
            SaveSettings();
        }
        UI::PopID();
        UI::PushID("A"+i);
        UI::SameLine();
        if (UI::ButtonColored("\\$990Ahead", 0.15f, b2, b2)) {
            jsonSettings["mdl_"+itemName] = 2;
            SaveSettings();
        }
        UI::SetItemTooltip("Only shows if you have \\$0f0already\\$fff achieved the medal.");
        UI::PopID();
         UI::PushID("B"+i);
        UI::SameLine();
        if (UI::ButtonColored("\\$990Behind", 0.15f, b3, b3)) {
            jsonSettings["mdl_"+itemName] = 3;
            SaveSettings();
        }
         UI::SetItemTooltip("Only shows if you have \\$f00not\\$fff achieved the medal.");
        UI::PopID();
         UI::SameLine();
        UI::Text(item);
        UI::SameLine();
        UI::Text(itemName);
	}
    UI::Text("\\$999" + Icons::InfoCircle + " Get Champion Medals, Warrior Medals, and Map Info for all times.");
}

}
