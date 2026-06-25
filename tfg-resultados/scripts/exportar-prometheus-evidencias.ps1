$ErrorActionPreference = "Stop"

$outDir = "C:\EasyMesh-Lab\tfg-resultados\evidencias\prometheus"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"

$queries = @(
    @{ name = "01_simulator_up"; query = "easymesh_simulator_up" },
    @{ name = "02_scenario_info"; query = "easymesh_sim_scenario_info" },
    @{ name = "03_event_info"; query = "easymesh_sim_event_info" },
    @{ name = "04_steering_count"; query = "easymesh_sim_steering_count_total" },

    @{ name = "05_movil_rssi_directo"; query = 'easymesh_sim_client_signal_dbm{client="MOVIL_SARA"}' },
    @{ name = "06_movil_qoe_directo"; query = 'easymesh_sim_client_qoe_score{client="MOVIL_SARA"}' },
    @{ name = "07_movil_latency_directo"; query = 'easymesh_sim_client_latency_ms{client="MOVIL_SARA"}' },
    @{ name = "08_movil_jitter_directo"; query = 'easymesh_sim_client_jitter_ms{client="MOVIL_SARA"}' },
    @{ name = "09_movil_packet_loss_directo"; query = 'easymesh_sim_client_packet_loss_percent{client="MOVIL_SARA"}' },
    @{ name = "10_movil_retry_rate_directo"; query = 'easymesh_sim_client_retry_rate_percent{client="MOVIL_SARA"}' },
    @{ name = "11_movil_throughput_down_directo"; query = 'easymesh_sim_client_throughput_down_mbps{client="MOVIL_SARA"}' },
    @{ name = "12_movil_throughput_up_directo"; query = 'easymesh_sim_client_throughput_up_mbps{client="MOVIL_SARA"}' },

    @{ name = "13_radio_utilization"; query = "easymesh_sim_radio_utilization_percent" },
    @{ name = "14_radio_noise"; query = "easymesh_sim_radio_noise_dbm" },
    @{ name = "15_radio_sta_count"; query = "easymesh_sim_radio_sta_count" },
    @{ name = "16_backhaul_rssi"; query = "easymesh_sim_backhaul_rssi_dbm" },
    @{ name = "17_backhaul_latency"; query = "easymesh_sim_backhaul_latency_ms" },
    @{ name = "18_backhaul_packet_loss"; query = "easymesh_sim_backhaul_packet_loss_percent" },

    @{ name = "19_csv_exporter_up"; query = "easymesh_csv_exporter_up" },
    @{ name = "20_csv_snapshots_total"; query = "easymesh_csv_snapshots_total" },
    @{ name = "21_csv_latest_snapshot"; query = 'easymesh_csv_latest_snapshot_timestamp_seconds{kind="tr181"}' },
    @{ name = "22_csv_tr181_qoe"; query = 'easymesh_csv_tr181_numeric_value{parameter="Device.X_SARA_QoE.QoEScore"}' },
    @{ name = "23_csv_tr181_rssi"; query = 'easymesh_csv_tr181_numeric_value{parameter="Device.X_SARA_QoE.SignalStrength"}' },
    @{ name = "24_csv_tr181_latency"; query = 'easymesh_csv_tr181_numeric_value{parameter="Device.X_SARA_QoE.LatencyMs"}' },
    @{ name = "25_csv_tr181_packet_loss"; query = 'easymesh_csv_tr181_numeric_value{parameter="Device.X_SARA_QoE.PacketLossPercent"}' },
    @{ name = "26_csv_tr181_eventos"; query = 'easymesh_csv_tr181_info{parameter=~".*Event.*"}' },
    @{ name = "27_csv_tr181_escenario"; query = 'easymesh_csv_tr181_info{parameter=~".*Scenario.*"}' },

    @{ name = "28_genieacs_up"; query = "genieacs_up" },
    @{ name = "29_genieacs_agents"; query = "easymesh_agent_number" },
    @{ name = "30_genieacs_clients"; query = "easymesh_total_client_number" },
    @{ name = "31_genieacs_rssi"; query = "easymesh_client_signal_strength_dbm" },
    @{ name = "32_genieacs_qoe"; query = "easymesh_client_qoe_state" },
    @{ name = "33_genieacs_radio"; query = "easymesh_radio_utilization_avg_percent" },
    @{ name = "34_genieacs_backhaul"; query = "easymesh_backhaul_rssi_dbm" }
)

$summaryRows = New-Object System.Collections.Generic.List[object]

foreach ($item in $queries) {
    $encoded = [uri]::EscapeDataString($item.query)
    $url = "http://localhost:9090/api/v1/query?query=$encoded"

    Write-Host "Consultando $($item.name): $($item.query)"

    $jsonPath = Join-Path $outDir "$($item.name)_$stamp.json"
    $csvPath  = Join-Path $outDir "$($item.name)_$stamp.csv"

    curl.exe -s $url -o $jsonPath

    $data = Get-Content $jsonPath -Raw | ConvertFrom-Json

    $rows = New-Object System.Collections.Generic.List[object]

    foreach ($r in $data.data.result) {
        $metricLabels = ($r.metric.PSObject.Properties | ForEach-Object {
            "$($_.Name)=$($_.Value)"
        }) -join ";"

        $rows.Add([PSCustomObject]@{
            timestamp_export = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            query_name       = $item.name
            promql           = $item.query
            labels           = $metricLabels
            value_timestamp  = $r.value[0]
            value            = $r.value[1]
        })
    }

    if ($rows.Count -gt 0) {
        $rows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    }
    else {
        [PSCustomObject]@{
            timestamp_export = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            query_name       = $item.name
            promql           = $item.query
            labels           = ""
            value_timestamp  = ""
            value            = "SIN_DATOS"
        } | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    }

    $summaryRows.Add([PSCustomObject]@{
        timestamp_export = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        query_name       = $item.name
        promql           = $item.query
        json_file        = $jsonPath
        csv_file         = $csvPath
        status           = $data.status
        result_count     = $data.data.result.Count
    })
}

$summaryPath = Join-Path $outDir "00_resumen_prometheus_queries_$stamp.csv"
$summaryRows | Export-Csv -Path $summaryPath -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "Exportacion terminada."
Write-Host "Carpeta:"
Write-Host $outDir
Write-Host ""
Write-Host "Resumen:"
Write-Host $summaryPath
