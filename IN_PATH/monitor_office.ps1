# Set workspaces 1/2/3 -> monitor 1, workspaces 4/5/6 -> monitor 0 in glazewm config.
$config = Join-Path $env:USERPROFILE '.glzr\glazewm\config.yaml'

busybox sed -i -b -E `
    -e '/name: "1"/,/bind_to_monitor:/ s/bind_to_monitor:[^[:cntrl:]]*/bind_to_monitor: 1/' `
    -e '/name: "2"/,/bind_to_monitor:/ s/bind_to_monitor:[^[:cntrl:]]*/bind_to_monitor: 1/' `
    -e '/name: "3"/,/bind_to_monitor:/ s/bind_to_monitor:[^[:cntrl:]]*/bind_to_monitor: 1/' `
    -e '/name: "4"/,/bind_to_monitor:/ s/bind_to_monitor:[^[:cntrl:]]*/bind_to_monitor: 0/' `
    -e '/name: "5"/,/bind_to_monitor:/ s/bind_to_monitor:[^[:cntrl:]]*/bind_to_monitor: 0/' `
    -e '/name: "6"/,/bind_to_monitor:/ s/bind_to_monitor:[^[:cntrl:]]*/bind_to_monitor: 0/' `
    $config

Write-Host "Set OFFICE layout: workspaces 1/2/3 -> monitor 1, workspaces 4/5/6 -> monitor 0"

glazewm command wm-exit 2>$null | Out-Null
Start-Sleep -Milliseconds 500
Start-Process -FilePath 'glazewm' -ArgumentList 'start' -WindowStyle Hidden
