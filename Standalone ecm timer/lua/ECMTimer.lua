if RequiredScript == "lib/managers/hudmanagerpd2" then
	EcmTimer = EcmTimer or class()

    function EcmTimer:init(hud)
		self._ecm_timer = 0
	    self._hud_panel = hud.panel
	    self._ecm_panel = self._hud_panel:panel({
		    name = "ecm_counter_panel",
			alpha =	1,
		    visible = false,
			y = 50,
		    w = 200,
		    h = 200
	    })
		self._hostages_panel = self._hud_panel:child("hostages_panel")
		if self._hostages_panel and alive(self._hostages_panel) then
			self._ecm_panel:set_top(self._hostages_panel:bottom() + 5)
		end
        self._ecm_panel:set_right(self._hud_panel:w() + 11)

	    local ecm_box = HUDBGBox_create(self._ecm_panel, { w = 38, h = 38, },  {})
		if ECM_Timer_v2:GetOption("hide_hudbox") then
			for _, child in ipairs({"bg", "left_top", "left_bottom", "right_top", "right_bottom"}) do
				ecm_box:child(child):hide()
			end
	    end

	    self._text = ecm_box:text({
		    name = "text",
		    text = "0",
		    valign = "center",
		    align = "center",
		    vertical = "center",
		    w = ecm_box:w(),
		    h = ecm_box:h(),
		    layer = 1,
		    color = ECM_Timer_v2:GetColor("ECMText"),
		    font = tweak_data.hud_corner.assault_font,
		    font_size = tweak_data.hud_corner.numhostages_size * 0.9
	    })

	    local ecm_icon = self._ecm_panel:bitmap({
		    name = "ecm_icon",
		    texture = "guis/textures/pd2/skilltree/icons_atlas",
		    texture_rect = { 64, 4 * 64, 64, 64 },
		    valign = "top",
			color = ECM_Timer_v2:GetColor("ECMIcon"),
		    layer = 1,
		    w = ecm_box:w(),
		    h = ecm_box:h()	
	    })
	    ecm_icon:set_right(ecm_box:parent():w())
	    ecm_icon:set_center_y(ecm_box:h() / 2)
		ecm_box:set_right(ecm_icon:left())
    end
	
	function EcmTimer:start_ecm_timer(end_time)
		if not (managers.groupai and managers.groupai:state():whisper_mode()) then
			return
		end
		self._ecm_timer = end_time

		self._text:stop()
		self._text:animate(function(o)
			while alive(o) do
				local t = self._ecm_timer - TimerManager:game():time()
				local is_stealth = managers.groupai and managers.groupai:state():whisper_mode()
				if t <= 0 then break end
				self._ecm_panel:set_visible(t > 0.1 and is_stealth)
				o:set_color(ECM_Timer_v2:GetColor("ECMText"))
				o:set_text(string.format(t < 10 and "%.1fs" or "%.0fs", t))

				if t < 3 then
					o:set_color(ECM_Timer_v2:GetColor("ecm_low"))
					if ECM_Timer_v2:GetOption("animate_low") then
						local pulse = 1 - math.sin(t * 700)
						local font = tweak_data.hud_corner.numhostages_size * 0.9
						o:set_font_size(math.lerp(font, font * 1.05, pulse))
					end
				elseif t < 10 then
					o:set_color(ECM_Timer_v2:GetColor("ecm_mid"))
				end

				coroutine.yield()
			end
		end)
	end

	--Init
	Hooks:PostHook(HUDManager, "_setup_player_info_hud_pd2", "ets_setup_player_info_hud_pd2", function(self)
		self._hud_ecm_counter = EcmTimer:new(managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2))
	end)

elseif RequiredScript == "lib/units/equipment/ecm_jammer/ecmjammerbase" then
	-- ECM in chat
	local counter = 0
	
	Hooks:PostHook(ECMJammerBase, "init", "ets_ECMJammerBase_init", function (self, ...)
		counter = counter + 1
	end)
	
	Hooks:PostHook(ECMJammerBase, "update", "ets_ECMJammerBase_update", function (self, ...)
		local low_time = ECM_Timer_v2:GetOption("low_time") or 5
		local stealth = managers.groupai and managers.groupai:state():whisper_mode()
		if self:active() and not self.notified and self._battery_life and self._battery_life < low_time and managers.chat and stealth and ECM_Timer_v2:GetOption("chat_ecm") then
			local ecm_color = ECM_Timer_v2:GetColor("ecm_color") or Color("09b1db")
			self.notified = true
			counter = counter - 1
			if counter == 0 then
				local peer = managers.network and managers.network:session() or nil
				peer = peer and peer:local_peer() or nil
				if peer then
					managers.chat:_receive_message(1, managers.localization:text("ECM_Timer_v2ChatTitle"), low_time..managers.localization:text("ECM_Timer_v2ChatText"), ecm_color)
				end
			end
		end
	end)
	
	local original_spawn = ECMJammerBase.spawn
	function ECMJammerBase.spawn(pos, rot, battery_life_upgrade_lvl, owner, peer_id, ...)
		local unit = original_spawn(pos, rot, battery_life_upgrade_lvl, owner, peer_id, ...)
		unit:base():SetPeersID(peer_id)
		return unit
	end
	
	Hooks:PostHook(ECMJammerBase, "set_server_information", "ets_ECMJammerBase_set_server_information", function(self, peer_id, ...)
		self:SetPeersID(peer_id)
	end)

	Hooks:PostHook(ECMJammerBase, "sync_setup", "ets_ECMJammerBase_sync_setup", function(self, upgrade_lvl, peer_id, ...)
		self:SetPeersID(peer_id)
	end)

	Hooks:PostHook(ECMJammerBase, "set_owner", "ets_ECMJammerBase_set_owner", function(self, ...)
		self:SetPeersID(self._owner_id or 0)
	end)

	function ECMJammerBase:SetPeersID(peer_id)
		local id = peer_id or 0
		self._ets_peer_id = id
		self._ets_local_peer = id == managers.network:session():local_peer():id()
	end

	--ECM Timer Host and Client
	Hooks:PostHook(ECMJammerBase, "set_active", "ets_ECMJammerBase_set_active", function(self, active, ...)
		if active and ECM_Timer_v2:GetOption("infoboxes") then
			local battery_life = self:battery_life()
			if battery_life == 0 then
				return
			end
			local jam_pagers = false
			if self._ets_local_peer then
				jam_pagers = managers.player:has_category_upgrade("ecm_jammer", "affects_pagers")
			elseif self._ets_peer_id ~= 0 then
				local peer = managers.network:session():peer(self._ets_peer_id)
				if peer and peer._unit and peer._unit.base then
					jam_pagers = peer._unit:base():upgrade_value("ecm_jammer", "affects_pagers")
				end
			end
			if jam_pagers or not ECM_Timer_v2:GetOption("pager_jam") then
				local end_time = TimerManager:game():time() + battery_life
				managers.hud._hud_ecm_counter:start_ecm_timer(end_time)
			else
				return
			end
		end
	end)

elseif RequiredScript == "lib/units/beings/player/playerinventory" then
	-- Pocket ECM
	Hooks:PostHook(PlayerInventory, "_start_jammer_effect", "ets_PlayerInventory__start_jammer_effect", function(self, end_time, ...)
		if ECM_Timer_v2:GetOption("infoboxes") and ECM_Timer_v2:GetOption("pocket_ecm") then
			local ecm_end_time = end_time or TimerManager:game():time() + self:get_jammer_time()
			if managers.hud and managers.hud._hud_ecm_counter and ecm_end_time > managers.hud._hud_ecm_counter._ecm_timer then
				managers.hud._hud_ecm_counter:start_ecm_timer(ecm_end_time)
			end
		end
	end)
end