-- Gestión visual mínima del retículo.
-- Esta primera versión sólo recolorea y cambia la textura base del retículo
-- de ESO para dar una señal pasiva, y añade un estado visual de bloqueo.
EZOCursor = EZOCursor or {}
EZOCursor.ReticleVisual = EZOCursor.ReticleVisual or {}

local EZO_CURSOR = EZOCursor
local ReticleVisual = EZO_CURSOR.ReticleVisual

local BLOCK_UPDATE_NAME = "EZOCursor_BlockState"
local PLAYER_ACTIVATED_EVENT = "EZOCursor_PlayerActivated"
local DEFAULT_RETICLE_TEXTURE = "EsoUI/Art/Reticle/reticleAnim.dds"
local CIRCULAR_RETICLE_TEXTURE = "EsoUI/Art/Reticle/reticleAnim-circle.dds"
local BLOCK_SHIELD_TEXTURE = "/EZOCursor/media/reticle/block_shield.dds"

ReticleVisual.isBlocking = false
ReticleVisual.originalAlpha = nil
ReticleVisual.originalTexture = nil
ReticleVisual.blockOverlay = nil

local function GetReticleControl()
    return ZO_ReticleContainerReticle
end

local function GetReticleSettings()
    return EZO_CURSOR.sv and EZO_CURSOR.sv.reticle or nil
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
    overlay:SetAlpha(0.96)
    overlay:SetMouseEnabled(false)
    overlay:SetHidden(true)

    ReticleVisual.blockOverlay = overlay
    return overlay
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

function ReticleVisual.ApplyCurrentState()
    local reticleControl = GetReticleControl()
    local settings = GetReticleSettings()
    if not reticleControl or not settings then
        return
    end

    RememberOriginalVisuals(reticleControl)
    local blockOverlay = EnsureBlockOverlay(reticleControl)

    if not settings.enabled then
        reticleControl:SetTexture(ReticleVisual.originalTexture or DEFAULT_RETICLE_TEXTURE)
        reticleControl:SetAlpha(ReticleVisual.originalAlpha or 1)
        ApplyColor(reticleControl, 1, 1, 1, 1)
        blockOverlay:SetHidden(true)
        return
    end

    if settings.useCircularReticle then
        reticleControl:SetTexture(CIRCULAR_RETICLE_TEXTURE)
    else
        reticleControl:SetTexture(DEFAULT_RETICLE_TEXTURE)
    end

    reticleControl:SetAlpha(settings.idleAlpha or 0.85)
    ApplyColor(reticleControl, 0.9, 0.95, 1, 1)

    blockOverlay:SetHidden(not (settings.blockIndicatorEnabled and ReticleVisual.isBlocking))
end

function ReticleVisual.RefreshBlockingState()
    local settings = GetReticleSettings()
    if not settings or not settings.enabled or not settings.blockIndicatorEnabled then
        if ReticleVisual.isBlocking then
            ReticleVisual.isBlocking = false
            ReticleVisual.ApplyCurrentState()
        end
        return
    end

    local isBlocking = type(IsBlockActive) == "function" and IsBlockActive() or false
    if isBlocking == ReticleVisual.isBlocking then
        return
    end

    ReticleVisual.isBlocking = isBlocking
    ReticleVisual.ApplyCurrentState()
end

function ReticleVisual.Start()
    local settings = GetReticleSettings()

    ReticleVisual.ApplyCurrentState()
    EVENT_MANAGER:UnregisterForUpdate(BLOCK_UPDATE_NAME)

    if settings and settings.enabled and settings.blockIndicatorEnabled then
        EVENT_MANAGER:RegisterForUpdate(BLOCK_UPDATE_NAME, 100, ReticleVisual.RefreshBlockingState)
    end
end

function ReticleVisual.Initialize()
    EVENT_MANAGER:UnregisterForEvent(PLAYER_ACTIVATED_EVENT, EVENT_PLAYER_ACTIVATED)
    EVENT_MANAGER:RegisterForEvent(PLAYER_ACTIVATED_EVENT, EVENT_PLAYER_ACTIVATED, function()
        ReticleVisual.Start()
    end)

    ReticleVisual.Start()

    if EZO_CURSOR.Print then
        EZO_CURSOR.Print(GetString(SI_EZOCURSOR_MSG_RETICLE_READY))
    end
end
