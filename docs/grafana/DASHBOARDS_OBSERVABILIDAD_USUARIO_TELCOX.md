# Dashboards de observabilidad de usuario y TelcoX

## Objetivo

Se mantienen las métricas TelcoX/TR-181, pero se añaden KPIs de observabilidad de usuario para que la demo sea comprensible.

## Dashboards añadidos

### 1. EasyMesh - Observabilidad de Usuario y QoE

Vista principal para empresa/tutor. Paneles: escenario activo, QoE media, peor QoE, clientes degradados, evento actual, QoE por cliente, SignalStrength/RSSI, latencia, pérdida, throughput, tasas de enlace, retry y tabla de clientes.

### 2. EasyMesh - TelcoX/TR-181 técnico + KPIs usuario

Vista técnica separando métricas TelcoX/TR-181, contexto de laboratorio y KPIs derivados de usuario.

## Importación

```powershell
cd C:\EasyMesh-Lab
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\importar-dashboards-observabilidad-usuario.ps1"
```

## Secuencia de prueba

```powershell
cd C:\EasyMesh-Lab
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\ejecutar-secuencia-escenarios-grafana.ps1"
```

## Exportación CSV

```powershell
cd C:\EasyMesh-Lab
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\exportar-observabilidad-usuario-escenarios.ps1"
```
