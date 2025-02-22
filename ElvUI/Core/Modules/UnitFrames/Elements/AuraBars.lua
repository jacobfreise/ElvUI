local E, L, V, P, G = unpack(ElvUI)
local UF = E:GetModule('UnitFrames')
local LSM = E.Libs.LSM

local _G = _G
local ipairs = ipairs
local unpack = unpack
local CreateFrame = CreateFrame

function UF:Construct_AuraBars(bar)
	bar:CreateBackdrop(nil, nil, nil, nil, true)
	bar:SetScript('OnMouseDown', UF.Aura_OnClick)
	bar:Point('LEFT')
	bar:Point('RIGHT')

	bar.spark:SetTexture(E.media.blankTex)
	bar.spark:SetVertexColor(1, 1, 1, 0.4)
	bar.spark:Width(2)

	bar.icon:CreateBackdrop(nil, nil, nil, nil, true)
	UF.statusbars[bar] = true
	UF:Update_StatusBar(bar)

	UF:Configure_FontString(bar.timeText)
	UF:Configure_FontString(bar.nameText)

	UF:AuraBars_UpdateBar(bar)

	bar.nameText:SetJustifyH('LEFT')
	bar.nameText:SetJustifyV('MIDDLE')
	bar.nameText:Point('RIGHT', bar.timeText, 'LEFT', -4, 0)
	bar.nameText:SetWordWrap(false)

	bar.bg = bar:CreateTexture(nil, 'BORDER')
	bar.bg:Show()
end

function UF:AuraBars_SetPosition(from, to)
	local anchor = self.initialAnchor
	local growth = (self.growth == 'BELOW' and -1) or 1
	local SPACING = UF.thinBorders and 1 or 5

	for i = from, to do
		local bar = self.active[i]
		if not bar then break end

		bar:ClearAllPoints()
		bar:Point(anchor, self, anchor, SPACING, (i == 1 and 0) or (growth * ((i - 1) * (self.height + self.spacing))))

		bar.icon:ClearAllPoints()
		bar.icon:Point('RIGHT', bar, 'LEFT', -SPACING, 0)
	end
end

function UF:AuraBars_UpdateBar(bar)
	local bars = bar:GetParent()
	bar.db = bars.db

	bar:SetReverseFill(bars.reverseFill)
	bar.spark:ClearAllPoints()
	bar.spark:Point(bars.reverseFill and 'LEFT' or 'RIGHT', bar:GetStatusBarTexture())
	bar.spark:Point('BOTTOM')
	bar.spark:Point('TOP')

	UF:Update_FontString(bar.timeText)
	UF:Update_FontString(bar.nameText)
end

function UF:Construct_AuraBarHeader(frame)
	local auraBar = CreateFrame('Frame', '$parent_AuraBars', frame)
	auraBar:SetFrameLevel(frame.RaisedElementParent.AuraBarLevel)
	auraBar:Size(1)

	auraBar.PreSetPosition = UF.SortAuras
	auraBar.PostCreateBar = UF.Construct_AuraBars
	auraBar.PostUpdateBar = UF.PostUpdateBar_AuraBars
	auraBar.CustomFilter = UF.AuraFilter
	auraBar.SetPosition = UF.AuraBars_SetPosition

	auraBar.sparkEnabled = true
	auraBar.initialAnchor = 'BOTTOMRIGHT'
	auraBar.type = 'aurabar'

	return auraBar
end

function UF:Configure_AuraBars(frame)
	local bars = frame.AuraBars
	local db = frame.db and frame.db.aurabar
	bars.db = db

	if db.enable then
		if not frame:IsElementEnabled('AuraBars') then
			frame:EnableElement('AuraBars')
		end

		local below = db.anchorPoint == 'BELOW'
		local detached = db.attachTo == 'DETACHED'
		local debuffs = db.attachTo == 'DEBUFFS'
		local buffs = db.attachTo == 'BUFFS'

		bars.height = db.height
		bars.growth = db.anchorPoint
		bars.maxBars = db.maxBars
		bars.spacing = db.spacing - (detached and 1 or 0)
		bars.reverseFill = bars.db.reverseFill
		bars.friendlyAuraType = db.friendlyAuraType
		bars.enemyAuraType = db.enemyAuraType
		bars.disableMouse = db.clickThrough
		bars.filterList = UF:ConvertFilters(bars, db.priority)
		bars.auraSort = UF.SortAuraFuncs[db.sortMethod]

		for _, bar in ipairs(bars) do
			UF:AuraBars_UpdateBar(bar)
		end

		E:UpdateClassColor(UF.db.colors.auraBarBuff)
		E:UpdateClassColor(UF.db.colors.auraBarDebuff)

		if not bars.Holder then
			local holder = CreateFrame('Frame', nil, bars)
			holder:Point('BOTTOM', frame, 'TOP', 0, 0)
			bars.Holder = holder

			if frame.unitframeType == 'player' then
				E:CreateMover(holder, 'ElvUF_PlayerAuraMover', 'Player Aura Bars', nil, nil, nil, 'ALL,SOLO', nil, 'unitframe,individualUnits,player,aurabar')
			elseif frame.unitframeType == 'target' then
				E:CreateMover(holder, 'ElvUF_TargetAuraMover', 'Target Aura Bars', nil, nil, nil, 'ALL,SOLO', nil, 'unitframe,individualUnits,target,aurabar')
			elseif frame.unitframeType == 'pet' then
				E:CreateMover(holder, 'ElvUF_PetAuraMover', 'Pet Aura Bars', nil, nil, nil, 'ALL,SOLO', nil, 'unitframe,individualUnits,pet,aurabar')
			elseif frame.unitframeType == 'focus' then
				E:CreateMover(holder, 'ElvUF_FocusAuraMover', 'Focus Aura Bars', nil, nil, nil, 'ALL,SOLO', nil, 'unitframe,individualUnits,focus,aurabar')
			end
		end

		local attachTo, xOffset, yOffset = frame
		local BORDER = UF.BORDER + UF.SPACING
		if detached then
			attachTo = bars.Holder
		elseif buffs then
			attachTo = frame.Buffs
		elseif debuffs then
			attachTo = frame.Debuffs
		elseif db.attachTo == 'PLAYER_AURABARS' and _G.ElvUF_Player then
			attachTo = _G.ElvUF_Player.AuraBars
			xOffset = 0
		end

		local POWER_OFFSET, BAR_WIDTH = 0
		if detached then
			E:EnableMover(bars.Holder.mover:GetName())
			BAR_WIDTH = db.detachedWidth

			yOffset = below and (BORDER + (UF.BORDER - UF.SPACING)) or -(db.height + BORDER)

			bars.Holder:Size(db.detachedWidth, db.height + (BORDER * 2))
		else
			E:DisableMover(bars.Holder.mover:GetName())
			BAR_WIDTH = frame.UNIT_WIDTH

			local offset = db.yOffset + (UF.thinBorders and 0 or 2)
			yOffset = (below and -(db.height + offset) or offset) + 1 -- 1 is connecting pixel

			if db.attachTo ~= 'FRAME' then
				POWER_OFFSET = frame.POWERBAR_OFFSET

				if frame.ORIENTATION == 'MIDDLE' then
					POWER_OFFSET = POWER_OFFSET * 2
				end
			end
		end

		local point = (buffs or debuffs) and attachTo.anchorPoint or 'TOPLEFT'
		local right = point:find('RIGHT')
		local p1, p2, p3 = below and 'TOP' or 'BOTTOM', below and 'BOTTOM' or 'TOP', right and 'RIGHT' or 'LEFT'

		bars:ClearAllPoints()
		bars:Point(p1..p3, attachTo, p2..p3, xOffset or (right and -(UF.SPACING + BORDER * 2) or bars.height+UF.BORDER), yOffset)
		bars.width = E:Scale(BAR_WIDTH - (BORDER * 4) - bars.height - POWER_OFFSET + 1) -- 1 is connecting pixel
		bars.initialAnchor = 'BOTTOM'..p3
		bars:Show()
	elseif frame:IsElementEnabled('AuraBars') then
		frame:DisableElement('AuraBars')
		bars:Hide()
	end
end

local GOTAK_ID = 86659
local GOTAK = GetSpellInfo(GOTAK_ID)
function UF:PostUpdateBar_AuraBars(_, bar, _, _, _, _, debuffType) -- unit, bar, index, position, duration, expiration, debuffType, isStealable
	local spellID = bar.spellID
	local spellName = bar.name

	bar.db = self.db
	bar.icon:SetTexCoord(unpack(E.TexCoords))

	local colors = E.global.unitframe.AuraBarColors[spellID] and E.global.unitframe.AuraBarColors[spellID].enable and E.global.unitframe.AuraBarColors[spellID].color

	if E.db.unitframe.colors.auraBarTurtle and (E.global.unitframe.aurafilters.TurtleBuffs.spells[spellID] or E.global.unitframe.aurafilters.TurtleBuffs.spells[spellName]) and not colors and (spellName ~= GOTAK or (spellName == GOTAK and spellID == GOTAK_ID)) then
		colors = E.db.unitframe.colors.auraBarTurtleColor
	end

	if not colors then
		if UF.db.colors.auraBarByType and bar.filter == 'HARMFUL' then
			if not debuffType or (debuffType == '' or debuffType == 'none') then
				colors = UF.db.colors.auraBarDebuff
			else
				colors = _G.DebuffTypeColor[debuffType]
			end
		elseif bar.filter == 'HARMFUL' then
			colors = UF.db.colors.auraBarDebuff
		else
			colors = UF.db.colors.auraBarBuff
		end
	end

	bar.custom_backdrop = UF.db.colors.customaurabarbackdrop and UF.db.colors.aurabar_backdrop

	if bar.bg then
		if (UF.db.colors.transparentAurabars and not bar.isTransparent) or (bar.isTransparent and (not UF.db.colors.transparentAurabars or bar.invertColors ~= UF.db.colors.invertAurabars)) then
			UF:ToggleTransparentStatusBar(UF.db.colors.transparentAurabars, bar, bar.bg, nil, UF.db.colors.invertAurabars)
		else
			local sbTexture = bar:GetStatusBarTexture()
			if not bar.bg:GetTexture() then
				UF:Update_StatusBar(bar.bg, UF.db.colors.transparentAurabars and E.media.blankTex or LSM:Fetch('statusbar', UF.db.statusbar))
			end

			UF:SetStatusBarBackdropPoints(bar, sbTexture, bar.bg)
		end
	end

	if colors then
		bar:SetStatusBarColor(colors.r, colors.g, colors.b)

		if not bar.hookedColor then
			UF.UpdateBackdropTextureColor(bar, colors.r, colors.g, colors.b)
		end
	else
		local r, g, b = bar:GetStatusBarColor()
		UF.UpdateBackdropTextureColor(bar, r, g, b)
	end
end
