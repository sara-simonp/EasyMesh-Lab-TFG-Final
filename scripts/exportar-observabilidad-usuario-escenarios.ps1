param(
  [int]$DuracionSegundos = 60,
  [int]$StepSegundos = 5
)

cd C:\EasyMesh-Lab

$outDir = ".\tfg-resultados\evidencias_finales\04_prometheus\csv_observabilidad_usuario"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function To-UnixSeconds([datetime]$dt) {
  return [int][Math]::Floor(($dt.ToUniversalTime() - [datetime]"1970-01-01T00:00:00Z").TotalSeconds)
}

function Get-LabelValue($metricObj, $name) {
  $p = $metricObj.PSObject.Properties[$name]
  if ($p) { return $p.Value }
  return ""
}

$escenarios = @("normal","coverage","interference","saturation","backhaul_degraded","ap_failure","roaming")

$metricas = @(
  @{Nombre="easymesh_sim_scenario_info"; Categoria="Control laboratorio"; Explicacion="Escenario activo"},
  @{Nombre="easymesh_sim_event_info"; Categoria="Control laboratorio"; Explicacion="Evento EasyMesh simulado"},
  @{Nombre="easymesh_sim_radio_utilization_percent"; Categoria="TelcoX/TR-181"; Explicacion="Radio Utilization"},
  @{Nombre="easymesh_sim_radio_noise_dbm"; Categoria="TelcoX/TR-181"; Explicacion="Radio Noise"},
  @{Nombre="easymesh_sim_client_signal_dbm"; Categoria="TelcoX/TR-181"; Explicacion="AssociatedDevice SignalStrength"},
  @{Nombre="easymesh_sim_client_phy_rate_down_mbps"; Categoria="TelcoX/TR-181"; Explicacion="LastDataDownlinkRate"},
  @{Nombre="easymesh_sim_client_phy_rate_up_mbps"; Categoria="TelcoX/TR-181"; Explicacion="LastDataUplinkRate"},
  @{Nombre="easymesh_sim_client_retry_rate_percent"; Categoria="TelcoX/TR-181 proxy"; Explicacion="Proxy de RetryCount"},
  @{Nombre="easymesh_sim_radio_sta_count"; Categoria="TelcoX/TR-181"; Explicacion="STA count por radio"},
  @{Nombre="easymesh_sim_client_qoe_score"; Categoria="KPI usuario derivado"; Explicacion="QoE 0-100"},
  @{Nombre="easymesh_sim_client_latency_ms"; Categoria="KPI usuario derivado"; Explicacion="Latencia usuario"},
  @{Nombre="easymesh_sim_client_packet_loss_percent"; Categoria="KPI usuario derivado"; Explicacion="Perdida de paquetes usuario"},
  @{Nombre="easymesh_sim_client_throughput_down_mbps"; Categoria="KPI usuario derivado"; Explicacion="Throughput bajada"},
  @{Nombre="easymesh_sim_client_throughput_up_mbps"; Categoria="KPI usuario derivado"; Explicacion="Throughput subida"},
  @{Nombre="easymesh_sim_backhaul_rssi_dbm"; Categoria="Contexto laboratorio"; Explicacion="RSSI backhaul"},
  @{Nombre="easymesh_sim_backhaul_latency_ms"; Categoria="Contexto laboratorio"; Explicacion="Latencia backhaul"},
  @{Nombre="easymesh_sim_backhaul_packet_loss_percent"; Categoria="Contexto laboratorio"; Explicacion="Packet loss backhaul"}
)

$todos = @()

foreach ($escenario in $escenarios) {
  Write-Host "======================================="
  Write-Host "Escenario: $escenario"
  Write-Host "======================================="

  curl.exe "http://localhost:9200/set?scenario=$escenario"
  Start-Sleep -Seconds 20

  $start = Get-Date
  Start-Sleep -Seconds $DuracionSegundos
  $end = Get-Date

  $startUnix = To-UnixSeconds $start
  $endUnix = To-UnixSeconds $end
  $rows = @()

  foreach ($m in $metricas) {
    $nombre = $m.Nombre
    $query = [uri]::EscapeDataString($nombre)
    $url = "http://localhost:9090/api/v1/query_range?query=$query&start=$startUnix&end=$endUnix&step=$StepSegundos"
    Write-Host "Exportando: $nombre"
    $r = Invoke-RestMethod $url

    foreach ($serie in $r.data.result) {
      $labels = $serie.metric
      $labelPairs = @()
      foreach ($prop in $labels.PSObject.Properties) {
        if ($prop.Name -ne "__name__") { $labelPairs += ($prop.Name + "=" + $prop.Value) }
      }

      foreach ($punto in $serie.values) {
        $unix = [double]$punto[0]
        $valor = $punto[1]
        $timestamp = ([datetime]"1970-01-01T00:00:00Z").AddSeconds($unix).ToLocalTime()
        $row = New-Object PSObject
        $row | Add-Member NoteProperty Scenario $escenario
        $row | Add-Member NoteProperty Categoria $m.Categoria
        $row | Add-Member NoteProperty Explicacion $m.Explicacion
        $row | Add-Member NoteProperty Metric $nombre
        $row | Add-Member NoteProperty Timestamp $timestamp
        $row | Add-Member NoteProperty Value $valor
        $row | Add-Member NoteProperty AP (Get-LabelValue $labels "ap")
        $row | Add-Member NoteProperty Radio (Get-LabelValue $labels "radio")
        $row | Add-Member NoteProperty Band (Get-LabelValue $labels "band")
        $row | Add-Member NoteProperty Channel (Get-LabelValue $labels "channel")
        $row | Add-Member NoteProperty Client (Get-LabelValue $labels "client")
        $row | Add-Member NoteProperty Service (Get-LabelValue $labels "service")
        $row | Add-Member NoteProperty State (Get-LabelValue $labels "state")
        $row | Add-Member NoteProperty EventType (Get-LabelValue $labels "type")
        $row | Add-Member NoteProperty Reason (Get-LabelValue $labels "reason")
        $row | Add-Member NoteProperty Labels ($labelPairs -join ";")
        $rows += $row
        $todos += $row
      }
    }
  }

  $csvEscenario = Join-Path $outDir ("observabilidad_usuario_" + $escenario + ".csv")
  $rows | Export-Csv -Path $csvEscenario -NoTypeInformation -Encoding UTF8
  Write-Host "Guardado: $csvEscenario"
}

$csvGlobal = Join-Path $outDir "observabilidad_usuario_todos_los_escenarios.csv"
$todos | Export-Csv -Path $csvGlobal -NoTypeInformation -Encoding UTF8
Write-Host "CSV global:"
Write-Host $csvGlobal
