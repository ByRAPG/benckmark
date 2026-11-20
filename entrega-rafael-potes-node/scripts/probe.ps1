param([int[]]$Levels, [int]$Duration = 30, [int]$Rampup = 10)
$root = (Resolve-Path "$PSScriptRoot\..").Path
$dir = "$root\evidencias\busqueda_estres"
New-Item -ItemType Directory -Force "$dir\raw" | Out-Null
$log = "$dir\busqueda_estres.csv"
if (-not (Test-Path $log)) { 'users,duration_s,samples,avg_ms,p90_ms,p95_ms,throughput,error_pct,errors_5xx,errors_socket,errors_other,top_error' | Set-Content $log }
$env:JVM_ARGS = '-Xms2g -Xmx6g'
foreach ($u in $Levels) {
  $jtl = "$dir\raw\probe_$u.jtl"
  Remove-Item $jtl -ErrorAction SilentlyContinue
  & C:\apache-jmeter-5.6.3\bin\jmeter.bat -n -t "$root\jmeter\Benchmark.jmx" "-Jusers=$u" "-Jduration=$Duration" "-Jrampup=$Rampup" "-Jjtl=$jtl" -j "$dir\raw\probe_$u.log" | Out-Null
  $m = python "$root\scripts\jtl_stats.py" $jtl --json | ConvertFrom-Json
  $top = ($m.top_error -replace ',', ';')
  "$u,$Duration,$($m.samples),$($m.avg),$($m.p90),$($m.p95),$($m.throughput),$($m.error_pct),$($m.errors_5xx),$($m.errors_socket),$($m.errors_other),$top" | Add-Content $log
  "$u -> avg=$($m.avg) p95=$($m.p95) tp=$($m.throughput) err=$($m.error_pct)% 5xx=$($m.errors_5xx) sock=$($m.errors_socket) other=$($m.errors_other) [$top]"
  Start-Sleep 10
}
