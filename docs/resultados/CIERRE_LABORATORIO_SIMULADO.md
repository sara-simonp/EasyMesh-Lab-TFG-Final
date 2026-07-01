# Cierre del laboratorio simulado EasyMesh-Lab

Este documento resume el estado final del laboratorio simulado EasyMesh-Lab antes de pasar a la fase de dispositivos reales.

---

## 1. Objetivo

El objetivo del laboratorio simulado es validar una arquitectura de observabilidad para redes WiFi EasyMesh orientada a QoE.

El laboratorio permite generar telemetria estructurada tipo TR-181/DataElements, simular escenarios de degradacion WiFi, recolectar metricas, almacenarlas y visualizarlas mediante Prometheus y Grafana.

---

## 2. Estado final del laboratorio

El laboratorio simulado incluye:

- simulador EasyMesh dinamico;
- generacion de CSV TR-181/DataElements;
- ramas Device.BulkData alineadas con el documento TelcoX;
- tr069-sim;
- GenieACS;
- exporter QoE desde GenieACS;
- exporter de CSV historicos;
- Prometheus;
- Grafana;
- dashboard final;
- scripts de captura por escenario;
- evidencias finales del laboratorio.

---

## 3. Escenarios validados

Se han validado los siguientes escenarios:

| Escenario | Objetivo |
|---|---|
| normal | linea base estable |
| coverage | degradacion de cobertura |
| interference | interferencia radio |
| saturation | saturacion de radio |
| backhaul_degraded | degradacion del backhaul |
| ap_failure | fallo de satelite |
| mixed | escenario combinado |
| roaming | movilidad y ClientSteering |

---

## 4. Evidencias generadas

Las evidencias principales se encuentran en:

tfg-resultados/simulador/csv/
tfg-resultados/simulador/capturas/
tfg-resultados/simulador/resumen/
tfg-resultados/evidencias_finales/

Los CSV principales son los ficheros:

data_model_easymesh_<escenario>_<timestamp>.csv

Estos contienen la telemetria TR-181/DataElements y las ramas BulkData/TelcoX.

Estos contienen la telemetria TR-181Los CSV complementarios son:

metricas_prometheus_<escenario>_<timestamp>.csv

Estos demuestran que el simulador tambien expone metricas consumibles por Prometheus.

---

## 5. Validacion TR-181 y BulkData

El simulador genera las siguientes ramas principales:

- Device.BulkData
- Device.BulkData.Profile.1
- Device.BulkData.Profile.1.Parameter.*.Reference
- Device.DeviceInfo
- Device.WiFi
- Device.WiFi.SSID
- Device.WiFi.Radio
- Device.WiFi.AccessPoint
- Device.WiFi.DataElements.Network
- Device.WiFi.DataElements.Network.Device
- Device.WiFi.DataElements.Network.Event
- Device.Hosts.Host
- Device.Firewall
- Device.Ethernet.Interface
- Device.IP.Interface
- Device.X_SARA_QoE
- InternetGatewayDevice.X_SARA_EasyMesh

Esto permite aproximar el payload BulkData TelcoX a nivel de modelo de datos.

---

## 6. Validacion QoE

La QoE se analiza mediante metricas como:

- RSSI;
- SNR;
- MCS;
- throughput;
- latencia;
- jitter;
- perdida de paquetes;
- retry rate;
- utilizacion radio;
- ruido radio;
- RSSI de backhaul;
- latencia de backhaul;
- perdida de backhaul;
- evento EasyMesh;
- QoE Score;
- QoE State.

Estas metricas permiten interpretar la experiencia de cliente en escenarios de cobertura, interferencia, saturacion, roaming y fallo de AP.

---

## 7. Pipeline validado

El pipeline validado es:

easymesh-network-simulator
  -> TR-181/DataElements CSV
  -> tr069-sim
  -> GenieACS
  -> genieacs-qoe-exporter
  -> Prometheus
  -> Grafana

Tambien se valida la ruta:

tfg-resultados/simulador/csv
  -> csv-prometheus-exporter
  -> Prometheus
  -> Grafana

Y la ruta directa:

easymesh-network-simulator
  -> Prometheus
  -> Grafana

---

## 8. Limitaciones

El laboratorio actual tiene las siguientes limitaciones:

- No implementa una pila EasyMesh certificada.
- No implementa el plano IEEE 1905.1 completo.
- No mide radiofrecuencia real.
- No ejecuta un POST HTTP real desde un CPE fisico hacia un collector BulkData.
- Las metricas Ethernet, IP y Firewall son simuladas.
- Algunas ramas X_SARA son extensiones propias del laboratorio.
- La disponibilidad real de parametros TR-181 dependera del fabricante y firmware del CPE.

---

## 9. Conclusion

El laboratorio simulado queda cerrado y validado para la fase actual del TFG.

Se ha conseguido:

- construir una arquitectura reproducible basada en Docker;
- generar telemetria TR-181/DataElements;
- aproximar un perfil BulkData TelcoX;
- simular una red EasyMesh con gateway, satelite y clientes;
- reproducir escenarios controlados;
- analizar QoE por cliente;
- detectar eventos como HighInterference, HighUtilization, BackhaulDegraded, APFailure y ClientSteering;
- exponer metricas a Prometheus;
- visualizar resultados en Grafana;
- generar evidencias finales.

La siguiente fase consiste en preparar un laboratorio separado para dispositivos reales, donde se validara que parametros TR-181 expone realmente el CPE fisico y si puede configurarse un envio BulkData HTTP/POST real hacia un collector.
