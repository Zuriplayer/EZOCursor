-- Módulo principal de arranque de EZOCursor.
-- Aquí sólo resolvemos el ciclo de carga del addon y delegamos la inicialización
-- a módulos pequeños para mantener el proyecto fácil de revisar.
EZOCursor = EZOCursor or {}
local EZO_CURSOR = EZOCursor

local function OnAddonLoaded(eventCode, addonName)
    if addonName ~= EZO_CURSOR.ADDON_NAME then
        return
    end

    EVENT_MANAGER:UnregisterForEvent(EZO_CURSOR.EVENT_NAMESPACE, EVENT_ADD_ON_LOADED)

    if EZO_CURSOR.Initialize == nil then
        return
    end

    EZO_CURSOR:Initialize()
end

EVENT_MANAGER:RegisterForEvent(EZOCursor.EVENT_NAMESPACE or "EZOCursor_Core", EVENT_ADD_ON_LOADED, OnAddonLoaded)
