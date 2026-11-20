param([int]$Users, [int]$Duration = 60, [int]$Rampup = 10, [int]$MidAt = 35, [switch]$KeepOpen)
$ErrorActionPreference = 'Continue'
. "$PSScriptRoot\win.ps1"
$root = (Resolve-Path "$PSScriptRoot\..").Path
$ev = "$root\evidencias"
New-Item -ItemType Directory -Force "$ev\raw", "$ev\capturas", "$ev\resultados" | Out-Null
$jtl = "$ev\raw\$Users.jtl"
Remove-Item $jtl -ErrorAction SilentlyContinue
$cap = "$ev\capturas\${Users}u"

$jmW = 1160; $rx = 1160; $rw = 760

# Terminales de monitoreo
$statsCmd = 'title BENCH-STATS & docker stats node-api-orders node-db-orders --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.PIDs}}"'
Start-Process conhost.exe -ArgumentList "cmd /k $statsCmd"
Start-Process conhost.exe -ArgumentList 'cmd /k title BENCH-HTOP & docker run --rm -it --pid=host htop-host'

# Muestreo de recursos en segundo plano
$stop = "$env:TEMP\stop_$Users"
Remove-Item $stop -ErrorAction SilentlyContinue
$res = "$ev\raw\${Users}_docker_stats.csv"
"ts,name,cpu,mem" | Set-Content $res
$job = Start-Job -ArgumentList $stop, $res -ScriptBlock {
  param($stop, $res)
  while (-not (Test-Path $stop)) {
    $ts = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
    docker stats --no-stream --format "{{.Name}},{{.CPUPerc}},{{.MemUsage}}" node-api-orders node-db-orders |
      ForEach-Object { "$ts,$_" } | Add-Content $res
  }
}

# JMeter GUI
$env:JVM_ARGS = '-Xms1g -Xmx4g'
Start-Process C:\apache-jmeter-5.6.3\bin\jmeter.bat -WindowStyle Minimized -ArgumentList "-t `"$root\jmeter\Benchmark.jmx`" -Jusers=$Users -Jduration=$Duration -Jrampup=$Rampup -Jjtl=$jtl -Jresultcollector.action_if_file_exists=APPEND"
$h = [IntPtr]::Zero
for ($i = 0; $i -lt 90 -and $h -eq [IntPtr]::Zero; $i++) { Start-Sleep 1; $h = Find-Win '*Apache JMeter*' }
Start-Sleep 4
$hs = Find-Win '*BENCH-STATS*'; $hh = Find-Win '*BENCH-HTOP*'
[W]::MoveWindow($hs, $rx, 0, $rw, 380, $true) | Out-Null
[W]::MoveWindow($hh, $rx, 380, $rw, 760, $true) | Out-Null
Focus-Win $h
[W]::MoveWindow($h, 0, 0, $jmW, 1140, $true) | Out-Null
Start-Sleep 1
Focus-Win $hs; Focus-Win $hh; Focus-Win $h

# Expandir el Thread Group y seleccionar Summary Report
Click-At 36 172
Click-At 150 272
Start-Sleep 1
$t0 = Get-Date
Click-At 390 87   # Start

Start-Sleep -Seconds $MidAt
Focus-Win $hs; Focus-Win $hh; Focus-Win $h
Start-Sleep 1
Shot-Screen "${cap}_pantalla_completa.png"
Shot-Win $hs "${cap}_docker_stats.png"
Shot-Win $hh "${cap}_htop.png"
Shot-Win $h "${cap}_jmeter_ejecutando.png"

# Esperar el fin de la corrida
$end = $t0.AddSeconds($Duration + 5)
while ((Get-Date) -lt $end) { Start-Sleep 1 }
$last = -1
for ($i = 0; $i -lt 60; $i++) {
  Start-Sleep 2
  $len = (Get-Item $jtl -ErrorAction SilentlyContinue).Length
  if ($len -eq $last) { break }
  $last = $len
}
New-Item $stop -ItemType File -Force | Out-Null
Start-Sleep 2

Focus-Win $h
Click-At 150 272
Start-Sleep 1
Shot-Win $h "${cap}_summary_report.png"
Click-At 150 297
Start-Sleep 1
Shot-Win $h "${cap}_aggregate_report.png"

Wait-Job $job -Timeout 20 | Out-Null; Remove-Job $job -Force

python "$root\scripts\jtl_stats.py" $jtl --summary "$ev\resultados\${Users}u_summary.csv" --aggregate "$ev\resultados\${Users}u_aggregate.csv" --json |
  Set-Content "$ev\resultados\${Users}u_metricas.json"
Get-Content "$ev\resultados\${Users}u_metricas.json"

if (-not $KeepOpen) {
  Get-Process java -ErrorAction SilentlyContinue | Where-Object MainWindowTitle -like '*JMeter*' | Stop-Process -Force
  Get-Process conhost, cmd -ErrorAction SilentlyContinue | Where-Object MainWindowTitle -like '*BENCH-*' | Stop-Process -Force
  docker ps -q --filter ancestor=htop-host | ForEach-Object { docker rm -f $_ | Out-Null }
}


