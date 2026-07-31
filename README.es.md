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
- Opcional: EZOCore para el panel central `Settings > EZO` y el modo de idioma compartido.
- Una versión de API de ESO compatible con `EZOCursor.txt`.

Metadata actual del manifiesto:

- Versión del addon: `0.1.25`
- AddOnVersion: `10025`
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
- Un indicador central de objetivo y líneas guía exteriores horizontal y vertical a pantalla completa.
- La información de objetivo y de combate usa zonas visuales separadas sin píxeles solapados:
  - la cruz central de 64 px muestra el color de objetivo configurado: sin objetivo atacable, objetivo atacable u objetivo preferente de cámara
  - el objetivo preferente de cámara tiene prioridad en el centro cuando ESO informa `IsGameCameraPreferredTargetValid()`
  - fuera de combate, las líneas exteriores visibles usan el mismo color de objetivo que el centro
  - en combate, las líneas exteriores usan el color de combate configurado mientras el centro sigue mostrando el estado de objetivo
  - el daño de combate aplica brevemente a las líneas exteriores el color configurado de daño reciente durante 600 ms
  - todos los tramos usan una textura base blanca neutra para que el tinte visible coincida con el color seleccionado en LibAddonMenu
- Integración con escenas HUD/HUD UI para los overlays visuales.
- Overlay de escudo de bloqueo mostrado sólo cuando se detecta bloqueo activo.
- Aviso de baja estamina al bloquear cuando la estamina actual está por debajo de cinco veces el `Block Cost` de Advanced Stats.
- Panel de depuración para validar estado de cursor, combate, bloqueo, estamina y escena HUD.
- Localización en inglés y español.
- Migración de SavedVariables para claves antiguas de colores de líneas guía.

## Panel de Configuración

EZOCursor registra su panel completo de ajustes en `Settings > EZO` cuando
EZOCore está disponible. Sin EZOCore, los mismos controles siguen disponibles
mediante la lista estándar de ajustes de addons de LibAddonMenu.

Opciones visibles actuales:

- Cabeceras informativas moradas con un icono de información de 26 px.
- La ayuda general de cada sección está en el tooltip de su cabecera.
- La ayuda específica de cada campo está en el tooltip del propio control.
- Activar o desactivar juntos el indicador central y las guías exteriores de pantalla.
- Elegir cuándo se muestran las líneas guía exteriores; el indicador central permanece visible mientras las guías del cursor están activadas:
  - siempre
  - sólo en combate
- Activar o desactivar el panel debug de estado del cursor.
- El panel debug sigue su propio ajuste visible y sigue disponible aunque un indicador maestro interno del retículo esté desactivado.
- Configurar los colores de objetivo usados por el indicador central y, fuera de combate, por las líneas exteriores visibles:
  - sin objetivo atacable
  - objetivo atacable
  - objetivo preferente de cámara
- Configurar los colores de combate usados por las líneas exteriores:
  - en combate
  - destello breve de daño de combate reciente

Existen algunos ajustes internos o por defecto en SavedVariables, como `enabled`, `blockIndicatorEnabled`, `useCircularReticle` e `idleAlpha`, pero en la beta actual no están expuestos como controles de LibAddonMenu.

## Estados y Límites de Seguridad

- `objetivo preferente de cámara` usa la señal `IsGameCameraPreferredTargetValid()` de ESO. Tiene prioridad visual en el centro, pero no garantiza identidad exacta del objetivo ni rango cuerpo a cuerpo.
- El estado de objetivo atacable usa señales de atacabilidad de ESO para `reticleover`; no es una comprobación de rango. El indicador central expone el estado de objetivo de forma independiente a los colores exteriores de combate.
- El daño de combate reciente sigue eventos reales de combate que implican al jugador. Cada evento aceptado reinicia el destello de 600 ms de las líneas exteriores.
- El aviso de bloqueo usa la estamina actual y el `Block Cost` de Advanced Stats; es un umbral de alerta, no una predicción de cada golpe entrante.
- Los controles visuales deben aparecer sólo en escenas normales de HUD y HUD UI.
- EZOCursor no automatiza combate, movimiento, selección de objetivos, entrada, keybinds, bloqueo, ataques, navegación de menús ni acciones de la UI base.
- EZOCursor no publica en Discord, no llama webhooks, no ejecuta workflows externos y no envía telemetría.

## Pruebas Recomendadas

Durante la beta, prueba estos escenarios:

- Entrar al juego y ejecutar `/reloadui` sin errores Lua.
- Abrir EZOCursor desde `Settings > EZO`, o desde el fallback de LibAddonMenu
  cuando EZOCore esté desactivado.
- Activar y desactivar juntos el indicador central y las líneas guía exteriores.
- Cambiar el modo de las guías exteriores entre `Siempre` y `En combate`; confirmar que el indicador central permanece visible en ambos modos.
- Cambiar cada color de objetivo y combate y confirmar que se actualiza la zona visual correspondiente.
- Confirmar que cada sección de ajustes muestra el icono informativo morado y abre su tooltip general al pasar el cursor.
- Confirmar que los tooltips específicos de cada campo se abren desde sus controles.
- Fuera de combate, apuntar a ningún objetivo, objetivos atacables y objetivos preferentes de cámara; confirmar que el centro y las líneas exteriores visibles usan gris, verde y azul por defecto.
- Entrar en combate y confirmar que las líneas exteriores se vuelven rojas mientras el centro sigue mostrando en gris, verde o azul el estado de objetivo sin mezcla de colores.
- Hacer o recibir daño y confirmar que las líneas exteriores destellan brevemente en naranja antes de volver al rojo.
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
