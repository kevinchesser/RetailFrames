local function print(msg) DEFAULT_CHAT_FRAME:AddMessage(msg) end

local UPDATE_INTERVAL = 0.25
local MAX_BUFFS = 6

local LOADED = false

local AURA_SIZE = 20

-------------------------------------------------------------------------------------------------------------------

SLASH_RETAILFRAMES1 = "/rf"

function SlashCmdList.RETAILFRAMES(arg1, arg2)
	local att, val = strsplit(" ", arg1, 2)
	val = tonumber(val)
	if val then 
		if att == "x" then
			RetailFrames_Options["x"] = val
		elseif att == "y" then
			RetailFrames_Options["y"] = val
		elseif att == "w" then
			RetailFrames_Options["w"] = val
		elseif att == "h" then
			RetailFrames_Options["h"] = val
		elseif att == "c" then
			RetailFrames_Options["c"] = val
		elseif att == "r" then
			RetailFrames_Options["r"] = val
		elseif att == "s" then 
			RetailFrames_Options["s"] = val
		else
			print("RetailFrames: /rf <x, y, h, w, c, r, s> <#>")
			return
		end
	else
		print("RetailFrames: /rf <x, y, h, w, c, r, s> <#>")
		return
	end
end

-------------------------------------------------------------------------------------------------------------------

local RetailFrames_Defaults = {
	["options"] = {
		["x"] = 10,
		["y"] = 50,
		["w"] = 80,
		["h"] = 50,
		["c"] = 8,
		["r"] = 5,
		["s"] = 1.0
	}
}

local test = "ass"

local RetailFrames_X = 20
local RetailFrames_Y = 20

local PowerBarColor = {}
PowerBarColor[0] = { r = 0.00, g = 0.00, b = 1.00 }
PowerBarColor[1] = { r = 1.00, g = 0.00, b = 0.00}
PowerBarColor[3] = { r = 1.00, g = 1.00, b = 0.00}

local powerToken = {}
powerToken[0] = "MANA"
powerToken[1] = "RAGE"
powerToken[3] = "ENERGY"

-------------------------------------------------------------------------------------------------------------------


function RetailFrames_Loader(self, event, ...)
	if not RetailFrames_Options then
		RetailFrames_Options = RetailFrames_Defaults["options"]
		print("RetailFrames: Options weren't found, generating...")
	end

	RetailFrames_Header:SetPoint("TOPLEFT", UIParent, "LEFT", RetailFrames_Options["x"], RetailFrames_Options["y"])
	RetailFrames_Header:SetAttribute("unitsPerColumn", RetailFrames_Options["r"])
	RetailFrames_Header:SetAttribute("maxColumns", RetailFrames_Options["c"])

	RetailFrames_Pet_Header:SetAttribute("unitsPerColumn", RetailFrames_Options["r"])
	RetailFrames_Pet_Header:SetAttribute("maxColumns", RetailFrames_Options["c"])

	LOADED = true
end

function RetailFrames_InitialConfig(self)
	self.healthBar:SetFrameLevel(1)
	self.powerBar:SetFrameLevel(1)
end

function RetailFrames_Pet_InitialConfig(self)
	self.healthBar:SetFrameLevel(1)
end

-------------------------------------------------------------------------------------------------------------------

function RetailFrames_OnLoad(self)
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("UNIT_MAXHEALTH")
	self:RegisterEvent("UNIT_MANA")
	self:RegisterEvent("UNIT_ENERGY")
	self:RegisterEvent("UNIT_RAGE")
	self:RegisterEvent("UNIT_MAXMANA")
	self:RegisterEvent("UNIT_DISPLAYPOWER")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("ADDON_LOADED")

	self.name = self:GetName() and _G[self:GetName() .. "_Unit_Name"]
	self.dead = self:GetName() and _G[self:GetName() .. "_Unit_Dead"]
	self.offline = self:GetName() and _G[self:GetName() .. "_Unit_Offline"]
	self.powerBar = self:GetName() and _G[self:GetName() .. "_Unit_PowerBar"]
	self.healthBar = self:GetName() and _G[self:GetName() .. "_Unit_HealthBar"]
	self.selected = self:GetName() and _G[self:GetName() .. "_Unit_Selected"]
	self.outOfRange = self:GetName() and _G[self:GetName() .. "_Unit_OutOfRange"]
	self.SizeSet = false
	self.TimeElapsedSinceLastUpdate = 0
end

function RetailFrames_OnShow(self)
	local unit = self:GetAttribute("unit")

	_G[self:GetName() .. "_AuraFrame"].unit = unit

	if not self.SizeSet then
		if LOADED then RetailFrames_UpdateSize(self) end
	end

	if unit then
		local guid = UnitGUID(unit)
		if guid ~= self.guid then
			RetailFrames_ResetUnitButton(self, unit)
			self.guid = guid
		end
	end
end

function RetailFrames_OnEvent(self, event, arg1, ...)
	local unit = self:GetAttribute("unit")
	if not unit then
		return
	end

	if event == "ADDON_LOADED" then
		RetailFrames_UpdateSize(self)
	elseif event == "PLAYER_ENTERING_WORLD" then
		RetailFrames_ResetUnitButton(self, unit)
	elseif event == "PLAYER_TARGET_CHANGED" then
		if UnitIsUnit(unit, "target") then
			self.selected:Show()
		else
			self.selected:Hide()
		end
	elseif arg1 and UnitIsUnit(unit, arg1) then
		if event == "UNIT_MAXHEALTH" then
			RetailFrames_UpdateHealthBar(self, unit)
		elseif event == "UNIT_HEALTH" then
			RetailFrames_UpdateHealthBar(self, unit)
		elseif event == "UNIT_DISPLAYPOWER" then
			RetailFrames_ResetPowerBar(self, unit)
		elseif event == "UNIT_MAXMANA" then
			RetailFrames_UpdatePowerBar(self, unit)
		else
			self.powerBar:SetValue(UnitMana(unit))
		end
	end
end

function RetailFrames_OnUpdate(self, elapsed)
	self.TimeElapsedSinceLastUpdate = self.TimeElapsedSinceLastUpdate + elapsed
	if self.TimeElapsedSinceLastUpdate > UPDATE_INTERVAL then
		---------------------------------------------------

		if UnitInRange(self:GetAttribute("unit")) then
			self.outOfRange:Hide()
		else
			self.outOfRange:Show()
		end

		---------------------------------------------------
		self.TimeElapsedSinceLastUpdate = 0
	end
end

-------------------------------------------------------------------------------------------------------------------

function RetailFrames_Pet_OnLoad(self)
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("UNIT_MAXHEALTH")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("ADDON_LOADED")

	self.name = self:GetName() and _G[self:GetName() .. "_Unit_Name"]
	self.dead = self:GetName() and _G[self:GetName() .. "_Unit_Dead"]
	self.healthBar = self:GetName() and _G[self:GetName() .. "_Unit_HealthBar"]
	self.selected = self:GetName() and _G[self:GetName() .. "_Unit_Selected"]
	self.outOfRange = self:GetName() and _G[self:GetName() .. "_Unit_OutOfRange"]
	self.SizeSet = false
	self.TimeElapsedSinceLastUpdate = 0
end

function RetailFrames_Pet_OnShow(self)
	local unit = self:GetAttribute("unit")

	if not self.SizeSet then
		if LOADED then RetailFrames_UpdateSize(self) end
	end

	if unit then
		local guid = UnitGUID(unit)
		if guid ~= self.guid then
			RetailFrames_Pet_ResetUnitButton(self, unit)
			self.guid = guid
		end
	end
end

function RetailFrames_Pet_OnEvent(self, event, arg1, ...)
	local unit = self:GetAttribute("unit")
	if not unit then
		return
	end

	if event == "ADDON_LOADED" then
		RetailFrames_UpdateSize(self)
	elseif event == "PLAYER_ENTERING_WORLD" then
		RetailFrames_Pet_ResetUnitButton(self, unit)
	elseif event == "PLAYER_TARGET_CHANGED" then
		if UnitIsUnit(unit, "target") then
			self.selected:Show()
		else
			self.selected:Hide()
		end
	elseif arg1 and UnitIsUnit(unit, arg1) then
		if event == "UNIT_MAXHEALTH" then
			RetailFrames_Pet_UpdateHealthBar(self, unit)
		elseif event == "UNIT_HEALTH" then
			RetailFrames_Pet_UpdateHealthBar(self, unit)
		end
	end
end

function RetailFrames_Pet_OnUpdate(self, elapsed)
	self.TimeElapsedSinceLastUpdate = self.TimeElapsedSinceLastUpdate + elapsed
	if self.TimeElapsedSinceLastUpdate > UPDATE_INTERVAL then
		---------------------------------------------------

		if UnitInRange(self:GetAttribute("unit")) then
			self.outOfRange:Hide()
		else
			self.outOfRange:Show()
		end

		---------------------------------------------------
		self.TimeElapsedSinceLastUpdate = 0
	end
end

-------------------------------------------------------------------------------------------------------------------

function RetailFrames_ResetUnitButton(self, unit)
	RetailFrames_ResetHealthBar(self, unit)
	RetailFrames_ResetPowerBar(self, unit)
	RetailFrames_ResetName(self, unit)
end

function RetailFrames_Pet_ResetUnitButton(self, unit)
	RetailFrames_Pet_ResetHealthBar(self, unit)
	RetailFrames_ResetName(self, unit)
end

function RetailFrames_ResetName(self, unit)
	local name = UnitName(unit) or UNKNOWN
	self.name:SetText(name)
end

function RetailFrames_UpdateHealthBar(self, unit)
	
	if UnitIsDeadOrGhost(unit) then
		self.healthBar:SetValue(0)
		self.dead:Show()
	else
		self.healthBar:SetMinMaxValues(0, UnitHealthMax(unit))
		self.healthBar:SetValue(UnitHealth(unit))
		self.dead:Hide()
	end
	if not UnitIsConnected(unit) then
		self.offline:Show()
	else
		self.offline:Hide()
	end
end

function RetailFrames_Pet_UpdateHealthBar(self, unit)
	
	if UnitIsDeadOrGhost(unit) then
		self.healthBar:SetValue(0)
		self.dead:Show()
	else
		self.healthBar:SetMinMaxValues(0, UnitHealthMax(unit))
		self.healthBar:SetValue(UnitHealth(unit))
		self.dead:Hide()
	end
end

function RetailFrames_ResetHealthBar(self, unit)
	local class = select(2, UnitClass(unit)) or "WARRIOR"
	local classColor = RAID_CLASS_COLORS[class]
	self.healthBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b)

	RetailFrames_UpdateHealthBar(self, unit)
end

function RetailFrames_Pet_ResetHealthBar(self, unit)
	RetailFrames_Pet_UpdateHealthBar(self, unit)
end

function RetailFrames_UpdatePowerBar(self, unit)
	self.powerBar:SetMinMaxValues(0, UnitManaMax(unit))
	self.powerBar:SetValue(UnitMana(unit))
end

function RetailFrames_ResetPowerBar(self, unit)
	local powerType = UnitPowerType(unit)
	local powerColor = PowerBarColor[powerType]
	self.powerBar:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b)

	self:UnregisterEvent("UNIT_MANA")
	self:UnregisterEvent("UNIT_RAGE")
	self:UnregisterEvent("UNIT_ENERGY")

	self:RegisterEvent("UNIT_" .. powerToken[powerType])

	RetailFrames_UpdatePowerBar(self, unit)
end

-------------------------------------------------------------------------------------------------------------------

function RetailFrames_UpdateSize(self)
	local width, height
	width = floor(RetailFrames_Options["w"] * RetailFrames_Options["s"])
	height = floor(RetailFrames_Options["h"] * RetailFrames_Options["s"])
	self:SetWidth(width)
	self:SetHeight(height)
	self.healthBar:SetHeight(height-8) 
	self.SizeSet = true
end

-------------------------------------------------------------------------------------------------------------------

function RetailAuras_OnLoad(self)
	self:RegisterEvent("UNIT_AURA")
	self:RegisterEvent("ADDON_LOADED")

	self.TimeElapsedSinceLastUpdate = 0

	self.Buffs = {}
	self.Debuffs = {}

	self.Buffs[0] = _G[self:GetName() .. "_BuffAnchor"]
	self.Debuffs[0] = _G[self:GetName() .. "_DebuffAnchor"]

	self.BUFFS_PRESENT = 0
	self.DEBUFFS_PRESENT = 0

	self.SizeSet = false

	for i=1, MAX_BUFFS do
		self.Buffs[i] = CreateFrame("Cooldown", self:GetName().."Buff"..i, self.Buffs[i-1], "RetailAuraButtonTemplate")
		_G[self.Buffs[i]:GetName() .. "_Border"]:SetVertexColor(0.0, 0.0, 0.0)

		self.Debuffs[i] = CreateFrame("Cooldown", self:GetName().."Debuff"..i, self.Debuffs[i-1], "RetailAuraButtonTemplate")
	end
end

function RetailAuras_OnEvent(self, event, arg1)
	if event == "ADDON_LOADED" then
		RetailAuras_UpdateSize(self)
	else
		if self.unit == arg1 then
			RetailAuras_UpdateHelpful(self)
			RetailAuras_UpdateHarmful(self)
		end
	end
end

function RetailAuras_OnUpdate(self, elapsed)
	self.TimeElapsedSinceLastUpdate = self.TimeElapsedSinceLastUpdate + elapsed
	 if self.TimeElapsedSinceLastUpdate > UPDATE_INTERVAL then
	 	-----------------------------------

		for i=1, self.BUFFS_PRESENT do
			RetailAuras_UpdateHelpfulDuration(self, i)
		end
 
	 	-----------------------------------
	 	self.TimeElapsedSinceLastUpdate = 0
	 end
end

function RetailAuras_OnShow(self)
	if not self.SizeSet then
		if LOADED then
			RetailAuras_UpdateSize(self)
		end
	end
end

-------------------------------------------------------------------------------------------------------------------

function RetailAuras_UpdateHelpful(self)
	local name, rank, icon, stacks
	local duration, fullDuration, startTime

	self.BUFFS_PRESENT = 0
	for i=1, MAX_BUFFS do
		if UnitBuff(self.unit, i, true) then
			name, rank, icon, stacks = UnitBuff(self.unit, i, true)
			fullDuration, duration = select(5, UnitBuff(self.unit, i, true))

			
			_G[self.Buffs[i]:GetName() .. "_Icon"]:SetTexture(icon)

			startTime = GetTime() - (fullDuration - duration)
			CooldownFrame_SetTimer(self.Buffs[i], startTime, fullDuration, 1)

			if stacks > 1 then
				_G[self.Buffs[i]:GetName() .. "_Stacks"]:SetText(stacks)
			else 
				_G[self.Buffs[i]:GetName() .. "_Stacks"]:SetText("")
			end

			--RetaiulAuras_UpdateHelpfulDuration(self, i)

			self.Buffs[i]:Show()
			self.BUFFS_PRESENT = self.BUFFS_PRESENT + 1
			--print("Name: "..name)
		else
			self.Buffs[i]:Hide()
			--print("No buff on index "..i..".")
			break
		end
	end
end

function RetailAuras_UpdateHelpfulDuration(self, i)
	local duration, expirationTime

	duration, expirationTime = select(5, UnitBuff(self.unit, i, true))	

	if not expirationTime or expirationTime >= 30 then
		_G[self.Buffs[i]:GetName() .. "_Duration"]:SetText("")
	else 
		_G[self.Buffs[i]:GetName() .. "_Duration"]:SetText(floor(expirationTime))
	end
end

function RetailAuras_UpdateHarmful(self)
	local name, rank, icon, stacks, duration
	self.DEBUFFS_PRESENT = 0
	for i=1, MAX_BUFFS do
		if UnitDebuff(self.unit, i, true) then
			name, rank, icon, stacks, debuffType = UnitDebuff(self.unit, i, true)

			_G[self.Debuffs[i]:GetName() .. "_Icon"]:SetTexture(icon)


			if debuffType == "Magic" then
				_G[self.Debuffs[i]:GetName() .. "_Border"]:SetVertexColor(0.2, 0.6, 1.0)
			elseif debuffType == "Curse" then
				_G[self.Debuffs[i]:GetName() .. "_Border"]:SetVertexColor(0.6, 0.0, 1.0)
			elseif debuffType == "Poison" then
				_G[self.Debuffs[i]:GetName() .. "_Border"]:SetVertexColor(0.0, 1.0, 0.0)
			elseif debuffType == "Disease" then
				_G[self.Debuffs[i]:GetName() .. "_Border"]:SetVertexColor(0.6, 0.4, 0.0)
			else
				_G[self.Debuffs[i]:GetName() .. "_Border"]:SetVertexColor(1.0, 0.0, 0.0)
			end

			if stacks > 1 then
				_G[self.Debuffs[i]:GetName() .. "_Stacks"]:SetText(stacks)
			else 
				_G[self.Debuffs[i]:GetName() .. "_Stacks"]:SetText("")
			end

			--RetaiulAuras_UpdateHarmfulDuration(self, i)
			
			self.Debuffs[i]:Show()
			self.DEBUFFS_PRESENT = self.DEBUFFS_PRESENT + 1
			--print("Name: "..name)
		else
			self.Debuffs[i]:Hide()
			--print("No debuff on index "..i..".")
			break
		end
	end
end

function RetailAuras_UpdateHarmfulDuration(self, i)
	local duration, expirationTime
	
	duration, expirationTime = select(6, UnitDebuff(self.unit, i))

	if not expirationTime or expirationTime >= 30 then
		_G[self.Debuffs[i]:GetName() .. "_Duration"]:SetText("")
	else 
		_G[self.Debuffs[i]:GetName() .. "_Duration"]:SetText(floor(expirationTime))
	end
end

-------------------------------------------------------------------------------------------------------------------

function RetailAuras_UpdateSize(self)
	local size
	size = floor(AURA_SIZE * RetailFrames_Options["s"])
	for i=1, MAX_BUFFS do
		self.Buffs[i]:SetWidth(size)
		self.Buffs[i]:SetHeight(size)
		self.Debuffs[i]:SetWidth(size)
		self.Debuffs[i]:SetHeight(size)
	end
	self.SizeSet = true
end


-------------------------------------------------------------------------------------------------------------------

RetailFrames_Header.initialConfigFunction = RetailFrames_InitialConfig
RetailFrames_Pet_Header.initialConfigFunction = RetailFrames_Pet_InitialConfig

RetailFrames_Header:Show()
RetailFrames_Pet_Header:Show()

local i = CreateFrame("Frame", nil, UIParent) --Hides the party frames
	i:RegisterEvent("PLAYER_ENTERING_WORLD")

	i:SetScript("OnEvent", function(self, event)
			PartyMemberFrame1:UnregisterAllEvents()
			PartyMemberFrame1:Hide()
			PartyMemberFrame2:UnregisterAllEvents()
			PartyMemberFrame2:Hide()
			PartyMemberFrame3:UnregisterAllEvents()
			PartyMemberFrame3:Hide()
			PartyMemberFrame4:UnregisterAllEvents()
			PartyMemberFrame4:Hide()
			PartyMemberBackground:UnregisterAllEvents()
			PartyMemberBackground:Hide()
end)