[CmdletBinding()]
param(
    [string]$GenieAcsNbiUrl = "http://localhost:7558",
    [string]$DeviceId,
    [string]$OutDir,
    [switch]$Refresh,
    [int]$RefreshTimeoutMs = 15000
)

$ErrorActionPreference = "Stop"

if (-not $OutDir) {
    $OutDir = Join-Path $PSScriptRoot "..\tfg-resultados\hx141-real\tr181"
}

function Get-GenieAcsDevices {
    $uri = "$($GenieAcsNbiUrl.TrimEnd('/'))/devices/"
    return @(Invoke-RestMethod -Method Get -Uri $uri)
}

function Get-LeafRows {
    param(
        [Parameter(Mandatory)]$Node,
        [string]$Path = ""
    )

    $rows = [System.Collections.Generic.List[object]]::new()

    if ($null -eq $Node -or $Node -isnot [psobject]) {
        return $rows
    }

    $properties = @($Node.PSObject.Properties)
    $valueProperty = $properties | Where-Object Name -eq "_value" | Select-Object -First 1

    if ($null -ne $valueProperty -and $Path) {
        $typeProperty = $properties | Where-Object Name -eq "_type" | Select-Object -First 1
        $timestampProperty = $properties | Where-Object Name -eq "_timestamp" | Select-Object -First 1
        $writableProperty = $properties | Where-Object Name -eq "_writable" | Select-Object -First 1

        $rows.Add([pscustomobject]@{
            Parameter = $Path
            Value = $valueProperty.Value
            Type = if ($typeProperty) { $typeProperty.Value } else { $null }
            Writable = if ($writableProperty) { $writableProperty.Value } else { $null }
            Timestamp = if ($timestampProperty) { $timestampProperty.Value } else { $null }
        })
    }

    foreach ($property in $properties) {
        if ($property.Name.StartsWith("_")) {
            continue
        }

        $childPath = if ($Path) { "$Path.$($property.Name)" } else { $property.Name }
        foreach ($row in (Get-LeafRows -Node $property.Value -Path $childPath)) {
            $rows.Add($row)
        }
    }

    return $rows
}

$devices = Get-GenieAcsDevices
if ($devices.Count -eq 0) {
    throw "GenieACS no tiene dispositivos. Comprueba el ACS URL del HX141 y espera a que envie un Inform."
}

if (-not $DeviceId) {
    if ($devices.Count -ne 1) {
        Write-Host "Hay $($devices.Count) dispositivos registrados. Vuelve a ejecutar indicando -DeviceId:" -ForegroundColor Yellow
        $devices | Select-Object _id, _lastInform | Format-Table -AutoSize
        throw "No se puede elegir el HX141 de forma segura."
    }
    $DeviceId = [string]$devices[0]._id
}

$encodedId = [uri]::EscapeDataString($DeviceId)
$baseUrl = $GenieAcsNbiUrl.TrimEnd('/')

if ($Refresh) {
    $taskUri = "$baseUrl/devices/$encodedId/tasks?timeout=$RefreshTimeoutMs&connection_request"
    $taskBody = @{ name = "refreshObject"; objectName = "" } | ConvertTo-Json -Compress
    try {
        Invoke-RestMethod -Method Post -Uri $taskUri -ContentType "application/json" -Body $taskBody | Out-Null
        Write-Host "Descubrimiento/refresh solicitado al HX141." -ForegroundColor Green
    }
    catch {
        Write-Warning "El refresh inmediato no se completo. La tarea puede quedar pendiente hasta el siguiente Inform: $($_.Exception.Message)"
    }
}

$query = @{ _id = $DeviceId } | ConvertTo-Json -Compress
$encodedQuery = [uri]::EscapeDataString($query)
$deviceResult = @(Invoke-RestMethod -Method Get -Uri "$baseUrl/devices/?query=$encodedQuery")
if ($deviceResult.Count -eq 0) {
    throw "No se encontro el dispositivo '$DeviceId' despues de consultarlo por ID."
}

$device = $deviceResult[0]
$allRows = @(Get-LeafRows -Node $device)
$tr181Rows = @($allRows | Where-Object {
    $_.Parameter -like "Device.*" -or $_.Parameter -like "InternetGatewayDevice.*"
} | Sort-Object Parameter)

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
$safeId = $DeviceId -replace '[^a-zA-Z0-9._-]', '_'
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$jsonPath = Join-Path $OutDir "hx141-$safeId-$stamp.json"
$csvPath = Join-Path $OutDir "hx141-$safeId-$stamp.csv"

$device | ConvertTo-Json -Depth 100 | Set-Content -Path $jsonPath -Encoding UTF8
$tr181Rows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

$deviceRootCount = @($tr181Rows | Where-Object Parameter -Like "Device.*").Count
$igdRootCount = @($tr181Rows | Where-Object Parameter -Like "InternetGatewayDevice.*").Count
$wifiCount = @($tr181Rows | Where-Object Parameter -Like "Device.WiFi.*").Count
$dataElementsCount = @($tr181Rows | Where-Object Parameter -Like "Device.WiFi.DataElements.*").Count

Write-Host ""
Write-Host "Exportacion completada para $DeviceId" -ForegroundColor Green
Write-Host "  Device.*:                         $deviceRootCount"
Write-Host "  InternetGatewayDevice.*:          $igdRootCount"
Write-Host "  Device.WiFi.*:                    $wifiCount"
Write-Host "  Device.WiFi.DataElements.*:       $dataElementsCount"
Write-Host "  JSON: $jsonPath"
Write-Host "  CSV:  $csvPath"

if ($dataElementsCount -eq 0) {
    Write-Warning "El firmware no ha expuesto Device.WiFi.DataElements.*. Esto no impide que existan metricas WiFi bajo Device.WiFi.* o ramas X_TP_* del fabricante."
}
