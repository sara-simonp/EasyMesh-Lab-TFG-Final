# Laboratorio real con TP-Link HX141 y GenieACS

## Objetivo

Configurar un HX141 como Controller EasyMesh, registrarlo como CPE TR-069 en GenieACS y descubrir qué parámetros TR-181 expone realmente su firmware. El resultado se puede extraer en JSON y CSV sin reutilizar los datos artificiales del simulador.

> El soporte declarado de TR-181 no garantiza que el firmware publique `Device.WiFi.DataElements.*` ni todos los KPI EasyMesh. Primero hay que descubrir el árbol real del dispositivo; también pueden aparecer ramas `Device.WiFi.*`, `InternetGatewayDevice.*` o extensiones `X_TP_*`.

## Topología recomendada

```text
Internet/ONT
    |
HX141-CTRL (Controller y gateway)
    |-- HX141-AGENT-1
    |-- HX141-AGENT-2
    `-- PC Docker Host (GenieACS)
```

Ejemplo de direccionamiento:

- HX141-CTRL: `192.168.50.1`
- PC Docker Host: `192.168.50.10` (IP reservada o estática)
- GenieACS CWMP: `http://192.168.50.10:7548/`
- GenieACS UI: `http://localhost:3010`
- GenieACS NBI: `http://localhost:7558`

Los puertos terminados en 8/10 evitan colisiones con el laboratorio simulado. Si no se ejecuta el laboratorio simulado, también se pueden remapear a 7547/7557/3000.

## 1. Preparar el HX141 Controller

1. Restablecer el HX141 que será principal si conserva una configuración de Agent.
2. Conectar el puerto WAN/LAN al ONT/router de acceso y un PC a un puerto LAN.
3. Entrar en la WebGUI indicada en la etiqueta del equipo o usar Aginet.
4. Completar la configuración inicial en modo **Router** (o **AP** si otro router mantiene la salida a Internet).
5. En EasyMesh, seleccionar el rol **Controller/Main device** y habilitar EasyMesh.
6. Configurar SSID, seguridad y contraseña; guardar y reiniciar si el firmware lo solicita.
7. Añadir los otros HX141 como **Agent/Satellite**, primero cerca del Controller. Se puede usar el flujo EasyMesh de la WebGUI/Aginet o WPS; después se valida cada nodo en la topología.

Los nombres exactos de los menús cambian según la versión regional y el firmware administrado por el ISP.

## 2. Arrancar GenieACS para el equipo real

Desde la raíz del repositorio:

```powershell
docker compose -f .\labs\docker-dispositivos-reales\docker-compose.real-hx141-core.yml up -d --build
docker compose -f .\labs\docker-dispositivos-reales\docker-compose.real-hx141-core.yml ps
```

Comprobar desde otro equipo de la LAN que `http://IP_DEL_PC:7548/` es alcanzable. Una respuesta HTTP de error o método no permitido sigue demostrando conectividad con el listener CWMP; no es una página web de usuario.

En Windows, permitir TCP de entrada a `7548` en el perfil de red privada. No publicar CWMP, NBI ni la UI directamente en Internet.

## 3. Apuntar el HX141 a GenieACS

En el menú de gestión remota/TR-069/CWMP del HX141:

- Enable CWMP/TR-069: `On`
- ACS URL: `http://192.168.50.10:7548/` (sustituir por la IP real del PC)
- ACS username/password: vacíos para la primera prueba, salvo que se configure autenticación en GenieACS
- Periodic Inform: `On`
- Periodic Inform Interval: `60` segundos durante las pruebas; después usar 300 s o más
- Connection Request username/password: credenciales locales exclusivas si el firmware las solicita
- Interface: la interfaz WAN/Internet que tenga alcance hacia el PC

Guardar y reiniciar el HX141. El ACS URL siempre debe usar la IP LAN del PC, nunca `localhost`, el nombre del contenedor ni una IP de la red interna de Docker.

Algunos firmwares de operador ocultan o bloquean el menú CWMP. En ese caso se necesita firmware/perfil de ISP, AginetConfig o acceso de servicio autorizado; GenieACS no puede forzar el alta si el CPE no permite cambiar su ACS URL.

## 4. Validar el registro

Abrir `http://localhost:3010`. El HX141 debe aparecer en **Devices** y `_lastInform` debe actualizarse.

También se puede comprobar por PowerShell:

```powershell
Invoke-RestMethod http://localhost:7558/devices/ |
  Select-Object _id, _lastInform
```

Si no aparece, revisar:

```powershell
docker logs hx141-genieacs-acs --since 10m
Test-NetConnection 192.168.50.10 -Port 7548
```

El segundo comando prueba la escucha desde el propio PC; para descartar firewall debe repetirse desde otro host de la LAN.

## 5. Descubrir y extraer TR-181

En el primer registro, solicitar un descubrimiento completo y exportar el resultado:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\exportar-tr181-hx141.ps1 -Refresh
```

Si hay más de un dispositivo, el script muestra sus IDs. Repetir indicando el del HX141:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\exportar-tr181-hx141.ps1 `
  -DeviceId "ID_MOSTRADO_POR_GENIEACS" `
  -Refresh
```

Los ficheros se guardan en `tfg-resultados/hx141-real/tr181/`:

- JSON: copia completa del documento GenieACS.
- CSV: una fila por parámetro, con valor, tipo, atributo writable y timestamp.

El resumen final cuenta por separado:

- `Device.*` (TR-181 Device:2)
- `InternetGatewayDevice.*` (TR-098 o modelo legado)
- `Device.WiFi.*`
- `Device.WiFi.DataElements.*`

Para buscar las métricas más útiles:

```powershell
Import-Csv .\tfg-resultados\hx141-real\tr181\hx141-*.csv |
  Where-Object Parameter -Match 'WiFi|Radio|AccessPoint|AssociatedDevice|SignalStrength|Noise|Utilization|Bytes|Packets|Errors|Retry|DataElements' |
  Sort-Object Parameter |
  Format-Table -AutoSize
```

No conviene conectar todavía el exporter QoE del simulador: está diseñado para un ID virtual y para `Device.WiFi.DataElements.Network`. Después del primer CSV real se debe crear un mapeo HX141 basado únicamente en las ramas confirmadas.

## 6. Criterio de éxito

La integración básica está conseguida cuando:

1. el HX141 figura como Controller y los Agent aparecen en su topología EasyMesh;
2. GenieACS recibe Inform periódicos del HX141;
3. el refresh descubre al menos `Device.*` o `InternetGatewayDevice.*`;
4. el CSV contiene parámetros WiFi reales y sus timestamps cambian tras una nueva consulta.

Que no aparezca `Device.WiFi.DataElements.*` es un resultado válido del ensayo: significa que esa rama no está publicada por ese firmware a través de CWMP, aunque el producto anuncie compatibilidad TR-181.
