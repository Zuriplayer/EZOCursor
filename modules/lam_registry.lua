-- Panel de configuración LAM de EZOCursor.
-- Mantiene las opciones iniciales pequeñas y centradas en el retículo.
EZOCursor = EZOCursor or {}
EZOCursor.LAM = EZOCursor.LAM or {}

local EZO_CURSOR = EZOCursor
local LAM = EZO_CURSOR.LAM

local GUIDES_ALWAYS = "always"
local GUIDES_COMBAT = "combat"
local INFO_HEADER_TEXTURE = "EsoUI/Art/Miscellaneous/help_icon.dds"
local PANEL_ID = "EZOCursor_Panel"
local FEEDBACK_URL = "https://discord.gg/ekw8zUAcRm"

local GUIDE_COLOR_DEFAULTS = {
    noAttackable = { r = 0.85, g = 0.85, b = 0.85, a = 0.8 },
    attackable = { r = 0.2, g = 1, b = 0.35, a = 0.95 },
    cameraPreferred = { r = 0.55, g = 0.65, b = 1, a = 1 },
    combat = { r = 1, g = 0.12, b = 0.08, a = 1 },
    combatDamage = { r = 1, g = 0.55, b = 0.2, a = 1 },
}

local function GetReticleSettings()
    EZO_CURSOR.sv = EZO_CURSOR.sv or {}
    EZO_CURSOR.sv.reticle = EZO_CURSOR.sv.reticle or {}
    EZO_CURSOR.sv.reticle.guideColors = EZO_CURSOR.sv.reticle.guideColors or {}
    return EZO_CURSOR.sv.reticle
end

local function RefreshReticleVisuals()
    if EZO_CURSOR.ReticleVisual and EZO_CURSOR.ReticleVisual.Start then
        EZO_CURSOR.ReticleVisual.Start()
        return
    end
    if EZO_CURSOR.ReticleVisual and EZO_CURSOR.ReticleVisual.ApplyCurrentState then
        EZO_CURSOR.ReticleVisual.ApplyCurrentState()
    end
    if EZO_CURSOR.ReticleVisual and EZO_CURSOR.ReticleVisual.RefreshGuideLayout then
        EZO_CURSOR.ReticleVisual.RefreshGuideLayout()
    end
end

function LAM.CreateInfoHeader(name, tooltip)
    return {
        type = "header",
        name = zo_strformat(
            "<<1>> |cB040FF|t26:26:<<2>>:inheritcolor|t|r",
            tostring(name or ""),
            INFO_HEADER_TEXTURE
        ),
        tooltip = tooltip,
    }
end

local function GetGuideColor(colorKey)
    local settings = GetReticleSettings()
    local defaults = GUIDE_COLOR_DEFAULTS[colorKey]
    settings.guideColors[colorKey] = settings.guideColors[colorKey] or {
        r = defaults.r,
        g = defaults.g,
        b = defaults.b,
        a = defaults.a,
    }

    local color = settings.guideColors[colorKey]
    return color.r or defaults.r, color.g or defaults.g, color.b or defaults.b, color.a or defaults.a
end

local function SetGuideColor(colorKey, red, green, blue, alpha)
    local settings = GetReticleSettings()
    settings.guideColors[colorKey] = {
        r = red,
        g = green,
        b = blue,
        a = alpha or 1,
    }
    RefreshReticleVisuals()
end

local function BuildGuideColorOption(colorKey, nameStringId)
    return {
        type = "colorpicker",
        name = GetString(nameStringId),
        tooltip = GetString(SI_EZOCURSOR_OPTION_GUIDE_COLOR_TOOLTIP),
        getFunc = function()
            return GetGuideColor(colorKey)
        end,
        setFunc = function(red, green, blue, alpha)
            SetGuideColor(colorKey, red, green, blue, alpha)
        end,
        default = GUIDE_COLOR_DEFAULTS[colorKey],
        disabled = function()
            return GetReticleSettings().guidesEnabled == false
        end,
        width = "full",
    }
end

local function BuildOptions()
    return {
        LAM.CreateInfoHeader(
            GetString(SI_EZOCURSOR_OPTION_RETICLE_HEADER),
            GetString(SI_EZOCURSOR_OPTION_RETICLE_HEADER_TOOLTIP)
        ),
        {
            type = "checkbox",
            name = GetString(SI_EZOCURSOR_OPTION_GUIDES_ENABLE),
            tooltip = GetString(SI_EZOCURSOR_OPTION_GUIDES_ENABLE_TOOLTIP),
            getFunc = function()
                return GetReticleSettings().guidesEnabled ~= false
            end,
            setFunc = function(value)
                GetReticleSettings().guidesEnabled = value == true
                RefreshReticleVisuals()
            end,
            default = true,
            width = "full",
        },
        {
            type = "dropdown",
            name = GetString(SI_EZOCURSOR_OPTION_GUIDES_MODE),
            tooltip = GetString(SI_EZOCURSOR_OPTION_GUIDES_TOOLTIP),
            choices = {
                GetString(SI_EZOCURSOR_GUIDES_ALWAYS),
                GetString(SI_EZOCURSOR_GUIDES_COMBAT),
            },
            choicesValues = {
                GUIDES_ALWAYS,
                GUIDES_COMBAT,
            },
            getFunc = function()
                return GetReticleSettings().guidesMode or GUIDES_ALWAYS
            end,
            setFunc = function(value)
                local mode = tostring(value or GUIDES_ALWAYS)
                if mode ~= GUIDES_ALWAYS and mode ~= GUIDES_COMBAT then
                    mode = GUIDES_ALWAYS
                end
                GetReticleSettings().guidesMode = mode
                RefreshReticleVisuals()
            end,
            default = GUIDES_ALWAYS,
            disabled = function()
                return GetReticleSettings().guidesEnabled == false
            end,
            width = "full",
        },
        LAM.CreateInfoHeader(
            GetString(SI_EZOCURSOR_OPTION_DEBUG_HEADER),
            GetString(SI_EZOCURSOR_OPTION_DEBUG_HEADER_TOOLTIP)
        ),
        {
            type = "checkbox",
            name = GetString(SI_EZOCURSOR_OPTION_DEBUG_ENABLE),
            tooltip = GetString(SI_EZOCURSOR_OPTION_DEBUG_ENABLE_TOOLTIP),
            getFunc = function()
                return GetReticleSettings().debugEnabled == true
            end,
            setFunc = function(value)
                if EZO_CURSOR.SetDebugModeEnabled then
                    EZO_CURSOR.SetDebugModeEnabled(value == true)
                else
                    GetReticleSettings().debugEnabled = value == true
                    RefreshReticleVisuals()
                end
            end,
            default = false,
            width = "full",
        },
        LAM.CreateInfoHeader(
            GetString(SI_EZOCURSOR_OPTION_GUIDE_COLORS_HEADER),
            GetString(SI_EZOCURSOR_OPTION_GUIDE_COLORS_HEADER_TOOLTIP)
        ),
        BuildGuideColorOption("noAttackable", SI_EZOCURSOR_OPTION_GUIDE_COLOR_NO_ATTACKABLE),
        BuildGuideColorOption("attackable", SI_EZOCURSOR_OPTION_GUIDE_COLOR_ATTACKABLE),
        BuildGuideColorOption("cameraPreferred", SI_EZOCURSOR_OPTION_GUIDE_COLOR_CAMERA_PREFERRED),
        BuildGuideColorOption("combat", SI_EZOCURSOR_OPTION_GUIDE_COLOR_COMBAT),
        BuildGuideColorOption("combatDamage", SI_EZOCURSOR_OPTION_GUIDE_COLOR_COMBAT_DAMAGE),
    }
end

function LAM.Initialize()
    if LAM.initialized then
        return
    end

    local lib = LibAddonMenu2
    if not lib then
        return
    end

    LAM.initialized = true

    local panelData = {
        type = "panel",
        name = EZO_CURSOR.ADDON_NAME,
        displayName = GetString(SI_EZOCURSOR_TITLE),
        author = EZO_CURSOR.AUTHOR,
        version = EZO_CURSOR.ADDON_VERSION,
        ezoStage = "beta",
        feedback = FEEDBACK_URL,
        registerForRefresh = true,
        registerForDefaults = true,
    }

    local options = BuildOptions()
    if EZOCore and type(EZOCore.RegisterSettingsPanel) == "function" then
        local registered = EZOCore:RegisterSettingsPanel(EZO_CURSOR.ADDON_NAME, PANEL_ID, panelData, options)
        if registered then
            EZO_CURSOR.ezoSettingsRegistered = true
            return
        end
    end

    local panel = lib:RegisterAddonPanel(PANEL_ID, panelData)
    EZO_CURSOR._lamPanel = panel
    _G.EZOCursor_Panel = panel

    lib:RegisterOptionControls(PANEL_ID, options)
end
