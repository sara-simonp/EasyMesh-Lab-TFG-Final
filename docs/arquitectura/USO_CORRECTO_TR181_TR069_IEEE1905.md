# Uso correcto de IEEE 1905.1, TR-181 y TR-069 en el laboratorio EasyMesh

## 1. Idea principal

El laboratorio separa tres conceptos que no deben mezclarse:

- IEEE 1905.1 / EasyMesh: comunicacion interna entre controlador y agentes.
- TR-181 / DataElements: modelo de datos que representa las metricas y el estado de la red.
- TR-069 / CWMP: protocolo de gestion remota entre un CPE y un ACS, usado para transportar o consultar parametros del modelo de datos.

## 2. IEEE 1905.1 / EasyMesh

IEEE 1905.1 y la especificacion Multi-AP/EasyMesh corresponden a la comunicacion interna de la red mesh.

En una red real, esta capa conecta:

- controlador EasyMesh
- agentes EasyMesh
- radios
- clientes asociados
- enlaces backhaul

Esta capa sirve para intercambiar informacion de topologia, metricas de enlace, eventos de clientes, steering, roaming y estado de los agentes.

En el laboratorio, esta parte se representa mediante:

- easymesh-network-simulator

El simulador no implementa una pila certificada IEEE 1905.1 completa. Su funcion es reproducir de forma controlada los efectos observables de una red EasyMesh: cobertura, interferencia, saturacion, roaming, degradacion de backhaul y fallo de AP.

## 3. TR-181 / DataElements

TR-181 no es un protocolo de comunicacion. Es un modelo de datos.

En este proyecto, TR-181 sirve para convertir el estado interno de la red EasyMesh en parametros normalizados que puedan ser consultados por sistemas de gestion y monitorizacion.

Ejemplos:

- Device.WiFi.DataElements.Network.Device.1.Radio.1.Utilization
- Device.WiFi.DataElements.Network.Device.1.STA.2.SignalStrength
- Device.WiFi.AccessPoint.1.AssociatedDevice.2.SignalStrength
- Device.X_SARA_QoE.QoEScore
- Device.X_SARA_QoE.QoEState
- InternetGatewayDevice.X_SARA_EasyMesh.ScenarioId
- InternetGatewayDevice.X_SARA_EasyMesh.Event.1.Type

En el laboratorio, el modelo TR-181 se materializa en:

- tr069-data/data_model_easymesh.csv

Este fichero actua como fotografia estructurada del estado EasyMesh en formato de parametros.

## 4. TR-069 / CWMP

TR-069 es el protocolo de gestion remota entre CPE y ACS.

En el laboratorio, no se usa TR-069 entre controlador y agentes. Esa comunicacion pertenece a la capa EasyMesh/IEEE 1905.1.

TR-069 se usa entre:

- tr069-sim
- genieacs-acs

tr069-sim representa un CPE virtual o gateway/controlador EasyMesh desde el punto de vista de gestion. Lee el fichero TR-181 generado por el simulador y expone esos parametros a GenieACS mediante CWMP.

Flujo:

easymesh-network-simulator
    -> genera estado EasyMesh
    -> escribe modelo TR-181 en data_model_easymesh.csv
    -> tr069-sim lee ese modelo
    -> tr069-sim se conecta a GenieACS por TR-069/CWMP
    -> GenieACS muestra los parametros del CPE

## 5. Prometheus y Grafana

Prometheus y Grafana se usan para visualizacion dinamica.

No debe decirse que Grafana visualiza TR-181 directamente. Lo correcto es:

Grafana visualiza metricas Prometheus derivadas del mismo estado EasyMesh que tambien se representa en TR-181.

Por tanto, existen dos caminos:

### Camino de observabilidad

easymesh-network-simulator
    -> /metrics
    -> Prometheus
    -> Grafana

### Camino ACS/TR-069

easymesh-network-simulator
    -> data_model_easymesh.csv con parametros TR-181
    -> tr069-sim
    -> TR-069/CWMP
    -> GenieACS
    -> tcpdump/Wireshark

## 6. Frase correcta para memoria y defensa

El simulador EasyMesh reproduce el comportamiento observable de una red mesh formada por controlador, agentes y clientes. La comunicacion interna EasyMesh entre controlador y agentes se representa conceptualmente mediante IEEE 1905.1/Multi-AP. Las metricas resultantes se normalizan mediante un modelo de datos TR-181/DataElements, que permite describir topologia, radios, clientes, backhaul, eventos y QoE. Para la integracion con ACS, un CPE virtual lee ese modelo TR-181 y lo expone a GenieACS mediante TR-069/CWMP. En paralelo, las mismas metricas se exportan hacia Prometheus y Grafana para visualizacion dinamica.

## 7. Resumen

IEEE 1905.1:
- Donde: controlador <-> agentes
- Para que: control interno EasyMesh, topologia, link metrics, steering
- En el laboratorio: simulado por easymesh-network-simulator

TR-181:
- Donde: salida normalizada del estado de red
- Para que: representar metricas y parametros de forma estructurada
- En el laboratorio: data_model_easymesh.csv y parametros en GenieACS

TR-069:
- Donde: CPE virtual <-> GenieACS
- Para que: gestion remota y consulta/envio de parametros TR-181
- En el laboratorio: tr069-sim hacia genieacs-acs por puerto 7547
