# Set workspaces 1/2/3 -> monitor 0, workspaces 4/5/6 -> monitor 1, workspaces 7/8/9 -> monitor 2 in glazewm config.
$config = Join-Path $env:USERPROFILE '.glzr\glazewm\config.yaml'

busybox sed -i -b -E `
    -e '/name: "1"/,/bind_to_monitor:/ s/bind_to_monitor:[^[:cntrl:]]*/bind_to_monitor: 0/' `
    -e '/name: "2"/,/bind_to_monitor:/ s/bind_to_monitor:[^[:cntrl:]]*/bind_to_monitor: 0/' `
    -e '/name: "3"/,/bind_to_monitor:/ s/bind_to_monitor:[^[:cntrl:]]*/bind_to_monitor: 0/' `
    -e '/name: "4"/,/bind_to_monitor:/ s/bind_to_monitor:[^[:cntrl:]]*/bind_to_monitor: 1/' `
    -e '/name: "5"/,/bind_to_monitor:/ s/bind_to_monitor:[^[:cntrl:]]*/bind_to_monitor: 1/' `
    -e '/name: "6"/,/bind_to_monitor:/ s/bind_to_monitor:[^[:cntrl:]]*/bind_to_monitor: 1/' `
    -e '/name: "7"/,/bind_to_monitor:/ s/bind_to_monitor:[^[:cntrl:]]*/bind_to_monitor: 2/' `
    -e '/name: "8"/,/bind_to_monitor:/ s/bind_to_monitor:[^[:cntrl:]]*/bind_to_monitor: 2/' `
    -e '/name: "9"/,/bind_to_monitor:/ s/bind_to_monitor:[^[:cntrl:]]*/bind_to_monitor: 2/' `
    $config

Write-Host "Set HOME layout: workspaces 1/2/3 -> monitor 0, workspaces 4/5/6 -> monitor 1, workspaces 7/8/9 -> monitor 2"

glazewm command wm-exit 2>$null | Out-Null
Start-Sleep -Milliseconds 500
Start-Process -FilePath 'glazewm' -ArgumentList 'start' -WindowStyle Hidden
