# Laboratorio real con TP-Link HX141

## Objetivo

Este laboratorio corresponde a la fase real del TFG "Monitorización de Experiencia de Cliente en redes WiFi EasyMesh".

El objetivo es validar con dispositivos físicos TP-Link HX141 la arquitectura de observabilidad planteada en la fase simulada, sustituyendo el simulador EasyMesh y el CPE virtual por equipos reales.

## Dispositivos utilizados

- HX141-CTRL: nodo principal, controller o gateway EasyMesh.
- HX141-AGENT-1: satélite EasyMesh.
- HX141-AGENT-2: satélite EasyMesh.
- PC Docker Host: equipo donde se ejecutan GenieACS, Prometheus y Grafana.
- Cliente WiFi de prueba: dispositivo móvil o portátil usado para pruebas de roaming y QoE.

## Arquitectura

HX141-CTRL actúa como nodo principal de la red EasyMesh.

HX141-AGENT-1 y HX141-AGENT-2 se asocian como satélites EasyMesh.

El PC Docker Host ejecuta los servicios de monitorización y gestión:

- GenieACS como ACS TR-069.
- Prometheus como sistema de ingesta de métricas.
- Grafana como sistema de visualización.
- Exporter QoE para exponer métricas desde GenieACS hacia Prometheus.

## Diferencia respecto al laboratorio simulado

En la fase simulada se utilizan:

- easymesh-network-simulator.
- tr069-sim.
- CSV TR-181 generado artificialmente.

En la fase real se utilizan:

- dispositivos TP-Link HX141 físicos.
- red EasyMesh real.
- clientes WiFi reales.
- telemetría expuesta por el firmware real del dispositivo.

## Objetivo técnico

Comprobar qué parámetros TR-181 reales expone el HX141, validar si es posible registrarlo en GenieACS mediante TR-069 y comparar la visibilidad real obtenida con la telemetría simulada del laboratorio anterior.

## Topología prevista

HX141-CTRL
  ├── HX141-AGENT-1
  ├── HX141-AGENT-2
  └── PC Docker Host

El PC Docker Host debe tener una IP fija o reservada en la LAN del HX141-CTRL.

Ejemplo:

- HX141-CTRL: 192.168.50.1
- PC Docker Host: 192.168.50.10
- ACS URL: http://192.168.50.10:7547/