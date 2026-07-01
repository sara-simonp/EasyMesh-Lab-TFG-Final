# Matriz de cumplimiento BulkData TelcoX

Este documento compara las metricas y ramas TR-181 solicitadas en el documento "IOMetrics TelcoX - BulkData Functional Overview" con las metricas generadas por el simulador EasyMesh-Lab.

---

## 1. Objetivo

El objetivo es comprobar si el laboratorio simulado genera las metricas necesarias para aproximarse al perfil BulkData definido por TelcoX.

El laboratorio no implementa un agente BulkData real con envio HTTP/POST desde un CPE fisico. En su lugar, genera un payload CSV tipo TR-181/DataElements que puede ser consumido por tr069-sim, GenieACS, Prometheus y Grafana.

---

## 2. Alcance implementado

Se implementan las siguientes areas:

- configuracion simulada Device.BulkData;
- perfil Device.BulkData.Profile.1;
- parametros Parameter.*.Reference del payload;
- configuracion HTTP simulada;
- configuracion JSON simulada;
- Device.DeviceInfo ampliado;
- Device.WiFi.SSID;
- Device.WiFi.Radio directo;
- Device.WiFi.AccessPoint con AssociatedDevice;
- Device.WiFi.DataElements.Network;
- Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.STA;
- Device.Hosts.Host;
- Device.Firewall;
- Device.Ethernet.Interface;
- Device.IP.Interface;
- metricas EasyMesh/QoE especificas del TFG.

---

## 3. Matriz de cumplimiento

| Bloque TelcoX | Estado | Implementacion en EasyMesh-Lab |
|---|---|---|
| Device.BulkData.Enable | Implementado | Device.BulkData.Enable |
| Device.BulkData.Profile.1.Alias | Implementado | StatusDeviceRadio |
| Device.BulkData.Profile.1.Enable | Implementado | true |
| Device.BulkData.Profile.1.EncodingType | Implementado | JSON |
| Device.BulkData.Profile.1.Protocol | Implementado | HTTP |
| Device.BulkData.Profile.1.ReportingInterval | Implementado | 3600 |
| Device.BulkData.Profile.1.HTTP.Method | Implementado | POST |
| Device.BulkData.Profile.1.HTTP.URL | Implementado simulado | http://collector.local/bulkdata o variable BULKDATA_HTTP_URL |
| Device.BulkData.Profile.1.HTTP.UseDateHeader | Implementado | true |
| Device.BulkData.Profile.1.JSONEncoding.ReportFormat | Implementado | NameValuePair |
| Device.BulkData.Profile.1.JSONEncoding.ReportTimestamp | Implementado | Unix-Epoch |
| Device.BulkData.Profile.1.Parameter.*.Reference | Implementado | Lista completa de referencias del payload |
| Device.DeviceInfo.Description | Implementado | EasyMesh telemetry simulator for QoE lab |
| Device.RootDataModelVersion | Implementado | 2.20 |
| Device.DeviceInfo.Manufacturer | Implementado | Sara-Lab |
| Device.DeviceInfo.ManufacturerOUI | Implementado | 535241 |
| Device.DeviceInfo.ProductClass | Implementado | EasyMeshVirtualCPE |
| Device.DeviceInfo.SerialNumber | Implementado | 200001 |
| Device.DeviceInfo.SoftwareVersion | Implementado | EasyMeshNetworkSimulator |
| Device.DeviceInfo.HardwareVersion | Implementado | virtual-1 |
| Device.DeviceInfo.ModelName | Implementado | EasyMeshVirtualCPE |
| Device.DeviceInfo.UpTime | Implementado | uptime del simulador |
| Device.DeviceInfo.MemoryStatus.Free | Implementado | memoria libre simulada |
| Device.DeviceInfo.MemoryStatus.Total | Implementado | memoria total simulada |
| Device.DeviceInfo.ProcessStatus.CPUUsage | Implementado | CPU simulada |
| Device.WiFi.X_TPG_BandSteering.Enable | Implementado simulado | true |
| Device.WiFi.SSID.*.SSID | Implementado | SaraMesh-24G / SaraMesh-5G |
| Device.WiFi.SSID.*.LowerLayers | Implementado | referencia a Device.WiFi.Radio |
| Device.WiFi.Radio.*.Enable | Implementado | true/false segun estado |
| Device.WiFi.Radio.*.Status | Implementado | Up/Down |
| Device.WiFi.Radio.*.Channel | Implementado | canal por radio |
| Device.WiFi.Radio.*.OperatingChannelBandwidth | Implementado | 40MHz / 80MHz |
| Device.WiFi.Radio.*.OperatingFrequencyBand | Implementado | 2.4GHz / 5GHz |
| Device.WiFi.Radio.*.CurrentOperatingChannelBandwidth | Implementado | 40MHz / 80MHz |
| Device.WiFi.Radio.*.OperatingStandards | Implementado | 802.11n/ac/ax |
| Device.WiFi.Radio.*.SupportedStandards | Implementado | 802.11n,802.11ac,802.11ax |
| Device.WiFi.Radio.*.TransmitPower | Implementado | potencia simulada |
| Device.WiFi.Radio.*.Stats.BytesSent | Implementado | contador simulado |
| Device.WiFi.Radio.*.Stats.BytesReceived | Implementado | contador simulado |
| Device.WiFi.Radio.*.Stats.ErrorsSent | Implementado | contador simulado |
| Device.WiFi.Radio.*.Stats.ErrorsReceived | Implementado | contador simulado |
| Device.WiFi.DataElements.Network.Device.*.Radio.*.Noise | Implementado | ruido radio por AP |
| Device.WiFi.DataElements.Network.Device.*.Radio.*.Utilization | Implementado | utilizacion radio por AP |
| Device.WiFi.AccessPoint.*.Status | Implementado | Enabled/Disabled |
| Device.WiFi.AccessPoint.*.Enable | Implementado | true/false |
| Device.WiFi.AccessPoint.*.SSIDReference | Implementado | referencia a SSID |
| Device.WiFi.AccessPoint.*.AssociatedDevice.*.MACAddress | Implementado | MAC cliente |
| Device.WiFi.AccessPoint.*.AssociatedDevice.*.SignalStrength | Implementado | RSSI cliente |
| Device.WiFi.AccessPoint.*.AssociatedDevice.*.LastDataDownlinkRate | Implementado | tasa bajada |
| Device.WiFi.AccessPoint.*.AssociatedDevice.*.LastDataUplinkRate | Implementado | tasa subida |
| Device.WiFi.AccessPoint.*.AssociatedDevice.*.OperatingStandard | Implementado | 802.11ax |
| Device.WiFi.AccessPoint.*.AssociatedDevice.*.Stats.RetryCount | Implementado | retry count estimado |
| Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.STANumberOfEntries | Implementado | numero de STA por BSS |
| Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.STA.*.MACAddress | Implementado | MAC del cliente |
| Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.STA.*.BytesSent | Implementado | bytes enviados |
| Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.STA.*.BytesReceived | Implementado | bytes recibidos |
| Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.STA.*.LastConnectTime | Implementado | timestamp simulado |
| Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.SSID | Implementado | SSID por BSS |
| Device.Hosts.Host.*.PhysAddress | Implementado | MAC cliente |
| Device.Hosts.Host.*.IPAddress | Implementado | IP cliente |
| Device.Hosts.Host.*.ClientID | Implementado | MAC cliente |
| Device.Hosts.Host.*.HostName | Implementado | nombre cliente |
| Device.Hosts.Host.*.Active | Implementado | true/false |
| Device.Hosts.Host.*.InterfaceType | Implementado | Wi-Fi |
| Device.Firewall.Enable | Implementado | true |
| Device.Ethernet.Interface.*.Enable | Implementado simulado | true |
| Device.Ethernet.Interface.*.Status | Implementado simulado | Up |
| Device.Ethernet.Interface.*.DuplexMode | Implementado simulado | Full |
| Device.Ethernet.Interface.*.Stats.BytesReceived | Implementado simulado | contadores agregados |
| Device.Ethernet.Interface.*.Stats.BytesSent | Implementado simulado | contadores agregados |
| Device.IP.Interface.*.Enable | Implementado simulado | true |
| Device.IP.Interface.*.Status | Implementado simulado | Up |
| Device.IP.Interface.*.IPv4Address.*.IPAddress | Implementado simulado | 192.168.1.1 / 172.25.0.40 |
| Device.IP.Interface.*.Stats.BytesReceived | Implementado simulado | contadores agregados |
| Device.IP.Interface.*.Stats.BytesSent | Implementado simulado | contadores agregados |

---

## 4. Metricas adicionales especificas del TFG

Ademas del payload TelcoX, el simulador genera metricas especificas para el analisis de QoE en EasyMesh:

- Device.X_SARA_QoE.SignalStrength;
- Device.X_SARA_QoE.LatencyMs;
- Device.X_SARA_QoE.PacketLossPercent;
- Device.X_SARA_QoE.QoEScore;
- Device.X_SARA_QoE.QoEState;
- Device.X_SARA_QoE.Reason;
- Device.WiFi.DataElements.Network.Event.1.Type;
- Device.WiFi.DataElements.Network.Event.1.ClientMAC;
- Device.WiFi.DataElements.Network.Event.1.FromDevice;
- Device.WiFi.DataElements.Network.Event.1.ToDevice;
- Device.WiFi.DataElements.Network.Event.1.SteeringCount;
- Device.WiFi.DataElements.Network.Device.*.BackhaulRSSI;
- Device.WiFi.DataElements.Network.Device.*.BackhaulLatencyMs;
- Device.WiFi.DataElements.Network.Device.*.BackhaulPacketLossPercent.

Estas metricas permiten estudiar el punto ciego de visibilidad, el roaming, la degradacion de backhaul y el impacto sobre la experiencia de cliente.

---

## 5. Limitaciones

Aunque se ha ampliado el simulador para cubrir el payload TelcoX, existen limitaciones:

- No se realiza un envio HTTP POST real desde un CPE fisico.
- El collector HTTP se representa como configuracion simulada.
- Los contadores Ethernet/IP son agregados simulados.
- Los parametros WiFi proceden de un modelo de simulacion, no de radiofrecuencia real.
- La disponibilidad real de parametros dependera del fabricante, modelo y firmware del CPE.
- En dispositivos reales sera necesario validar el arbol TR-181 soportado mediante GetParameterNames o equivalente.

---

## 6. Conclusion

Tras la ampliacion, el laboratorio EasyMesh-Lab queda alineado funcionalmente con el payload BulkData TelcoX a nivel de modelo de datos TR-181.

El laboratorio simulado permite validar:

- seleccion de metricas;
- estructura del payload;
- correlacion por cliente;
- metricas WiFi y DataElements;
- metricas de hosts;
- metricas de radio y AP;
- metricas de interfaces IP/Ethernet;
- eventos EasyMesh;
- QoE de cliente;
- pipeline de observabilidad con Prometheus y Grafana.

La fase con dispositivos reales debera validar que estas rutas existen en el CPE fisico y adaptar las rutas propietarias cuando el fabricante no exponga la rama estandar completa.
