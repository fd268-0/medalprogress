namespace JsonLoader {

    dictionary UnpackDictionary(const Json::Value@ statsData) {
        dictionary statistics = {};
        auto statsKeys = statsData.GetKeys();
        for (uint i = 0; i < statsKeys.Length; i++) {
            string key = statsKeys[i];
            auto value = statsData[key];

            if (value.GetType() == Json::Type::Number) {
                statistics[key] = float(statsData[key]);
            } else if (value.GetType() == Json::Type::String) {
                statistics[key] = string(statsData[key]);
            } else if (value.GetType() == Json::Type::Boolean) {
                statistics[key] = bool(statsData[key]);
            } else {
                warn("Unsupported type in Json at key " + key);
            }
        }
        return statistics;
    }

    dictionary JsonToDictionary(const string filename) {
        dictionary statistics = {};
        string storageLocation = IO::FromStorageFolder(filename);

        if (! IO::FileExists(storageLocation)) {
            warn("No file found, setting contents...");
            Json::ToFile(storageLocation, Json::Object());
        }
        auto statsData = Json::FromFile(storageLocation);

        if (statsData.GetType() != Json::Type::Object) {
            warn("Non-object Json base value found, overwriting contents...");
            statsData = Json::Object();
        }

        statistics = UnpackDictionary(statsData);

        return statistics;
    }

    void SaveDictionaryToFile(const string fileName, const dictionary dict) {
        string storageLocation = IO::FromStorageFolder(fileName);

        Json::ToFile(storageLocation, dict.ToJson());
    }
}
