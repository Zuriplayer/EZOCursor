-- Persistencia centralizada de EZOCursor.
-- Arrancamos con una base muy pequeña para no inventar estados todavía.
EZOCursor = EZOCursor or {}

local EZO_CURSOR = EZOCursor

local function BuildDefaults()
    return {
        general = {
            language = EZO_CURSOR.I18N and EZO_CURSOR.I18N.GetSupportedLanguage() or "en",
        },
        reticle = {
            enabled = true,
            blockIndicatorEnabled = true,
            useCircularReticle = true,
            idleAlpha = 0.85,
        },
    }
end

local function EnsureSavedVariables()
    local worldName = GetWorldName()
    EZO_CURSOR.sv = ZO_SavedVars:NewAccountWide("EZOCursor_Saved", 1, worldName, BuildDefaults())
end

local function SafeChat(message)
    if LibChatMessage then
        LibChatMessage(EZO_CURSOR.ADDON_NAME, "EZOC"):Print(tostring(message))
        return
    end

    d(tostring(message))
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
    EZO_CURSOR.Print(GetString(SI_EZOCURSOR_MSG_INIT))

    if EZO_CURSOR.ReticleVisual and EZO_CURSOR.ReticleVisual.Initialize then
        EZO_CURSOR.ReticleVisual.Initialize()
    end
end
