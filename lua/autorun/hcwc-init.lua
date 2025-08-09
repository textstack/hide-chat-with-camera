if SERVER then
	if not game.SinglePlayer() then return end

	util.AddNetworkString("hidechatwithcamera")

	hook.Add("PlayerSwitchWeapon", "HideChatWithCamera", function(ply, oldWep, newWep)
		if not IsFirstTimePredicted() or oldWep == newWep then return end

		net.Start("hidechatwithcamera")

		if string.find(newWep:GetClass(), "camera") then
			net.WriteBool(true)
		elseif string.find(oldWep:GetClass(), "camera") then
			net.WriteBool(false)
		end

		net.Broadcast()
	end)

	return
end

local cameraOut
local chatOut

local lastChatOut
local function hideCCHistory()
	if not CustomChat or not IsValid(CustomChat.frame) then
		hook.Remove("Think", "HideChatWithCamera_CC")
		return
	end

	if lastChatOut ~= chatOut then
		CustomChat.frame.history:SetVisible(chatOut)
		lastChatOut = chatOut
	end
end

local function cameraHide()
	g_VoicePanelList:Hide()
	cameraOut = true

	if CustomChat and IsValid(CustomChat.frame) then
		lastChatOut = -1
		hook.Add("Think", "HideChatWithCamera_CC", hideCCHistory)
	end
end

local function cameraShow()
	g_VoicePanelList:Show()
	cameraOut = nil

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

		if string.find(newWep:GetClass(), "camera") then
			cameraHide()
		elseif string.find(oldWep:GetClass(), "camera") then
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

local hideAllGUICvar = CreateClientConVar("hide_gui_with_camera", 0, true, false, "Whether holding the camera out hides GLua GUI", 0, 1)

hook.Add("HUDShouldDraw", "HideChatWithCamera", function(name)
	if cameraOut and not chatOut and name == "CHudChat" then return false end
	if hideAllGUICvar:GetBool() and name == "CHudGMod" then return false end
end)