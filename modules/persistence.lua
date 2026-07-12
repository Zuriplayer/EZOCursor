-- Persistencia centralizada de EZOCursor.
-- Arrancamos con una base muy pequeña para no inventar estados todavía.
EZOCursor = EZOCursor or {}

local EZO_CURSOR = EZOCursor
local LOGGER_TAG = "EZOCursor"

local function BuildDefaults()
    return {
        general = {
            language = EZO_CURSOR.I18N and EZO_CURSOR.I18N.GetSupportedLanguage() or "en",
        },
        reticle = {
            enabled = true,
            blockIndicatorEnabled = true,
            guidesEnabled = true,
            guidesMode = "always",
            debugEnabled = false,
            guideColors = {
                noAttackable = { r = 0.85, g = 0.85, b = 0.85, a = 0.8 },
                attackable = { r = 0.2, g = 1, b = 0.35, a = 0.95 },
                cameraPreferred = { r = 0.55, g = 0.65, b = 1, a = 1 },
                combat = { r = 1, g = 0.12, b = 0.08, a = 1 },
                combatDamage = { r = 1, g = 0.55, b = 0.2, a = 1 },
            },
            useCircularReticle = true,
            idleAlpha = 0.85,
        },
    }
end

local function MoveGuideColor(colors, fromKey, toKey)
    if type(colors[fromKey]) == "table" then
        colors[toKey] = colors[fromKey]
    end
    colors[fromKey] = nil
end

local function MigrateSavedVariables()
    local colors = EZO_CURSOR.sv
        and EZO_CURSOR.sv.reticle
        and EZO_CURSOR.sv.reticle.guideColors
        or nil

    if type(colors) ~= "table" then
        return
    end

    MoveGuideColor(colors, "neutral", "noAttackable")
    MoveGuideColor(colors, "attackableFocused", "cameraPreferred")
    MoveGuideColor(colors, "attacked", "combat")
    MoveGuideColor(colors, "attackedFocused", "combatDamage")
end

local function EnsureSavedVariables()
    local worldName = GetWorldName()
    EZO_CURSOR.sv = ZO_SavedVars:NewAccountWide("EZOCursor_Saved", 1, worldName, BuildDefaults())
    MigrateSavedVariables()
end

local function SafeChat(message)
    if LibChatMessage then
        LibChatMessage(EZO_CURSOR.ADDON_NAME, "EZOC"):Print(tostring(message))
        return
    end

    d(tostring(message))
end

local function LogInfo(message)
    local lib = _G.LibDebugLogger
    if type(lib) ~= "function" and type(lib) ~= "table" then
        return false
    end

    if not EZO_CURSOR._debugLogger and type(lib) == "function" then
        local ok, logger = pcall(lib, LOGGER_TAG)
        if ok then
            EZO_CURSOR._debugLogger = logger
        end
    end
    if not EZO_CURSOR._debugLogger and type(lib) == "table" and type(lib.Create) == "function" then
        local ok, logger = pcall(function()
            return lib:Create(LOGGER_TAG)
        end)
        if ok then
            EZO_CURSOR._debugLogger = logger
        end
    end

    local logger = EZO_CURSOR._debugLogger
    if logger and type(logger.Info) == "function" then
        return pcall(function()
            logger:Info(tostring(message or ""))
        end)
    end

    return false
end

function EZO_CURSOR.Initialize()
    EnsureSavedVariables()

    local selectedLanguage = EZO_CURSOR.sv
        and EZO_CURSOR.sv.general
        and EZO_CURSOR.sv.general.language
        or nil

    local appliedLanguage = EZO_CURSOR.I18N and EZO_CURSOR.I18N.Apply(selectedLanguage) or "en"

    if EZO_CURSOR.sv and EZO_CURSOR.sv.general then
        EZO_CURSOR.sv.general.language = appliedLanguage
    end

    EZO_CURSOR.Print = SafeChat
    EZO_CURSOR.LogInfo = LogInfo
    EZO_CURSOR.DebugLog = LogInfo
    LogInfo(GetString(SI_EZOCURSOR_MSG_INIT))
    EZO_CURSOR.Print(GetString(SI_EZOCURSOR_MSG_INIT))

    if EZO_CURSOR.ReticleVisual and EZO_CURSOR.ReticleVisual.Initialize then
        EZO_CURSOR.ReticleVisual.Initialize()
    end

    if EZO_CURSOR.LAM and EZO_CURSOR.LAM.Initialize then
        EZO_CURSOR.LAM.Initialize()
    end
end
