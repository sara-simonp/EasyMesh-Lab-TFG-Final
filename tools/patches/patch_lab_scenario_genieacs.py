from pathlib import Path

path = Path("simulator/easymesh-network-simulator/app.py")
text = path.read_text(encoding="utf-8")

marker = '    tmp = CSV_FILE + ".tmp"\n'

block = r'''
    # -------------------------------------------------------------------------
    # Lab control metadata for GenieACS demo.
    # This branch is NOT part of the TelcoX BulkData strict payload.
    # It is kept separated so GenieACS can show which simulator scenario is active
    # while TelcoX/TR-181 metrics remain under Device.WiFi.*, Device.BulkData.*,
    # Device.DeviceInfo.*, Device.Hosts.*, Device.Ethernet.* and Device.IP.*.
    # -------------------------------------------------------------------------
    lab = "Device.X_SARA_Lab"
    csv_write_object(rows, lab)
    csv_write_object(rows, f"{lab}.Scenario")
    csv_write_object(rows, f"{lab}.Event")

    csv_write_param(rows, f"{lab}.Scenario.Id", state["scenario"], "xsd:string")
    csv_write_param(rows, f"{lab}.Scenario.Description", state["scenario_description"], "xsd:string")
    csv_write_param(rows, f"{lab}.Scenario.LastUpdateUTC", state["timestamp_utc"], "xsd:string")
    csv_write_param(rows, f"{lab}.Scenario.Source", "Laboratory scenario marker - not TelcoX BulkData", "xsd:string")

    e = state["event"]
    csv_write_param(rows, f"{lab}.Event.Type", e["type"], "xsd:string")
    csv_write_param(rows, f"{lab}.Event.Result", e["result"], "xsd:string")
    csv_write_param(rows, f"{lab}.Event.Reason", e.get("reason", ""), "xsd:string")
    csv_write_param(rows, f"{lab}.Event.FromDevice", e.get("from_device", ""), "xsd:string")
    csv_write_param(rows, f"{lab}.Event.ToDevice", e.get("to_device", ""), "xsd:string")
    csv_write_param(rows, f"{lab}.Event.ClientMAC", e.get("client_mac", ""), "xsd:string")
    csv_write_param(rows, f"{lab}.Event.SteeringCount", e.get("steering_count", 0), "xsd:unsignedInt")

'''

if "Laboratory scenario marker - not TelcoX BulkData" in text:
    print("OK: la rama Device.X_SARA_Lab ya estaba aplicada.")
else:
    if marker not in text:
        raise SystemExit("ERROR: no encuentro el punto de insercion tmp = CSV_FILE. No se ha modificado app.py.")

    backup = path.with_suffix(".py.bak_lab_scenario_genieacs")
    backup.write_text(text, encoding="utf-8")

    text = text.replace(marker, block + "\n" + marker)
    path.write_text(text, encoding="utf-8")

    print("OK: añadida rama Device.X_SARA_Lab para mostrar escenario en GenieACS.")
    print(f"Backup creado: {backup}")
