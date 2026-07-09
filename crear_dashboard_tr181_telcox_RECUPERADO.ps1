$ErrorActionPreference = "Stop"

$grafanaUrl = "http://localhost:3001"
$user = "admin"
$pass = "admin"

$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$user`:$pass"))

Write-Host "Comprobando datasource Prometheus en Grafana..."

$datasources = Invoke-RestMethod `
  -Uri "$grafanaUrl/api/datasources" `
  -Headers @{ Authorization = "Basic $auth" }

$promDs = $datasources | Where-Object { $_.type -eq "prometheus" } | Select-Object -First 1

if (-not $promDs) {
  throw "No se ha encontrado datasource Prometheus en Grafana."
}

Write-Host "Datasource encontrado:" $promDs.name "UID:" $promDs.uid

$ds = @{
  type = "prometheus"
  uid = $promDs.uid
}

function New-TimeSeriesPanel {
  param(
    [int]$Id,
    [string]$Title,
    [int]$X,
    [int]$Y,
    [int]$W,
    [int]$H,
    [string]$Expr,
    [string]$Legend
  )

  return @{
    id = $Id
    title = $Title
    type = "timeseries"
    datasource = $ds
    gridPos = @{
      h = $H
      w = $W
      x = $X
      y = $Y
    }
    targets = @(
      @{
        refId = "A"
        expr = $Expr
        legendFormat = $Legend
      }
    )
    options = @{
      legend = @{
        displayMode = "table"
        placement = "bottom"
      }
      tooltip = @{
        mode = "multi"
      }
    }
  }
}

function New-StatPanel {
  param(
    [int]$Id,
    [string]$Title,
    [int]$X,
    [int]$Y,
    [int]$W,
    [int]$H,
    [string]$Expr,
    [string]$Unit
  )

  return @{
    id = $Id
    title = $Title
    type = "stat"
    datasource = $ds
    gridPos = @{
      h = $H
      w = $W
      x = $X
      y = $Y
    }
    targets = @(
      @{
        refId = "A"
        expr = $Expr
      }
    )
    fieldConfig = @{
      defaults = @{
        unit = $Unit
      }
    }
    options = @{
      reduceOptions = @{
        calcs = @("lastNotNull")
        fields = ""
        values = $false
      }
    }
  }
}

function New-TablePanel {
  param(
    [int]$Id,
    [string]$Title,
    [int]$X,
    [int]$Y,
    [int]$W,
    [int]$H,
    [string]$Expr
  )

  return @{
    id = $Id
    title = $Title
    type = "table"
    datasource = $ds
    gridPos = @{
      h = $H
      w = $W
      x = $X
      y = $Y
    }
    targets = @(
      @{
        refId = "A"
        expr = $Expr
        instant = $true
        format = "table"
      }
    )
    options = @{
      showHeader = $true
    }
  }
}

$panels = @()

$panels += New-StatPanel `
  -Id 1 `
  -Title "CSV exporter UP" `
  -X 0 -Y 0 -W 6 -H 4 `
  -Expr 'easymesh_csv_exporter_up' `
  -Unit "none"

$panels += New-StatPanel `
  -Id 2 `
  -Title "Snapshots CSV procesados" `
  -X 6 -Y 0 -W 6 -H 4 `
  -Expr 'easymesh_csv_snapshots_total' `
  -Unit "none"

$panels += New-StatPanel `
  -Id 3 `
  -Title "Último snapshot CSV" `
  -X 12 -Y 0 -W 6 -H 4 `
  -Expr 'easymesh_csv_latest_snapshot_timestamp_seconds' `
  -Unit "dateTimeAsIso"

$panels += New-StatPanel `
  -Id 4 `
  -Title "Métricas TR-181 numéricas" `
  -X 18 -Y 0 -W 6 -H 4 `
  -Expr 'count(easymesh_csv_tr181_numeric_value)' `
  -Unit "none"

$panels += New-TimeSeriesPanel `
  -Id 5 `
  -Title "DeviceInfo - CPU, memoria y uptime" `
  -X 0 -Y 4 -W 24 -H 8 `
  -Expr 'easymesh_csv_tr181_numeric_value{parameter=~"Device\\.DeviceInfo\\.(UpTime|MemoryStatus\\.Free|MemoryStatus\\.Total|ProcessStatus\\.CPUUsage)"}' `
  -Legend "{{parameter}}"

$panels += New-TimeSeriesPanel `
  -Id 6 `
  -Title "WiFi Radio - canal y potencia" `
  -X 0 -Y 12 -W 12 -H 8 `
  -Expr 'easymesh_csv_tr181_numeric_value{parameter=~"Device\\.WiFi\\.Radio\\..*\\.(Channel|TransmitPower)"}' `
  -Legend "{{parameter}}"

$panels += New-TimeSeriesPanel `
  -Id 7 `
  -Title "WiFi DataElements - Noise" `
  -X 12 -Y 12 -W 12 -H 8 `
  -Expr 'easymesh_csv_tr181_numeric_value{parameter=~"Device\\.WiFi\\.DataElements\\.Network\\.Device\\..*\\.Radio\\..*\\.Noise"}' `
  -Legend "{{parameter}}"

$panels += New-TimeSeriesPanel `
  -Id 8 `
  -Title "WiFi DataElements - Utilization" `
  -X 0 -Y 20 -W 12 -H 8 `
  -Expr 'easymesh_csv_tr181_numeric_value{parameter=~"Device\\.WiFi\\.DataElements\\.Network\\.Device\\..*\\.Radio\\..*\\.Utilization"}' `
  -Legend "{{parameter}}"

$panels += New-TimeSeriesPanel `
  -Id 9 `
  -Title "AssociatedDevice - SignalStrength / RSSI" `
  -X 12 -Y 20 -W 12 -H 8 `
  -Expr 'easymesh_csv_tr181_numeric_value{parameter=~"Device\\.WiFi\\.AccessPoint\\..*\\.AssociatedDevice\\..*\\.SignalStrength"}' `
  -Legend "{{parameter}}"

$panels += New-TimeSeriesPanel `
  -Id 10 `
  -Title "AssociatedDevice - LastDataDownlinkRate / LastDataUplinkRate" `
  -X 0 -Y 28 -W 12 -H 8 `
  -Expr 'easymesh_csv_tr181_numeric_value{parameter=~"Device\\.WiFi\\.AccessPoint\\..*\\.AssociatedDevice\\..*\\.(LastDataDownlinkRate|LastDataUplinkRate)"}' `
  -Legend "{{parameter}}"

$panels += New-TimeSeriesPanel `
  -Id 11 `
  -Title "AssociatedDevice - RetryCount" `
  -X 12 -Y 28 -W 12 -H 8 `
  -Expr 'easymesh_csv_tr181_numeric_value{parameter=~"Device\\.WiFi\\.AccessPoint\\..*\\.AssociatedDevice\\..*\\.Stats\\.RetryCount"}' `
  -Legend "{{parameter}}"

$panels += New-TimeSeriesPanel `
  -Id 12 `
  -Title "DataElements STA - BytesSent / BytesReceived" `
  -X 0 -Y 36 -W 12 -H 8 `
  -Expr 'easymesh_csv_tr181_numeric_value{parameter=~"Device\\.WiFi\\.DataElements\\.Network\\.Device\\..*\\.Radio\\..*\\.BSS\\..*\\.STA\\..*\\.(BytesSent|BytesReceived)"}' `
  -Legend "{{parameter}}"

$panels += New-TimeSeriesPanel `
  -Id 13 `
  -Title "DataElements STA - EstMACDataRate Downlink/Uplink" `
  -X 12 -Y 36 -W 12 -H 8 `
  -Expr 'easymesh_csv_tr181_numeric_value{parameter=~"Device\\.WiFi\\.DataElements\\.Network\\.Device\\..*\\.Radio\\..*\\.BSS\\..*\\.STA\\..*\\.(EstMACDataRateDownlink|EstMACDataRateUplink|LastDataDownlinkRate|LastDataUplinkRate)"}' `
  -Legend "{{parameter}}"

$panels += New-TablePanel `
  -Id 14 `
  -Title "Hosts - dispositivos conectados" `
  -X 0 -Y 44 -W 24 -H 8 `
  -Expr 'easymesh_csv_tr181_info{parameter=~"Device\\.Hosts\\.Host\\..*\\.(HostName|IPAddress|PhysAddress|ClientID|Active|InterfaceType)"}'

$panels += New-TimeSeriesPanel `
  -Id 15 `
  -Title "Ethernet - tráfico y errores" `
  -X 0 -Y 52 -W 12 -H 8 `
  -Expr 'easymesh_csv_tr181_numeric_value{parameter=~"Device\\.Ethernet\\.Interface\\..*\\.Stats\\.(BytesReceived|BytesSent|ErrorsReceived|ErrorsSent|PacketsReceived|PacketsSent)"}' `
  -Legend "{{parameter}}"

$panels += New-TablePanel `
  -Id 16 `
  -Title "Ethernet - estado de interfaces" `
  -X 12 -Y 52 -W 12 -H 8 `
  -Expr 'easymesh_csv_tr181_info{parameter=~"Device\\.Ethernet\\.Interface\\..*\\.(Status|DuplexMode|Enable|Name|MACAddress|Upstream)"}'

$panels += New-TablePanel `
  -Id 17 `
  -Title "IP - interfaces y direcciones" `
  -X 0 -Y 60 -W 12 -H 8 `
  -Expr 'easymesh_csv_tr181_info{parameter=~"Device\\.IP\\.Interface\\..*"}'

$panels += New-TablePanel `
  -Id 18 `
  -Title "BulkData Profile - configuración" `
  -X 12 -Y 60 -W 12 -H 8 `
  -Expr 'easymesh_csv_tr181_info{parameter=~"Device\\.BulkData\\..*"}'

$panels += New-TablePanel `
  -Id 19 `
  -Title "TR-181 info completa filtrada" `
  -X 0 -Y 68 -W 24 -H 8 `
  -Expr 'easymesh_csv_tr181_info{parameter=~"Device\\.(DeviceInfo|WiFi|Hosts|Ethernet|IP|BulkData)\\..*"}'

$dashboard = @{
  uid = "tfg-tr181-telcox"
  title = "TFG EasyMesh - TR-181 BulkData TelcoX"
  timezone = "browser"
  schemaVersion = 39
  version = 0
  refresh = "10s"
  time = @{
    from = "now-30m"
    to = "now"
  }
  tags = @("TFG", "EasyMesh", "TR-181", "BulkData", "TelcoX", "CSV")
  panels = $panels
}

$body = @{
  dashboard = $dashboard
  overwrite = $true
} | ConvertTo-Json -Depth 100

Write-Host "Importando dashboard TR-181 BulkData TelcoX..."

$response = Invoke-RestMethod `
  -Uri "$grafanaUrl/api/dashboards/db" `
  -Method Post `
  -Headers @{
    Authorization = "Basic $auth"
    "Content-Type" = "application/json"
  } `
  -Body $body

Write-Host "Dashboard importado correctamente."
Write-Host "$grafanaUrl/d/tfg-tr181-telcox"
