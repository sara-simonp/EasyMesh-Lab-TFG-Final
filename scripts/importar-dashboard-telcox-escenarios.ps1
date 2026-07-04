$ErrorActionPreference = "Stop"

cd C:\EasyMesh-Lab

$pair = "admin:admin"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)
$headers = @{ Authorization = "Basic $base64" }

$ds = @{
  name = "Prometheus"
  uid = "prometheus"
  type = "prometheus"
  access = "proxy"
  url = "http://prometheus-monitoring:9090"
  isDefault = $true
} | ConvertTo-Json -Depth 10

try {
  Invoke-RestMethod -Method Post -Uri "http://localhost:3001/api/datasources" -Headers $headers -ContentType "application/json" -Body $ds | Out-Null
  Write-Host "Datasource Prometheus creado."
} catch {
  Write-Host "Datasource ya existe o no se pudo crear; continuo."
}

$dashboardPath = ".\monitoring\grafana\dashboards\easymesh-telcox-escenarios.json"
$dashboard = Get-Content $dashboardPath -Raw | ConvertFrom-Json

$payload = @{
  dashboard = $dashboard
  overwrite = $true
  folderId = 0
} | ConvertTo-Json -Depth 100

Invoke-RestMethod -Method Post -Uri "http://localhost:3001/api/dashboards/db" -Headers $headers -ContentType "application/json" -Body $payload | Out-Null

Write-Host "Dashboard importado."
Start-Process "http://localhost:3001/d/easymesh-telcox-escenarios/easymesh-seguimiento-telcox-y-escenarios"
