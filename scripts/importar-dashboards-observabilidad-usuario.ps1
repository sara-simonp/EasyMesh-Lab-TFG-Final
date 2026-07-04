param(
  [string]$GrafanaUrl = "http://localhost:3001",
  [string]$User = "admin",
  [string]$Password = "admin"
)

cd (Split-Path -Parent $MyInvocation.MyCommand.Path)
cd ..

$pair = "$User`:$Password"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [Convert]::ToBase64String($bytes)
$headers = @{ Authorization = "Basic $base64" }

Write-Host "Comprobando Grafana en $GrafanaUrl ..."
try {
  $datasources = Invoke-RestMethod -Uri "$GrafanaUrl/api/datasources" -Headers $headers
} catch {
  Write-Host "ERROR: No se pudo acceder a Grafana. Si sale Unauthorized, ejecuta:"
  Write-Host "docker exec grafana-monitoring grafana-cli admin reset-admin-password admin"
  throw
}

$prom = $datasources | Where-Object { $_.type -eq "prometheus" } | Select-Object -First 1

if (-not $prom) {
  Write-Host "No existe datasource Prometheus. Creandolo..."
  $bodyDs = '{"name":"Prometheus","type":"prometheus","uid":"Prometheus","access":"proxy","url":"http://prometheus-monitoring:9090","isDefault":true}'
  Invoke-RestMethod -Method Post -Uri "$GrafanaUrl/api/datasources" -Headers $headers -ContentType "application/json" -Body $bodyDs | Out-Null
  $datasources = Invoke-RestMethod -Uri "$GrafanaUrl/api/datasources" -Headers $headers
  $prom = $datasources | Where-Object { $_.type -eq "prometheus" } | Select-Object -First 1
}

Write-Host "Datasource Prometheus detectado:"
Write-Host "  name: $($prom.name)"
Write-Host "  uid : $($prom.uid)"
Write-Host "  url : $($prom.url)"

$dashboardFiles = @(
  ".\monitoring\grafana\dashboards\easymesh-observabilidad-usuario-qoe.json",
  ".\monitoring\grafana\dashboards\easymesh-telcox-tecnico-kpis-usuario.json"
)

foreach ($dashboardPath in $dashboardFiles) {
  if (-not (Test-Path $dashboardPath)) {
    Write-Host "No existe: $dashboardPath"
    continue
  }

  Write-Host "Importando dashboard: $dashboardPath"
  $dashboardJson = Get-Content $dashboardPath -Raw
  $dashboardJson = $dashboardJson.Replace('${DS_PROMETHEUS}', $prom.uid)
  $body = '{"dashboard":' + $dashboardJson + ',"overwrite":true,"folderId":0}'

  $result = Invoke-RestMethod `
    -Method Post `
    -Uri "$GrafanaUrl/api/dashboards/db" `
    -Headers $headers `
    -ContentType "application/json" `
    -Body $body

  Write-Host "  OK: $($result.status) -> $GrafanaUrl$($result.url)"
}

Write-Host ""
Write-Host "Dashboards importados. Abre Grafana: $GrafanaUrl"
Write-Host "Busca:"
Write-Host "  EasyMesh - Observabilidad de Usuario y QoE"
Write-Host "  EasyMesh - TelcoX/TR-181 tecnico + KPIs usuario"
