# Awake# one-shot toggle
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $here 'LidToggle.Lib.ps1')
Add-Type -AssemblyName System.Windows.Forms
$cur = Get-LidBatteryAction
if ($cur -eq 0) { $next = 2 } else { $next = 0 }
Set-LidBatteryAction -Action $next
$label = Get-LidActionLabel -Action $next
[void][System.Windows.Forms.MessageBox]::Show(
    "Με μπαταρία → Όταν κλείνω το καπάκι:`n$label",
    'Awake#',
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
)
