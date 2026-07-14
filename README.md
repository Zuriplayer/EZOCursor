# EZOCursor

Beta addon for The Elder Scrolls Online that adds cursor-centered HUD aids from the EZO addon family.

¿Prefieres español? Lee el [README en español](README.es.md).
Support, bug reports, and suggestions: https://discord.gg/ekw8zUAcRm

## Beta Status

EZOCursor is in public beta. The current scope is intentionally focused: it adds visual reticle, guide-line, block, and debug aids. It does not automate gameplay, input, targeting, combat decisions, or addon management.

## Requirements

- The Elder Scrolls Online PC client.
- LibAddonMenu-2.0.
- Optional: LibChatMessage for cleaner addon chat output when available.
- An ESO API version supported by `EZOCursor.txt`.

Current manifest metadata:

- Addon version: `0.1.13`
- AddOnVersion: `10013`
- APIVersion: `101049 101050`

## Installation

1. Download or clone this repository.
2. Copy the `EZOCursor` folder into your ESO AddOns directory:
   - Live: `Documents\Elder Scrolls Online\live\AddOns\EZOCursor`
   - PTS: `Documents\Elder Scrolls Online\pts\AddOns\EZOCursor`
3. Install or enable `LibAddonMenu-2.0`.
4. Start ESO or run `/reloadui`.
5. Enable `EZOCursor` in the ESO Add-Ons menu.

## Implemented Features

- Optional replacement of the base ESO reticle texture with ESO's circular reticle texture.
- Full-screen horizontal and vertical guide lines crossing at the reticle point.
- Dynamic guide-line colors based on current ESO API state:
  - no attackable target
  - attackable target
  - camera preferred target
  - in combat
  - recent combat damage involving the player
- HUD/HUD UI scene integration for visual overlays.
- Block shield overlay shown only when active blocking is detected.
- Low-stamina block warning when current stamina is below five times the Advanced Stats `Block Cost`.
- Debug panel for validating cursor, combat, block, stamina, and HUD scene state.
- English and Spanish localization.
- SavedVariables migration for older guide-color keys.

## Settings Panel

EZOCursor uses LibAddonMenu-2.0 for its visible settings.

Current visible options:

- Purple informational section headers with a 26 px info icon.
- General section help is attached to each section header tooltip.
- Field-specific help is attached to the tooltip of each control.
- Enable or disable screen guide lines.
- Choose when guide lines are shown:
  - always
  - only in combat
- Enable or disable the cursor state debug panel.
- Configure guide-line colors for:
  - no attackable target
  - out of combat: attackable target
  - camera preferred target
  - in combat
  - recent combat damage

Some internal/default reticle settings exist in SavedVariables, such as `enabled`, `blockIndicatorEnabled`, `useCircularReticle`, and `idleAlpha`, but they are not exposed as LibAddonMenu controls in the current beta.

## State and Safety Limits

- `camera preferred target` uses ESO's `IsGameCameraPreferredTargetValid()` signal. It does not guarantee exact target identity or melee range.
- Attackable target state uses ESO attackability signals for `reticleover`; it is not a range check.
- Recent combat damage follows real combat events involving the player.
- The block warning uses current stamina and Advanced Stats `Block Cost`; it is an alert threshold, not a prediction of every incoming hit.
- Visual controls are intended to appear only in normal HUD and HUD UI scenes.
- EZOCursor does not automate combat, movement, targeting, input, keybinds, blocking, attacks, menu navigation, or vanilla UI actions.
- EZOCursor does not publish to Discord, call webhooks, run external workflows, or send telemetry.

## Recommended Testing

Please test these scenarios during beta:

- Login and `/reloadui` without Lua errors.
- Open the LibAddonMenu settings panel for EZOCursor.
- Enable and disable screen guide lines.
- Switch guide-line mode between `Always` and `In combat`.
- Change each guide-line color and confirm the visual state updates.
- Confirm each settings section shows the purple info icon and opens its general tooltip on hover.
- Confirm field-specific tooltips open from their controls.
- Aim at no target, non-attackable targets, and attackable targets.
- Enter and leave combat.
- Deal or receive damage and confirm recent-combat color behavior.
- Confirm overlays hide in inventory, map, Champion Points, crafting, Tales of Tribute, addon settings, and other non-HUD scenes.
- Confirm the block shield appears only while the character is actively blocking.
- Confirm the block shield changes to warning color when stamina is below `Block Cost * 5`.
- Enable the debug panel and confirm its values match visible behavior.
- Confirm English and Spanish strings load correctly.

## Development Checks

Before release or commit:

```powershell
.\tools\bump-version.ps1 -Check -ApiVersion "101049 101050"
git diff --check
```

Only update `## APIVersion` after verifying the current ESO API version.

## License

EZOCursor is released under the MIT License. See [LICENSE](LICENSE).
