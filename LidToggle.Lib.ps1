# Awake# library | lid close on battery
$script:LidSubButtons = '4f971e89-eebd-4455-a8de-9e59040e7347'
$script:LidCloseGuid  = '5ca83367-6e45-459f-a27b-476b1d01c936'

function Get-LidActiveSchemeGuid {
    $line = (powercfg /getactivescheme | Out-String)
    if ($line -match '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})') {
        return $Matches[1]
    }
    throw 'Active power scheme not found.'
}

function Get-LidBatteryAction {
    $scheme = Get-LidActiveSchemeGuid
    $path = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\$scheme\$script:LidSubButtons\$script:LidCloseGuid"
    if (Test-Path $path) {
        return [int](Get-ItemProperty -Path $path).DCSettingIndex
    }
    $def = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\$script:LidSubButtons\$script:LidCloseGuid\DefaultPowerSchemeValues\$scheme"
    if (Test-Path $def) {
        return [int](Get-ItemProperty -Path $def).DCSettingIndex
    }
    return 2
}

function Set-LidBatteryAction {
    param([Parameter(Mandatory)][ValidateSet(0,1,2,3)][int]$Action)
    powercfg /SETDCVALUEINDEX SCHEME_CURRENT $script:LidSubButtons $script:LidCloseGuid $Action | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "powercfg SETDCVALUEINDEX failed ($LASTEXITCODE)" }
    powercfg /SETACTIVE SCHEME_CURRENT | Out-Null
}

function Get-LidActionLabel {
    param([int]$Action)
    switch ($Action) {
        0 { 'Καμία ενέργεια' }
        1 { 'Αναστολή λειτουργίας' }
        2 { 'Αδρανοποίηση' }
        3 { 'Τερματισμός' }
        default { "Άγνωστο ($Action)" }
    }
}

function Get-AwakeHashStartupPath {
    Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup\Awake#.lnk'
}

function Test-AwakeHashStartsWithWindows {
    Test-Path -LiteralPath (Get-AwakeHashStartupPath)
}

function Set-AwakeHashStartsWithWindows {
    param([Parameter(Mandatory)][bool]$Enabled)
    $lnkPath = Get-AwakeHashStartupPath
    $dir = Split-Path -Parent $PSCommandPath
    if (-not $dir) { $dir = Join-Path $env:LOCALAPPDATA 'LidToggle' }
    $vbs = Join-Path $dir 'Start-LidTray.vbs'
    $ico = Join-Path $dir 'AwakeHash.ico'

    if ($Enabled) {
        $w = New-Object -ComObject WScript.Shell
        $s = $w.CreateShortcut($lnkPath)
        $s.TargetPath = 'wscript.exe'
        $s.Arguments = '"' + $vbs + '"'
        $s.WorkingDirectory = $dir
        $s.Description = 'Awake# — start with Windows'
        if (Test-Path -LiteralPath $ico) { $s.IconLocation = "$ico,0" }
        $s.Save()
    } else {
        if (Test-Path -LiteralPath $lnkPath) {
            Remove-Item -LiteralPath $lnkPath -Force
        }
    }
}
