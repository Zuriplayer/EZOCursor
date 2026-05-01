-- Registro y aplicación de textos localizados.
-- La idea es mantener todos los textos fuera de la lógica para no hardcodear
-- mensajes en módulos futuros.
EZOCursor = EZOCursor or {}
EZOCursor.I18N = EZOCursor.I18N or {}

local I18N = EZOCursor.I18N

local function GetClientDefaultLanguage()
    if type(GetCVar) == "function" then
        local language = zo_strlower(tostring(GetCVar("Language.2") or ""))
        if language == "es" or language == "en" then
            return language
        end
    end

    return "en"
end

local function RegisterString(stringIdName, value)
    local stringId = _G[stringIdName]
    if type(stringId) ~= "number" then
        ZO_CreateStringId(stringIdName, tostring(value))
        stringId = _G[stringIdName]
    end

    if type(stringId) ~= "number" then
        return
    end

    SafeAddVersion(stringId, 1)
    SafeAddString(stringId, tostring(value), 1)
end

function I18N.GetSupportedLanguage(language)
    if language == "es" or language == "en" then
        return language
    end

    return GetClientDefaultLanguage()
end

function I18N.Apply(language)
    local supportedLanguage = I18N.GetSupportedLanguage(language)
    local source = supportedLanguage == "es" and EZO_CURSOR_STRINGS_ES or EZO_CURSOR_STRINGS_EN

    if type(source) ~= "table" then
        return "en"
    end

    for stringIdName, value in pairs(source) do
        RegisterString(stringIdName, value)
    end

    EZOCursor.activeLanguage = supportedLanguage
    return supportedLanguage
end
