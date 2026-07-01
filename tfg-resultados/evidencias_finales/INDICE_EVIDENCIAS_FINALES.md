# Indice de evidencias finales del laboratorio

Este documento describe el contenido de la carpeta:

tfg-resultados/evidencias_finales/

La finalidad de estas evidencias es demostrar que el laboratorio simulado EasyMesh-Lab esta levantado, genera telemetria, expone metricas y permite validar escenarios de QoE mediante TR-181/DataElements, Prometheus y Grafana.

---

## 1. Estructura de evidencias

La carpeta de evidencias finales se organiza en los siguientes bloques:

| Carpeta | Contenido | Finalidad |
|---|---|---|
| 01_docker | Estado de contenedores y red Docker | Demostrar que el laboratorio esta desplegado |
| 02_simulador | Health, escenarios, estado y metricas del simulador | Demostrar que el simulador funciona |
| 03_genieacs | Dispositivos GenieACS y metricas del exporter | Demostrar integracion TR-069/ACS |
| 04_prometheus | Targets y queries Prometheus | Demostrar que Prometheus recoge metricas |
| 05_grafana | Export del dashboard | Demostrar visualizacion del laboratorio |
| 06_csv | Listado de CSV y validacion BulkData | Demostrar evidencias TR-181/DataElements |
| 07_logs | Logs de servicios | Apoyo para trazabilidad y depuracion |

---

## 2. Evidencias Docker

Ruta:

tfg-resultados/evidencias_finales/01_docker/

Archivos esperados:

- docker_ps.txt
- docker_network_inspect.json

Estos archivos demuestran que los contened trazabilidad y depuracion |

---

## 2. Evidencias Docker

Ruta:

tfg-resultados/evidencias_finales/01_docker/

Archivos esperados:

- docker_ps.txt
- docker_network_inspect.json

Estos archivos demuestran que los contenedores principales del laboratorio estan levantados y conectados a la red Docker del proyecto.

---

## 3. Evidencias del simulador

Ruta:

tfg-resultados/evidencias_finales/02_simulador/

Archivos esperados:

- health.txt
- scenarios.json
- state_actual.json
- metrics_actual.txt

Estos archivos demuestran que el simulador EasyMesh responde correctamente, expone escenarios, mantiene un estado de red y publica metricas Prometheus.

---

## 4. Evidencias GenieACS

Ruta:

tfg-resultados/evidencias_finales/03_genieacs/

Archivos esperados:

- genieacs_devices.json
- genieacs_qoe_exporter_metrics.txt

Estos archivos documentan la parte asociada a TR-069/GenieACS y al exporter QoE.

---

## 5. Evidencias Prometheus

Ruta:

tfg-resultados/evidencias_finales/04_prometheus/

Archivos esperados:

- targets.json
- query_easymesh_simulator_up.json
- query_client_qoe_score.json
- query_client_signal.json
- query_event_info.json
- query_csv_exporter_up.json
- query_genieacs_up.json

Estos archivos demuestran que Prometheus recoge metricas del simulador, del exporter CSV y del exporter asociado a GenieACS/QoE.

---

## 6. Evidencias Grafana

Ruta:

tfg-resultados/evidencias_finales/05_grafana/

Archivo esperado:

- dashboard_tfg_easymesh_final.json

Este archivo contiene la exportacion del dashboard de Grafana usado para visualizar el laboratorio.

---

## 7. Evidencias CSV y BulkData

Ruta:

tfg-resultados/evidencias_finales/06_csv/

Archivos esperados:

- listado_csv.txt
- listado_state_json.txt
- listado_resumenes.txt
- validacion_bulkdata_telcox.txt

Estos archivos demuestran que existen CSV historicos de escenarios, capturas JSON, resumenes y parametros BulkData/TelcoX dentro del modelo TR-181 generado por el simulador.

---

## 8. Logs finales

Ruta:

tfg-resultados/evidencias_finales/07_logs/

Archivos esperados:

- logs_easymesh_network_simulator.txt
- logs_tr069_sim.txt
- logs_genieacs_acs.txt
- logs_genieacs_qoe_exporter.txt
- logs_prometheus.txt
- logs_grafana.txt
- logs_csv_prometheus_exporter.txt

Estos logs permiten justificar que los servicios estaban funcionando durante la captura final de evidencias.

---

## 9. Conclusion

La carpeta de evidencias finales permite acreditar que el laboratorio simulado EasyMesh-Lab esta operativo y que se han validado las rutas principales de observabilidad:

- simulador EasyMesh;
- generacion TR-181/DataElements;
- aproximacion BulkData/TelcoX;
- exportacion de metricas Prometheus;
- visualizacion Grafana;
- integracion TR-069/GenieACS;
- ejecucion de escenarios controlados;
- analisis QoE por cliente.

Estas evidencias complementan los documentos de validacion de escenarios, matriz BulkData/TelcoX y cierre del laboratorio simulado.
