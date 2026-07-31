-- Gestión visual del retículo y de las líneas guía de pantalla.
EZOCursor = EZOCursor or {}
EZOCursor.ReticleVisual = EZOCursor.ReticleVisual or {}

local EZO_CURSOR = EZOCursor
local ReticleVisual = EZO_CURSOR.ReticleVisual

local BLOCK_UPDATE_NAME = "EZOCursor_BlockState"
local PLAYER_ACTIVATED_EVENT = "EZOCursor_PlayerActivated"
local SCREEN_RESIZED_EVENT = "EZOCursor_ScreenResized"
local COMBAT_STATE_EVENT = "EZOCursor_CombatState"
local TARGET_CHANGED_EVENT = "EZOCursor_TargetChanged"
local GUIDE_STATE_UPDATE_NAME = "EZOCursor_GuideState"
local COMBAT_DAMAGE_EVENT_PREFIX = "EZOCursor_CombatDamage"
local SCENE_STATE_CALLBACK_NAME = "SceneStateChanged"
local DEFAULT_RETICLE_TEXTURE = "EsoUI/Art/Reticle/reticleAnim.dds"
local CIRCULAR_RETICLE_TEXTURE = "EsoUI/Art/Reticle/reticleAnim-circle.dds"
local BLOCK_SHIELD_TEXTURE = "/EZOCursor/media/reticle/block_shield.dds"
local GUIDE_TEXTURE = "/EZOCursor/media/reticle/guide_pixel.dds"
local GUIDE_THICKNESS = 4
local TARGET_INDICATOR_LENGTH = 64
local BLOCK_ALERT_COST_MULTIPLIER = 5
local BLOCK_NORMAL_COLOR = { 1, 1, 1, 0.96 }
local BLOCK_LOW_STAMINA_COLOR = { 1, 0.18, 0.05, 1 }
local GUIDE_COLOR_FALLBACKS = {
    noAttackable = { 0.85, 0.85, 0.85, 0.8 },
    attackable = { 0.2, 1, 0.35, 0.95 },
    cameraPreferred = { 0.55, 0.65, 1, 1 },
    combat = { 1, 0.12, 0.08, 1 },
    combatDamage = { 1, 0.55, 0.2, 1 },
}
local GUIDE_STATE_STRING_ID_NAMES = {
    noAttackable = "SI_EZOCURSOR_STATE_NO_ATTACKABLE",
    attackable = "SI_EZOCURSOR_STATE_ATTACKABLE",
    cameraPreferred = "SI_EZOCURSOR_STATE_CAMERA_PREFERRED",
    combat = "SI_EZOCURSOR_STATE_COMBAT",
    combatDamage = "SI_EZOCURSOR_STATE_COMBAT_DAMAGE",
}
local GUIDE_STATE_UPDATE_MS = 150
local PREFERRED_TARGET_UPDATE_MS = 250
local COMBAT_DAMAGE_FLASH_MS = 600
local DEBUG_HISTORY_LIMIT = 5
local DEBUG_ROW_COUNT = 11
local DAMAGE_RESULTS = {
    ACTION_RESULT_DAMAGE,
    ACTION_RESULT_CRITICAL_DAMAGE,
    ACTION_RESULT_DOT_TICK,
    ACTION_RESULT_DOT_TICK_CRITICAL,
    ACTION_RESULT_DAMAGE_SHIELDED,
    ACTION_RESULT_BLOCKED_DAMAGE,
}
local HUD_SCENE_NAMES = {
    hud = true,
    hudui = true,
}

ReticleVisual.isBlocking = false
ReticleVisual.isBlockStaminaLow = false
ReticleVisual.currentStamina = 0
ReticleVisual.blockCost = 0
ReticleVisual.originalAlpha = nil
ReticleVisual.originalTexture = nil
ReticleVisual.blockOverlay = nil
ReticleVisual.blockFragment = nil
ReticleVisual.guideOverlay = nil
ReticleVisual.guideFragment = nil
ReticleVisual.outerGuides = nil
ReticleVisual.horizontalTargetGuide = nil
ReticleVisual.verticalTargetGuide = nil
ReticleVisual.inCombat = false
ReticleVisual.targetName = nil
ReticleVisual.targetAttackable = false
ReticleVisual.preferredTargetValid = false
ReticleVisual.lastPreferredCheckMs = 0
ReticleVisual.lastCombatDamageMs = 0
ReticleVisual.playerName = nil
ReticleVisual.currentGuideState = nil
ReticleVisual.currentTargetState = nil
ReticleVisual.stateHistory = {}
ReticleVisual.debugPanel = nil
ReticleVisual.debugFragment = nil
ReticleVisual.debugRows = nil
ReticleVisual.sceneCallbackRegistered = false

local function GetReticleControl()
    return ZO_ReticleContainerReticle
end

local function GetCurrentSceneName()
    if type(SCENE_MANAGER) ~= "table" then
        return nil
    end

    if type(SCENE_MANAGER.GetCurrentSceneName) == "function" then
        return SCENE_MANAGER:GetCurrentSceneName()
    end

    if type(SCENE_MANAGER.GetCurrentScene) ~= "function" then
        return nil
    end

    local currentScene = SCENE_MANAGER:GetCurrentScene()
    if currentScene and type(currentScene.GetName) == "function" then
        return currentScene:GetName()
    end
    if currentScene and currentScene.name then
        return currentScene.name
    end

    return nil
end

local function IsHudSceneActive()
    if type(SCENE_MANAGER) ~= "table" then
        return true
    end

    if type(SCENE_MANAGER.IsShowing) == "function" then
        for sceneName in pairs(HUD_SCENE_NAMES) do
            if SCENE_MANAGER:IsShowing(sceneName) then
                return true
            end
        end
    end

    local currentSceneName = GetCurrentSceneName()
    if currentSceneName then
        return HUD_SCENE_NAMES[currentSceneName] == true
    end

    return true
end

local function SetControlHidden(control, hidden)
    if control and type(control.SetHidden) == "function" then
        control:SetHidden(hidden == true)
    end
end

local function HideAddonVisuals()
    SetControlHidden(ReticleVisual.blockOverlay, true)
    SetControlHidden(ReticleVisual.guideOverlay, true)
    SetControlHidden(ReticleVisual.debugPanel, true)
end

local function HideGuideAndDebug()
    SetControlHidden(ReticleVisual.guideOverlay, true)
    SetControlHidden(ReticleVisual.debugPanel, true)
end

local function HideGuides()
    SetControlHidden(ReticleVisual.guideOverlay, true)
end

local function HideOuterGuides()
    for _, control in pairs(ReticleVisual.outerGuides or {}) do
        SetControlHidden(control, true)
    end
end

local function HideTargetIndicator()
    SetControlHidden(ReticleVisual.horizontalTargetGuide, true)
    SetControlHidden(ReticleVisual.verticalTargetGuide, true)
end

local function ShouldShowTargetIndicator(settings)
    return IsHudSceneActive() and settings and settings.guidesEnabled ~= false
end

local function RegisterHudFragment(control, fragmentField)
    if ReticleVisual[fragmentField] or not control or not ZO_SimpleSceneFragment then
        return
    end

    local fragment = ZO_SimpleSceneFragment:New(control)
    ReticleVisual[fragmentField] = fragment

    if HUD_SCENE and type(HUD_SCENE.AddFragment) == "function" then
        HUD_SCENE:AddFragment(fragment)
    end
    if HUD_UI_SCENE and type(HUD_UI_SCENE.AddFragment) == "function" then
        HUD_UI_SCENE:AddFragment(fragment)
    end
end

local function GetReticleSettings()
    return EZO_CURSOR.sv and EZO_CURSOR.sv.reticle or nil
end

local function GetGuideColor(colorKey)
    local fallback = GUIDE_COLOR_FALLBACKS[colorKey] or GUIDE_COLOR_FALLBACKS.noAttackable
    local settings = GetReticleSettings()
    local savedColor = settings and settings.guideColors and settings.guideColors[colorKey] or nil

    if type(savedColor) ~= "table" then
        return fallback
    end

    return {
        savedColor.r or fallback[1],
        savedColor.g or fallback[2],
        savedColor.b or fallback[3],
        savedColor.a or fallback[4],
    }
end

local function CleanUnitName(unitName)
    if type(unitName) ~= "string" then
        return nil
    end

    local cleanName = string.gsub(unitName, "%^%w+", "")
    if cleanName == "" then
        return nil
    end
    return cleanName
end

local function GetNowMs()
    if type(GetGameTimeMilliseconds) == "function" then
        return GetGameTimeMilliseconds()
    end
    return 0
end

local function GetGuideStateText(state)
    local stringIdName = GUIDE_STATE_STRING_ID_NAMES[state] or GUIDE_STATE_STRING_ID_NAMES.noAttackable
    local stringId = _G[stringIdName] or SI_EZOCURSOR_STATE_NO_ATTACKABLE
    if type(stringId) ~= "number" then
        return tostring(state or "noAttackable")
    end
    return GetString(stringId)
end

local function ShouldShowDebugPanel(settings)
    return IsHudSceneActive() and settings and settings.debugEnabled == true
end

local function ShouldShowOuterGuides(settings)
    if not ShouldShowTargetIndicator(settings) then
        return false
    end

    local mode = settings and settings.guidesMode or "always"
    if mode == "combat" then
        return ReticleVisual.inCombat == true
    end
    return true
end

local function CreateGuideSegment(name, parent, texture, color)
    local control = WINDOW_MANAGER:CreateControl(name, parent, CT_TEXTURE)
    control:SetTexture(texture)
    control:SetColor(unpack(color))
    control:SetDrawLayer(DL_OVERLAY)
    control:SetDrawTier(DT_HIGH)
    control:SetMouseEnabled(false)
    control:ClearAnchors()
    return control
end

local function EnsureBlockOverlay(reticleControl)
    if ReticleVisual.blockOverlay then
        return ReticleVisual.blockOverlay
    end

    local overlay = WINDOW_MANAGER:CreateControl("EZOCursor_BlockOverlay", reticleControl:GetParent(), CT_TEXTURE)
    overlay:SetDimensions(74, 74)
    overlay:ClearAnchors()
    overlay:SetAnchor(CENTER, reticleControl, CENTER, 0, 0)
    overlay:SetTexture(BLOCK_SHIELD_TEXTURE)
    overlay:SetColor(unpack(BLOCK_NORMAL_COLOR))
    overlay:SetDrawLayer(DL_OVERLAY)
    overlay:SetDrawTier(DT_HIGH)
    overlay:SetMouseEnabled(false)
    overlay:SetHidden(true)

    ReticleVisual.blockOverlay = overlay
    RegisterHudFragment(overlay, "blockFragment")
    return overlay
end

local function EnsureGuideOverlay(reticleControl)
    if ReticleVisual.guideOverlay
        and ReticleVisual.outerGuides
        and ReticleVisual.horizontalTargetGuide
        and ReticleVisual.verticalTargetGuide then
        return ReticleVisual.guideOverlay
    end

    local overlay = WINDOW_MANAGER:CreateControl("EZOCursor_GuideOverlay", reticleControl:GetParent(), CT_CONTROL)
    overlay:SetDimensions(1, 1)
    overlay:ClearAnchors()
    overlay:SetAnchor(CENTER, reticleControl, CENTER, 0, 0)
    overlay:SetDrawLayer(DL_OVERLAY)
    overlay:SetDrawTier(DT_HIGH)
    overlay:SetMouseEnabled(false)
    overlay:SetHidden(true)

    local initialColor = GetGuideColor("noAttackable")
    local halfTargetLength = TARGET_INDICATOR_LENGTH / 2
    local outerGuides = {
        left = CreateGuideSegment("EZOCursor_GuideHorizontalLeft", overlay, GUIDE_TEXTURE, initialColor),
        right = CreateGuideSegment("EZOCursor_GuideHorizontalRight", overlay, GUIDE_TEXTURE, initialColor),
        top = CreateGuideSegment("EZOCursor_GuideVerticalTop", overlay, GUIDE_TEXTURE, initialColor),
        bottom = CreateGuideSegment("EZOCursor_GuideVerticalBottom", overlay, GUIDE_TEXTURE, initialColor),
    }
    outerGuides.left:SetAnchor(RIGHT, overlay, CENTER, -halfTargetLength, 0)
    outerGuides.right:SetAnchor(LEFT, overlay, CENTER, halfTargetLength, 0)
    outerGuides.top:SetAnchor(BOTTOM, overlay, CENTER, 0, -halfTargetLength)
    outerGuides.bottom:SetAnchor(TOP, overlay, CENTER, 0, halfTargetLength)

    local horizontalTargetGuide = CreateGuideSegment(
        "EZOCursor_GuideTargetHorizontal",
        overlay,
        GUIDE_TEXTURE,
        initialColor
    )
    horizontalTargetGuide:SetDimensions(TARGET_INDICATOR_LENGTH, GUIDE_THICKNESS)
    horizontalTargetGuide:SetAnchor(CENTER, overlay, CENTER, 0, 0)

    local verticalTargetGuide = CreateGuideSegment(
        "EZOCursor_GuideTargetVertical",
        overlay,
        GUIDE_TEXTURE,
        initialColor
    )
    verticalTargetGuide:SetDimensions(GUIDE_THICKNESS, TARGET_INDICATOR_LENGTH)
    verticalTargetGuide:SetAnchor(CENTER, overlay, CENTER, 0, 0)

    ReticleVisual.guideOverlay = overlay
    ReticleVisual.outerGuides = outerGuides
    ReticleVisual.horizontalTargetGuide = horizontalTargetGuide
    ReticleVisual.verticalTargetGuide = verticalTargetGuide
    RegisterHudFragment(overlay, "guideFragment")
    return overlay
end

local function EnsureDebugPanel()
    if ReticleVisual.debugPanel and ReticleVisual.debugRows then
        return ReticleVisual.debugPanel
    end

    local panel = WINDOW_MANAGER:CreateTopLevelWindow("EZOCursor_DebugPanel")
    panel:SetDimensions(330, 306)
    panel:ClearAnchors()
    panel:SetAnchor(RIGHT, GuiRoot, RIGHT, -80, 0)
    panel:SetDrawLayer(DL_OVERLAY)
    panel:SetDrawTier(DT_HIGH)
    panel:SetMouseEnabled(false)
    panel:SetHidden(true)

    local backdrop = WINDOW_MANAGER:CreateControl("EZOCursor_DebugPanelBackdrop", panel, CT_BACKDROP)
    backdrop:SetAnchor(TOPLEFT, panel, TOPLEFT, 0, 0)
    backdrop:SetAnchor(BOTTOMRIGHT, panel, BOTTOMRIGHT, 0, 0)
    backdrop:SetCenterColor(0, 0, 0, 0.62)
    backdrop:SetEdgeColor(0.75, 0.75, 0.75, 0.65)
    backdrop:SetMouseEnabled(false)

    local title = WINDOW_MANAGER:CreateControl("EZOCursor_DebugPanelTitle", panel, CT_LABEL)
    title:SetAnchor(TOPLEFT, panel, TOPLEFT, 10, 8)
    title:SetDimensions(310, 20)
    title:SetFont("ZoFontGameSmall")
    title:SetColor(1, 1, 1, 1)
    title:SetText(GetString(SI_EZOCURSOR_DEBUG_CURSOR_STATES))
    title:SetMouseEnabled(false)

    ReticleVisual.debugRows = {}
    for index = 1, DEBUG_ROW_COUNT do
        local row = WINDOW_MANAGER:CreateControl("EZOCursor_DebugPanelRow" .. tostring(index), panel, CT_LABEL)
        row:SetAnchor(TOPLEFT, panel, TOPLEFT, 10, 30 + (index - 1) * 24)
        row:SetDimensions(310, 22)
        row:SetFont(index == 1 and "ZoFontGameMedium" or "ZoFontGameSmall")
        row:SetColor(0.75, 0.75, 0.75, 0.9)
        row:SetMouseEnabled(false)
        row:SetText("")
        ReticleVisual.debugRows[index] = row
    end

    ReticleVisual.debugPanel = panel
    RegisterHudFragment(panel, "debugFragment")
    return panel
end

local function TrackGuideState(state)
    if ReticleVisual.stateHistory[1] == state then
        return
    end

    table.insert(ReticleVisual.stateHistory, 1, state)
    while #ReticleVisual.stateHistory > DEBUG_HISTORY_LIMIT do
        table.remove(ReticleVisual.stateHistory)
    end
end

local function IsCombatDamageActive()
    return ReticleVisual.inCombat == true
        and ReticleVisual.lastCombatDamageMs > 0
        and GetNowMs() - ReticleVisual.lastCombatDamageMs <= COMBAT_DAMAGE_FLASH_MS
end

local function GetBooleanText(value)
    if value then
        return GetString(SI_EZOCURSOR_DEBUG_YES)
    end
    return GetString(SI_EZOCURSOR_DEBUG_NO)
end

local function SetDebugRow(index, labelStringId, valueText, active)
    local row = ReticleVisual.debugRows and ReticleVisual.debugRows[index] or nil
    if not row then
        return
    end

    row:SetText(GetString(labelStringId) .. " " .. tostring(valueText or ""))
    if active then
        row:SetColor(1, 0.92, 0.35, 1)
    else
        row:SetColor(0.82, 0.82, 0.82, 0.9)
    end
end

local function UpdateDebugPanel(outerState, targetState)
    local settings = GetReticleSettings()
    if not ShouldShowDebugPanel(settings) then
        SetControlHidden(ReticleVisual.debugPanel, true)
        return
    end

    local panel = EnsureDebugPanel()
    TrackGuideState(outerState)
    panel:SetHidden(false)

    SetDebugRow(1, SI_EZOCURSOR_DEBUG_OUTER_PREFIX, GetGuideStateText(outerState), true)
    SetDebugRow(2, SI_EZOCURSOR_DEBUG_CENTER_PREFIX, GetGuideStateText(targetState), true)
    SetDebugRow(3, SI_EZOCURSOR_DEBUG_ATTACKABLE_PREFIX, GetBooleanText(ReticleVisual.targetAttackable), ReticleVisual.targetAttackable)
    SetDebugRow(4, SI_EZOCURSOR_DEBUG_CAMERA_PREFERRED_PREFIX, GetBooleanText(ReticleVisual.preferredTargetValid), ReticleVisual.preferredTargetValid)
    SetDebugRow(5, SI_EZOCURSOR_DEBUG_COMBAT_PREFIX, GetBooleanText(ReticleVisual.inCombat), ReticleVisual.inCombat)
    SetDebugRow(6, SI_EZOCURSOR_DEBUG_RECENT_DAMAGE_PREFIX, GetBooleanText(IsCombatDamageActive()), IsCombatDamageActive())
    SetDebugRow(7, SI_EZOCURSOR_DEBUG_HUD_PREFIX, GetBooleanText(IsHudSceneActive()), IsHudSceneActive())
    SetDebugRow(8, SI_EZOCURSOR_DEBUG_BLOCKING_PREFIX, GetBooleanText(ReticleVisual.isBlocking), ReticleVisual.isBlocking)
    SetDebugRow(9, SI_EZOCURSOR_DEBUG_BLOCK_COST_PREFIX, tostring(ReticleVisual.blockCost or 0), false)
    SetDebugRow(10, SI_EZOCURSOR_DEBUG_STAMINA_PREFIX, tostring(ReticleVisual.currentStamina or 0), ReticleVisual.isBlockStaminaLow)
    SetDebugRow(11, SI_EZOCURSOR_DEBUG_PREVIOUS_PREFIX, ReticleVisual.stateHistory[2] and GetGuideStateText(ReticleVisual.stateHistory[2]) or "-", false)
end

local function RememberOriginalVisuals(reticleControl)
    if ReticleVisual.originalAlpha == nil then
        ReticleVisual.originalAlpha = reticleControl:GetAlpha()
    end

    if ReticleVisual.originalTexture == nil and reticleControl.GetTextureFileName then
        ReticleVisual.originalTexture = reticleControl:GetTextureFileName()
    end
end

local function ApplyColor(reticleControl, red, green, blue, alpha)
    reticleControl:SetColor(red, green, blue, alpha)

    if ZO_ReticleContainerStealthIconStealthEye then
        ZO_ReticleContainerStealthIconStealthEye:SetColor(red, green, blue, alpha)
    end
end

local function GetCurrentStamina()
    if type(GetUnitPower) ~= "function" or POWERTYPE_STAMINA == nil then
        return 0
    end

    return GetUnitPower("player", POWERTYPE_STAMINA) or 0
end

local function GetBlockCost()
    if type(GetAdvancedStatValue) ~= "function" or ADVANCED_STAT_DISPLAY_TYPE_BLOCK_COST == nil then
        return 0
    end

    local blockCost = select(2, GetAdvancedStatValue(ADVANCED_STAT_DISPLAY_TYPE_BLOCK_COST))
    if type(blockCost) ~= "number" or blockCost < 0 then
        return 0
    end
    return blockCost
end

local function IsBlockStateActive()
    if type(GetAllyUnitBlockState) == "function" and BLOCK_STATE_ACTIVE ~= nil then
        return GetAllyUnitBlockState("player") == BLOCK_STATE_ACTIVE
    end

    if type(IsBlockActive) ~= "function" then
        return false
    end

    return IsBlockActive() == true and GetCurrentStamina() > 0
end

local function RefreshBlockResourceState()
    ReticleVisual.currentStamina = GetCurrentStamina()
    ReticleVisual.blockCost = GetBlockCost()

    if ReticleVisual.blockCost <= 0 then
        ReticleVisual.isBlockStaminaLow = false
        return
    end

    ReticleVisual.isBlockStaminaLow = ReticleVisual.currentStamina < (ReticleVisual.blockCost * BLOCK_ALERT_COST_MULTIPLIER)
end

local function ApplyBlockOverlayState(blockOverlay)
    if not blockOverlay then
        return
    end

    if ReticleVisual.isBlockStaminaLow then
        blockOverlay:SetColor(unpack(BLOCK_LOW_STAMINA_COLOR))
    else
        blockOverlay:SetColor(unpack(BLOCK_NORMAL_COLOR))
    end
end

local function ApplyTargetIndicatorState(settings, targetState)
    if not ShouldShowTargetIndicator(settings) then
        HideTargetIndicator()
        return
    end

    if not ReticleVisual.horizontalTargetGuide or not ReticleVisual.verticalTargetGuide then
        return
    end

    local color = GetGuideColor(targetState)

    ReticleVisual.horizontalTargetGuide:SetColor(unpack(color))
    ReticleVisual.verticalTargetGuide:SetColor(unpack(color))
    ReticleVisual.horizontalTargetGuide:SetHidden(false)
    ReticleVisual.verticalTargetGuide:SetHidden(false)
end

local function GetTargetState()
    if ReticleVisual.preferredTargetValid then
        return "cameraPreferred"
    end

    if ReticleVisual.targetAttackable then
        return "attackable"
    end

    return "noAttackable"
end

local function GetOuterGuideState(targetState)
    if ReticleVisual.inCombat then
        return IsCombatDamageActive() and "combatDamage" or "combat"
    end

    return targetState
end

local function ResizeGuideSegments()
    if not ReticleVisual.outerGuides
        or not ReticleVisual.horizontalTargetGuide
        or not ReticleVisual.verticalTargetGuide then
        return
    end

    local screenWidth = GuiRoot:GetWidth()
    local screenHeight = GuiRoot:GetHeight()
    if type(screenWidth) ~= "number" or type(screenHeight) ~= "number" then
        return
    end

    local horizontalLength = math.max(0, (screenWidth - TARGET_INDICATOR_LENGTH) / 2)
    local verticalLength = math.max(0, (screenHeight - TARGET_INDICATOR_LENGTH) / 2)
    ReticleVisual.outerGuides.left:SetDimensions(horizontalLength, GUIDE_THICKNESS)
    ReticleVisual.outerGuides.right:SetDimensions(horizontalLength, GUIDE_THICKNESS)
    ReticleVisual.outerGuides.top:SetDimensions(GUIDE_THICKNESS, verticalLength)
    ReticleVisual.outerGuides.bottom:SetDimensions(GUIDE_THICKNESS, verticalLength)
    ReticleVisual.horizontalTargetGuide:SetDimensions(TARGET_INDICATOR_LENGTH, GUIDE_THICKNESS)
    ReticleVisual.verticalTargetGuide:SetDimensions(GUIDE_THICKNESS, TARGET_INDICATOR_LENGTH)
end

local function ApplyOuterGuideState(settings, outerState)
    if not ShouldShowOuterGuides(settings) then
        HideOuterGuides()
        return
    end

    local color = GetGuideColor(outerState)
    for _, control in pairs(ReticleVisual.outerGuides or {}) do
        control:SetColor(unpack(color))
        control:SetHidden(false)
    end
end

local function ApplyGuideState()
    local settings = GetReticleSettings()
    local targetState = GetTargetState()
    local outerState = GetOuterGuideState(targetState)
    ReticleVisual.currentGuideState = outerState
    ReticleVisual.currentTargetState = targetState
    UpdateDebugPanel(outerState, targetState)

    if not IsHudSceneActive() then
        HideAddonVisuals()
        return
    end

    if not ReticleVisual.guideOverlay or not ReticleVisual.outerGuides then
        return
    end

    ReticleVisual.guideOverlay:SetHidden(not ShouldShowTargetIndicator(settings))
    ApplyTargetIndicatorState(settings, targetState)
    ApplyOuterGuideState(settings, outerState)
    ResizeGuideSegments()
end

local function RefreshTargetState()
    local targetExists = type(DoesUnitExist) == "function" and DoesUnitExist("reticleover") == true
    if not targetExists then
        ReticleVisual.targetName = nil
        ReticleVisual.targetAttackable = false
        return
    end

    ReticleVisual.targetName = CleanUnitName(GetUnitName("reticleover"))

    if type(IsGameCameraUnitHighlightedAttackable) == "function" then
        ReticleVisual.targetAttackable = IsGameCameraUnitHighlightedAttackable() == true
    elseif type(IsUnitAttackable) == "function" then
        ReticleVisual.targetAttackable = IsUnitAttackable("reticleover") == true
    else
        ReticleVisual.targetAttackable = false
    end

end

local function RefreshPreferredTargetState()
    if type(IsGameCameraPreferredTargetValid) ~= "function" then
        ReticleVisual.preferredTargetValid = false
        return
    end

    ReticleVisual.preferredTargetValid = IsGameCameraPreferredTargetValid() == true
end

local function RefreshGuideState()
    local settings = GetReticleSettings()
    if not settings or (settings.debugEnabled ~= true and settings.guidesEnabled == false) then
        HideGuideAndDebug()
        HideTargetIndicator()
        return
    end

    if not IsHudSceneActive() then
        HideAddonVisuals()
        return
    end

    RefreshTargetState()

    local now = GetNowMs()
    if now - ReticleVisual.lastPreferredCheckMs >= PREFERRED_TARGET_UPDATE_MS then
        ReticleVisual.lastPreferredCheckMs = now
        RefreshPreferredTargetState()
    end

    ApplyGuideState()
end

local function OnCombatDamage(_eventCode, _result, isError, _abilityName, _abilityGraphic, _abilityActionSlotType, _sourceName, sourceType, targetName, targetType)
    if isError then
        return
    end

    local isPlayerSource = sourceType == COMBAT_UNIT_TYPE_PLAYER or sourceType == COMBAT_UNIT_TYPE_PLAYER_PET
    local isPlayerTarget = targetType == COMBAT_UNIT_TYPE_PLAYER
    if not isPlayerTarget and ReticleVisual.playerName then
        isPlayerTarget = CleanUnitName(targetName) == ReticleVisual.playerName
    end

    if not isPlayerSource and not isPlayerTarget then
        return
    end

    ReticleVisual.lastCombatDamageMs = GetNowMs()
    ApplyGuideState()
end

function ReticleVisual.ApplyCurrentState()
    local reticleControl = GetReticleControl()
    local settings = GetReticleSettings()
    if not reticleControl or not settings then
        return
    end

    if not IsHudSceneActive() then
        HideAddonVisuals()
        return
    end

    RememberOriginalVisuals(reticleControl)
    local blockOverlay = EnsureBlockOverlay(reticleControl)
    local guideOverlay = EnsureGuideOverlay(reticleControl)

    if not settings.enabled then
        reticleControl:SetTexture(ReticleVisual.originalTexture or DEFAULT_RETICLE_TEXTURE)
        reticleControl:SetAlpha(ReticleVisual.originalAlpha or 1)
        ApplyColor(reticleControl, 1, 1, 1, 1)
        blockOverlay:SetHidden(true)
        HideTargetIndicator()
        HideOuterGuides()
        guideOverlay:SetHidden(true)
        if settings.debugEnabled == true then
            ApplyGuideState()
        else
            SetControlHidden(ReticleVisual.debugPanel, true)
        end
        return
    end

    if settings.useCircularReticle then
        reticleControl:SetTexture(CIRCULAR_RETICLE_TEXTURE)
    else
        reticleControl:SetTexture(DEFAULT_RETICLE_TEXTURE)
    end

    reticleControl:SetAlpha(settings.idleAlpha or 0.85)
    ApplyColor(reticleControl, 0.9, 0.95, 1, 1)

    guideOverlay:SetHidden(not ShouldShowTargetIndicator(settings))
    ApplyGuideState()
    ApplyBlockOverlayState(blockOverlay)
    blockOverlay:SetHidden(not (settings.blockIndicatorEnabled and ReticleVisual.isBlocking))
end

function ReticleVisual.RefreshGuideLayout()
    local reticleControl = GetReticleControl()
    local settings = GetReticleSettings()
    if not reticleControl or not settings then
        HideAddonVisuals()
        return
    end

    if not IsHudSceneActive() then
        HideAddonVisuals()
        return
    end

    if not settings.enabled then
        HideGuides()
        if settings.debugEnabled == true then
            ApplyGuideState()
        else
            SetControlHidden(ReticleVisual.debugPanel, true)
        end
        return
    end

    local guideOverlay = EnsureGuideOverlay(reticleControl)
    guideOverlay:SetHidden(not ShouldShowTargetIndicator(settings))
    ResizeGuideSegments()
    ApplyGuideState()
end

function ReticleVisual.RefreshBlockingState()
    local settings = GetReticleSettings()
    if not IsHudSceneActive() then
        HideAddonVisuals()
        return
    end

    if not settings or not settings.enabled or not settings.blockIndicatorEnabled then
        if ReticleVisual.isBlocking then
            ReticleVisual.isBlocking = false
            ReticleVisual.ApplyCurrentState()
        end
        return
    end

    local wasLowStamina = ReticleVisual.isBlockStaminaLow
    RefreshBlockResourceState()
    local isBlocking = IsBlockStateActive()
    local wasBlocking = ReticleVisual.isBlocking
    ReticleVisual.isBlocking = isBlocking

    if isBlocking == wasBlocking and ReticleVisual.isBlockStaminaLow == wasLowStamina then
        return
    end

    ReticleVisual.ApplyCurrentState()
end

function ReticleVisual.RefreshSceneVisibility()
    if IsHudSceneActive() then
        ReticleVisual.ApplyCurrentState()
        ReticleVisual.RefreshGuideLayout()
    else
        HideAddonVisuals()
    end
end

function ReticleVisual.Start()
    local settings = GetReticleSettings()

    ReticleVisual.inCombat = type(IsUnitInCombat) == "function" and IsUnitInCombat("player") == true
    ReticleVisual.playerName = CleanUnitName(GetUnitName("player"))
    RefreshBlockResourceState()
    ReticleVisual.ApplyCurrentState()
    ReticleVisual.RefreshGuideLayout()
    EVENT_MANAGER:UnregisterForUpdate(BLOCK_UPDATE_NAME)
    EVENT_MANAGER:UnregisterForUpdate(GUIDE_STATE_UPDATE_NAME)

    if settings and settings.enabled and settings.blockIndicatorEnabled then
        EVENT_MANAGER:RegisterForUpdate(BLOCK_UPDATE_NAME, 100, ReticleVisual.RefreshBlockingState)
    end

    if settings and (settings.guidesEnabled ~= false or settings.debugEnabled == true) then
        EVENT_MANAGER:RegisterForUpdate(GUIDE_STATE_UPDATE_NAME, GUIDE_STATE_UPDATE_MS, RefreshGuideState)
    end
end

function ReticleVisual.Initialize()
    if not ReticleVisual.sceneCallbackRegistered and SCENE_MANAGER and type(SCENE_MANAGER.RegisterCallback) == "function" then
        SCENE_MANAGER:RegisterCallback(SCENE_STATE_CALLBACK_NAME, function()
            ReticleVisual.RefreshSceneVisibility()
        end)
        ReticleVisual.sceneCallbackRegistered = true
    end

    EVENT_MANAGER:UnregisterForEvent(PLAYER_ACTIVATED_EVENT, EVENT_PLAYER_ACTIVATED)
    EVENT_MANAGER:RegisterForEvent(PLAYER_ACTIVATED_EVENT, EVENT_PLAYER_ACTIVATED, function()
        ReticleVisual.Start()
    end)
    EVENT_MANAGER:UnregisterForEvent(SCREEN_RESIZED_EVENT, EVENT_SCREEN_RESIZED)
    EVENT_MANAGER:RegisterForEvent(SCREEN_RESIZED_EVENT, EVENT_SCREEN_RESIZED, function()
        ReticleVisual.RefreshGuideLayout()
    end)
    EVENT_MANAGER:UnregisterForEvent(COMBAT_STATE_EVENT, EVENT_PLAYER_COMBAT_STATE)
    EVENT_MANAGER:RegisterForEvent(COMBAT_STATE_EVENT, EVENT_PLAYER_COMBAT_STATE, function(_eventCode, inCombat)
        ReticleVisual.inCombat = inCombat == true
        if not ReticleVisual.inCombat then
            ReticleVisual.lastCombatDamageMs = 0
        end
        ReticleVisual.ApplyCurrentState()
        ReticleVisual.RefreshGuideLayout()
    end)
    EVENT_MANAGER:UnregisterForEvent(TARGET_CHANGED_EVENT, EVENT_RETICLE_TARGET_CHANGED)
    EVENT_MANAGER:RegisterForEvent(TARGET_CHANGED_EVENT, EVENT_RETICLE_TARGET_CHANGED, function()
        RefreshTargetState()
        RefreshPreferredTargetState()
        ApplyGuideState()
    end)

    for index, result in ipairs(DAMAGE_RESULTS) do
        local eventName = COMBAT_DAMAGE_EVENT_PREFIX .. tostring(index)
        EVENT_MANAGER:UnregisterForEvent(eventName, EVENT_COMBAT_EVENT)
        if result then
            EVENT_MANAGER:RegisterForEvent(eventName, EVENT_COMBAT_EVENT, OnCombatDamage)
            EVENT_MANAGER:AddFilterForEvent(eventName, EVENT_COMBAT_EVENT, REGISTER_FILTER_COMBAT_RESULT, result, REGISTER_FILTER_IS_ERROR, false)
        end
    end

    ReticleVisual.Start()

    if EZO_CURSOR.Print then
        EZO_CURSOR.Print(GetString(SI_EZOCURSOR_MSG_RETICLE_READY))
    end
end
