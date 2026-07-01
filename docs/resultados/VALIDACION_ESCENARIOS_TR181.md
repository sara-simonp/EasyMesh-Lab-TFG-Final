# Validacion de escenarios TR-181 / DataElements

Este documento recoge la validacion final de los escenarios simulados en EasyMesh-Lab tras la ampliacion del simulador con ramas BulkData/TelcoX.

La validacion se basa en los CSV definitivos generados por el simulador en la ruta:

tfg-resultados/simulador/csv/

---

## 1. Objetivo

El objetivo de esta validacion es comprobar que el simulador EasyMesh genera telemetria coherente para distintos escenarios de red y que dicha telemetria puede utilizarse para analizar la experiencia de cliente mediante metricas TR-181/DataElements.

Los escenarios evaluados son:

- normal
- coverage
- interference
- saturation
- backhaul_degraded
- ap_failure
- mixed
- roaming

---

## 2. Fuentes de datos utilizadas

Los CSV definitivos TR-181/DataElements revisados son:

| Escenario | CSV |
|---|---|
| normal | data_model_easymesh_normal_20260701_123452.csv |
| coverage | data_model_easymesh_coverage_20260701_123530.csv |
| interference | data_model_easymesh_interference_20260701_125505.csv |
| saturation | data_model_easymesh_saturation_20260701_123655.csv |
| backhaul_degraded | data_model_easymesh_backhaul_degraded_20260701_123802.csv |
| ap_failure | data_model_easymesh_ap_failure_20260701_123837.csv |
| mixed | data_model_easymesh_mixed_20260701_123942.csv |
| roaming | data_model_easymesh_roaming_20260701_124321.csv |

Tambien se utilizan como evidencias complementarias los CSV de metricas Prometheus:

- metricas_prometheus_normal_20260701_123452.csv
- metricas_prometheus_coverage_20260701_123530.csv
- metricas_prometheus_interference_20260701_125505.csv
- metricas_prometheus_saturation_20260701_123655.csv
- metricas_prometheus_ap_failure_20260701_123837.csv
- metricas_prometheus_mixed_20260701_123942.csv
- metricas_prometheus_roaming_20260701_124321.csv

---

## 3. Ramas TR-181/DataElements verificadas

Los CSV definitivos contienen las siguientes ramas principales:

| Rama | Estado |
|---|---|
| Device.BulkData | OK |
| Device.BulkData.Profile.1 | OK |
| Device.BulkData.Profile.1.Parameter.*.Reference | OK |
| Device.DeviceInfo | OK |
| Device.WiFi | OK |
| Device.WiFi.SSID | OK |
| Device.WiFi.Radio | OK |
| Device.WiFi.AccessPoint | OK |
| Device.WiFi.AccessPoint.*.AssociatedDevice | OK |
| Device.WiFi.DataElements.Network | OK |
| Device.WiFi.DataElements.Network.Controller | OK |
| Device.WiFi.DataElements.Network.Device | OK |
| Device.WiFi.DataElements.Network.Device.*.Radio | OK |
| Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS | OK |
| Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.STA | OK |
| Device.WiFi.DataElements.Network.Device.*.STA | OK |
| Device.WiFi.DataElements.Network.Event | OK |
| Device.Hosts.Host | OK |
| Device.Firewall | OK |
| Device.Ethernet.Interface | OK |
| Device.IP.Interface | OK |
| Device.X_SARA_QoE | OK |
| InternetGatewayDevice.X_SARA_EasyMesh | OK |

---

## 4. Tabla comparativa de escenarios

| Escenario | AP MOVIL_SARA | RSSI | Latencia | Packet loss | QoE | Estado QoE | Evento |
|---|---:|---:|---:|---:|---:|---|---|
| normal | AP_SALON | -50.6 dBm | 9.4 ms | 0 % | 100 | Buena | None |
| coverage | AP_SALON | -67.6 dBm | 17.3 ms | 0 % | 88 | Buena | None |
| interference | AP_SALON | -57.8 dBm | 20.8 ms | 0 % | 83 | Buena | HighInterference |
| saturation | AP_SALON | -53.4 dBm | 28.6 ms | 3.09 % | 53 | Degradada | HighUtilization |
| backhaul_degraded | AP_DORMITORIO | -44.9 dBm | 30.8 ms | 3.4 % | 76 | Media | BackhaulDegraded |
| ap_failure | AP_SALON | -72.9 dBm | 36.0 ms | 1.74 % | 47 | Degradada | APFailure |
| mixed | AP_SALON | -55.7 dBm | 21.6 ms | 0.01 % | 79 | Media | ClientSteering |
| roaming | AP_DORMITORIO | -46.2 dBm | 9.3 ms | 0 % | 100 | Buena | ClientSteering |

---

## 5. Interpretacion por escenario

### 5.1 Escenario normal

El escenario normal actua como linea base del laboratorio.

Resultados principales:

- MOVIL_SARA conectado a AP_SALON.
- RSSI de -50.6 dBm.
- Latencia de 9.4 ms.
- Sin perdida de paquetes.
- QoE 100.
- Estado QoE Buena.
- Evento None.

Interpretacion:

La red funciona en condiciones estables. Este escenario sirve como referencia para comparar los escenarios degradados.

---

### 5.2 Escenario coverage

El escenario coverage simula una degradacion de cobertura.

Resultados principales:

- MOVIL_SARA conectado a AP_SALON.
- RSSI de -67.6 dBm.
- Latencia de 17.3 ms.
- Sin perdida de paquetes.
- QoE 88.
- Estado QoE Buena.
- Evento None.

Interpretacion:

La degradacion de cobertura se observa principalmente en la bajada del RSSI. Aunque la QoE se mantiene en estado Buena, el escenario refleja una situacion de cobertura limite moderada.

---

### 5.3 Escenario interference

El escenario interference simula interferencia elevada en el entorno WiFi.

Resultados principales:

- MOVIL_SARA conectado a AP_SALON.
- RSSI de -57.8 dBm.
- Latencia de 20.8 ms.
- Sin perdida de paquetes.
- QoE 83.
- Estado QoE Buena.
- Evento HighInterference.

Interpretacion:

El escenario genera correctamente un evento de interferencia. La latencia aumenta respecto al escenario normal y se activa el evento HighInterference, lo que permite identificar degradacion de calidad radio.

---

### 5.4 Escenario saturation

El escenario saturation simula carga alta y saturacion de radio.

Resultados principales:

- MOVIL_SARA conectado a AP_SALON.
- RSSI de -53.4 dBm.
- Latencia de 28.6 ms.
- Packet loss de 3.09 %.
- QoE 53.
- Estado QoE Degradada.
- Evento HighUtilization.

Interpretacion:

Este escenario es uno de los mas claros. Aunque el RSSI no es malo, la experiencia se degrada por carga de radio, aumento de latencia y perdida de paquetes. Es una evidencia directa de que la QoE no depende solo de la senal, sino tambien de la utilizacion y la calidad de servicio.

---

### 5.5 Escenario backhaul_degraded

El escenario backhaul_degraded simula degradacion del enlace entre gateway y satelite.

Resultados principales:

- MOVIL_SARA conectado a AP_DORMITORIO.
- RSSI de -44.9 dBm.
- Latencia de 30.8 ms.
- Packet loss de 3.4 %.
- QoE 76.
- Estado QoE Media.
- Evento BackhaulDegraded.

Interpretacion:

Este escenario demuestra un caso importante para EasyMesh: el cliente puede tener buen RSSI con el satelite, pero la experiencia se degrada por el backhaul. Esto es relevante para analizar el punto ciego de visibilidad en redes mesh.

---

### 5.6 Escenario ap_failure

El escenario ap_failure simula fallo del punto de acceso satelite.

Resultados principales:

- MOVIL_SARA conectado a AP_SALON.
- RSSI de -72.9 dBm.
- Latencia de 36.0 ms.
- Packet loss de 1.74 %.
- QoE 47.
- Estado QoE Degradada.
- Evento APFailure.

Interpretacion:

El fallo del satelite fuerza al cliente a quedar conectado al AP principal con peor cobertura. Se observa un descenso fuerte de RSSI y degradacion de QoE. Este escenario es util para validar deteccion de fallos y reasociacion de clientes.

---

### 5.7 Escenario mixed

El escenario mixed combina distintas condiciones de degradacion.

Resultados principales:

- MOVIL_SARA conectado a AP_SALON.
- RSSI de -55.7 dBm.
- Latencia de 21.6 ms.
- Packet loss de 0.01 %.
- QoE 79.
- Estado QoE Media.
- Evento ClientSteering.

Interpretacion:

El escenario mixed sirve como caso combinado. No debe usarse como evidencia principal de una degradacion concreta, pero si como prueba de que el simulador puede alternar condiciones y generar eventos de movilidad.

---

### 5.8 Escenario roaming

El escenario roaming simula movilidad y steering del cliente.

Resultados principales:

- MOVIL_SARA conectado a AP_DORMITORIO.
- RSSI de -46.2 dBm.
- Latencia de 9.3 ms.
- Sin perdida de paquetes.
- QoE 100.
- Estado QoE Buena.
- Evento ClientSteering.

Interpretacion:

El evento ClientSteering demuestra que el simulador reproduce el cambio de AP del cliente MOVIL_SARA. Este escenario permite estudiar la continuidad de visibilidad durante roaming y la correlacion temporal del cliente entre APs.

---

## 6. Validacion del pipeline Prometheus

Los CSV de metricas Prometheus confirman que el simulador expone metricas consumibles por Prometheus.

Metricas principales observadas:

- easymesh_simulator_up
- easymesh_sim_scenario_info
- easymesh_sim_client_signal_dbm
- easymesh_sim_client_snr_db
- easymesh_sim_client_qoe_score
- easymesh_sim_client_latency_ms
- easymesh_sim_client_jitter_ms
- easymesh_sim_client_packet_loss_percent
- easymesh_sim_client_retry_rate_percent
- easymesh_sim_radio_utilization_percent
- easymesh_sim_radio_noise_dbm
- easymesh_sim_backhaul_rssi_dbm
- easymesh_sim_backhaul_latency_ms
- easymesh_sim_backhaul_packet_loss_percent
- easymesh_sim_event_info
- easymesh_sim_steering_count_total

Esto valida la ruta:

easymesh-network-simulator -> Prometheus -> Grafana

---

## 7. Validacion del modelo TR-181/BulkData

Los CSV definitivos incluyen configuracion simulada de BulkData:

- Device.BulkData.Enable
- Device.BulkData.Profile.1.Alias
- Device.BulkData.Profile.1.Enable
- Device.BulkData.Profile.1.EncodingType
- Device.BulkData.Profile.1.Protocol
- Device.BulkData.Profile.1.ReportingInterval
- Device.BulkData.Profile.1.HTTP.Method
- Device.BulkData.Profile.1.HTTP.URL
- Device.BulkData.Profile.1.HTTP.UseDateHeader
- Device.BulkData.Profile.1.JSONEncoding.ReportFormat
- Device.BulkData.Profile.1.JSONEncoding.ReportTimestamp
- Device.BulkData.Profile.1.Parameter.*.Reference

Tambien incluyen 85 referencias de parametros BulkData, desde:

Device.BulkData.Profile.1.Parameter.1.Reference

hasta:

Device.BulkData.Profile.1.Parameter.85.Reference

---

## 8. Conclusion

La validacion confirma que el simulador EasyMesh-Lab funciona correctamente para la fase simulada del TFG.

El laboratorio permite:

- generar telemetria TR-181/DataElements;
- simular escenarios de cobertura, interferencia, saturacion, roaming, backhaul degradado y fallo de AP;
- analizar KPIs de QoE;
- correlacionar cliente, AP, backhaul y evento;
- exportar metricas hacia Prometheus;
- preparar visualizacion en Grafana;
- aproximar un payload BulkData TelcoX a nivel de modelo de datos.

Limitacion principal:

El laboratorio actual no implementa un CPE fisico enviando reportes HTTP/POST JSON a un collector real. Esa validacion queda reservada para la fase con dispositivos reales.
