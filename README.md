# EasyMesh Lab — Monitorización QoE con TR-069, TR-181, Prometheus y Grafana

Repositorio del laboratorio desarrollado para el TFG **“Monitorización de Experiencia de Cliente en redes WiFi EasyMesh”**.

El objetivo del proyecto es construir un entorno reproducible basado en Docker para simular una red WiFi EasyMesh residencial, generar telemetría estructurada tipo TR-181/DataElements, integrarla con GenieACS mediante TR-069 y visualizar indicadores de experiencia de cliente mediante Prometheus y Grafana.

---

## 1. Objetivo del laboratorio

El laboratorio permite analizar la experiencia de cliente en una red WiFi distribuida formada por un gateway principal, un punto de acceso satélite y varios clientes WiFi.

El sistema reproduce escenarios controlados como:

* funcionamiento normal;
* cobertura degradada;
* interferencias;
* saturación de radio;
* roaming;
* degradación del backhaul;
* fallo de un punto de acceso;
* escenario mixto.

Para cada escenario se generan métricas de:

* RSSI;
* SNR;
* MCS;
* throughput;
* latencia;
* jitter;
* pérdida de paquetes;
* retry rate;
* utilización de radio;
* estado del backhaul;
* eventos EasyMesh;
* puntuación QoE.

---

## 2. Alcance del simulador

El componente principal del laboratorio es un simulador de comportamiento y telemetría EasyMesh.

El simulador **no implementa una certificación EasyMesh real**, ni el plano de control completo IEEE 1905.1, ni una capa física WiFi exacta. Su función es generar telemetría coherente y reproducible para estudiar cómo podría monitorizarse la experiencia de usuario en una red EasyMesh mediante TR-181, GenieACS, Prometheus y Grafana.

Por tanto, el laboratorio debe interpretarse como:

> Simulador de telemetría EasyMesh orientado a QoE y validación de pipeline de observabilidad.

Y no como:

> Implementación certificada completa de EasyMesh.

---

## 3. Arquitectura general

La arquitectura final del laboratorio es:

```text
easymesh-network-simulator
 ├── /state
 ├── /metrics
 ├── /scenarios
 ├── /set?scenario=...
 └── data_model_easymesh.csv
          │
          ├── tr069-sim
          │       └── GenieACS
          │              └── genieacs-qoe-exporter
          │                       └── Prometheus
          │                              └── Grafana
          │
          └── csv-prometheus-exporter
                  └── Prometheus
                         └── Grafana
```

El laboratorio tiene tres rutas de observabilidad:

1. **Simulador directo → Prometheus → Grafana**

   Métricas `easymesh_sim_*` generadas directamente por el simulador.

2. **CSV TR-181 histórico → CSV exporter → Prometheus → Grafana**

   Métricas `easymesh_csv_*` generadas a partir de CSV guardados por escenario.

3. **TR-069 / GenieACS → QoE exporter → Prometheus → Grafana**

   Métricas `easymesh_*` obtenidas desde los parámetros cargados en GenieACS.

---

## 4. Componentes principales

### 4.1 Simulador EasyMesh final

Ruta:

```text
simulator/easymesh-network-simulator/
```

Archivos principales:

```text
simulator/easymesh-network-simulator/app.py
simulator/easymesh-network-simulator/Dockerfile
```

Servicio Docker:

```text
easymesh-network-simulator
```

Puerto:

```text
9200
```

Endpoints:

```text
http://localhost:9200/state
http://localhost:9200/metrics
http://localhost:9200/scenarios
http://localhost:9200/set?scenario=normal
http://localhost:9200/set?scenario=coverage
http://localhost:9200/set?scenario=interference
http://localhost:9200/set?scenario=saturation
http://localhost:9200/set?scenario=roaming
http://localhost:9200/set?scenario=backhaul_degraded
http://localhost:9200/set?scenario=ap_failure
http://localhost:9200/set?scenario=mixed
```

Archivos generados por el simulador:

```text
tr069-data/data_model_easymesh.csv
tr069-data/easymesh_simulator_state.json
tr069-data/easymesh_simulator_summary.txt
```

---

### 4.2 GenieACS

Servicio Docker:

```text
genieacs-acs
```

URLs principales:

```text
GenieACS UI:    http://localhost:3000
GenieACS NBI:   http://localhost:7557/devices
GenieACS CWMP:  http://localhost:7547
```

GenieACS actúa como ACS para gestionar el CPE virtual y almacenar los parámetros recibidos mediante TR-069.

---

### 4.3 Simulador TR-069

Servicio Docker:

```text
tr069-sim
```

Función:

```text
Lee el CSV TR-181 generado por el simulador y lo expone hacia GenieACS como dispositivo CWMP.
```

Dispositivo virtual:

```text
535241-EasyMeshVirtualCPE-200001
```

---

### 4.4 Exporter QoE de GenieACS

Ruta:

```text
monitoring/qoe-exporter/
```

Servicio Docker:

```text
genieacs-qoe-exporter
```

Puerto:

```text
9108
```

Endpoint:

```text
http://localhost:9108/metrics
```

Este exporter consulta GenieACS y expone métricas Prometheus relacionadas con:

* estado de GenieACS;
* número de agentes EasyMesh;
* número de clientes;
* RSSI de cliente;
* utilización de radio;
* backhaul;
* eventos;
* estado QoE.

---

### 4.5 Prometheus

Servicio Docker:

```text
prometheus-monitoring
```

URL:

```text
http://localhost:9090
```

Archivo de configuración:

```text
monitoring/prometheus/prometheus.yml
```

Targets principales:

```text
easymesh-network-simulator:9200
csv-prometheus-exporter:9210
genieacs-qoe-exporter:9108
```

---

### 4.6 Grafana

Servicio Docker:

```text
grafana-monitoring
```

URL:

```text
http://localhost:3001
```

Credenciales por defecto:

```text
admin / admin
```

Dashboard principal:

```text
TFG EasyMesh - Simulador final TR-181 TR-069 QoE
```

Script de creación del dashboard:

```text
crear_dashboard_grafana_tfg.ps1
```

Dashboard exportado:

```text
monitoring/grafana/dashboards/tfg_easymesh_dashboard_final.json
```

---

### 4.7 CSV Prometheus Exporter

Ruta:

```text
tools/csv-exporter/
```

Servicio Docker:

```text
csv-prometheus-exporter
```

Puerto:

```text
9210
```

Endpoint:

```text
http://localhost:9210/metrics
```

Función:

```text
Lee los CSV históricos guardados en tfg-resultados/simulador/csv y los transforma en métricas Prometheus.
```

Métricas principales:

```text
easymesh_csv_exporter_up
easymesh_csv_snapshots_total
easymesh_csv_latest_snapshot_timestamp_seconds
easymesh_csv_tr181_numeric_value
easymesh_csv_tr181_info
easymesh_csv_prometheus_metric_value
```

---

## 5. Estructura del repositorio

Estructura principal:

```text
EasyMesh-Lab/
│
├── docker-compose.yml
├── docker-compose.monitoring.yml
├── docker-compose.simulator-final-local.yml
├── docker-compose.csv-exporter.yml
├── docker-compose.prometheus-local.yml
│
├── simulator/
│   └── easymesh-network-simulator/
│       ├── app.py
│       └── Dockerfile
│
├── tr069-sim/
│   ├── Dockerfile
│   └── ...
│
├── genieacs/
│   ├── Dockerfile
│   ├── supervisord.conf
│   └── config/
│
├── monitoring/
│   ├── prometheus/
│   │   └── prometheus.yml
│   ├── grafana/
│   │   ├── dashboards/
│   │   └── provisioning/
│   └── qoe-exporter/
│       ├── app.py
│       └── Dockerfile
│
├── tools/
│   └── csv-exporter/
│       └── csv_exporter.py
│
├── tr069-data/
│   ├── data_model_easymesh.csv
│   ├── easymesh_simulator_state.json
│   └── easymesh_simulator_summary.txt
│
├── tfg-resultados/
│   ├── scripts/
│   ├── simulador/
│   │   ├── csv/
│   │   ├── capturas/
│   │   └── resumen/
│   └── evidencias/
│
├── pag-web/
│   └── index.html
│
└── README.md
```

---

## 6. Puesta en marcha del laboratorio

### 6.1 Requisitos

* Windows 10/11 o Linux.
* Docker Desktop o Docker Engine.
* Docker Compose.
* PowerShell.
* Git.

---

### 6.2 Crear red Docker externa si no existe

```powershell
docker network create `
  --driver bridge `
  --subnet 172.25.0.0/24 `
  --gateway 172.25.0.1 `
  easymesh-lab_easymesh-net
```

Si la red ya existe, Docker mostrará un mensaje de que ya está creada.

---

### 6.3 Levantar el laboratorio completo

Desde la raíz del repositorio:

```powershell
cd C:\EasyMesh-Lab

docker compose `
  -f docker-compose.yml `
  -f docker-compose.monitoring.yml `
  -f docker-compose.simulator-final-local.yml `
  -f docker-compose.tr069-local.yml `
  -f docker-compose.csv-exporter.yml `
  -f docker-compose.prometheus-local.yml `
  -f docker-compose.web-local.yml `
  up -d --build
```

---

### 6.4 Comprobar contenedores

```powershell
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

Servicios esperados:

```text
mongo-db
redis-cache
genieacs-acs
tr069-sim
easymesh-network-simulator
genieacs-qoe-exporter
csv-prometheus-exporter
prometheus-monitoring
grafana-monitoring
pag-web
```

---

## 7. Uso del simulador

### 7.1 Ver escenarios disponibles

```powershell
curl.exe http://localhost:9200/scenarios
```

---

### 7.2 Ejecutar escenario normal

```powershell
curl.exe "http://localhost:9200/set?scenario=normal"
Start-Sleep -Seconds 20
curl.exe http://localhost:9200/state
```

---

### 7.3 Ejecutar escenario de interferencia

```powershell
curl.exe "http://localhost:9200/set?scenario=interference"
Start-Sleep -Seconds 20
curl.exe http://localhost:9200/state
```

---

### 7.4 Ejecutar escenario de saturación

```powershell
curl.exe "http://localhost:9200/set?scenario=saturation"
Start-Sleep -Seconds 20
curl.exe http://localhost:9200/state
```

---

### 7.5 Ejecutar escenario de roaming

```powershell
curl.exe "http://localhost:9200/set?scenario=roaming"
Start-Sleep -Seconds 90
curl.exe http://localhost:9200/state
```

El roaming depende de condiciones de RSSI. El evento `ClientSteering` aparece cuando el AP alternativo tiene una señal suficientemente mejor que el AP actual.

---

## 8. Guardar evidencias por escenario

Script:

```text
tfg-resultados/scripts/guardar-ejecucion-simulador.ps1
```

Ejemplo:

```powershell
cd C:\EasyMesh-Lab

powershell.exe -ExecutionPolicy Bypass -File "C:\EasyMesh-Lab\tfg-resultados\scripts\guardar-ejecucion-simulador.ps1" -Scenario interference -WaitSeconds 30
```

Esto genera:

```text
tfg-resultados/simulador/csv/data_model_easymesh_interference_<fecha>.csv
tfg-resultados/simulador/csv/metricas_prometheus_interference_<fecha>.csv
tfg-resultados/simulador/capturas/state_interference_<fecha>.json
tfg-resultados/simulador/resumen/summary_interference_<fecha>.txt
```

---

## 9. Consultas Prometheus principales

### 9.1 Simulador activo

```promql
easymesh_simulator_up
```

### 9.2 Escenario actual

```promql
easymesh_sim_scenario_info
```

### 9.3 RSSI de MOVIL_SARA

```promql
easymesh_sim_client_signal_dbm{client="MOVIL_SARA"}
```

### 9.4 QoE de MOVIL_SARA

```promql
easymesh_sim_client_qoe_score{client="MOVIL_SARA"}
```

### 9.5 Latencia de MOVIL_SARA

```promql
easymesh_sim_client_latency_ms{client="MOVIL_SARA"}
```

### 9.6 Jitter de MOVIL_SARA

```promql
easymesh_sim_client_jitter_ms{client="MOVIL_SARA"}
```

### 9.7 Pérdida de paquetes

```promql
easymesh_sim_client_packet_loss_percent{client="MOVIL_SARA"}
```

### 9.8 Utilización radio

```promql
easymesh_sim_radio_utilization_percent
```

### 9.9 RSSI del backhaul

```promql
easymesh_sim_backhaul_rssi_dbm
```

### 9.10 Eventos EasyMesh

```promql
easymesh_sim_event_info
```

---

## 10. Consultas CSV TR-181

### 10.1 CSV exporter activo

```promql
easymesh_csv_exporter_up
```

### 10.2 Número de CSV guardados

```promql
easymesh_csv_snapshots_total
```

### 10.3 QoE desde CSV TR-181

```promql
easymesh_csv_tr181_numeric_value{parameter="Device.X_SARA_QoE.QoEScore"}
```

### 10.4 RSSI desde CSV TR-181

```promql
easymesh_csv_tr181_numeric_value{parameter="Device.X_SARA_QoE.SignalStrength"}
```

### 10.5 Latencia desde CSV TR-181

```promql
easymesh_csv_tr181_numeric_value{parameter="Device.X_SARA_QoE.LatencyMs"}
```

### 10.6 Eventos desde CSV TR-181

```promql
easymesh_csv_tr181_info{parameter=~".*Event.*"}
```

---

## 11. Consultas GenieACS / TR-069

### 11.1 GenieACS activo

```promql
genieacs_up
```

### 11.2 Número de agentes EasyMesh

```promql
easymesh_agent_number
```

### 11.3 Número de clientes WiFi

```promql
easymesh_total_client_number
```

### 11.4 RSSI vía GenieACS

```promql
easymesh_client_signal_strength_dbm
```

### 11.5 QoE vía GenieACS

```promql
easymesh_client_qoe_state
```

### 11.6 Utilización radio vía GenieACS

```promql
easymesh_radio_utilization_avg_percent
```

### 11.7 Backhaul vía GenieACS

```promql
easymesh_backhaul_rssi_dbm
```

---

## 12. Grafana

Abrir Grafana:

```text
http://localhost:3001
```

Credenciales:

```text
admin / admin
```

Crear dashboard automáticamente:

```powershell
cd C:\EasyMesh-Lab

powershell.exe -ExecutionPolicy Bypass -File "C:\EasyMesh-Lab\crear_dashboard_grafana_tfg.ps1"
```

Dashboard esperado:

```text
TFG EasyMesh - Simulador final TR-181 TR-069 QoE
```

---

## 13. Evidencias recomendadas para el TFG

Además de los CSV, se recomienda recoger:

```text
1. Captura de docker ps.
2. Captura de http://localhost:9200/state.
3. Captura de http://localhost:9200/metrics.
4. Captura de http://localhost:9090/targets.
5. Captura de Prometheus con easymesh_sim_client_qoe_score.
6. Captura de Prometheus con easymesh_csv_tr181_numeric_value.
7. Captura de GenieACS con el dispositivo 535241-EasyMeshVirtualCPE-200001.
8. Captura de parámetros Device.WiFi.DataElements.Network en GenieACS.
9. Captura del dashboard Grafana completo.
10. Logs de easymesh-network-simulator.
11. Logs de tr069-sim.
12. Logs de genieacs-acs.
13. Logs de genieacs-qoe-exporter.
14. JSON exportado del dashboard Grafana.
15. JSON de estado por escenario.
```

---

## 14. Comandos de validación rápida

### 14.1 Estado del simulador

```powershell
curl.exe http://localhost:9200/state
```

### 14.2 Métricas del simulador

```powershell
curl.exe http://localhost:9200/metrics | findstr /i "easymesh_sim"
```

### 14.3 Targets Prometheus

```powershell
curl.exe "http://localhost:9090/api/v1/targets" | findstr /i "easymesh csv genieacs up"
```

### 14.4 CSV exporter

```powershell
curl.exe http://localhost:9210/metrics | findstr /i "easymesh_csv"
```

### 14.5 QoE exporter GenieACS

```powershell
curl.exe http://localhost:9108/metrics | findstr /i "genieacs_up easymesh"
```

---

## 15. Estado actual del proyecto

El laboratorio simulado ya dispone de:

* simulador EasyMesh con escenarios dinámicos;
* generación de CSV TR-181/DataElements;
* generación de métricas Prometheus directas;
* integración con tr069-sim;
* integración con GenieACS;
* exporter QoE desde GenieACS;
* exporter de CSV históricos;
* Prometheus;
* Grafana;
* dashboard automatizado;
* scripts de captura de evidencias por escenario.

Pendiente para cierre del TFG:

* revisar CSV finales de cada escenario;
* recoger evidencias visuales;
* exportar dashboard final;
* documentar resultados;
* preparar laboratorio separado para dispositivos reales;
* redactar memoria final.

---

## 16. Laboratorio futuro con dispositivos reales

El laboratorio actual está orientado a simulación. Para pruebas con equipos reales se propone crear un laboratorio Docker separado en:

```text
labs/docker-dispositivos-reales/
```

En ese laboratorio no se usará el simulador como fuente principal. El flujo será:

```text
CPE/router real
    → TR-069/CWMP
    → GenieACS
    → exporter
    → Prometheus
    → Grafana
```

El objetivo será comparar qué parámetros TR-181 existen realmente en los equipos físicos y cuáles han sido simulados en el laboratorio actual.
