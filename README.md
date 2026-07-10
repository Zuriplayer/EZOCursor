# EZOCursor

EZOCursor is a beta addon for The Elder Scrolls Online in the EZO addon family.

The addon is currently intended for public beta testing. Expect focused cursor and HUD utilities, conservative feature scope, and possible behavior changes before a stable release.

## Requirements

- The Elder Scrolls Online.
- LibAddonMenu-2.0.
- An ESO API version supported by the manifest in `EZOCursor.txt`.

## Installation

1. Download or clone this repository.
2. Copy the `EZOCursor` folder into your ESO AddOns directory:
   - Windows live: `Documents\Elder Scrolls Online\live\AddOns\EZOCursor`
   - Windows PTS: `Documents\Elder Scrolls Online\pts\AddOns\EZOCursor`
3. Install or enable `LibAddonMenu-2.0`.
4. Start ESO or run `/reloadui`.
5. Enable `EZOCursor` from the Add-Ons menu.

## Main Features

- Optional circular ESO reticle texture.
- Full-screen horizontal and vertical guide lines crossing at the reticle point.
- Dynamic guide-line colors based on real game state:
  - no attackable target
  - attackable target
  - camera preferred target
  - in combat
  - recent combat damage involving the player
- Block indicator overlay shown only when the player is actively blocking.
- Low-stamina block warning when current stamina is below five times the Advanced Stats `Block Cost`.
- Optional debug panel for validating detected cursor, combat, block, stamina, and HUD state.
- HUD/HUD UI scene integration so addon visuals are hidden outside normal gameplay HUD scenes.

## Safety and Limitations

- EZOCursor does not automate combat, movement, targeting, input, keybinds, or vanilla UI navigation.
- The guide-line states are based on ESO API signals; `camera preferred target` does not guarantee exact target identity or melee range.
- Block warning uses the current Advanced Stats `Block Cost` and current stamina. It is an alert threshold, not a prediction of every incoming hit.
- Visual controls are intended to appear only in HUD and HUD UI scenes.

## Testing Notes

For beta testing, verify these scenarios in game:

- Addon loads without UI errors after `/reloadui`.
- Guide lines hide in inventory, map, Champion Points, crafting, Tales of Tribute, addon settings, and other non-HUD scenes.
- Guide-line colors change when moving over attackable targets, entering combat, and dealing or receiving damage.
- Block icon appears only while the character is actually blocking.
- Block icon changes to warning color when stamina is below `Block Cost * 5`.
- Debug panel values match the visible behavior when enabled.

## Development Checks

Before release or commit:

```powershell
.\tools\bump-version.ps1 -Check -ApiVersion "101049 101050"
git diff --check
```

Only update `## APIVersion` after verifying the current ESO API version.
