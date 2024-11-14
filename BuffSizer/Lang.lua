local setmetatable = setmetatable
local C_CreatureInfo = C_CreatureInfo

local GetLocale = GetLocale

local L = {}


-- Superhack allowing use key as value if not present in table
LibStub("BuffSizer").L = setmetatable(L, {
    __index = function(t, k)
        return k
    end
})