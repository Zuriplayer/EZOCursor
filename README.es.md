# EZOCursor

Addon beta para The Elder Scrolls Online que añade ayudas HUD centradas en el cursor dentro de la familia de addons EZO.

Prefer English? Read the [README in English](README.md).
Soporte, errores y sugerencias: https://discord.gg/ekw8zUAcRm

## Estado Beta

EZOCursor está en beta pública. El alcance actual es intencionadamente concreto: añade ayudas visuales para retículo, líneas guía, bloqueo y depuración. No automatiza juego, entrada, selección de objetivos, decisiones de combate ni gestión de addons.

## Requisitos

- Cliente de The Elder Scrolls Online para PC.
- LibAddonMenu-2.0.
- Opcional: LibChatMessage para una salida de chat más limpia cuando esté disponible.
- Una versión de API de ESO compatible con `EZOCursor.txt`.

Metadata actual del manifiesto:

- Versión del addon: `0.1.12`
- AddOnVersion: `10012`
- APIVersion: `101049 101050`

## Instalación

1. Descarga o clona este repositorio.
2. Copia la carpeta `EZOCursor` en tu directorio de AddOns de ESO:
   - Live: `Documents\Elder Scrolls Online\live\AddOns\EZOCursor`
   - PTS: `Documents\Elder Scrolls Online\pts\AddOns\EZOCursor`
3. Instala o activa `LibAddonMenu-2.0`.
4. Inicia ESO o ejecuta `/reloadui`.
5. Activa `EZOCursor` en el menú de complementos de ESO.

## Funciones Implementadas

- Sustitución opcional de la textura base del retículo de ESO por la textura circular de ESO.
- Líneas guía horizontal y vertical a pantalla completa que se cruzan en el punto del retículo.
- Colores dinámicos de líneas guía basados en el estado actual expuesto por la API de ESO:
  - sin objetivo atacable
  - objetivo atacable
  - objetivo preferente de cámara
  - en combate
  - daño de combate reciente que implica al jugador
- Integración con escenas HUD/HUD UI para los overlays visuales.
- Overlay de escudo de bloqueo mostrado sólo cuando se detecta bloqueo activo.
- Aviso de baja estamina al bloquear cuando la estamina actual está por debajo de cinco veces el `Block Cost` de Advanced Stats.
- Panel de depuración para validar estado de cursor, combate, bloqueo, estamina y escena HUD.
- Localización en inglés y español.
- Migración de SavedVariables para claves antiguas de colores de líneas guía.

## Panel de Configuración

EZOCursor usa LibAddonMenu-2.0 para sus opciones visibles.

Opciones visibles actuales:

- Activar o desactivar las líneas guía de pantalla.
- Elegir cuándo se muestran las líneas guía:
  - siempre
  - sólo en combate
- Activar o desactivar el panel debug de estado del cursor.
- Configurar colores de líneas guía para:
  - sin objetivo atacable
  - sin combate: objetivo atacable
  - objetivo preferente de cámara
  - en combate
  - daño de combate reciente

Existen algunos ajustes internos o por defecto en SavedVariables, como `enabled`, `blockIndicatorEnabled`, `useCircularReticle` e `idleAlpha`, pero en la beta actual no están expuestos como controles de LibAddonMenu.

## Estados y Límites de Seguridad

- `objetivo preferente de cámara` usa la señal `IsGameCameraPreferredTargetValid()` de ESO. No garantiza identidad exacta del objetivo ni rango cuerpo a cuerpo.
- El estado de objetivo atacable usa señales de atacabilidad de ESO para `reticleover`; no es una comprobación de rango.
- El daño de combate reciente sigue eventos reales de combate que implican al jugador.
- El aviso de bloqueo usa la estamina actual y el `Block Cost` de Advanced Stats; es un umbral de alerta, no una predicción de cada golpe entrante.
- Los controles visuales deben aparecer sólo en escenas normales de HUD y HUD UI.
- EZOCursor no automatiza combate, movimiento, selección de objetivos, entrada, keybinds, bloqueo, ataques, navegación de menús ni acciones de la UI base.
- EZOCursor no publica en Discord, no llama webhooks, no ejecuta workflows externos y no envía telemetría.

## Pruebas Recomendadas

Durante la beta, prueba estos escenarios:

- Entrar al juego y ejecutar `/reloadui` sin errores Lua.
- Abrir el panel de configuración de EZOCursor en LibAddonMenu.
- Activar y desactivar las líneas guía de pantalla.
- Cambiar el modo de líneas guía entre `Siempre` y `En combate`.
- Cambiar cada color de línea guía y confirmar que el estado visual se actualiza.
- Apuntar a ningún objetivo, objetivos no atacables y objetivos atacables.
- Entrar y salir de combate.
- Hacer o recibir daño y confirmar el comportamiento del color de daño reciente.
- Confirmar que los overlays se ocultan en inventario, mapa, Champion Points, crafting, Tales of Tribute, configuración de addons y otras escenas que no sean HUD.
- Confirmar que el escudo de bloqueo aparece sólo mientras el personaje está bloqueando activamente.
- Confirmar que el escudo de bloqueo cambia al color de alerta cuando la estamina está por debajo de `Block Cost * 5`.
- Activar el panel debug y confirmar que sus valores coinciden con el comportamiento visible.
- Confirmar que los textos en inglés y español cargan correctamente.

## Comprobaciones de Desarrollo

Antes de publicar o hacer commit:

```powershell
.\tools\bump-version.ps1 -Check -ApiVersion "101049 101050"
git diff --check
```

Actualiza `## APIVersion` sólo después de verificar la versión actual de la API de ESO.

## Licencia

EZOCursor se publica bajo la licencia MIT. Consulta [LICENSE](LICENSE).
