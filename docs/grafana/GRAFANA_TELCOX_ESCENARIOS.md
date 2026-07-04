# Dashboard Grafana - Seguimiento TelcoX y escenarios

Este dashboard separa:

1. Paneles TelcoX/TR-181 permitidos:
   - Radio Utilization
   - Radio Noise
   - SignalStrength
   - LastDataDownlinkRate / LastDataUplinkRate
   - Radio Stats

2. Panel de control de escenario:
   - `easymesh_sim_scenario_info`
   - No es una metrica TelcoX. Solo indica que escenario se esta ejecutando.

3. Panel derivado de laboratorio:
   - latency
   - packet loss
   - QoE
   - No pertenece al perfil TelcoX estricto. Sirve para explicar la experiencia de usuario.

## Aplicacion

```powershell
cd C:\EasyMesh-Lab

Expand-Archive -Force "$env:USERPROFILE\Downloads\grafana_telcox_dashboard_patch.zip" "."

powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\importar-dashboard-telcox-escenarios.ps1"
```

## Lectura por escenario

- normal: utilization bajo, noise estable, signal alto, rates altos.
- coverage: signal baja, rates pueden bajar.
- interference: noise sube.
- saturation: utilization sube.
- roaming: cambia la etiqueta AP asociada al cliente.
- ap_failure: se observa cambio de AP/status si el simulador lo expone.
- backhaul_degraded: no tiene metrica Backhaul en TelcoX estricto; se interpreta indirectamente o en panel derivado.
