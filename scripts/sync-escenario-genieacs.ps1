param(
  [string]$Scenario = "saturation",
  [int]$WaitAfterScenario = 25,
  [int]$WaitAfterRestart = 45
)

cd C:\EasyMesh-Lab

Write-Host "======================================="
Write-Host "Sincronizando escenario con GenieACS"
Write-Host "Escenario: $Scenario"
Write-Host "======================================="

Write-Host "1) Cambiando escenario en simulador..."
curl.exe "http://localhost:9200/set?scenario=$Scenario"

Write-Host "2) Esperando a que el simulador regenere CSV..."
Start-Sleep -Seconds $WaitAfterScenario

Write-Host "3) Comprobando rama de laboratorio en CSV..."
Select-String `
  -Path ".\tr069-data\data_model_easymesh.csv" `
  -Pattern "Device.X_SARA_Lab.Scenario.Id|Device.X_SARA_Lab.Scenario.Description|Device.X_SARA_Lab.Event.Type|Utilization|Noise|SignalStrength" |
  Select-Object -First 30

Write-Host "4) Reiniciando tr069-sim para que recargue el CSV..."
docker restart tr069-sim | Out-Null

Write-Host "5) Esperando nueva sesion TR-069/CWMP..."
Start-Sleep -Seconds $WaitAfterRestart

$deviceId = "535241-EasyMeshVirtualCPE-200001"
$encodedId = [uri]::EscapeDataString($deviceId)

$objects = @(
  "Device.X_SARA_Lab",
  "Device.WiFi",
  "Device.WiFi.Radio",
  "Device.WiFi.AccessPoint",
  "Device.WiFi.DataElements.Network",
  "Device.Hosts",
  "Device.DeviceInfo",
  "Device.BulkData"
)

Write-Host "6) Lanzando refreshObject en GenieACS..."

foreach ($objectName in $objects) {
  try {
    Write-Host "RefreshObject -> $objectName"

    $body = @{
      name = "refreshObject"
      objectName = $objectName
    } | ConvertTo-Json -Compress

    Invoke-RestMethod `
      -Method Post `
      -Uri "http://localhost:7557/devices/$encodedId/tasks?connection_request" `
      -ContentType "application/json" `
      -Body $body | Out-Null
  }
  catch {
    Write-Host "Aviso: no se pudo refrescar $objectName"
    Write-Host $_.Exception.Message
  }
}

Write-Host "7) Esperando actualizacion final..."
Start-Sleep -Seconds 25

Write-Host "8) Consultando GenieACS con projection segura..."

$url = "http://localhost:7557/devices?projection=_id,_lastInform,Device.X_SARA_Lab.Scenario.Id,Device.X_SARA_Lab.Scenario.Description,Device.X_SARA_Lab.Scenario.LastUpdateUTC,Device.X_SARA_Lab.Event.Type,Device.X_SARA_Lab.Event.Reason,Device.WiFi.DataElements.Network.Device.1.Radio.1.Utilization,Device.WiFi.DataElements.Network.Device.1.Radio.1.Noise,Device.WiFi.AccessPoint.1.AssociatedDevice.1.SignalStrength,Device.WiFi.AccessPoint.1.AssociatedDevice.1.Stats.RetryCount,Device.WiFi.AccessPoint.1.AssociatedDevice.1.LastDataDownlinkRate,Device.WiFi.AccessPoint.1.AssociatedDevice.1.LastDataUplinkRate"

$content = (Invoke-WebRequest -UseBasicParsing $url).Content

$content

Write-Host "======================================="
Write-Host "Fin sincronizacion: $Scenario"
Write-Host "======================================="
