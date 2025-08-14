local function hasCamera(ply, wep)
	if not IsValid(wep) then return false end
	return string.find(wep:GetClass(), "camera") ~= nil
end

if SERVER then
	if not game.SinglePlayer() then return end

	util.AddNetworkString("hidechatwithcamera")

	hook.Add("PlayerSwitchWeapon", "HideChatWithCamera", function(ply, oldWep, newWep)
		if not IsFirstTimePredicted() or oldWep == newWep then return end

		net.Start("hidechatwithcamera")
		net.WriteBool(hasCamera(ply, newWep))
		net.Broadcast()
	end)

	return
end

local hideChatCvar = CreateClientConVar("hide_chat_with_camera", 1, true, false, "Whether chat gets hidden with your camera out", 0, 1)
local hideGHUDCvar = CreateClientConVar("hide_ghud_with_camera", 0, true, false, "Whether all GLua hud elements are hidden with your camera out (usually not needed)", 0, 1)

local cameraOut
local chatOut

local lastChatOut = -1
local function hideCCHistory()
	if not CustomChat or not IsValid(CustomChat.frame) then
		hook.Remove("Think", "HideChatWithCamera_CC")
		return
	end

	if not cameraOut then
		CustomChat.frame.history:SetVisible(true)
		hook.Remove("Think", "HideChatWithCamera_CC")
		return
	end

	if lastChatOut ~= chatOut then
		CustomChat.frame.history:SetVisible(chatOut)
		lastChatOut = chatOut
	end
end

local function cameraHide()
	if IsValid(g_VoicePanelList) then
		g_VoicePanelList:Hide()
	end

	cameraOut = true

	if not hideChatCvar:GetBool() then return end

	if CustomChat and IsValid(CustomChat.frame) then
		lastChatOut = -1
		hook.Add("Think", "HideChatWithCamera_CC", hideCCHistory)
	end
end

local function cameraShow()
	if IsValid(g_VoicePanelList) then
		g_VoicePanelList:Show()
	end

	cameraOut = nil

	if not hideChatCvar:GetBool() then return end

	if CustomChat and IsValid(CustomChat.frame) then
		CustomChat.frame.history:SetVisible(true)
		hook.Remove("Think", "HideChatWithCamera_CC")
	end
end

if game.SinglePlayer() then
	net.Receive("hidechatwithcamera", function()
		if net.ReadBool() then
			cameraHide()
		else
			cameraShow()
		end
	end)
else
	hook.Add("PlayerSwitchWeapon", "HideChatWithCamera", function(ply, oldWep, newWep)
		if not IsFirstTimePredicted() or ply ~= LocalPlayer() or oldWep == newWep then return end

		if hasCamera(ply, newWep) then
			cameraHide()
		else
			cameraShow()
		end
	end)
end

hook.Add("StartChat", "HideChatWIthCamera", function()
	chatOut = true
end)

hook.Add("FinishChat", "HideChatWIthCamera", function()
	chatOut = nil
end)

cvars.AddChangeCallback("hide_chat_with_camera", function(_, oldVal, val)
	if oldVal == val then return end

	if val ~= "0" then
		if cameraOut then
			cameraHide()
		else
			cameraShow()
		end
	else
		if IsValid(g_VoicePanelList) then
			g_VoicePanelList:Show()
		end

		if CustomChat and IsValid(CustomChat.frame) then
			CustomChat.frame.history:SetVisible(true)
			hook.Remove("Think", "HideChatWithCamera_CC")
		end
	end
end)

hook.Add("HUDShouldDraw", "HideChatWithCamera", function(name)
	if not cameraOut then return end
	if hideChatCvar:GetBool() and not chatOut and name == "CHudChat" then return false end
	if hideGHUDCvar:GetBool() and name == "CHudGMod" then return false end
end)