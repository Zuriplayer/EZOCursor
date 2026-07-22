-- Persistencia centralizada de EZOCursor.
-- Arrancamos con una base muy pequeña para no inventar estados todavía.
EZOCursor = EZOCursor or {}

local EZO_CURSOR = EZOCursor
local LOGGER_TAG = "EZOCursor"
local languageCallbackRegistered = false
local ezocoreRegistered = false
local debugControllerRegistered = false
local SAVED_VARIABLES_NAME = "EZOCursor_Saved"
local SAVED_VARIABLES_VERSION = 1
local MIGRATION_MARKER = "__ezoPreferenceScopeMigrated"

local function BuildDefaults()
    return {
        general = {
            language = EZO_CURSOR.I18N and EZO_CURSOR.I18N.GetDefaultLanguage() or "inherit",
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

local function DeepCopy(src)
    if type(src) ~= "table" then
        return src
    end

    local out = {}
    for key, value in pairs(src) do
        out[key] = DeepCopy(value)
    end
    return out
end

local function ApplyDefaults(target, defaults)
    if type(target) ~= "table" or type(defaults) ~= "table" then
        return
    end

    for key, value in pairs(defaults) do
        if target[key] == nil then
            target[key] = DeepCopy(value)
        elseif type(target[key]) == "table" and type(value) == "table" then
            ApplyDefaults(target[key], value)
        end
    end
end

local function CopySavedValues(target, source)
    if type(target) ~= "table" or type(source) ~= "table" then
        return
    end

    for key, value in pairs(source) do
        if key ~= MIGRATION_MARKER then
            target[key] = DeepCopy(value)
        end
    end
end

local function GetPreferenceScope()
    if EZOCore and type(EZOCore.GetPreferenceScope) == "function" then
        local ok, scope = pcall(function()
            return EZOCore:GetPreferenceScope("ezocursor", "settings")
        end)
        if ok and scope == "character" then
            return "character"
        end
    end
    return "account"
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
    local defaults = BuildDefaults()
    local scope = GetPreferenceScope()
    EZO_CURSOR.preferenceScope = scope

    if scope == "character" then
        EZO_CURSOR.sv = ZO_SavedVars:NewCharacterIdSettings(
            SAVED_VARIABLES_NAME,
            SAVED_VARIABLES_VERSION,
            worldName,
            defaults)
        if type(EZO_CURSOR.sv) == "table" and EZO_CURSOR.sv[MIGRATION_MARKER] ~= true then
            local accountSv = ZO_SavedVars:NewAccountWide(
                SAVED_VARIABLES_NAME,
                SAVED_VARIABLES_VERSION,
                worldName,
                nil)
            CopySavedValues(EZO_CURSOR.sv, accountSv)
            EZO_CURSOR.sv[MIGRATION_MARKER] = true
        end
    else
        EZO_CURSOR.sv = ZO_SavedVars:NewAccountWide(SAVED_VARIABLES_NAME, SAVED_VARIABLES_VERSION, worldName, defaults)
    end

    ApplyDefaults(EZO_CURSOR.sv, defaults)
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
    if EZO_CURSOR._debugLoggerUnavailable == true then
        return false
    end

    local lib = _G.LibDebugLogger
    if type(lib) ~= "function" and type(lib) ~= "table" then
        EZO_CURSOR._debugLoggerUnavailable = true
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
        EZO_CURSOR._debugLoggerUnavailable = false
        return pcall(function()
            logger:Info(tostring(message or ""))
        end)
    end

    EZO_CURSOR._debugLoggerUnavailable = true
    return false
end

local function RegisterEZOCoreLanguageCallback()
    if languageCallbackRegistered
        or not (EZOCore and type(EZOCore.RegisterCallback) == "function") then
        return false
    end

    local eventName = EZOCore.EVENT_LANGUAGE_CHANGED or "EZO_CORE_LANGUAGE_CHANGED"
    local ok, result = pcall(function()
        return EZOCore:RegisterCallback(eventName, function()
            if EZO_CURSOR.sv
                and EZO_CURSOR.sv.general
                and EZO_CURSOR.I18N
                and EZO_CURSOR.I18N.Apply then
                EZO_CURSOR.I18N.Apply(EZO_CURSOR.sv.general.language or "inherit")
            end
        end)
    end)
    languageCallbackRegistered = ok and result == true
    return languageCallbackRegistered
end

local function RegisterWithEZOCore()
    if ezocoreRegistered
        or not (EZOCore and type(EZOCore.RegisterAddon) == "function") then
        return false
    end

    local ok, result = pcall(function()
        return EZOCore:RegisterAddon({
            id = "ezocursor",
            name = EZO_CURSOR.ADDON_NAME or "EZOCursor",
            version = EZO_CURSOR.ADDON_VERSION or "0.0.0",
            addOnVersion = 10015,
            apiVersion = 1,
            capabilities = {
                "cursor.blockState",
                "cursor.reticle",
                "family.debug.controller",
                "family.language.consumer",
                "family.settings.consumer",
            },
        })
    end)

    ezocoreRegistered = ok and result == true
    return ezocoreRegistered
end

function EZO_CURSOR.SetDebugModeEnabled(enabled)
    local settings = EZO_CURSOR.sv and EZO_CURSOR.sv.reticle
    if not settings then
        return false
    end

    settings.debugEnabled = enabled == true
    if EZO_CURSOR.ReticleVisual and EZO_CURSOR.ReticleVisual.Start then
        EZO_CURSOR.ReticleVisual.Start()
    end
    return settings.debugEnabled == (enabled == true)
end

local function RegisterDebugWithEZOCore()
    if debugControllerRegistered
        or not (EZOCore and type(EZOCore.GetService) == "function") then
        return false
    end

    local service = EZOCore:GetService("family.debug", 1)
    if not service or type(service.RegisterController) ~= "function" then
        return false
    end

    local ok, result = pcall(function()
        return service:RegisterController({
            id = "ezocursor.debug",
            addonId = "ezocursor",
            addonName = "EZOCursor",
            name = function() return GetString(SI_EZOCURSOR_OPTION_DEBUG_ENABLE) end,
            isEnabled = function()
                return EZO_CURSOR.sv
                    and EZO_CURSOR.sv.reticle
                    and EZO_CURSOR.sv.reticle.debugEnabled == true
            end,
            setEnabled = function(enabled)
                return EZO_CURSOR.SetDebugModeEnabled(enabled == true)
            end,
        })
    end)

    debugControllerRegistered = ok and result == true
    return debugControllerRegistered
end

function EZO_CURSOR.Initialize()
    EnsureSavedVariables()

    local selectedLanguage = EZO_CURSOR.sv
        and EZO_CURSOR.sv.general
        and EZO_CURSOR.sv.general.language
        or nil

    local appliedLanguage = EZO_CURSOR.I18N and EZO_CURSOR.I18N.Apply(selectedLanguage) or "en"

    if EZO_CURSOR.sv and EZO_CURSOR.sv.general and not EZO_CURSOR.sv.general.language then
        EZO_CURSOR.sv.general.language = EZO_CURSOR.I18N and EZO_CURSOR.I18N.GetDefaultLanguage() or appliedLanguage
    end
    RegisterEZOCoreLanguageCallback()
    RegisterWithEZOCore()
    RegisterDebugWithEZOCore()

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
