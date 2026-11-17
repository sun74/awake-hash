# Awake# Install — copy not needed if already in this folder; creates shortcuts
$ErrorActionPreference = 'Stop'
$src = Split-Path -Parent $MyInvocation.MyCommand.Path
$dst = Join-Path $env:LOCALAPPDATA 'LidToggle'

$needed = @(
  'LidToggle.Lib.ps1',
  'LidTray.ps1',
  'Toggle-Lid-Battery.ps1',
  'Toggle Lid Battery.bat',
  'Start-LidTray.vbs',
  'AwakeHash.ico'
)
foreach ($f in $needed) {
  if (-not (Test-Path -LiteralPath (Join-Path $src $f))) {
    throw "Λείπει αρχείο: $f"
  }
}

New-Item -ItemType Directory -Force -Path $dst | Out-Null
foreach ($f in $needed) {
  Copy-Item -LiteralPath (Join-Path $src $f) -Destination (Join-Path $dst $f) -Force
}

$vbs = Join-Path $dst 'Start-LidTray.vbs'
$ico = Join-Path $dst 'AwakeHash.ico'
$bat = Join-Path $dst 'Toggle Lid Battery.bat'
$w = New-Object -ComObject WScript.Shell

function New-AwakeLnk($path, $target, $arguments, $desc, $hotkey) {
  $s = $w.CreateShortcut($path)
  $s.TargetPath = $target
  if ($arguments) { $s.Arguments = $arguments }
  $s.WorkingDirectory = $dst
  $s.Description = $desc
  if (Test-Path -LiteralPath $ico) { $s.IconLocation = "$ico,0" }
  if ($hotkey) { $s.Hotkey = $hotkey }
  $s.Save()
}

$start = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$desk = [Environment]::GetFolderPath('Desktop')
New-AwakeLnk (Join-Path $start 'Awake#.lnk') 'wscript.exe' ('"' + $vbs + '"') 'Awake# tray' $null
New-AwakeLnk (Join-Path $desk 'Awake#.lnk') 'wscript.exe' ('"' + $vbs + '"') 'Awake# tray' $null
New-AwakeLnk (Join-Path $start 'Awake# Toggle.lnk') $bat $null 'Awake# one-shot' 'CTRL+ALT+L'

# Default: ask about startup
Add-Type -AssemblyName System.Windows.Forms
$ans = [System.Windows.Forms.MessageBox]::Show(
  "Να ξεκινάει το Awake# αυτόματα με τα Windows;`n(Μπορείς να το αλλάξεις μετά από το μενού στο tray.)",
  'Awake#',
  [System.Windows.Forms.MessageBoxButtons]::YesNo,
  [System.Windows.Forms.MessageBoxIcon]::Question
)
. (Join-Path $dst 'LidToggle.Lib.ps1')
# Fix PSCommandPath context for Set-AwakeHashStartsWithWindows: set via explicit paths
$lnkPath = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup\Awake#.lnk'
if ($ans -eq [System.Windows.Forms.DialogResult]::Yes) {
  $s = $w.CreateShortcut($lnkPath)
  $s.TargetPath = 'wscript.exe'
  $s.Arguments = '"' + $vbs + '"'
  $s.WorkingDirectory = $dst
  $s.Description = 'Awake# — start with Windows'
  $s.IconLocation = "$ico,0"
  $s.Save()
} else {
  if (Test-Path -LiteralPath $lnkPath) { Remove-Item -LiteralPath $lnkPath -Force }
}

Start-Process -FilePath 'wscript.exe' -ArgumentList ('"' + $vbs + '"')
[void][System.Windows.Forms.MessageBox]::Show(
  "Εγκατάσταση OK.`n`nΦάκελος: $dst`nDesktop + Start menu: Awake#`nTray: δεξί κλικ για ρυθμίσεις.",
  'Awake#',
  [System.Windows.Forms.MessageBoxButtons]::OK,
  [System.Windows.Forms.MessageBoxIcon]::Information
)
