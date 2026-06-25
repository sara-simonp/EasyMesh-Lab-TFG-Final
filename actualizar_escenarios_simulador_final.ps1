cd C:\EasyMesh-Lab

$path = "C:\EasyMesh-Lab\pag-web\index.html"

if (!(Test-Path $path)) {
    throw "No existe el archivo: $path"
}

$backup = "C:\EasyMesh-Lab\pag-web\index_backup_escenarios_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
Copy-Item $path $backup -Force
Write-Host "Backup creado en: $backup"

$html = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

if ($html -match 'id="simulador-final-grafico"') {
    Write-Host "El bloque grafico del simulador final ya existe. No se modifica el HTML."
    exit
}

$css = @'

    /* =========================================================
       BLOQUE GRAFICO DEL SIMULADOR FINAL EN 13_ESCENARIOS
       ========================================================= */

    .sfg-card {
      margin: 24px 0;
      border: 1px solid #dbeafe;
      border-radius: 26px;
      background: linear-gradient(135deg, #ffffff, #eff6ff 45%, #f5f3ff);
      box-shadow: 0 18px 42px rgba(15,23,42,.14);
      overflow: hidden;
      color: #0f172a;
    }

    .sfg-head {
      padding: 22px 24px;
      border-bottom: 1px solid #dbeafe;
      background: rgba(255,255,255,.88);
    }

    .sfg-head h3 {
      margin: 0 0 8px;
      color: #0f172a;
      font-size: 26px;
      letter-spacing: -.03em;
    }

    .sfg-head p {
      margin: 0;
      color: #475569;
      line-height: 1.6;
    }

    .sfg-layout {
      display: grid;
      grid-template-columns: minmax(700px, 1.35fr) minmax(320px, .65fr);
    }

    .sfg-map {
      position: relative;
      min-height: 620px;
      background:
        radial-gradient(circle at 24% 38%, rgba(34,197,94,.15), transparent 24%),
        radial-gradient(circle at 76% 38%, rgba(124,58,237,.14), transparent 24%),
        linear-gradient(180deg, #f8fafc, #eef6ff);
      border-right: 1px solid #dbeafe;
      overflow: hidden;
    }

    .sfg-map::before {
      content: "";
      position: absolute;
      inset: 20px;
      border: 1px dashed rgba(100,116,139,.28);
      border-radius: 26px;
      pointer-events: none;
    }

    .sfg-lines {
      position: absolute;
      inset: 0;
      width: 100%;
      height: 100%;
      z-index: 1;
      pointer-events: none;
    }

    .sfg-line {
      fill: none;
      stroke: rgba(100,116,139,.35);
      stroke-width: 6;
      stroke-linecap: round;
      transition: .25s ease;
    }

    .sfg-line.good {
      stroke: #16a34a;
    }

    .sfg-line.warn {
      stroke: #f97316;
      stroke-dasharray: 12 9;
      animation: sfgLineFlow 1.2s linear infinite;
    }

    .sfg-line.bad {
      stroke: #ef4444;
      stroke-dasharray: 8 8;
      animation: sfgLineFlow .9s linear infinite;
    }

    .sfg-line.roam {
      stroke: #7c3aed;
      stroke-width: 7;
      stroke-dasharray: 14 10;
      animation: sfgLineFlow 1s linear infinite;
    }

    .sfg-line.off {
      opacity: .14;
    }

    @keyframes sfgLineFlow {
      to { stroke-dashoffset: -44; }
    }

    .sfg-node {
      position: absolute;
      z-index: 3;
      transform: translate(-50%, -50%);
      min-width: 160px;
      border-radius: 20px;
      padding: 13px 15px;
      background: rgba(255,255,255,.96);
      border: 1px solid #cbd5e1;
      box-shadow: 0 16px 30px rgba(15,23,42,.13);
      transition: .25s ease;
    }

    .sfg-node .kind {
      display: block;
      font-size: 11px;
      text-transform: uppercase;
      letter-spacing: .06em;
      font-weight: 900;
      color: #64748b;
      margin-bottom: 5px;
    }

    .sfg-node .name {
      font-size: 17px;
      font-weight: 900;
      color: #0f172a;
      margin-bottom: 5px;
    }

    .sfg-node .desc {
      font-size: 13px;
      color: #475569;
      line-height: 1.35;
    }

    .sfg-controller {
      left: 50%;
      top: 12%;
      border-color: #60a5fa;
    }

    .sfg-ap1 {
      left: 24%;
      top: 37%;
      border-color: #22c55e;
    }

    .sfg-ap2 {
      left: 76%;
      top: 37%;
      border-color: #a78bfa;
    }

    .sfg-client1 {
      left: 15%;
      top: 72%;
    }

    .sfg-client2 {
      left: 34%;
      top: 82%;
    }

    .sfg-client3 {
      left: 84%;
      top: 72%;
    }

    .sfg-node.warn {
      border-color: #f97316;
      box-shadow: 0 0 0 6px rgba(249,115,22,.13), 0 18px 34px rgba(249,115,22,.20);
    }

    .sfg-node.bad {
      border-color: #ef4444;
      box-shadow: 0 0 0 6px rgba(239,68,68,.13), 0 18px 34px rgba(239,68,68,.22);
    }

    .sfg-node.roam {
      border-color: #7c3aed;
      box-shadow: 0 0 0 6px rgba(124,58,237,.13), 0 18px 34px rgba(124,58,237,.22);
    }

    .sfg-signal {
      display: inline-flex;
      margin-top: 8px;
      padding: 5px 9px;
      border-radius: 999px;
      background: #dcfce7;
      color: #166534;
      font-size: 12px;
      font-weight: 900;
    }

    .sfg-signal.warn {
      background: #ffedd5;
      color: #9a3412;
    }

    .sfg-signal.bad {
      background: #fee2e2;
      color: #991b1b;
    }

    .sfg-signal.roam {
      background: #ede9fe;
      color: #5b21b6;
    }

    .sfg-stage {
      position: absolute;
      left: 28px;
      top: 28px;
      z-index: 5;
      border-radius: 18px;
      padding: 12px 14px;
      background: rgba(15,23,42,.92);
      color: #ffffff;
      box-shadow: 0 18px 36px rgba(15,23,42,.20);
    }

    .sfg-stage small {
      display: block;
      font-size: 11px;
      color: #cbd5e1;
      text-transform: uppercase;
      letter-spacing: .06em;
      margin-bottom: 4px;
      font-weight: 800;
    }

    .sfg-event {
      position: absolute;
      right: 28px;
      bottom: 26px;
      z-index: 5;
      min-width: 260px;
      border-radius: 18px;
      padding: 14px 16px;
      background: #ffffff;
      border: 1px solid #e2e8f0;
      box-shadow: 0 18px 36px rgba(15,23,42,.16);
    }

    .sfg-event small {
      display: block;
      color: #64748b;
      text-transform: uppercase;
      letter-spacing: .06em;
      font-size: 11px;
      font-weight: 900;
      margin-bottom: 5px;
    }

    .sfg-event strong {
      color: #0f172a;
      font-size: 18px;
    }

    .sfg-side {
      padding: 22px;
      background: #ffffff;
      display: grid;
      gap: 16px;
      align-content: start;
    }

    .sfg-buttons {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
    }

    .sfg-btn {
      border: 1px solid #cbd5e1;
      background: #f8fafc;
      color: #0f172a;
      padding: 9px 12px;
      border-radius: 999px;
      font-weight: 900;
      cursor: pointer;
      transition: .16s ease;
      font-size: 13px;
    }

    .sfg-btn:hover {
      transform: translateY(-1px);
      border-color: #60a5fa;
    }

    .sfg-btn.active {
      background: #2563eb;
      border-color: #2563eb;
      color: white;
      box-shadow: 0 12px 22px rgba(37,99,235,.22);
    }

    .sfg-info {
      border: 1px solid #e2e8f0;
      border-radius: 18px;
      background: #f8fafc;
      padding: 16px;
    }

    .sfg-info h4 {
      margin: 0 0 8px;
      font-size: 19px;
      color: #0f172a;
    }

    .sfg-info p {
      margin: 0;
      color: #475569;
      line-height: 1.55;
    }

    .sfg-kpis {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 10px;
    }

    .sfg-kpi {
      border: 1px solid #e2e8f0;
      border-radius: 16px;
      background: #f8fafc;
      padding: 12px;
    }

    .sfg-kpi span {
      display: block;
      font-size: 11px;
      color: #64748b;
      text-transform: uppercase;
      letter-spacing: .05em;
      font-weight: 900;
      margin-bottom: 5px;
    }

    .sfg-kpi strong {
      color: #0f172a;
      font-size: 16px;
    }

    .sfg-path {
      border-radius: 18px;
      border: 1px solid #172033;
      background: #0b1220;
      color: #dbeafe;
      padding: 14px;
      font-family: var(--mono);
      font-size: 12.5px;
      line-height: 1.55;
      white-space: pre-wrap;
      overflow: auto;
      max-height: 250px;
    }

    .sfg-table {
      margin: 18px 0;
      border: 1px solid #e2e8f0;
      border-radius: 18px;
      overflow: auto;
      background: #ffffff;
    }

    .sfg-table table {
      min-width: 850px;
      width: 100%;
      border-collapse: collapse;
      background: #ffffff;
    }

    .sfg-table th {
      background: #0f172a;
      color: #e2e8f0;
    }

    .sfg-table td {
      color: #334155;
      border-bottom: 1px solid #e2e8f0;
    }

    @media (max-width: 1200px) {
      .sfg-layout {
        grid-template-columns: 1fr;
      }

      .sfg-map {
        min-width: 850px;
        border-right: none;
        border-bottom: 1px solid #dbeafe;
      }

      .sfg-card {
        overflow-x: auto;
      }
    }

'@

$block = @'

        <div id="simulador-final-grafico" class="sfg-card">
          <div class="sfg-head">
            <h3>&#129514; Simulador final de escenarios EasyMesh</h3>
            <p>
              En la versión final del laboratorio, el contenedor <code>easymesh-network-simulator</code>
              genera escenarios dinámicos de red WiFi EasyMesh. Cada escenario modifica la topología,
              los clientes, el RSSI, la QoE, la utilización radio, el backhaul y los eventos que se ven
              en Prometheus y Grafana.
            </p>
          </div>

          <div class="sfg-layout">
            <div class="sfg-map">
              <svg class="sfg-lines" viewBox="0 0 1000 620" preserveAspectRatio="none" aria-hidden="true">
                <path id="sfgLineControllerSalon" class="sfg-line good" d="M500 74 C430 130 330 165 240 230"></path>
                <path id="sfgLineControllerDorm" class="sfg-line good" d="M500 74 C580 130 680 165 760 230"></path>
                <path id="sfgLineSalonPortatil" class="sfg-line good" d="M240 230 C190 305 155 375 150 445"></path>
                <path id="sfgLineSalonMovil" class="sfg-line good" d="M240 230 C285 320 320 405 340 508"></path>
                <path id="sfgLineDormTablet" class="sfg-line good" d="M760 230 C810 305 840 375 840 445"></path>
                <path id="sfgLineDormMovil" class="sfg-line off" d="M760 230 C770 325 765 415 760 508"></path>
                <path id="sfgLineRoaming" class="sfg-line off" d="M340 508 C465 570 625 570 760 508"></path>
              </svg>

              <div class="sfg-stage">
                <small>Escenario activo</small>
                <strong id="sfgStageText">normal</strong>
              </div>

              <div class="sfg-node sfg-controller">
                <span class="kind">Controller</span>
                <div class="name">GW_MASTER</div>
                <div class="desc">Controlador EasyMesh<br>2 agentes · 3 clientes</div>
              </div>

              <div class="sfg-node sfg-ap1" id="sfgApSalon">
                <span class="kind">Agente EasyMesh</span>
                <div class="name">AP_SALON</div>
                <div class="desc" id="sfgSalonDesc">Backhaul Ethernet · estado correcto</div>
              </div>

              <div class="sfg-node sfg-ap2" id="sfgApDormitorio">
                <span class="kind">Agente EasyMesh</span>
                <div class="name">AP_DORMITORIO</div>
                <div class="desc" id="sfgDormDesc">Backhaul WiFi-5GHz · estado correcto</div>
              </div>

              <div class="sfg-node sfg-client1">
                <span class="kind">Cliente</span>
                <div class="name">PORTATIL_SARA</div>
                <div class="desc">Asociado a AP_SALON</div>
                <span class="sfg-signal">RSSI -49 dBm</span>
              </div>

              <div class="sfg-node sfg-client2" id="sfgClientMovil">
                <span class="kind">Cliente objetivo</span>
                <div class="name">MOVIL_SARA</div>
                <div class="desc" id="sfgMovilDesc">Asociado a AP_SALON</div>
                <span class="sfg-signal" id="sfgMovilSignal">RSSI -48 dBm</span>
              </div>

              <div class="sfg-node sfg-client3">
                <span class="kind">Cliente</span>
                <div class="name">TABLET</div>
                <div class="desc">Asociado a AP_DORMITORIO</div>
                <span class="sfg-signal">RSSI -59 dBm</span>
              </div>

              <div class="sfg-event">
                <small>Evento generado</small>
                <strong id="sfgEventText">None / NoEvent</strong>
              </div>
            </div>

            <div class="sfg-side">
              <div class="sfg-buttons">
                <button class="sfg-btn active" data-sfg-scenario="normal">Normal</button>
                <button class="sfg-btn" data-sfg-scenario="coverage">Cobertura</button>
                <button class="sfg-btn" data-sfg-scenario="interference">Interferencia</button>
                <button class="sfg-btn" data-sfg-scenario="saturation">Saturación</button>
                <button class="sfg-btn" data-sfg-scenario="roaming">Roaming</button>
                <button class="sfg-btn" data-sfg-scenario="backhaul_degraded">Backhaul</button>
                <button class="sfg-btn" data-sfg-scenario="ap_failure">Fallo AP</button>
                <button class="sfg-btn" data-sfg-scenario="mixed">Mixto</button>
              </div>

              <div class="sfg-info">
                <h4 id="sfgScenarioTitle">Escenario normal</h4>
                <p id="sfgScenarioDesc">
                  Estado estable de la red EasyMesh. Los clientes tienen buena señal, la QoE es alta y no hay eventos de degradación.
                </p>
              </div>

              <div class="sfg-kpis">
                <div class="sfg-kpi">
                  <span>AP de MOVIL_SARA</span>
                  <strong id="sfgKpiAp">AP_SALON</strong>
                </div>
                <div class="sfg-kpi">
                  <span>RSSI MOVIL_SARA</span>
                  <strong id="sfgKpiRssi">-48 dBm</strong>
                </div>
                <div class="sfg-kpi">
                  <span>QoE Score</span>
                  <strong id="sfgKpiQoe">100</strong>
                </div>
                <div class="sfg-kpi">
                  <span>Evento</span>
                  <strong id="sfgKpiEvent">None</strong>
                </div>
              </div>

              <div class="sfg-path" id="sfgScenarioPath">Endpoint del simulador:
http://localhost:9200/state

Métricas:
easymesh_sim_client_signal_dbm
easymesh_sim_client_qoe_score
easymesh_sim_radio_utilization_percent
easymesh_sim_event_info</div>
            </div>
          </div>
        </div>

        <div class="sfg-table">
          <table>
            <thead>
              <tr>
                <th>Escenario final</th>
                <th>Qué representa</th>
                <th>Resultado esperado en Grafana</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td><code>normal</code></td>
                <td>Red estable y sin eventos.</td>
                <td>QoE alta, RSSI correcto y evento <code>None</code>.</td>
              </tr>
              <tr>
                <td><code>coverage</code></td>
                <td>Cliente con cobertura degradada.</td>
                <td>Baja el RSSI y empeora la QoE.</td>
              </tr>
              <tr>
                <td><code>interference</code></td>
                <td>Ruido e interferencia radio.</td>
                <td>Suben jitter, retry rate y pérdida de paquetes.</td>
              </tr>
              <tr>
                <td><code>saturation</code></td>
                <td>Canal WiFi saturado.</td>
                <td>Sube la utilización radio y aumenta la latencia.</td>
              </tr>
              <tr>
                <td><code>roaming</code></td>
                <td>MOVIL_SARA cambia de AP.</td>
                <td>Aparece <code>ClientSteering</code> y cambia el AP asociado.</td>
              </tr>
              <tr>
                <td><code>backhaul_degraded</code></td>
                <td>El enlace backhaul del AP satélite se degrada.</td>
                <td>Empeora el RSSI, la latencia y la pérdida del backhaul.</td>
              </tr>
              <tr>
                <td><code>ap_failure</code></td>
                <td>Fallo de un punto de acceso.</td>
                <td>Se degradan clientes y aparece evento de fallo.</td>
              </tr>
              <tr>
                <td><code>mixed</code></td>
                <td>Varias degradaciones al mismo tiempo.</td>
                <td>Se afectan RSSI, QoE, radio, backhaul y eventos.</td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="code-card">
          <div class="code-head"><strong>Comandos reales para mover el simulador final</strong><button class="copy">Copiar</button></div>
          <pre><code>curl.exe http://localhost:9200/state
curl.exe http://localhost:9200/metrics

curl.exe "http://localhost:9200/set?scenario=normal"
curl.exe "http://localhost:9200/set?scenario=coverage"
curl.exe "http://localhost:9200/set?scenario=interference"
curl.exe "http://localhost:9200/set?scenario=saturation"
curl.exe "http://localhost:9200/set?scenario=roaming"
curl.exe "http://localhost:9200/set?scenario=backhaul_degraded"
curl.exe "http://localhost:9200/set?scenario=ap_failure"
curl.exe "http://localhost:9200/set?scenario=mixed"</code></pre>
        </div>

'@

$js = @'

    // Bloque gráfico del simulador final dentro de 13_escenarios
    const sfgScenarioData = {
      normal: {
        title: "Escenario normal",
        desc: "Estado estable de la red EasyMesh. Los clientes tienen buena señal, la QoE es alta y no hay eventos de degradación.",
        ap: "AP_SALON",
        rssi: "-48 dBm",
        qoe: "100",
        event: "None",
        eventText: "None / NoEvent",
        movilDesc: "Asociado a AP_SALON",
        signalClass: "",
        movilClass: "",
        salonClass: "",
        dormClass: "",
        salonDesc: "Backhaul Ethernet · estado correcto",
        dormDesc: "Backhaul WiFi-5GHz · estado correcto",
        lines: ["good","good","good","good","good","off","off"],
        path: "Endpoint del simulador:\nhttp://localhost:9200/state\n\nMétricas principales:\neasymesh_sim_client_signal_dbm\neasymesh_sim_client_qoe_score\neasymesh_sim_radio_utilization_percent\neasymesh_sim_event_info"
      },
      coverage: {
        title: "Escenario de cobertura",
        desc: "MOVIL_SARA se aleja de la zona de cobertura. El RSSI baja y el estado QoE empeora.",
        ap: "AP_SALON",
        rssi: "-74 dBm",
        qoe: "45",
        event: "LowRSSI",
        eventText: "LowRSSI / CandidateForSteering",
        movilDesc: "Asociado a AP_SALON · cobertura baja",
        signalClass: "warn",
        movilClass: "warn",
        salonClass: "warn",
        dormClass: "",
        salonDesc: "Backhaul Ethernet · cliente con baja señal",
        dormDesc: "Backhaul WiFi-5GHz · estado correcto",
        lines: ["good","good","good","warn","good","off","off"],
        path: "Qué cambia:\n- SignalStrength baja\n- QoE Score baja\n- MOVIL_SARA queda como candidato a steering\n\nConsulta Prometheus:\neasymesh_sim_client_signal_dbm{client=\"MOVIL_SARA\"}"
      },
      interference: {
        title: "Escenario de interferencia",
        desc: "Aparece ruido radio. La conexión sigue activa, pero aumenta el retry rate, el jitter y la pérdida de paquetes.",
        ap: "AP_SALON",
        rssi: "-57 dBm",
        qoe: "62",
        event: "HighInterference",
        eventText: "HighInterference / DegradedQoE",
        movilDesc: "Asociado a AP_SALON · interferencia radio",
        signalClass: "warn",
        movilClass: "warn",
        salonClass: "warn",
        dormClass: "",
        salonDesc: "Radio con ruido e interferencia",
        dormDesc: "Backhaul WiFi-5GHz · estado correcto",
        lines: ["good","good","warn","warn","good","off","off"],
        path: "Qué cambia:\n- Sube el ruido\n- Sube retry rate\n- Sube jitter\n- Puede subir packet loss\n\nMétricas:\neasymesh_sim_client_jitter_ms\neasymesh_sim_client_retry_rate_percent\neasymesh_sim_client_packet_loss_percent"
      },
      saturation: {
        title: "Escenario de saturación",
        desc: "El canal WiFi tiene mucha carga. La utilización radio sube y empeora la latencia.",
        ap: "AP_SALON",
        rssi: "-55 dBm",
        qoe: "58",
        event: "HighUtilization",
        eventText: "HighUtilization / ChannelBusy",
        movilDesc: "Asociado a AP_SALON · canal ocupado",
        signalClass: "warn",
        movilClass: "warn",
        salonClass: "warn",
        dormClass: "",
        salonDesc: "Alta utilización radio",
        dormDesc: "Backhaul WiFi-5GHz · estado correcto",
        lines: ["good","good","warn","warn","good","off","off"],
        path: "Qué cambia:\n- Sube radio utilization\n- Sube latencia\n- Puede bajar throughput\n\nMétricas:\neasymesh_sim_radio_utilization_percent\neasymesh_sim_client_latency_ms\neasymesh_sim_client_throughput_down_mbps"
      },
      roaming: {
        title: "Escenario roaming",
        desc: "MOVIL_SARA cambia de AP_SALON a AP_DORMITORIO. El simulador genera un evento ClientSteering.",
        ap: "AP_DORMITORIO",
        rssi: "-49 dBm",
        qoe: "92",
        event: "ClientSteering",
        eventText: "ClientSteering / Success",
        movilDesc: "Asociado a AP_DORMITORIO",
        signalClass: "roam",
        movilClass: "roam",
        salonClass: "",
        dormClass: "roam",
        salonDesc: "Backhaul Ethernet · queda con menos carga",
        dormDesc: "Backhaul WiFi-5GHz · recibe a MOVIL_SARA",
        lines: ["good","good","good","off","good","roam","roam"],
        path: "Qué cambia:\n- MOVIL_SARA pasa a AP_DORMITORIO\n- Mejora SignalStrength\n- Aparece ClientSteering\n\nMétricas:\neasymesh_sim_event_info\neasymesh_sim_client_signal_dbm"
      },
      backhaul_degraded: {
        title: "Escenario backhaul degradado",
        desc: "El enlace backhaul del AP_DORMITORIO se degrada. Puede haber buena señal WiFi, pero mala salida hacia la red.",
        ap: "AP_DORMITORIO",
        rssi: "-52 dBm",
        qoe: "54",
        event: "BackhaulDegraded",
        eventText: "BackhaulDegraded / Warning",
        movilDesc: "Asociado a AP_DORMITORIO · backhaul degradado",
        signalClass: "warn",
        movilClass: "warn",
        salonClass: "",
        dormClass: "warn",
        salonDesc: "Backhaul Ethernet · estado correcto",
        dormDesc: "Backhaul WiFi-5GHz · degradado",
        lines: ["good","warn","good","off","warn","warn","off"],
        path: "Qué cambia:\n- Empeora BackhaulRSSI\n- Sube latencia de backhaul\n- Puede subir packet loss\n\nMétricas:\neasymesh_sim_backhaul_rssi_dbm\neasymesh_sim_backhaul_latency_ms\neasymesh_sim_backhaul_packet_loss_percent"
      },
      ap_failure: {
        title: "Escenario fallo de AP",
        desc: "Un punto de acceso falla. El simulador refleja pérdida de servicio y clientes afectados.",
        ap: "Sin servicio estable",
        rssi: "N/A",
        qoe: "20",
        event: "APFailure",
        eventText: "APFailure / Critical",
        movilDesc: "Cliente afectado por fallo de AP",
        signalClass: "bad",
        movilClass: "bad",
        salonClass: "bad",
        dormClass: "",
        salonDesc: "AP con fallo o servicio no disponible",
        dormDesc: "Backhaul WiFi-5GHz · operativo",
        lines: ["bad","good","bad","bad","good","off","off"],
        path: "Qué cambia:\n- Un AP queda en fallo\n- Clientes afectados pierden calidad\n- Aparece evento APFailure\n\nMétricas:\neasymesh_sim_event_info\neasymesh_sim_client_qoe_score"
      },
      mixed: {
        title: "Escenario mixto",
        desc: "Se combinan varias degradaciones: cobertura, interferencia, saturación y posible afectación del backhaul.",
        ap: "Variable",
        rssi: "-65 dBm",
        qoe: "40",
        event: "MixedDegradation",
        eventText: "MixedDegradation / MultipleIssues",
        movilDesc: "Cliente con degradación combinada",
        signalClass: "bad",
        movilClass: "bad",
        salonClass: "warn",
        dormClass: "warn",
        salonDesc: "Radio con carga e interferencia",
        dormDesc: "Backhaul parcialmente degradado",
        lines: ["warn","warn","warn","bad","warn","warn","off"],
        path: "Qué cambia:\n- RSSI degradado\n- QoE baja\n- Radio utilization alta\n- Puede empeorar backhaul\n\nUso:\nEscenario realista para validar el dashboard final."
      }
    };

    function sfgSetText(id, text) {
      const el = document.getElementById(id);
      if (el) el.textContent = text;
    }

    function sfgSetClass(id, base, extra) {
      const el = document.getElementById(id);
      if (el) el.className = (base + " " + (extra || "")).trim();
    }

    function sfgApplyScenario(key) {
      const data = sfgScenarioData[key];
      if (!data) return;

      document.querySelectorAll(".sfg-btn").forEach(btn => {
        btn.classList.toggle("active", btn.dataset.sfgScenario === key);
      });

      sfgSetText("sfgStageText", key);
      sfgSetText("sfgScenarioTitle", data.title);
      sfgSetText("sfgScenarioDesc", data.desc);
      sfgSetText("sfgKpiAp", data.ap);
      sfgSetText("sfgKpiRssi", data.rssi);
      sfgSetText("sfgKpiQoe", data.qoe);
      sfgSetText("sfgKpiEvent", data.event);
      sfgSetText("sfgEventText", data.eventText);
      sfgSetText("sfgMovilDesc", data.movilDesc);
      sfgSetText("sfgSalonDesc", data.salonDesc);
      sfgSetText("sfgDormDesc", data.dormDesc);
      sfgSetText("sfgScenarioPath", data.path);
      sfgSetText("sfgMovilSignal", data.rssi === "N/A" ? "RSSI N/A" : "RSSI " + data.rssi);

      sfgSetClass("sfgClientMovil", "sfg-node sfg-client2", data.movilClass);
      sfgSetClass("sfgApSalon", "sfg-node sfg-ap1", data.salonClass);
      sfgSetClass("sfgApDormitorio", "sfg-node sfg-ap2", data.dormClass);
      sfgSetClass("sfgMovilSignal", "sfg-signal", data.signalClass);

      const lineIds = [
        "sfgLineControllerSalon",
        "sfgLineControllerDorm",
        "sfgLineSalonPortatil",
        "sfgLineSalonMovil",
        "sfgLineDormTablet",
        "sfgLineDormMovil",
        "sfgLineRoaming"
      ];

      lineIds.forEach((id, index) => {
        const line = document.getElementById(id);
        if (line) line.setAttribute("class", "sfg-line " + data.lines[index]);
      });
    }

    document.querySelectorAll(".sfg-btn").forEach(btn => {
      btn.addEventListener("click", () => sfgApplyScenario(btn.dataset.sfgScenario));
    });

    sfgApplyScenario("normal");

'@

$styleIndex = $html.IndexOf("</style>")
if ($styleIndex -lt 0) {
    throw "No se ha encontrado </style> en el HTML."
}

$html = $html.Insert($styleIndex, "`r`n" + $css + "`r`n")

$pattern = '(<span class="section-tag">Validación EasyMesh interactiva</span>\s*</div>)'
$match = [regex]::Match($html, $pattern)

if (!$match.Success) {
    throw "No se ha encontrado la cabecera del apartado 13_escenarios."
}

$insertPosition = $match.Index + $match.Length
$html = $html.Insert($insertPosition, "`r`n" + $block + "`r`n")

$scriptIndex = $html.LastIndexOf("</script>")
if ($scriptIndex -lt 0) {
    throw "No se ha encontrado </script> en el HTML."
}

$html = $html.Insert($scriptIndex, "`r`n" + $js + "`r`n")

[System.IO.File]::WriteAllText(
    $path,
    $html,
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host "Actualizacion completada correctamente."
Write-Host "Se ha añadido un bloque grafico del simulador final dentro de 13_escenarios."