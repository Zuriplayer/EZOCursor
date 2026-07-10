# Tools

## bump-version.ps1

Wrapper local para la herramienta compartida `..\..\EZOFamilyTools\bump-version.ps1`.

Uso habitual:

```powershell
.\tools\bump-version.ps1 -Patch -ApiVersion "101049 101050"
```

Comprobación:

```powershell
.\tools\bump-version.ps1 -Check -ApiVersion "101049 101050"
```

`## APIVersion` controla si ESO marca el addon como desactualizado en la pantalla de complementos/addons. No usar más de dos valores.
