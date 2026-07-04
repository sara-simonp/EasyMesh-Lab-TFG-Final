param(
  [int]$Segundos = 45
)

cd C:\EasyMesh-Lab

$escenarios = @(
  "normal",
  "coverage",
  "interference",
  "saturation",
  "backhaul_degraded",
  "ap_failure",
  "roaming",
  "normal"
)

foreach ($escenario in $escenarios) {
  Write-Host "Aplicando escenario: $escenario"
  curl.exe "http://localhost:9200/set?scenario=$escenario"
  Start-Sleep -Seconds $Segundos
}

Write-Host "Secuencia finalizada."
