# Awake# — tray app for lid-close on battery (NOT PowerToys Awake)
# Left-click: toggle Do nothing <-> Hibernate
# Right-click: menu (incl. start with Windows)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $here 'LidToggle.Lib.ps1')

$mutex = New-Object System.Threading.Mutex($false, 'Local\AwakeHash_LidTray')
if (-not $mutex.WaitOne(0, $false)) { exit 0 }

function New-LidIcon {
    param([Parameter(Mandatory)][bool]$DoNothing, [int]$Size = 32)
    $bmp = New-Object System.Drawing.Bitmap $Size, $Size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)

    $bodyBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 55, 65, 81))
    $g.FillRectangle($bodyBrush, 4, 18, 24, 10)
    $bodyBrush.Dispose()

    if ($DoNothing) {
        $screen = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 16, 185, 129))
        $g.FillRectangle($screen, 6, 6, 20, 13)
        $screen.Dispose()
        $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 5, 150, 105), 2)
        $g.DrawLine($pen, 8, 26, 24, 26)
        $pen.Dispose()
    } else {
        $lid = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 99, 102, 241))
        $g.FillRectangle($lid, 6, 10, 20, 9)
        $lid.Dispose()
        $font = New-Object System.Drawing.Font 'Segoe UI', 7, ([System.Drawing.FontStyle]::Bold)
        $g.DrawString('Z', $font, [System.Drawing.Brushes]::White, 11, 9)
        $font.Dispose()
    }

    $g.Dispose()
    $icon = [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
    return @{ Icon = $icon; Bitmap = $bmp }
}

$form = New-Object System.Windows.Forms.Form
$form.ShowInTaskbar = $false
$form.WindowState = 'Minimized'
$form.FormBorderStyle = 'FixedToolWindow'
$form.Opacity = 0
$form.Visible = $false

$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Visible = $true

$menu = New-Object System.Windows.Forms.ContextMenuStrip
$itemNothing = New-Object System.Windows.Forms.ToolStripMenuItem 'Καμία ενέργεια (κλείσιμο καπακιού)'
$itemHibernate = New-Object System.Windows.Forms.ToolStripMenuItem 'Αδρανοποίηση (κλείσιμο καπακιού)'
$sep1 = New-Object System.Windows.Forms.ToolStripSeparator
$itemStartup = New-Object System.Windows.Forms.ToolStripMenuItem 'Έναρξη με τα Windows'
$itemRefresh = New-Object System.Windows.Forms.ToolStripMenuItem 'Ανανέωση κατάστασης'
$sep2 = New-Object System.Windows.Forms.ToolStripSeparator
$itemExit = New-Object System.Windows.Forms.ToolStripMenuItem 'Έξοδος'
[void]$menu.Items.Add($itemNothing)
[void]$menu.Items.Add($itemHibernate)
[void]$menu.Items.Add($sep1)
[void]$menu.Items.Add($itemStartup)
[void]$menu.Items.Add($itemRefresh)
[void]$menu.Items.Add($sep2)
[void]$menu.Items.Add($itemExit)
$notify.ContextMenuStrip = $menu

$script:iconHold = $null

function Update-LidTrayUi {
    param([switch]$Balloon)
    $action = Get-LidBatteryAction
    $doNothing = ($action -eq 0)
    $label = Get-LidActionLabel -Action $action
    $tip = "Awake#: $label"
    if ($tip.Length -gt 63) { $tip = $tip.Substring(0, 63) }
    $notify.Text = $tip

    $itemNothing.Checked = $doNothing
    $itemHibernate.Checked = (-not $doNothing -and $action -eq 2)
    $itemStartup.Checked = Test-AwakeHashStartsWithWindows

    if ($script:iconHold -ne $null) {
        try { $script:iconHold.Icon.Dispose() } catch {}
        try { $script:iconHold.Bitmap.Dispose() } catch {}
    }
    $script:iconHold = New-LidIcon -DoNothing:$doNothing
    $notify.Icon = $script:iconHold.Icon

    if ($Balloon) {
        $notify.BalloonTipTitle = 'Awake#'
        $notify.BalloonTipText = "Καπάκι (μπαταρία): $label"
        $notify.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
        $notify.ShowBalloonTip(1800)
    }
}

function Set-AndRefresh {
    param([int]$Action, [switch]$Balloon)
    Set-LidBatteryAction -Action $Action
    Update-LidTrayUi -Balloon:$Balloon
}

function Toggle-Lid {
    $cur = Get-LidBatteryAction
    if ($cur -eq 0) { Set-AndRefresh -Action 2 -Balloon } else { Set-AndRefresh -Action 0 -Balloon }
}

$itemNothing.Add_Click({ Set-AndRefresh -Action 0 -Balloon })
$itemHibernate.Add_Click({ Set-AndRefresh -Action 2 -Balloon })
$itemStartup.Add_Click({
    $newState = -not (Test-AwakeHashStartsWithWindows)
    Set-AwakeHashStartsWithWindows -Enabled:$newState
    $itemStartup.Checked = $newState
    $notify.BalloonTipTitle = 'Awake#'
    if ($newState) {
        $notify.BalloonTipText = 'Έναρξη με τα Windows: ενεργό'
    } else {
        $notify.BalloonTipText = 'Έναρξη με τα Windows: ανενεργό'
    }
    $notify.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
    $notify.ShowBalloonTip(1600)
})
$itemRefresh.Add_Click({ Update-LidTrayUi })
$itemExit.Add_Click({
    $notify.Visible = $false
    $notify.Dispose()
    [System.Windows.Forms.Application]::Exit()
})

$notify.Add_MouseClick({
    param($sender, $e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        Toggle-Lid
    }
})

Update-LidTrayUi
[System.Windows.Forms.Application]::Run()
