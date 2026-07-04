# Uso correcto de IEEE 1905.1, TR-181 y TR-069 en el laboratorio EasyMesh

## 1. Separacion de conceptos

El proyecto queda dividido en tres capas tecnicas:

1. **IEEE 1905.1 / EasyMesh**: comunicacion interna entre controlador EasyMesh y agentes.
2. **TR-181 / DataElements**: modelo de datos que representa las metricas observables del CPE/red.
3. **TR-069 / CWMP**: protocolo de gestion entre CPE y ACS, usado para que GenieACS consulte o reciba parametros TR-181.

## 2. IEEE 1905.1 / EasyMesh

En una red real, IEEE 1905.1/Multi-AP/EasyMesh conecta:

- controlador EasyMesh
- agentes/satelites
- topologia
- eventos de steering/roaming
- estado de radios y enlaces backhaul

En este laboratorio, `easymesh-network-simulator` no implementa una pila certificada IEEE 1905.1. Simula los efectos observables de esa capa para poder generar telemetria controlada.

## 3. TR-181

TR-181 no es el transporte. Es el arbol de parametros.

En este proyecto se usa para convertir el estado EasyMesh simulado en rutas normalizadas:

- `Device.WiFi.Radio.*`
- `Device.WiFi.AccessPoint.*`
- `Device.WiFi.DataElements.Network.Device.*`
- `Device.Hosts.Host.*`
- `Device.Ethernet.Interface.*`
- `Device.IP.Interface.*`
- `Device.DeviceInfo.*`
- `Device.BulkData.*`

El perfil estricto del proyecto solo exporta hacia ACS/TR-069 las metricas indicadas por el documento TelcoX.

## 4. TR-069 / CWMP

TR-069 no conecta agentes EasyMesh con el controlador. Esa parte es EasyMesh/IEEE 1905.1.

En el laboratorio TR-069 se usa asi:

`tr069-sim` -> `genieacs-acs`

`tr069-sim` representa un CPE virtual/gateway que lee el CSV TR-181 generado por el simulador y se comunica con GenieACS por CWMP en el puerto 7547.

## 5. Flujos del laboratorio

### Flujo EasyMesh conceptual

controlador EasyMesh <-> agentes EasyMesh  
capa conceptual: IEEE 1905.1 / Multi-AP

### Flujo ACS

easymesh-network-simulator  
-> `tr069-data/data_model_easymesh.csv`  
-> tr069-sim  
-> TR-069/CWMP  
-> GenieACS  
-> tcpdump/Wireshark

### Flujo observabilidad

easymesh-network-simulator  
-> /metrics  
-> Prometheus  
-> Grafana

## 6. Frase para memoria

El simulador reproduce el comportamiento observable de una red EasyMesh. La comunicacion interna controlador-agentes se representa conceptualmente como IEEE 1905.1/Multi-AP. Las metricas resultantes se normalizan mediante TR-181/DataElements. Para la integracion con ACS, un CPE virtual lee ese modelo TR-181 y lo expone a GenieACS mediante TR-069/CWMP. El perfil de recoleccion se limita a las metricas definidas por el documento TelcoX BulkData.
