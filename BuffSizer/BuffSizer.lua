local select, type, tostring = select, type, tostring
local ADDON_NAME = "BuffSizer"
--libs
local LibStub = LibStub
--WoW API
local getglobal = getglobal
local ReloadUI = ReloadUI
local CreateFrame = CreateFrame
local TargetFrame_UpdateAuras = TargetFrame_UpdateAuras
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local UnitIsEnemy = UnitIsEnemy
local UnitDebuff = UnitDebuff
local GetTime = GetTime

---------------------------

-- CORE

---------------------------

local L
local MAJOR, MINOR = ADDON_NAME, 4
local BuffSizer = LibStub:NewLibrary(MAJOR, MINOR)

BuffSizer.defaults = {
	profile = {
		--target
		targetHighlightStealable = true,
		targetBuffSize = 25,
		targetBuffMaxWidth = 122,
		targetDebuffSize = 25,
		targetDebuffMaxWidth = 122,
		targetBuffPosition = "BOTTOM",
		targetDebuffPosition = "BOTTOM",
		targetBuffSelfFactor = 1.1,
		targetDebuffSelfFactor = 1.1,
		targetBuffOnTop = true,
		--focus
		focusHighlightStealable = true,
		focusBuffSize = 25,
		focusBuffMaxWidth = 122,
		focusDebuffSize = 25,
		focusDebuffMaxWidth = 122,
		focusBuffPosition = "BOTTOM",
		focusDebuffPosition = "BOTTOM",
		focusBuffSelfFactor = 1.1,
		focusDebuffSelfFactor = 1.1,
		focusBuffOnTop = true,
		buffOffset = 2,
		debuffOffset = 2,
	},
}

BuffSizer.debug = false

function BuffSizer:Debug(...)
	if not self.debug then return end
	local text = "|cff0384fc" .. ADDON_NAME .. "|r:"
	local val
	for i = 1, select("#", ...) do
		val = select(i, ...)
		if (type(val) == 'boolean') then val = val and "true" or false end
		text = text .. " " .. tostring(val)
	end
	DEFAULT_CHAT_FRAME:AddMessage(text)
end



BuffSizer.events = CreateFrame("Frame")
function BuffSizer.events:OnEvent(event, ...)
	BuffSizer[event](BuffSizer, ...)
end
BuffSizer.events:SetScript("OnEvent", BuffSizer.events.OnEvent)
BuffSizer.events:RegisterEvent("PLAYER_ENTERING_WORLD")
BuffSizer.events:RegisterEvent("PLAYER_LOGIN")

function BuffSizer:PLAYER_ENTERING_WORLD(...)
	--hooksecurefunc("TargetFrame_UpdateBuffAnchor", BuffSizer.UpdateBuffAnchor)
	--hooksecurefunc("TargetFrame_UpdateDebuffAnchor", BuffSizer.UpdateDebuffAnchor)
end

function BuffSizer:PLAYER_LOGIN(...)
	self:CreateOptions()
end

---------------------------

-- INIT + OPTIONS

---------------------------

local function getOpt(info)
	local key = info.arg or info[#info]
	return BuffSizer.dbi.profile[key]
end
local function setOpt(info, value)
	local key = info.arg or info[#info]
	BuffSizer.dbi.profile[key] = value
	TargetFrame_UpdateAuras(TargetFrame)
	TargetFrame_UpdateAuras(FocusFrame)
end

function BuffSizer:CreateOptions()
	self.dbi = LibStub("AceDB-3.0"):New("BuffSizerDB", self.defaults)
	self.db = self.dbi.profile
	L = self.L

	self.options = {
		type = "group",
		name = ADDON_NAME,
		plugins = {},
		childGroups = "tree",
		get = getOpt,
		set = setOpt,
		args = {
			reload = {
				order = 3,
				width = "0.7",
				name = L["ReloadUI"],
				type = "execute",
				func = function()
					ReloadUI()
				end,
			},
			target = {
				type = "group",
				name = L["Target"],
				desc = L["Target settings"],
				childGroups = "tab",
				order = 5,
				args = {
					headerGeneral = {
						type = "header",
						name = L["General"],
						order = 1,
					},
					targetBuffOnTop = {
						type = "toggle",
						name = L["Buffs above Debuffs"],
						desc = L["When buffs and debuffs are on the same side (eg both BOTTOM), show the buffs above the debuffs."],
						order = 2,
					},
					targetHighlightStealable = {
						type = "toggle",
						name = L["highlightStealable"],
						desc = L["highlightStealable"],
						order = 3,
					},
					headerBuffs = {
						type = "header",
						name = L["Buffs"],
						order = 10,
					},
					targetBuffSize = {
						type = "range",
						name = L["targetBuffSize"],
						desc = L["targetBuffSize"],
						order = 11,
						min = 5,
						max = 50,
						step = .1,
					},
					targetBuffMaxWidth = {
						type = "range",
						name = L["targetBuffMaxWidth"],
						desc = L["targetBuffMaxWidth"],
						order = 12,
						min = 100,
						max = 200,
						step = 1,
					},
					targetBuffPosition = {
						type = "select",
						name = L["targetBuffPosition"],
						order = 13,
						values = {
							["BOTTOM"] = L["BOTTOM"],
							["TOP"] = L["TOP"],
						}
					},
					targetBuffSelfFactor = {
						type = "range",
						name = L["targetBuffSelfFactor"],
						desc = L["targetBuffSelfFactor"],
						order = 14,
						min = 1,
						max = 2,
						step = .01,
					},
					headerDebuffs = {
						type = "header",
						name = L["Debuffs"],
						order = 20,
					},
					targetDebuffSize = {
						type = "range",
						name = L["targetDebuffSize"],
						desc = L["targetDebuffSize"],
						order = 21,
						min = 5,
						max = 50,
						step = .1,
					},
					targetDebuffMaxWidth = {
						type = "range",
						name = L["targetDebuffMaxWidth"],
						desc = L["targetDebuffMaxWidth"],
						order = 22,
						min = 100,
						max = 200,
						step = 1,
					},
					targetDebuffPosition = {
						type = "select",
						name = L["targetDebuffPosition"],
						order = 23,
						values = {
							["BOTTOM"] = L["BOTTOM"],
							["TOP"] = L["TOP"],
						}
					},
					targetDebuffSelfFactor = {
						type = "range",
						name = L["targetDebuffSelfFactor"],
						desc = L["targetDebuffSelfFactor"],
						order = 24,
						min = 1,
						max = 2,
						step = .01,
					},
				},
			},
			focus = {
				type = "group",
				name = L["Focus"],
				desc = L["Focus settings"],
				childGroups = "tab",
				order = 6,
				args = {
					headerGeneral = {
						type = "header",
						name = L["General"],
						order = 1,
					},
					focusBuffOnTop = {
						type = "toggle",
						name = L["Buffs above Debuffs"],
						desc = L["When buffs and debuffs are on the same side (eg both BOTTOM), show the buffs above the debuffs."],
						order = 2,
					},
					focusHighlightStealable = {
						type = "toggle",
						name = L["highlightStealable"],
						desc = L["highlightStealable"],
						order = 3,
					},
					headerBuffs = {
						type = "header",
						name = L["Buffs"],
						order = 10,
					},
					focusBuffSize = {
						type = "range",
						name = L["focusBuffSize"],
						desc = L["focusBuffSize"],
						order = 11,
						min = 5,
						max = 50,
						step = .1,
					},
					focusBuffMaxWidth = {
						type = "range",
						name = L["focusBuffMaxWidth"],
						desc = L["focusBuffMaxWidth"],
						order = 12,
						min = 100,
						max = 200,
						step = 1,
					},
					focusBuffPosition = {
						type = "select",
						name = L["focusBuffPosition"],
						order = 13,
						values = {
							["BOTTOM"] = L["BOTTOM"],
							["TOP"] = L["TOP"],
						}
					},
					focusBuffSelfFactor = {
						type = "range",
						name = L["focusBuffSelfFactor"],
						desc = L["focusBuffSelfFactor"],
						order = 14,
						min = 1,
						max = 2,
						step = .01,
					},
					focusDebuffs = {
						type = "header",
						name = L["Debuffs"],
						order = 20,
					},
					focusDebuffSize = {
						type = "range",
						name = L["focusDebuffSize"],
						desc = L["focusDebuffSize"],
						order = 21,
						min = 5,
						max = 50,
						step = .1,
					},
					focusDebuffMaxWidth = {
						type = "range",
						name = L["focusDebuffMaxWidth"],
						desc = L["focusDebuffMaxWidth"],
						order = 22,
						min = 100,
						max = 200,
						step = 1,
					},
					focusDebuffPosition = {
						type = "select",
						name = L["focusDebuffPosition"],
						order = 23,
						values = {
							["BOTTOM"] = L["BOTTOM"],
							["TOP"] = L["TOP"],
						}
					},
					focusDebuffSelfFactor = {
						type = "range",
						name = L["focusDebuffSelfFactor"],
						desc = L["focusDebuffSelfFactor"],
						order = 24,
						min = 1,
						max = 2,
						step = .01,
					},

				}
			}
		},
	}

	local options = {
		name = ADDON_NAME,
		type = "group",
		args = {
			load = {
				name = "Load configuration",
				desc = "Load configuration options",
				type = "execute",
				func = function()
					HideUIPanel(InterfaceOptionsFrame)
					HideUIPanel(GameMenuFrame)
					LibStub("AceConfigDialog-3.0"):Open(ADDON_NAME)
				end,
			},
		},
	}

	self.options.plugins.profiles = { profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.dbi) }
	LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON_NAME .. "_blizz", options)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME .. "_blizz", ADDON_NAME)
	LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON_NAME, self.options)
end

---------------------------

-- (DE)BUFF HANDLING

---------------------------

local AURA_ROW_WIDTH = 122;
local TOT_AURA_ROW_WIDTH = 101;
local AURA_START_X = 5;
local AURA_START_Y = 32;

local decisionTable = {
	["TOP"]    = {["true"]  = { ["Buff"] = "debuffs",  ["Debuff"] = "frame"},
				  ["false"] = { ["Buff"] = "frame",    ["Debuff"] = "buffs"}},
	["BOTTOM"] = {["true"]  = { ["Buff"] = "frame",    ["Debuff"] = "buffs"},
				  ["false"] = { ["Buff"] = "debuffs",  ["Debuff"] = "frame"}},
}
local validUnits = { ["target"] = true, ["focus"] = true }

local function determinePoints(frame, offsetX, offsetY, auraType, numAuras)
	local relativeFrameMatrix = { ["debuffs"] = frame.debuffs, ["frame"] = frame, ["buffs"] = frame.buffs }
	local unit = frame.unit
	local size = BuffSizer.db[unit .. auraType .. "Size"]
	local factor = BuffSizer.db[unit .. auraType .."SelfFactor"]
	local position = BuffSizer.db[unit .. auraType .. "Position"]
	local point, relativePoint, startY, startX, auraOffsetY, relativeFrame

	local pos = BuffSizer.db[unit .. "BuffPosition"]
	local bot = BuffSizer.db[unit .. "BuffOnTop"] and "true" or "false"
	if (BuffSizer.db[unit .. "BuffPosition"] == BuffSizer.db[unit .. "DebuffPosition"] and numAuras > 0) then
		--BuffSizer:Print(unit, pos, bot, auraType, decisionTable[pos][bot][auraType])
		relativeFrame = relativeFrameMatrix[decisionTable[pos][bot][auraType]]
	else
		relativeFrame = frame
		pos = "TOP"
		bot = auraType == "Buff" and "false" or "true"
	end
	if (size and factor and position) then
		if (position == "TOP") then
			point = "BOTTOM";
			relativePoint = "TOP";
			startX = numAuras == 0 and decisionTable[pos][bot][auraType] ~= "frame" and AURA_START_X
					or numAuras > 0 and decisionTable[pos][bot][auraType] ~= "frame" and 0
					or AURA_START_X
			startY = decisionTable[pos][bot][auraType] == "frame" and -15
					or numAuras == 0 and decisionTable[pos][bot][auraType] ~= "frame" and -15
					or 1
			offsetY = - offsetY;
			auraOffsetY = -1;
		elseif (position == "BOTTOM") then
			point = "TOP";
			relativePoint="BOTTOM";
			startX = numAuras == 0 and decisionTable[pos][bot][auraType] ~= "frame" and AURA_START_X
					or numAuras > 0 and decisionTable[pos][bot][auraType] ~= "frame" and 0
					or AURA_START_X
			startY = decisionTable[pos][bot][auraType] == "frame" and 32
					or numAuras == 0 and decisionTable[pos][bot][auraType] ~= "frame" and 32
					or -1;
			auraOffsetY = 1;
		end
	end
	return point and point, relativePoint, startY, startX, auraOffsetY, offsetY, size, factor, relativeFrame or nil
end

local decisionTableSpell = {
	["Buff"] = {
		--BuffOnTop
		["true"] = {
			--numAuras > 0
			["false"] = "buff"
		},
		["false"] = {
			--numAuras > 0
			["true"] = "buff",
			["false"] = "buff",
		},
	},
	["Debuff"] = {
		--BuffOnTop
		["true"] = {
			--numAuras > 0
			["true"] = "buff",
			["false"] = "buff",
		},
		["false"] = {
			--numAuras > 0
			["false"] = "buff",
		},
	}
}

local function determineSpellbarAnchor(frame, buff, auraType, numAuras)
	local unit = frame.unit
	if (BuffSizer.db[unit .. "BuffPosition"] == "TOP" and BuffSizer.db[unit .. "DebuffPosition"] == "TOP") then
		-- TOP just do parentFrame
		BuffSizer:Debug("SpellbarAnchor = frame", unit)
		frame.spellbarAnchor2Type = "frame"
		return frame
	end
	if (BuffSizer.db[unit .. "BuffPosition"] == BuffSizer.db[unit .. "DebuffPosition"]) then
		-- both at BOTTOM
		local buffOnTop = BuffSizer.db[unit .. "BuffOnTop"] and "true" or "false"
		local numAurasStr = numAuras > 0 and "true" or "false"
		BuffSizer:Debug("SpellbarAnchor =", decisionTableSpell[auraType][buffOnTop][numAurasStr] and "buff" or "frame", unit)
		frame.spellbarAnchor2Type = decisionTableSpell[auraType][buffOnTop][numAurasStr] and "buff" or "frame"
		return decisionTableSpell[auraType][buffOnTop][numAurasStr] and buff or frame
	end
	if (numAuras > 0 and BuffSizer.db[unit .. auraType .. "Position"] == "TOP") then
		BuffSizer:Debug("SpellbarAnchor = old value", unit)
		return frame.spellbarAnchor2
	end
	if (BuffSizer.db[unit .. auraType .. "Position"] == "BOTTOM") then
		BuffSizer:Debug("SpellbarAnchor = buff", unit)
		frame.spellbarAnchor2Type = "buff"
		return buff
	end
	BuffSizer:Debug("SpellbarAnchor = frame", unit)
	frame.spellbarAnchor2Type = "frame"
	return frame
end

local TargetFrame_UpdateBuffAnchor_old = TargetFrame_UpdateBuffAnchor
TargetFrame_UpdateBuffAnchor = function(self, buffName, index, numDebuffs, anchorIndex, size, offsetX, offsetY)
    -- Only override for target/focus frames
    if not validUnits[self.unit] then
        return TargetFrame_UpdateBuffAnchor_old(self, buffName, index, numDebuffs, anchorIndex, size, offsetX, offsetY)
    end

    -- Calculate anchor info (same as before)
    local point, relativePoint, startY, startX, auraOffsetY, offsetY, baseSize, factor, relativeFrame
    point, relativePoint, startY, startX, auraOffsetY, offsetY, baseSize, factor, relativeFrame =
        determinePoints(self, offsetX, offsetY, "Buff", numDebuffs)

    local buff = _G[buffName..index]
    -- IMPORTANT: get the Stealable border texture here:
    local frameStealable = _G[buffName..index.."Stealable"]  

    -- If "INCLUDE_NAME_PLATE_ONLY" isn’t recognized on your 3.3.5 server, remove or replace that.
    local name, rank, icon, count, debuffType, duration, expirationTime, caster, isStealable = UnitBuff(self.unit, index)
    if not icon then
        -- No buff at this index; default code would do: buff:Hide()
        buff:Hide()
        return
    end

    -- Enlarge buffs cast by the player
    local buffSize = (caster == "player") and baseSize * factor or baseSize
    offsetX = BuffSizer.db.debuffOffset

    -- =================================
    --  Positioning/anchor logic, as before
    -- =================================
    if (index == 1) then
        self.buffRowWidth = buffSize
        self.buffNewRowIndex = 1
        self.buffRowCount = 1
        buff:ClearAllPoints()
        self.buffs:ClearAllPoints()
        buff:SetPoint(point.."LEFT", relativeFrame, relativePoint.."LEFT", startX, startY)
        self.buffs:SetPoint(point.."LEFT", buff, point.."LEFT", 0, 0)
        self.buffs:SetPoint(relativePoint.."LEFT", buff, relativePoint.."LEFT", 0, -auraOffsetY)

        self.spellbarAnchor2 = determineSpellbarAnchor(self, buff, "Buff", numDebuffs)
    elseif ( self.buffRowWidth + buffSize > BuffSizer.db[self.unit .. "BuffMaxWidth"] ) then
        -- Start a new row
        buff:ClearAllPoints()
        buff:SetPoint(point.."LEFT", _G[buffName..self.buffNewRowIndex], relativePoint.."LEFT", 0, offsetY)
        self.buffRowCount = self.buffRowCount + 1
        self.buffNewRowIndex = index
        self.buffRowWidth = buffSize
        self.buffs:ClearAllPoints()
        self.buffs:SetPoint(relativePoint.."LEFT", buff, relativePoint.."LEFT", 0, -auraOffsetY)

        self.spellbarAnchor2 = determineSpellbarAnchor(self, buff, "Buff", numDebuffs)
    else
        -- Same row, anchor to previous buff
        self.buffRowWidth = self.buffRowWidth + buffSize + BuffSizer.db.buffOffset
        buff:ClearAllPoints()
        buff:SetPoint(point.."LEFT", _G[buffName..(index - 1)], point.."RIGHT", BuffSizer.db.buffOffset, 0)
    end

    -- ===========================
    --   SHOW/HIDE STEALABLE GLOW
    -- ===========================
    if frameStealable then
        local highlightOpt = BuffSizer.db[self.unit .. "HighlightStealable"]  -- e.g. targetHighlightStealable
        if highlightOpt
           and UnitIsEnemy("player", self.unit)
           and isStealable
           and debuffType == "Magic"
        then
            frameStealable:Show()
            -- Optionally rescale it if you want
            frameStealable:SetWidth(buffSize + buffSize / 7)
            frameStealable:SetHeight(buffSize + buffSize / 7)
        else
            frameStealable:Hide()
        end
    end

    -- Finally, set the buff icon’s size
    buff:SetWidth(buffSize)
    buff:SetHeight(buffSize)

    -- Resize the buff’s border if present
    local border = _G[buffName..index.."Border"]
    if border then
        border:SetWidth(buffSize + 2)
        border:SetHeight(buffSize + 2)
    end
end


local TargetFrame_UpdateDebuffAnchor_old = TargetFrame_UpdateDebuffAnchor
TargetFrame_UpdateDebuffAnchor = function(self, buffName, index, numBuffs, anchorIndex, size, offsetX, offsetY)
	if not validUnits[self.unit] then
		TargetFrame_UpdateDebuffAnchor_old(self, buffName, index, numBuffs, anchorIndex, size, offsetX, offsetY)
		return
	end

	local debuff = getglobal(buffName..index)

	local point, relativePoint, startY, startX, auraOffsetY, factor, relativeFrame
	point, relativePoint, startY, startX, auraOffsetY, offsetY, size, factor, relativeFrame = determinePoints(self, offsetX, offsetY, "Debuff", numBuffs)

	local _, _, _, _, _, _, caster = UnitDebuff(self.unit, index, "INCLUDE_NAME_PLATE_ONLY")
	local debuffSize = caster == "player" and size * factor or size
	offsetX = BuffSizer.db.debuffOffset

	if ( index == 1 ) then
		self.debuffRowWidth = debuffSize
		self.debuffNewRowIndex = 1
		self.debuffRowCount = 1
		debuff:ClearAllPoints()
		debuff:SetPoint(point.."LEFT", relativeFrame, relativePoint.."LEFT", startX, startY)
		self.debuffs:ClearAllPoints()
		self.debuffs:SetPoint(point.."LEFT", debuff, point.."LEFT", 0, 0)
		self.debuffs:SetPoint(relativePoint.."LEFT", debuff, relativePoint.."LEFT", 0, -auraOffsetY)
		self.spellbarAnchor2 = determineSpellbarAnchor(self, debuff, "Debuff", numBuffs)
	elseif ( self.debuffRowWidth + debuffSize > BuffSizer.db[self.unit .. "DebuffMaxWidth"]
			-- ToT visible and first line
			or BuffSizer.db[self.unit .. "DebuffPosition"] == "BOTTOM" and self.debuffRowCount == 1 and self.haveToT and self.debuffRowWidth + BuffSizer.db.debuffOffset + debuffSize > TOT_AURA_ROW_WIDTH and self == relativeFrame
			-- ToT visible and and not first line and last lines dont exceed ToT height
			or BuffSizer.db[self.unit .. "DebuffPosition"] == "BOTTOM" and self.haveToT and self.debuffRowCount > 1 and (self.debuffRowCount - 1) * size * factor < 35 and self.debuffRowWidth + BuffSizer.db.debuffOffset + debuffSize > TOT_AURA_ROW_WIDTH) then
		-- new row
		debuff:ClearAllPoints()
		debuff:SetPoint(point.."LEFT", getglobal(buffName..self.debuffNewRowIndex), relativePoint.."LEFT", 0, -offsetY)
		self.debuffNewRowIndex = index
		self.debuffRowWidth = debuffSize
		self.debuffRowCount = self.debuffRowCount + 1
		self.debuffs:ClearAllPoints()
		self.debuffs:SetPoint(relativePoint.."LEFT", debuff, relativePoint.."LEFT", 0, -auraOffsetY)
		self.spellbarAnchor2 = determineSpellbarAnchor(self, debuff, "Debuff", numBuffs)
	else
		-- anchor to previous
		self.debuffRowWidth = self.debuffRowWidth + debuffSize + BuffSizer.db.debuffOffset
		debuff:ClearAllPoints()
		debuff:SetPoint(point.."LEFT", getglobal(buffName..(index - 1)), point.."RIGHT", BuffSizer.db.debuffOffset, 0)
	end

	-- Resize
	debuff:SetWidth(debuffSize)
	debuff:SetHeight(debuffSize)

	local border = getglobal(buffName..index.."Border")
	border:SetWidth(debuffSize +2)
	border:SetHeight(debuffSize +2)
end

local TargetFrame_UpdateAuraPositions_old = TargetFrame_UpdateAuraPositions
TargetFrame_UpdateAuraPositions = function(self, auraName, numAuras, numOppositeAuras, largeAuraList, updateFunc, maxRowWidth, offsetX, mirrorAurasVertically)
	if numAuras == 0 and numOppositeAuras == 0 then
		self.spellbarAnchor2 = self
		self.spellbarAnchor2Type = "frame"
		Target_Spellbar_AdjustPosition(self.spellbar)
	end
	TargetFrame_UpdateAuraPositions_old(self, auraName, numAuras, numOppositeAuras, largeAuraList, updateFunc, maxRowWidth, offsetX, mirrorAurasVertically)
end

---------------------------

-- SPELLBAR

---------------------------

local last = GetTime()
local frames = { ["target"] = TargetFrame, ["focus"] = FocusFrame}
local Target_Spellbar_AdjustPosition_old = Target_Spellbar_AdjustPosition
Target_Spellbar_AdjustPosition = function(self)
	local parent = self:GetParent()

	if not validUnits[self.unit] then
		Target_Spellbar_AdjustPosition_old(self)
		return
	end

	if GetTime() - last > 3 then
		last = GetTime()
		BuffSizer:Debug("Target_Spellbar_AdjustPosition", parent.spellbarAnchor2Type)
	end

	if (parent.haveToT and not parent.lastHaveTot) then
		parent.lastHaveTot = true
		TargetFrame_UpdateAuras(parent)
	end

	if (not parent.haveToT and parent.lastHaveTot) then
		parent.lastHaveTot = false
		TargetFrame_UpdateAuras(parent)
	end

	--BuffSizer:Debug(parent.unit, parent.spellbarAnchor2Type, parent.haveToT)
	local yOffset = parent.haveToT and -15 or (parent.spellbarAnchor2Type == "frame" and not parent.haveToT and 7) or -15
	local xOffset = parent.spellbarAnchor2Type == "buff" and 20 or 25
	parent.spellbar:ClearAllPoints()
	parent.spellbar:SetPoint("TOPLEFT", parent.spellbarAnchor2, "BOTTOMLEFT", xOffset, yOffset);
end

local TargetFrame_OnUpdate_old = TargetFrame_OnUpdate
TargetFrame_OnUpdate = function(self, elapsed)
	if (not self.spellbarAnchor2) then
		self.spellbarAnchor2 = self
	end
	if (not self.spellbarAnchor2Type) then
		self.spellbarAnchor2Type = "frame"
	end
	TargetFrame_OnUpdate_old(self, elapsed)
	Target_Spellbar_AdjustPosition(self.spellbar)
end

