local function print(msg) DEFAULT_CHAT_FRAME:AddMessage(msg) end


local PowerBarColor = {}
PowerBarColor[0] = { r = 0.00, g = 0.00, b = 1.00 }
PowerBarColor[1] = { r = 1.00, g = 0.00, b = 0.00}
PowerBarColor[3] = { r = 1.00, g = 1.00, b = 0.00}

local powerToken = {}
powerToken[0] = "MANA"
powerToken[1] = "RAGE"
powerToken[3] = "ENERGY"

function RetailFrames_InitialConfig(frame)
	frame.powerBar = frame:GetName() and _G[frame:GetName() .. "_Unit_PowerBar"]
	frame.healthBar = frame:GetName() and _G[frame:GetName() .. "_Unit_HealthBar"]
	frame.healthBar:SetFrameLevel(2)
	frame.powerBar:SetFrameLevel(2)
end

function RetailFrames_OnLoad()
	RetailFrames_Header.initialConfigFunction = RetailFrames_InitialConfig
	RetailFrames_Header:Show()
end

function RetailFrames_OnShow(button)
	local unit = button:GetAttribute("unit")
	button.name = button:GetName() and _G[button:GetName() .. "_Unit_Name"]
	button.powerBar = button:GetName() and _G[button:GetName() .. "_Unit_PowerBar"]
	button.healthBar = button:GetName() and _G[button:GetName() .. "_Unit_HealthBar"]

	if unit then
		local guid = UnitGUID(unit)
		if guid ~= button.guid then
			RetailFrames_ResetUnitButton(button, unit)
			button.guid = guid
		end
	end
end

function RetailFrames_OnEvent(self, event, arg1, ...)
	local button = self
	local unit = button:GetAttribute("unit")

	button.name = button:GetName() and _G[button:GetName() .. "_Unit_Name"]
	button.powerBar = button:GetName() and _G[button:GetName() .. "_Unit_PowerBar"]
	button.healthBar = button:GetName() and _G[button:GetName() .. "_Unit_HealthBar"]

	if not unit then
		return
	end

	if event == "PLAYER_ENTERING_WORLD" then
		RetailFrames_ResetUnitButton(button, unit)
	elseif arg1 and UnitIsUnit(unit, arg1) then
		if event == "UNIT_MAXHEALTH" then
			RetailFrames_UpdateHealthBar(button, unit)
		elseif event == "UNIT_HEALTH" then
			button.healthBar:SetValue(UnitHealth(unit))
		elseif event == "UNIT_DISPLAYPOWER" then
			RetailFrames_ResetPowerBar(button, unit)
		elseif event == "UNIT_MAXMANA" then
			RetailFrames_UpdatePowerBar(button, unit)
		else
			button.powerBar:SetValue(UnitMana(unit))
		end
	end
end

function RetailFrames_ResetUnitButton(button, unit)
	RetailFrames_ResetHealthBar(button, unit)
	RetailFrames_ResetPowerBar(button, unit)
	RetailFrames_ResetName(button, unit)
end

function RetailFrames_ResetName(button, unit)
	local name = UnitName(unit) or UNKNOWN
	button.name:SetText(name)
end

function RetailFrames_UpdateHealthBar(button, unit)
	button.healthBar:SetMinMaxValues(0, UnitHealthMax(unit))
	button.healthBar:SetValue(UnitHealth(unit))
end

function RetailFrames_ResetHealthBar(button, unit)
	local class = select(2, UnitClass(unit)) or "WARRIOR"
	local classColor = RAID_CLASS_COLORS[class]
	button.healthBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b)

	RetailFrames_UpdateHealthBar(button, unit)
end

function RetailFrames_UpdatePowerBar(button, unit)
	button.powerBar:SetMinMaxValues(0, UnitManaMax(unit))
	button.powerBar:SetValue(UnitMana(unit))
end

function RetailFrames_ResetPowerBar(button, unit)
	local powerType = UnitPowerType(unit)
	local powerColor = PowerBarColor[powerType]
	button.powerBar:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b)

	button:UnregisterEvent("UNIT_MANA")
	button:UnregisterEvent("UNIT_RAGE")
	button:UnregisterEvent("UNIT_ENERGY")

	button:RegisterEvent("UNIT_" .. powerToken[powerType])

	RetailFrames_UpdatePowerBar(button, unit)
end

