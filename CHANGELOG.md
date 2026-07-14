# Changelog

## 0.1.14

- Integrated the existing settings panel into `Settings > EZO` when EZOCore is available.
- Preserved the standalone LibAddonMenu panel as a compatibility fallback.
- Declared the runtime lifecycle stage as beta and added the permanent Discord feedback link to the panel header.
- Resynchronized `ezo-addon.json` and its package filename with the visible addon version.

## 0.1.13

- Updated the LibAddonMenu settings panel to use EZO-family informational section headers with purple help icons.
- Moved section-wide help into header tooltips while preserving field-specific tooltips.
- Updated English and Spanish public documentation for the settings help pattern.

## 0.1.12 - Public Beta

- Added LibAddonMenu-based settings for guide-line visibility, debug display, and guide-line state colors.
- Added full-screen guide-line overlay with state-driven colors.
- Added HUD/HUD UI scene integration for visual overlays.
- Added block indicator overlay.
- Added low-stamina block warning based on Advanced Stats `Block Cost`.
- Added debug panel for cursor, combat, block, stamina, and HUD-state validation.
- Added guide-line media assets and refreshed block shield media.
- Removed optional EZOBindings registration from addon startup.
- Updated version tooling wrapper for the shared EZO family version script.

## 0.1.0

- Initial addon structure.
- Basic reticle visual module.
- SavedVariables and localization scaffolding.
