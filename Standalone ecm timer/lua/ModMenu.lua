Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_ECM_Timer_v2", function( loc )
	local localization = ECM_Timer_v2._path .. "loc/"
	local GetFiles = _G.file.GetFiles
	local Idstring = _G.Idstring
	local activelanguagekey = SystemInfo:language():key()
	for __, filename in ipairs(GetFiles(localization)) do
		if Idstring(filename:match("^(.*).json$") or ""):key() == activelanguagekey then
			loc:load_localization_file(localization .. filename)
		    break
		end
	end
	loc:load_localization_file(localization .. "english.json", false)
end)

Hooks:Add("MenuManagerBuildCustomMenus", "MenuManagerBuildCustomMenus_ECM_Timer_v2", function(menu_manager, nodes)
    MenuCallbackHandler.OpenECM_Timer_v2ModOptions = function(self, item)
        ECM_Timer_v2.Menu = ECM_Timer_v2.Menu or ECM_Timer_v2Menu:new()
		ECM_Timer_v2.Menu:Open()

        Hooks:PostHook(MenuManager, "update", "update_menu_ECM_Timer_v2", function(self, t, dt)
            if ECM_Timer_v2.Menu and ECM_Timer_v2.Menu.update and ECM_Timer_v2.Menu._enabled then
                ECM_Timer_v2.Menu:update(t, dt)
            end
        end)
	end

	local node = nodes["blt_options"]

	local item_params = {
		name = "ECM_Timer_v2_OpenMenu",
		text_id = "ECM_Timer_v2_title",
		help_id = "ECM_Timer_v2_desc",
		callback = "OpenECM_Timer_v2ModOptions",
		localize = true,
	}
	local item = node:create_item({type = "CoreMenuItem.Item"}, item_params)
    node:add_item(item)
end)