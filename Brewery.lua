local isTank, inCombat

local FONT = [[Interface\AddOns\Brewery\semplice.ttf]]
local BACKDROP = {
	bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
	insets = {top = -1, bottom = -1, left = -1, right = -1}
}

local function FadeStop(frame)
	if(frame.timer) then
		frame.timer:Cancel()
		frame.timer = nil
	end

	if(frame.ticker) then
		frame.ticker:Cancel()
		frame.ticker = nil
	end

	frame:SetAlpha(1)
	frame:Show()
end

local function FadeOut(frame)
	if(frame.timer or not frame:IsShown()) then
		return
	end

	frame.timer = C_Timer.NewTimer(5, function()
		frame.ticker = C_Timer.NewTicker(1/60, function(self)
			frame:SetAlpha(frame:GetAlpha() - 1/60)

			if(self._remainingIterations == 0) then
				frame:Hide()
				frame.ticker = nil
				frame.timer = nil
			end
		end, 60)
	end)
end

local ResolveSpell = GetSpellInfo(158300)
local ResolveBar = CreateFrame('StatusBar', nil, UIParent)
ResolveBar:SetPoint('CENTER', 0, -220)
ResolveBar:SetSize(160, 9)
ResolveBar:Hide()
ResolveBar:SetStatusBarTexture(0.6, 0.3, 0)
ResolveBar:SetMinMaxValues(0, 240)
ResolveBar:SetBackdrop(BACKDROP)
ResolveBar:SetBackdropColor(0, 0, 0)
ResolveBar:RegisterUnitEvent('UNIT_AURA', 'player')
ResolveBar:SetScript('OnEvent', function(self, event, unit)
	local _, _, _, _, _, _, _, _, _, _, _, _, _, _, perc = UnitAura('player', ResolveSpell, nil, 'HELPFUL')
	self:SetValue(perc or 0)
	self.Text:SetFormattedText('%d%%', perc or 0)
end)

local ResolveBackground = ResolveBar:CreateTexture(nil, 'BORDER')
ResolveBackground:SetAllPoints()
ResolveBackground:SetTexture(1/8, 1/8, 1/8)

local ResolveText = ResolveBar:CreateFontString()
ResolveText:SetPoint('CENTER', 0, 1)
ResolveText:SetFont(FONT, 8, 'OUTLINEMONOCHROME')
ResolveText:SetJustifyH('CENTER')
ResolveBar.Text = ResolveText

local StaggerBar
if(select(2, UnitClass('player')) == 'MONK') then
	local StaggerBar = CreateFrame('StatusBar', nil, UIParent)
	StaggerBar:SetPoint('BOTTOM', ResolveBar, 'TOP', 0, 5)
	StaggerBar:SetSize(160, 9)
	StaggerBar:Hide()
	StaggerBar:SetStatusBarTexture(0.1, 0.6, 0.4)
	StaggerBar:SetMinMaxValues(0, 100)
	StaggerBar:SetBackdrop(BACKDROP)
	StaggerBar:SetBackdropColor(0, 0, 0)
	StaggerBar:RegisterUnitEvent('UNIT_AURA', 'player')
	StaggerBar:RegisterUnitEvent('UNIT_DISPLAYPOWER', 'player')
	StaggerBar:SetScript('OnEvent', function(self, event, unit)
		local perc = floor(UnitStagger('player') / UnitHealthMax('player') * 100)
		self:SetValue(perc)
		self.Text:SetFormattedText('%d%%', perc)

		if(perc == 0 and not UnitAffectingCombat('player')) then
			FadeOut(self)
		end
	end)

	local StaggerBackground = StaggerBar:CreateTexture(nil, 'BORDER')
	StaggerBackground:SetAllPoints()
	StaggerBackground:SetTexture(1/8, 1/8, 1/8)

	local StaggerText = StaggerBar:CreateFontString()
	StaggerText:SetPoint('CENTER', 0, 1)
	StaggerText:SetFont(FONT, 8, 'OUTLINEMONOCHROME')
	StaggerText:SetJustifyH('CENTER')
	StaggerBar.Text = StaggerText
end

local Handler = CreateFrame('Frame')
Handler:RegisterEvent('PLAYER_TALENT_UPDATE')
Handler:RegisterEvent('PLAYER_REGEN_ENABLED')
Handler:RegisterEvent('PLAYER_REGEN_DISABLED')
Handler:RegisterUnitEvent('UNIT_ENTERED_VEHICLE', 'player')
Handler:RegisterUnitEvent('UNIT_EXITED_VEHICLE', 'player')
Handler:SetScript('OnEvent', function(self, event, ...)
	if(event == 'PLAYER_TALENT_UPDATE') then
		isTank = GetSpecializationRole(GetSpecialization()) == 'TANK'
	end

	if(not isTank or UnitHasVehicleUI('player')) then
		ResolveBar:Hide()

		if(StaggerBar) then
			StaggerBar:Hide()
		end
	else
		if(UnitAffectingCombat('player')) then
			FadeStop(ResolveBar)

			if(StaggerBar) then
				FadeStop(StaggerBar)
			end
		else
			FadeOut(ResolveBar)

			if(StaggerBar and StaggerBar:GetValue() == 0) then
				FadeOut(StaggerBar)
			end
		end
	end
end)
