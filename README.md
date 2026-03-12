# InventarioDeRescursos-IntegracionConServicesPrincipal
Módulo Azure Resource Inventory modificado para aceptar autenticación por Service Principal interactivamente.
graph TD
    %% Estilos de los nodos
    classDef startEnd fill:#f9f,stroke:#333,stroke-width:2px;
    classDef process fill:#bbf,stroke:#333,stroke-width:2px;
    classDef decision fill:#ff9,stroke:#333,stroke-width:2px;
    classDef error fill:#f99,stroke:#333,stroke-width:2px;
    classDef success fill:#9f9,stroke:#333,stroke-width:2px;
    classDef userAction fill:#fdb,stroke:#333,stroke-width:2px;

    %% FASE 1: INSTALACIÓN
    subgraph Fase 1: Instalación (Install-ARI-Custom.ps1)
        A1("Inicio: Ejecutar Install-ARI-Custom.ps1"):::startEnd --> A2["Detectar versión de PowerShell y obtener ruta $env:PSModulePath"]:::process
        A2 --> A3{"¿Existe una versión\nprevia en la ruta?"}:::decision
        A3 -- Sí --> A4["Eliminar versión anterior"]:::process
        A3 -- No --> A5
        A4 --> A5["Copiar carpeta '3.6.11' a la ruta de Módulos"]:::process
        A5 --> A6["Aplicar Unblock-File a la carpeta (Quitar Mark of the Web)"]:::process
        A6 --> A7["Recargar caché de módulos (Get-Module -Refresh)"]:::process
        A7 --> A8{"¿Módulo Cargado y\nReconocido?"}:::decision
        A8 -- No --> A9("Error: Mostrar mensaje rojo y Ruta Inválida"):::error
        A8 -- Sí --> A10("Éxito: Módulo listo para usarse"):::success
    end

    %% FASE 2: EJECUCIÓN DEL INVENTARIO
    subgraph Fase 2: Ejecución de Inventario (Invoke-ARI)
        B1("El usuario abre PowerShell y escribe 'Invoke-ARI'"):::userAction --> B2{"¿Se pasaron parámetros\nde autenticación\n(ej. -TenantID)?"}:::decision
        
        %% Flujo Original
        B2 -- Sí --> B3["Ejecutar flujo original de Azure Resource Inventory\n(Requiere login interactivo en navegador)"]:::process
        
        %% Nuevo Flujo Modificado
        B2 -- No --> B4["Desplegar Prompt Personalizado\n(Modificación en Connect-ARILoginSession.ps1)"]:::process
        B4 --> B5("El usuario ingresa:\n- App ID\n- Secret Value (Oculto)\n- Tenant ID\n- Subscription ID (Opcional)"):::userAction
        B5 --> B6["Ejecutar: Connect-AzAccount -ServicePrincipal"]:::process
        B6 --> B7{"¿Autenticación\nExitosa?"}:::decision
        B7 -- No --> B8("Error: Credenciales de Service Principal Inválidas"):::error
        B7 -- Sí --> B9{"¿El App Registration tiene\npermisos de lectura (Reader)\nen la Suscripción/Tenant?"}:::decision
        
        B9 -- No --> B10("Error: ARI falla al extraer recursos\n(Falta de permisos RBAC)"):::error
        B9 -- Sí --> B11["Continuar con la orquestación normal de ARI\n(Extracción de recursos por API)"]:::process
        
        B3 --> B11
        B11 --> B12("Generar Tablero Excel (.xlsx) con el Inventario Físico"):::success
    end

    %% Conexión entre fases
    A10 -. "Habilita el comando" .-> B1
