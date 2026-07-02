param(
  [Parameter(Mandatory=$true)]
  [ValidateSet("normal","coverage","interference","saturation","backhaul_degraded","ap_failure","mixed","roaming")]
  [string]$Scenario,

  [int]$WaitSeconds = 25
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "==============================================="
Write-Host " Cambiando escenario EasyMesh: $Scenario"
Write-Host "==============================================="
Write-Host ""

# 1. Cambiar escenario en el simulador
curl.exe "http://localhost:9200/set?scenario=$Scenario" | Out-Null

Write-Host "Escenario aplicado en el simulador."
Write-Host "Esperando $WaitSeconds segundos para que se regenere el modelo TR-181..."
Start-Sleep -Seconds $WaitSeconds

# 2. Comprobar que existe el CSV vivo de TR-181
$csvPath = "C:\EasyMesh-Lab\tr069-data\data_model_easymesh.csv"

if (-not (Test-Path $csvPath)) {
  Write-Host "No existe $csvPath"
  Write-Host "Intentando copiar el ultimo CSV historico..."

  $latestCsv = Get-ChildItem "C:\EasyMesh-Lab\tfg-resultados\simulador\csv\data_model_easymesh_*.csv" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

  if (-not $latestCsv) {
    throw "No se encontro ningun CSV TR-181 historico."
  }

  Copy-Item $latestCsv.FullName $csvPath -Force
}

Write-Host ""
Write-Host "CSV TR-181 usado por tr069-sim:"
Get-Item $csvPath | Select-Object FullName, Length, LastWriteTime

# 3. Mostrar algunas metricas del CSV para verificar que cambia
Write-Host ""
Write-Host "Metricas TR-181/QoE actuales:"
Select-String -Path $csvPath -Pattern "QoEScore|QoEState|LatencyMs|PacketLossPercent|SignalStrength|Utilization" |
  Select-Object -First 20

# 4. Reiniciar tr069-sim para que recargue el modelo actualizado
Write-Host ""
Write-Host "Reiniciando tr069-sim para enviar el modelo actualizado a GenieACS..."
docker restart tr069-sim | Out-Null

Start-Sleep -Seconds 35

Write-Host ""
Write-Host "Ultimos logs de tr069-sim:"
docker logs tr069-sim --tail 40

Write-Host ""
Write-Host "Proceso completado."
Write-Host "Ahora refresca GenieACS en http://localhost:3000"
