if not ECM_Timer_v2 then
    _G.ECM_Timer_v2 =
    {
        _path = ModPath,
        _menu_path = ModPath .. "Menu/",
        _data_path = SavePath .. "ECM_Timer_v2.json",
        SaveDataVer = 1,
        ModVersion = ModInstance and ModInstance:GetVersion() or "N/A",
        _data = {}
    }


    function ECM_Timer_v2:Save()
        local file = io.open( self._data_path, "w+" )
        if file then
            self._data.SaveDataVer = self.SaveDataVer
            file:write( json.encode( self._data ) )
            file:close()
        end
    end

    function ECM_Timer_v2:Load()
        self:LoadDefaults()
        local file = io.open( self._data_path, "r" )
        if file then
            local data = json.decode( file:read("*all") )
            file:close()
            if data.SaveDataVer and data.SaveDataVer == self.SaveDataVer then
                for k, v in pairs(data) do
                    if self._data[k] ~= nil then
                        self._data[k] = v
                    end
                end
            end
        end
    end

    function ECM_Timer_v2:LoadDefaults()
        local default_file = io.open(ECM_Timer_v2._path .."Menu/default_values.json")
        self._data = json.decode(default_file:read("*all"))
        default_file:close()
    end

    function ECM_Timer_v2:GetOption(id)
        return self._data[id]
    end

    function ECM_Timer_v2:GetColor(id)
        local color = self._data[id]
        if color and color.r and color.b and color.g then
            return Color(255, color.r, color.g, color.b) / 255
        end
        return Color.white
    end

    ECM_Timer_v2:Load()
end