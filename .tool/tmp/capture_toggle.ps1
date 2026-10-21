param(
    [int]$ClientX = 63,
    [int]$ClientY = 60,
    [int]$Frames = 10,
    [int]$IntervalMs = 40,
    [string]$Tag = "run1"
)
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint d, uint e, uint extra, IntPtr h);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    public struct RECT { public int Left, Top, Right, Bottom; }
    public struct POINT { public int X, Y; }
}
"@

$proc = Get-Process -Name centauri | Select-Object -First 1
$hwnd = $proc.MainWindowHandle
[Win32]::SetForegroundWindow($hwnd) | Out-Null
Start-Sleep -Milliseconds 400

$outDir = Join-Path $env:TEMP "centauri_frames\$Tag"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
Remove-Item "$outDir\*.png" -ErrorAction SilentlyContinue

function Grab([string]$name) {
    $r = New-Object Win32+RECT
    [Win32]::GetClientRect($hwnd, [ref]$r) | Out-Null
    $p = New-Object Win32+POINT
    [Win32]::ClientToScreen($hwnd, [ref]$p) | Out-Null
    $bmp = New-Object System.Drawing.Bitmap($r.Right, $r.Bottom)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($p.X, $p.Y, 0, 0, $bmp.Size)
    $bmp.Save((Join-Path $outDir $name))
    $g.Dispose(); $bmp.Dispose()
}

Grab "frame_00.png"
$cr = New-Object Win32+RECT
[Win32]::GetClientRect($hwnd, [ref]$cr) | Out-Null
$cp = New-Object Win32+POINT
$cp.X = $ClientX; $cp.Y = $ClientY
[Win32]::ClientToScreen($hwnd, [ref]$cp) | Out-Null
[Win32]::SetCursorPos($cp.X, $cp.Y) | Out-Null
Start-Sleep -Milliseconds 120
[Win32]::mouse_event(0x0002, 0, 0, 0, [IntPtr]::Zero)
[Win32]::mouse_event(0x0004, 0, 0, 0, [IntPtr]::Zero)
for ($i = 1; $i -le $Frames; $i++) {
    Start-Sleep -Milliseconds $IntervalMs
    Grab ("frame_{0:d2}.png" -f $i)
}
Get-ChildItem "$outDir\frame_*.png" | Sort-Object Name | ForEach-Object {
    $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
    $md5 = [System.BitConverter]::ToString(([System.Security.Cryptography.MD5]::Create()).ComputeHash($bytes)).Substring(0,8)
    "{0}  {1}  {2}" -f $md5, $_.Length, $_.Name
}
