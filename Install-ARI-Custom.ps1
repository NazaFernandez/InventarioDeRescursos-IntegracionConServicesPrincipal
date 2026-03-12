<#
.SYNOPSIS
    Script de instalación para el módulo personalizado Azure Resource Inventory (ARI).

.DESCRIPTION
    Este script automatiza la instalación de la versión modificada del módulo ARI
    (que incluye soporte interactivo para Service Principal) en la máquina de cualquier usuario.
    
    Lógica de funcionamiento:
    1. Define la ruta destino oficial de PowerShell para el usuario actual:
       C:\Users\<Usuario>\Documents\PowerShell\Modules\AzureResourceInventory
    2. Comprueba si ya existe una versión anterior en esa ruta y la elimina.
    3. Copia todos los archivos del módulo desde la carpeta actual (donde se ejecuta el script)
       hacia la ruta destino oficial de PowerShell.
    4. Verifica que la copia fue exitosa y lista el módulo instalado.

.NOTES
    Instrucciones de uso:
    1. Coloca este script (Install-ARI-Custom.ps1) justo al lado de la carpeta '3.6.11' del módulo.
    2. Haz clic derecho en el script y selecciona "Run with PowerShell" (Ejecutar con PowerShell).
#>

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host " Instalador: Azure Resource Inventory Custom (Service Principal)" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Definir la ruta donde PowerShell guarda los módulos del usuario actual
# Usamos el primer path disponible en el sistema (el del usuario) para compatibilidad con OneDrive y PS7
$UserModulePath = ($env:PSModulePath -split ';')[0]
$DestinoPath = Join-Path -Path $UserModulePath -ChildPath "AzureResourceInventory"

# La carpeta fuente es donde se encuentra este script
$OrigenPath = $PSScriptRoot

# Nombre de la versión (la carpeta que contiene los archivos del módulo)
$VersionFolder = "3.6.11"
$OrigenVersionPath = Join-Path -Path $OrigenPath -ChildPath $VersionFolder
$DestinoVersionPath = Join-Path -Path $DestinoPath -ChildPath $VersionFolder

# Verificar si la carpeta versión existe junto al script
if (-not (Test-Path -Path $OrigenVersionPath)) {
    Write-Host "[ERROR] No se encontró la carpeta del módulo '$VersionFolder' junto a este script." -ForegroundColor Red
    Write-Host "Por favor, asegúrate de extraer todo el contenido del .zip en una misma carpeta." -ForegroundColor Yellow
    Write-Host ""
    Pause
    Exit
}

Write-Host "[INFO] Preparando la instalación en: $DestinoPath"

# 2. Si ya existe una versión previa en el destino, la borramos para evitar conflictos
if (Test-Path -Path $DestinoPath) {
    Write-Host "[INFO] Se encontró una versión anterior. Eliminando..." -ForegroundColor Yellow
    Remove-Item -Path $DestinoPath -Recurse -Force -ErrorAction SilentlyContinue
}

# 3. Crear la estructura de carpetas destino y copiar los archivos
try {
    Write-Host "[INFO] Copiando archivos del módulo..."
    New-Item -ItemType Directory -Force -Path $DestinoVersionPath | Out-Null
    Copy-Item -Path "$OrigenVersionPath\*" -Destination $DestinoVersionPath -Recurse -Force
    
    # IMPORTANTE: Desbloquear los archivos descargados para evitar el error de "not digitally signed" (Mark of the Web)
    Get-ChildItem -Path $DestinoVersionPath -Recurse | Unblock-File
    
    Write-Host "[EXITO] Módulo copiado correctamente." -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Ocurrió un error al copiar los archivos: $_" -ForegroundColor Red
    Write-Host ""
    Pause
    Exit
}

# 4. Validar que PowerShell ahora reconoce el módulo
Write-Host "[INFO] Validando instalación en PowerShell..."
$ModuleLoaded = Get-Module -ListAvailable -Name AzureResourceInventory -Refresh
$ImportSuccess = $false

if ($ModuleLoaded) {
    try {
        Import-Module -Name AzureResourceInventory -Force -ErrorAction Stop
        $ImportSuccess = $true
    }
    catch {
        Write-Host "[WARNING] El módulo existe pero no se pudo importar automáticamente: $_" -ForegroundColor Yellow
    }
}

if ($ModuleLoaded -and $ImportSuccess) {
    Write-Host "=======================================================" -ForegroundColor Cyan
    Write-Host "  ¡Instalación Completada con Éxito!" -ForegroundColor Green
    Write-Host "  Ya puedes abrir una nueva consola y usar Invoke-ARI" -ForegroundColor Cyan
    Write-Host "=======================================================" -ForegroundColor Cyan
}
else {
    Write-Host "[ERROR] Los archivos se copiaron, pero PowerShell no parece reconocer el módulo." -ForegroundColor Red
    Write-Host "Verifica si la ruta de módulos de tu usuario ($DestinoPath) es correcta." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Presiona cualquier tecla para salir..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
