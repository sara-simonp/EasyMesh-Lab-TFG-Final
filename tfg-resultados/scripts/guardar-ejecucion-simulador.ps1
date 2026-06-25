param(
    [Parameter(Mandatory=$true)]
    [string]$Scenario,

    [int]$WaitSeconds = 25
)

$ErrorActionPreference = "Stop"

$base = "C:\EasyMesh-Lab"
$resultBase = "$base\tfg-resultados\simulador"

$csvDir = "$resultBase\csv"
$jsonDir = "$resultBase\capturas"
$resumenDir = "$resultBase\resumen"

New-Item -ItemType Directory -Force -Path $csvDir | Out-Null
New-Item -ItemType Directory -Force -Path $jsonDir | Out-Null
New-Item -ItemType Directory -Force -Path $resumenDir | Out-Null

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "========================================"
Write-Host "Escenario: $Scenario"
Write-Host "Timestamp: $stamp"
Write-Host "========================================"

# 1. Cambiar escenario en el simulador real
curl.exe "http://localhost:9200/set?scenario=$Scenario" | Out-Null

Write-Host "Esperando $WaitSeconds segundos para que el simulador actualice estado, metricas y CSV..."
Start-Sleep -Seconds $WaitSeconds

# 2. Rutas vivas generadas por el simulador
$liveCsv = "$base\tr069-data\data_model_easymesh.csv"
$liveState = "$base\tr069-data\easymesh_simulator_state.json"
$liveSummary = "$base\tr069-data\easymesh_simulator_summary.txt"

if (!(Test-Path $liveCsv)) {
    throw "No existe el CSV vivo: $liveCsv"
}

if (!(Test-Path $liveState)) {
    throw "No existe el JSON vivo: $liveState"
}

# 3. Rutas historicas, no se sobrescriben
$outCsv = "$csvDir\data_model_easymesh_${Scenario}_${stamp}.csv"
$outMetricsCsv = "$csvDir\metricas_prometheus_${Scenario}_${stamp}.csv"
$outState = "$jsonDir\state_${Scenario}_${stamp}.json"
$outSummary = "$resumenDir\summary_${Scenario}_${stamp}.txt"

# 4. Copiar CSV TR-181 generado por el simulador
Copy-Item $liveCsv $outCsv -Force

# 5. Copiar estado JSON
Copy-Item $liveState $outState -Force

# 6. Copiar resumen si existe
if (Test-Path $liveSummary) {
    Copy-Item $liveSummary $outSummary -Force
}
else {
    "Resumen no disponible para $Scenario en $stamp" | Set-Content -Path $outSummary -Encoding UTF8
}

# 7. Guardar tambien las metricas /metrics en CSV historico
$metricsRaw = curl.exe "http://localhost:9200/metrics"

$metricRows = New-Object System.Collections.Generic.List[object]

foreach ($line in $metricsRaw) {
    if ([string]::IsNullOrWhiteSpace($line)) {
        continue
    }

    if ($line.StartsWith("#")) {
        continue
    }

    $metricName = ""
    $labels = ""
    $value = ""

    if ($line -match '^([a-zA-Z_:][a-zA-Z0-9_:]*)\{(.*)\}\s+(.+)$') {
        $metricName = $matches[1]
        $labels = $matches[2]
        $value = $matches[3]
    }
    elseif ($line -match '^([a-zA-Z_:][a-zA-Z0-9_:]*)\s+(.+)$') {
        $metricName = $matches[1]
        $labels = ""
        $value = $matches[2]
    }
    else {
        continue
    }

    $metricRows.Add([PSCustomObject]@{
        timestamp_utc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        scenario      = $Scenario
        metric        = $metricName
        labels        = $labels
        value         = $value
    })
}

$metricRows | Export-Csv -Path $outMetricsCsv -NoTypeInformation -Encoding UTF8

# 8. Mostrar resumen de la ejecucion
$state = Get-Content $outState -Raw | ConvertFrom-Json

Write-Host ""
Write-Host "Ejecucion guardada correctamente:"
Write-Host "CSV TR-181:        $outCsv"
Write-Host "CSV metricas:      $outMetricsCsv"
Write-Host "JSON estado:       $outState"
Write-Host "Resumen:           $outSummary"
Write-Host ""
Write-Host "Estado capturado:"
Write-Host "Escenario activo:  $($state.scenario)"
Write-Host "MOVIL_SARA AP:     $($state.mobile_summary.ap)"
Write-Host "RSSI MOVIL_SARA:   $($state.mobile_summary.signal_strength_dbm)"
Write-Host "QoE MOVIL_SARA:    $($state.mobile_summary.qoe_score)"
Write-Host "Evento:            $($state.event.type)"
Write-Host "Resultado:         $($state.event.result)"
Write-Host "Steering count:    $($state.event.steering_count)"
