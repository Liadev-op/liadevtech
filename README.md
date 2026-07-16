# Liadev Tech - Windows Toolbox

Utilidad todo-en-uno para Windows: instalación de aplicaciones seleccionadas, tweaks del sistema, reparaciones y gestión de actualizaciones, con interfaz gráfica en azul y blanco.

Basado en [WinUtil de Chris Titus Tech](https://github.com/ChrisTitusTech/winutil), publicado bajo licencia MIT.

## Requisitos

- Windows 10 / 11
- PowerShell (se recomienda Windows Terminal)
- Permisos de **Administrador** (la herramienta se auto-eleva si hace falta)

## Compilar y ejecutar

Desde la raíz del proyecto, en PowerShell:

```powershell
# Compilar (genera liadevtech.ps1)
.\Compile.ps1

# Compilar y ejecutar
.\Compile.ps1 -Run
```

También se puede ejecutar el script ya compilado directamente:

```powershell
.\liadevtech.ps1
```

## Estructura

- `Compile.ps1` — une funciones, configuración JSON y XAML en un único `liadevtech.ps1`.
- `config/` — todo lo declarativo: `applications.json` (apps instalables), `tweaks.json`, `feature.json`, `preset.json`, `dns.json`, `themes.json` (colores).
- `functions/` — funciones PowerShell (privadas y públicas de la UI).
- `xaml/inputXML.xaml` — interfaz WPF.
- `pester/` — tests.

Para agregar o quitar aplicaciones, editar `config/applications.json` y recompilar.

## Licencia

MIT. Ver [LICENSE](LICENSE). Incluye código de WinUtil, Copyright (c) 2022 CT Tech Group LLC.
