param(
  [string]$CsvPath = ".\tr069-data\data_model_easymesh.csv"
)

if (-not (Test-Path $CsvPath)) {
  Write-Host "No existe $CsvPath"
  exit 1
}

Write-Host ""
Write-Host "Validacion TelcoX estricta"
Write-Host "CSV: $CsvPath"
Write-Host ""

$refCount = (Select-String -Path $CsvPath -Pattern "Device\.BulkData\.Profile\.1\.Parameter\.[0-9]+\.Reference").Count
Write-Host "Referencias BulkData encontradas: $refCount / 85"

Write-Host ""
Write-Host "Debe estar VACIO. Si aparecen lineas, hay metricas fuera del documento:"
Select-String -Path $CsvPath -Pattern "X_SARA|QoE|LatencyMs|JitterMs|PacketLossPercent|ScenarioId|ScenarioName|Backhaul|Event\.1|RSSI|SNR|Throughput" |
  Select-Object -First 40

Write-Host ""
Write-Host "Muestras permitidas:"
Select-String -Path $CsvPath -Pattern "Device\.WiFi\.DataElements\.Network\.Device\.[0-9]+\.Radio\.[0-9]+\.Utilization|Device\.WiFi\.AccessPoint\.[0-9]+\.AssociatedDevice\.[0-9]+\.SignalStrength|Device\.WiFi\.AccessPoint\.[0-9]+\.AssociatedDevice\.[0-9]+\.Stats\.RetryCount|Device\.DeviceInfo\.ProcessStatus\.CPUUsage" |
  Select-Object -First 30
