# Metrica TelcoX estricta para el laboratorio EasyMesh

## Criterio aplicado

La exportacion TR-181 usada por tr069-sim y GenieACS queda limitada al perfil TelcoX BulkData:

- configuracion `Device.BulkData`
- perfil `Device.BulkData.Profile.1`
- las 85 referencias `Device.BulkData.Profile.1.Parameter.{i}.Reference`

Quedan fuera de la exportacion ACS/TR-069 las ramas de laboratorio que no aparecen en el documento TelcoX, por ejemplo:

- `InternetGatewayDevice.X_SARA_EasyMesh.*`
- `Device.X_SARA_QoE.*`
- `LatencyMs`
- `JitterMs`
- `PacketLossPercent`
- `QoEScore`
- `QoEState`
- eventos propietarios de escenario

Estas metricas pueden seguir existiendo como calculo interno del simulador o como KPI derivado en Prometheus/Grafana, pero no deben presentarse como parametros TelcoX recolectados por BulkData.

## Uso por capas

- IEEE 1905.1 / EasyMesh: comunicacion conceptual controlador-agentes.
- TR-181 / DataElements: modelo normalizado de parametros a recolectar.
- TR-069 / CWMP: canal CPE virtual -> GenieACS para consultar/transportar parametros TR-181.
- BulkData: perfil que selecciona las rutas TR-181 que se reportarian periodicamente.
- Prometheus/Grafana: observabilidad dinamica; si se muestran QoE o latencia, deben etiquetarse como KPI derivados del laboratorio.

## Referencias permitidas

Ver `docs/tr181/telcox_allowed_references.csv`.
