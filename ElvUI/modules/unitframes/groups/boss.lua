local E, L, V, P, G = unpack(select(2, ...)); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local UF = E:GetModule('UnitFrames');

--Cache global variables
--Lua functions
local _G = _G
local pairs = pairs
local tinsert = table.insert
local format = format
--WoW API / Variables
local MAX_BOSS_FRAMES = MAX_BOSS_FRAMES

--Global variables that we don't cache, list them here for mikk's FindGlobals script
-- GLOBALS: BossHeaderMover

local _, ns = ...
local ElvUF = ns.oUF
assert(ElvUF, "ElvUI was unable to locate oUF.")

local BossHeader = CreateFrame('Frame', 'BossHeader', UIParent)
function UF:Construct_BossFrames(frame)
	frame.Health = self:Construct_HealthBar(frame, true, true, 'RIGHT')

	frame.Power = self:Construct_PowerBar(frame, true, true, 'LEFT')

	frame.Name = self:Construct_NameText(frame)

	frame.Portrait3D = self:Construct_Portrait(frame, 'model')
	frame.Portrait2D = self:Construct_Portrait(frame, 'texture')

	frame.Buffs = self:Construct_Buffs(frame)

	frame.Debuffs = self:Construct_Debuffs(frame)
	frame.DebuffHighlight = self:Construct_DebuffHighlight(frame)
	frame.TargetGlow = UF:Construct_TargetGlow(frame)
	tinsert(frame.__elements, UF.UpdateTargetGlow)
	frame:RegisterEvent('PLAYER_TARGET_CHANGED', UF.UpdateTargetGlow)
	frame:RegisterEvent('PLAYER_ENTERING_WORLD', UF.UpdateTargetGlow)
	frame:RegisterEvent('GROUP_ROSTER_UPDATE', UF.UpdateTargetGlow)

	frame.Castbar = self:Construct_Castbar(frame, 'RIGHT')
	frame.RaidIcon = UF:Construct_RaidIcon(frame)
	frame.AltPowerBar = self:Construct_AltPowerBar(frame)
	frame.Range = UF:Construct_Range(frame)
	frame:SetAttribute("type2", "focus")
	frame.customTexts = {}
	BossHeader:Point('BOTTOMRIGHT', E.UIParent, 'RIGHT', -105, -165)
	E:CreateMover(BossHeader, BossHeader:GetName()..'Mover', L["Boss Frames"], nil, nil, nil, 'ALL,PARTY,RAID')
end

function UF:Update_BossFrames(frame, db)
	frame.db = db

	do
		frame.ORIENTATION = db.orientation --allow this value to change when unitframes position changes on screen?
		frame.UNIT_WIDTH = db.width
		frame.UNIT_HEIGHT = db.height

		frame.USE_POWERBAR = db.power.enable
		frame.POWERBAR_DETACHED = db.power.detachFromFrame
		frame.USE_INSET_POWERBAR = not frame.POWERBAR_DETACHED and db.power.width == 'inset' and frame.USE_POWERBAR
		frame.USE_MINI_POWERBAR = (not frame.POWERBAR_DETACHED and db.power.width == 'spaced' and frame.USE_POWERBAR)
		frame.USE_POWERBAR_OFFSET = db.power.offset ~= 0 and frame.USE_POWERBAR and not frame.POWERBAR_DETACHED
		frame.POWERBAR_OFFSET = frame.USE_POWERBAR_OFFSET and db.power.offset or 0

		frame.POWERBAR_HEIGHT = not frame.USE_POWERBAR and 0 or db.power.height
		frame.POWERBAR_WIDTH = frame.USE_MINI_POWERBAR and (frame.UNIT_WIDTH - (frame.BORDER*2))/2 or (frame.POWERBAR_DETACHED and db.power.detachedWidth or (frame.UNIT_WIDTH - ((frame.BORDER+frame.SPACING)*2)))

		frame.USE_PORTRAIT = db.portrait and db.portrait.enable
		frame.USE_PORTRAIT_OVERLAY = frame.USE_PORTRAIT and (db.portrait.overlay or frame.ORIENTATION == "MIDDLE")
		frame.PORTRAIT_WIDTH = (frame.USE_PORTRAIT_OVERLAY or not frame.USE_PORTRAIT) and 0 or db.portrait.width

		frame.CAN_HAVE_CLASSBAR = true
		frame.MAX_CLASS_BAR = 0
		frame.USE_CLASSBAR = true
		frame.CLASSBAR_SHOWN = frame.AltPowerBar:IsShown()
		frame.CLASSBAR_DETACHED = false
		frame.USE_MINI_CLASSBAR = false
		frame.CLASSBAR_HEIGHT = frame.CLASSBAR_SHOWN and db.power.height or 0
		frame.CLASSBAR_WIDTH = frame.UNIT_WIDTH - ((frame.BORDER+frame.SPACING)*2) - frame.PORTRAIT_WIDTH  - frame.POWERBAR_OFFSET
		frame.CLASSBAR_YOFFSET = (not frame.USE_CLASSBAR or not frame.CLASSBAR_SHOWN) and 0 or (frame.CLASSBAR_HEIGHT + frame.SPACING)
	end

	frame.colors = ElvUF.colors
	frame.Portrait = db.portrait.style == '2D' and frame.Portrait2D or frame.Portrait3D
	frame:RegisterForClicks(self.db.targetOnMouseDown and 'AnyDown' or 'AnyUp')
	frame:Size(frame.UNIT_WIDTH, frame.UNIT_HEIGHT)

	--Health
	UF:Configure_HealthBar(frame)

	--Name
	UF:UpdateNameSettings(frame)

	--Power
	UF:Configure_Power(frame)

	--Portrait
	UF:Configure_Portrait(frame)

	--Target Glow
	UF:Configure_TargetGlow(frame)

	--Auras
	UF:EnableDisable_Auras(frame)
	UF:Configure_Auras(frame, 'Buffs')
	UF:Configure_Auras(frame, 'Debuffs')

	--Castbar
	UF:Configure_Castbar(frame)

	--Raid Icon
	UF:Configure_RaidIcon(frame)

	--AltPowerBar
	UF:Configure_AltPower(frame)

	UF:Configure_DebuffHighlight(frame)

	UF:Configure_CustomTexts(frame)

	UF:Configure_Range(frame)

	frame:ClearAllPoints()
	if frame.index == 1 then
		if db.growthDirection == 'UP' then
			frame:Point('BOTTOMRIGHT', BossHeaderMover, 'BOTTOMRIGHT')
		elseif db.growthDirection == 'RIGHT' then
			frame:Point('LEFT', BossHeaderMover, 'LEFT')
		elseif db.growthDirection == 'LEFT' then
			frame:Point('RIGHT', BossHeaderMover, 'RIGHT')
		else --Down
			frame:Point('TOPRIGHT', BossHeaderMover, 'TOPRIGHT')
		end
	else
		if db.growthDirection == 'UP' then
			frame:Point('BOTTOMRIGHT', _G['ElvUF_Boss'..frame.index-1], 'TOPRIGHT', 0, db.spacing)
		elseif db.growthDirection == 'RIGHT' then
			frame:Point('LEFT', _G['ElvUF_Boss'..frame.index-1], 'RIGHT', db.spacing, 0)
		elseif db.growthDirection == 'LEFT' then
			frame:Point('RIGHT', _G['ElvUF_Boss'..frame.index-1], 'LEFT', -db.spacing, 0)
		else --Down
			frame:Point('TOPRIGHT', _G['ElvUF_Boss'..frame.index-1], 'BOTTOMRIGHT', 0, -db.spacing)
		end
	end

	if db.growthDirection == 'UP' or db.growthDirection == 'DOWN' then
		BossHeader:Width(frame.UNIT_WIDTH)
		BossHeader:Height(frame.UNIT_HEIGHT + ((frame.UNIT_HEIGHT + db.spacing) * (MAX_BOSS_FRAMES -1)))
	elseif db.growthDirection == 'LEFT' or db.growthDirection == 'RIGHT' then
		BossHeader:Width(frame.UNIT_WIDTH + ((frame.UNIT_WIDTH + db.spacing) * (MAX_BOSS_FRAMES -1)))
		BossHeader:Height(frame.UNIT_HEIGHT)
	end

	if UF.db.colors.transparentHealth then
		UF:ToggleTransparentStatusBar(true, frame.Health, frame.Health.bg)
	else
		UF:ToggleTransparentStatusBar(false, frame.Health, frame.Health.bg, (frame.USE_PORTRAIT and frame.USE_PORTRAIT_OVERLAY) ~= true)
	end

	if UF.db.colors.transparentPower then
		UF:ToggleTransparentStatusBar(true, frame.Power, frame.Power.bg)
	else
		UF:ToggleTransparentStatusBar(false, frame.Power, frame.Power.bg, true)
	end

	UF:ToggleTransparentStatusBar(UF.db.colors.transparentHealth, frame.Health, frame.Health.bg, true)
	UF:ToggleTransparentStatusBar(UF.db.colors.transparentPower, frame.Power, frame.Power.bg)

	frame:UpdateAllElements()
end

UF['unitgroupstoload']['boss'] = {MAX_BOSS_FRAMES}
