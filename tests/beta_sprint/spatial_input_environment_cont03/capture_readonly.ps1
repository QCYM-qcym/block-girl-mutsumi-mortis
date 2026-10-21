param([Parameter(Mandatory=$true)][string]$OutputDirectory)
$ErrorActionPreference = 'Stop'
if (Test-Path -LiteralPath $OutputDirectory) { throw 'Output directory must be new; evidence is immutable.' }
New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
# Metadata only: no activation, messages, hooks, input injection or screenshots.
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class InputEnvironmentReadOnly {
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
  [StructLayout(LayoutKind.Sequential)] public struct Rect { public int left, top, right, bottom; }
  [StructLayout(LayoutKind.Sequential)] public struct GuiThreadInfo {
    public uint cbSize, flags; public IntPtr hwndActive, hwndFocus, hwndCapture, hwndMenuOwner, hwndMoveSize, hwndCaret; public Rect rcCaret;
  }
  [DllImport("user32.dll")] public static extern bool GetGUIThreadInfo(uint idThread, ref GuiThreadInfo info);
}
'@
$snapshotUtc = [DateTime]::UtcNow.ToString('o')
$gameProcesses = @(Get-CimInstance Win32_Process -Filter "Name LIKE '%godot%'" | ForEach-Object {
  $live = Get-Process -Id $_.ProcessId -ErrorAction SilentlyContinue
  if ($null -eq $live) { return }
  $handle = $live.MainWindowHandle
  [uint32]$windowPid = 0
  $thread = [InputEnvironmentReadOnly]::GetWindowThreadProcessId($handle, [ref]$windowPid)
  $info = New-Object InputEnvironmentReadOnly+GuiThreadInfo
  $info.cbSize = [Runtime.InteropServices.Marshal]::SizeOf($info)
  $guiOk = $false
  if ($thread -ne 0) { $guiOk = [InputEnvironmentReadOnly]::GetGUIThreadInfo($thread, [ref]$info) }
  [pscustomobject]@{
    pid = $_.ProcessId; name = $_.Name; executable = $_.ExecutablePath; command_line = $_.CommandLine
    created_utc = $_.CreationDate.ToUniversalTime().ToString('o'); session_id = $_.SessionId
    main_window_handle = $handle.ToInt64(); main_window_title = $live.MainWindowTitle
    window_owner_pid = $windowPid; visible = [InputEnvironmentReadOnly]::IsWindowVisible($handle)
    minimized = [InputEnvironmentReadOnly]::IsIconic($handle); gui_thread_query_succeeded = $guiOk
    thread_active_equals_main = $(if ($guiOk) { $info.hwndActive -eq $handle } else { $null })
    thread_focus_equals_main = $(if ($guiOk) { $info.hwndFocus -eq $handle } else { $null })
  }
})
$foregroundHandle = [InputEnvironmentReadOnly]::GetForegroundWindow()
[uint32]$foregroundPid = 0
[void][InputEnvironmentReadOnly]::GetWindowThreadProcessId($foregroundHandle, [ref]$foregroundPid)
$foregroundIsGodot = $foregroundPid -in @($gameProcesses.pid)
$toolProcesses = @(Get-Process | Where-Object { $_.ProcessName -match '^(codex-computer-use|cua_node)$' } | ForEach-Object {
  [pscustomobject]@{name=$_.ProcessName; pid=$_.Id; session_id=$_.SessionId; started_utc=$_.StartTime.ToUniversalTime().ToString('o')}
})
$result = [ordered]@{
  schema = 'spatial-input-environment-readonly-v1'; sampled_utc = $snapshotUtc
  collector_session_id = (Get-Process -Id $PID).SessionId
  godot_processes = $gameProcesses
  prior_qa_pid_32312_present = [bool](Get-Process -Id 32312 -ErrorAction SilentlyContinue)
  foreground_is_observed_godot = $foregroundIsGodot
  foreground_godot_pid = $(if ($foregroundIsGodot) { $foregroundPid } else { $null })
  unrelated_foreground_identity = 'NOT_RECORDED'
  known_tool_processes = $toolProcesses
  input_actions_attempted = 0; process_mutations = 0; window_mutations = 0
  limitations = @('Point-in-time metadata; not input dispatch or receipt proof.', 'Godot process list may change while sampled.', 'Per-thread focus does not establish system foreground ownership.', 'Tool-process presence does not establish tool health or input capability.')
}
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'PROCESS_WINDOW_SNAPSHOT.json') -Encoding utf8
$result | ConvertTo-Json -Depth 8
