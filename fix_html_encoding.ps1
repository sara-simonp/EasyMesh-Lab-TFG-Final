$path = "C:\EasyMesh-Lab\pag-web\index.html"

if (!(Test-Path $path)) {
    throw "No existe C:\EasyMesh-Lab\pag-web\index.html"
}

$backup = "C:\EasyMesh-Lab\pag-web\index_backup_codificacion_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
Copy-Item $path $backup -Force
Write-Host "Backup creado en: $backup"

$html = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

function S([int[]]$codes) {
    return -join ($codes | ForEach-Object { [char]$_ })
}

# Caracteres correctos
$middot = [char]0x00B7
$emdash = [char]0x2014
$endash = [char]0x2013
$arrow  = [char]0x2192
$leftright = [char]0x2194
$play = [char]0x25B6
$pause = [char]0x23F8

# Reparaciones frecuentes de UTF-8 mal interpretado como Windows-1252
$fixes = @(
    @((S @(0x00C2,0x00B7)), "$middot"),
    @((S @(0x00E2,0x20AC,0x201D)), "$emdash"),
    @((S @(0x00E2,0x20AC,0x201C)), "$endash"),
    @((S @(0x00E2,0x2020,0x2019)), "$arrow"),
    @((S @(0x00E2,0x2020,0x201D)), "$leftright"),
    @((S @(0x00E2,0x2013,0x00B6)), "$play"),
    @((S @(0x00E2,0x00B8,0x008F)), "$pause"),

    @((S @(0x00C3,0x00A1)), "á"),
    @((S @(0x00C3,0x00A9)), "é"),
    @((S @(0x00C3,0x00AD)), "í"),
    @((S @(0x00C3,0x00B3)), "ó"),
    @((S @(0x00C3,0x00BA)), "ú"),
    @((S @(0x00C3,0x00B1)), "ñ"),
    @((S @(0x00C3,0x0081)), "Á"),
    @((S @(0x00C3,0x0089)), "É"),
    @((S @(0x00C3,0x008D)), "Í"),
    @((S @(0x00C3,0x0093)), "Ó"),
    @((S @(0x00C3,0x009A)), "Ú"),
    @((S @(0x00C3,0x0091)), "Ñ"),
    @((S @(0x00C3,0x00BC)), "ü"),
    @((S @(0x00C3,0x009C)), "Ü"),

    @((S @(0x00C2,0x00BF)), "¿"),
    @((S @(0x00C2,0x00A1)), "¡")
)

foreach ($pair in $fixes) {
    $html = $html.Replace($pair[0], $pair[1])
}

# Limpieza adicional de iconos corruptos comunes. Se sustituyen por entidades HTML.
$html = [regex]::Replace(
    $html,
    '(<div class="brand-icon">).*?(</div>)',
    '$1&#128193;$2',
    [System.Text.RegularExpressions.RegexOptions]::Singleline
)

# Iconos del menu lateral con entidades HTML seguras
$icons = @{
    "arquitectura"       = "&#129517;"
    "compose"            = "&#128051;"
    "genieacs"           = "&#128998;"
    "prplmesh"           = "&#129001;"
    "adapter"            = "&#129002;"
    "tr069"              = "&#128999;"
    "datamodel"          = "&#128196;"
    "evidencias"         = "&#9989;"
    "comandos"           = "&#9000;&#65039;"
    "pagina"             = "&#127760;"
    "tiemporeal"         = "&#128308;"
    "tr181"              = "&#128225;"
    "escenarios"         = "&#129514;"
    "tr069data"          = "&#128450;&#65039;"
    "recogida"           = "&#128190;"
    "faults"             = "&#9888;&#65039;"
    "migracion"          = "&#128187;"
    "migracionpc"        = "&#128187;"
    "simuladorfinal"     = "&#128202;"
    "simulador_final"    = "&#128202;"
    "resultadofinal"     = "&#127942;"
    "resultado_final"    = "&#127942;"
}

foreach ($target in $icons.Keys) {
    $pattern = '(<button[^>]*data-target="' + [regex]::Escape($target) + '"[^>]*>\s*<span class="emoji">).*?(</span>)'
    $html = [regex]::Replace(
        $html,
        $pattern,
        '$1' + $icons[$target] + '$2',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
}

# Reparar iconos internos del diagrama principal
$html = [regex]::Replace($html, '(<div class="zone docker">).*?Docker Compose:', '$1&#128051; Docker Compose:')
$html = [regex]::Replace($html, '(<div class="zone host">).*?PC Windows', '$1&#128187; PC Windows')
$html = [regex]::Replace($html, '(<span class="mini-badge" style="background:#7c3aed">).*?(</span>Adaptador)', '$1&#8596;$2')
$html = [regex]::Replace($html, '(<span class="mini-badge" style="background:#0891b2">).*?(</span>pag-web)', '$1&#127760;$2')
$html = [regex]::Replace($html, '(<span class="mini-badge" style="background:#64748b">).*?(</span>tcpdump)', '$1&#9673;$2')
$html = [regex]::Replace($html, '(<span class="mini-badge" style="background:#ca8a04">).*?(</span>Evidencias)', '$1&#10003;$2')

# Asegurar charset
$html = [regex]::Replace($html, '<meta charset="[^"]+"\s*/?>', '<meta charset="UTF-8" />', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

# Guardar como UTF-8 con BOM para Windows
[System.IO.File]::WriteAllText(
    $path,
    $html,
    [System.Text.UTF8Encoding]::new($true)
)

Write-Host "Reparacion terminada correctamente."
Write-Host "Archivo guardado en UTF-8."
