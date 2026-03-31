$ErrorActionPreference = 'Stop'

$chromePath = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$htmlPath = 'd:\Fachri\WORKSPACES\CatatCuan\output\panduan-catatcuan-ujikom.html'
$pdfPath = 'd:\Fachri\WORKSPACES\CatatCuan\output\Panduan_Aplikasi_CatatCuan_Ujikom.pdf'
$profileDir = 'd:\Fachri\WORKSPACES\CatatCuan\output\chrome-devtools-profile'
$port = 9223

if (!(Test-Path $chromePath)) {
  throw "Chrome tidak ditemukan di $chromePath"
}

if (!(Test-Path $htmlPath)) {
  throw "File HTML tidak ditemukan di $htmlPath"
}

if (!(Test-Path $profileDir)) {
  New-Item -ItemType Directory -Path $profileDir | Out-Null
}

$htmlUri = 'file:///' + (($htmlPath -replace '\\', '/') -replace '^([A-Za-z]):', '$1:')

$chromeArgs = @(
  '--headless=new'
  '--disable-gpu'
  '--disable-crash-reporter'
  '--no-first-run'
  '--no-default-browser-check'
  "--remote-debugging-port=$port"
  "--user-data-dir=$profileDir"
  'about:blank'
)

$process = Start-Process -FilePath $chromePath -ArgumentList $chromeArgs -PassThru -WindowStyle Hidden

try {
  $targetInfo = $null
  for ($i = 0; $i -lt 20; $i++) {
    try {
      $targets = Invoke-RestMethod -Uri "http://127.0.0.1:$port/json/list" -TimeoutSec 2
      $targetInfo = @($targets) | Where-Object { $_.type -eq 'page' } | Select-Object -First 1
      if ($targetInfo) { break }
    } catch {
      Start-Sleep -Milliseconds 500
    }
  }

  if (-not $targetInfo) {
    throw 'Tidak bisa menemukan target halaman Chrome DevTools.'
  }

  $ws = [System.Net.WebSockets.ClientWebSocket]::new()
  $ws.ConnectAsync([Uri]$targetInfo.webSocketDebuggerUrl, [Threading.CancellationToken]::None).GetAwaiter().GetResult() | Out-Null

  function Send-DevToolsMessage {
    param(
      [System.Net.WebSockets.ClientWebSocket]$Socket,
      [int]$Id,
      [string]$Method,
      [hashtable]$Params
    )

    $payload = @{
      id = $Id
      method = $Method
    }

    if ($Params) {
      $payload.params = $Params
    }

    $json = $payload | ConvertTo-Json -Compress -Depth 10
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $segment = [ArraySegment[byte]]::new($bytes)
    $Socket.SendAsync(
      $segment,
      [System.Net.WebSockets.WebSocketMessageType]::Text,
      $true,
      [Threading.CancellationToken]::None
    ).GetAwaiter().GetResult() | Out-Null
  }

  function Receive-DevToolsMessage {
    param([System.Net.WebSockets.ClientWebSocket]$Socket)

    $buffer = New-Object byte[] 65536
    $builder = New-Object System.Text.StringBuilder

    do {
      $segment = [ArraySegment[byte]]::new($buffer)
      $result = $Socket.ReceiveAsync($segment, [Threading.CancellationToken]::None).GetAwaiter().GetResult()

      if ($result.MessageType -eq [System.Net.WebSockets.WebSocketMessageType]::Close) {
        throw 'Koneksi DevTools ditutup sebelum render selesai.'
      }

      $builder.Append([System.Text.Encoding]::UTF8.GetString($buffer, 0, $result.Count)) | Out-Null
    } while (-not $result.EndOfMessage)

    return $builder.ToString()
  }

  Send-DevToolsMessage -Socket $ws -Id 1 -Method 'Page.enable' -Params @{}
  Send-DevToolsMessage -Socket $ws -Id 2 -Method 'Runtime.enable' -Params @{}
  Send-DevToolsMessage -Socket $ws -Id 3 -Method 'Emulation.setEmulatedMedia' -Params @{ media = 'print' }
  Send-DevToolsMessage -Socket $ws -Id 4 -Method 'Page.navigate' -Params @{ url = $htmlUri }

  $loaded = $false
  while (-not $loaded) {
    $message = Receive-DevToolsMessage -Socket $ws
    if ($message -match '"method":"Page.loadEventFired"') {
      $loaded = $true
    }
  }

  Start-Sleep -Milliseconds 1200

  $footerTemplate = "<div style='width:100%; font-size:9px; color:#6b7280; text-align:center; padding:0 12mm;'><span class='pageNumber'></span></div>"
  $headerTemplate = "<div></div>"

  Send-DevToolsMessage -Socket $ws -Id 5 -Method 'Page.printToPDF' -Params @{
    printBackground = $true
    displayHeaderFooter = $true
    headerTemplate = $headerTemplate
    footerTemplate = $footerTemplate
    preferCSSPageSize = $true
    marginTop = 0.87
    marginBottom = 0.87
    marginLeft = 0.7
    marginRight = 0.7
  }

  $pdfBase64 = $null
  while (-not $pdfBase64) {
    $message = Receive-DevToolsMessage -Socket $ws
    $parsed = $message | ConvertFrom-Json

    if ($parsed.id -eq 5 -and $parsed.result.data) {
      $pdfBase64 = $parsed.result.data
    }
  }

  [IO.File]::WriteAllBytes($pdfPath, [Convert]::FromBase64String($pdfBase64))

  if ($ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
    $ws.CloseAsync(
      [System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure,
      'done',
      [Threading.CancellationToken]::None
    ).GetAwaiter().GetResult() | Out-Null
  }

  Write-Output "PDF berhasil dibuat: $pdfPath"
} finally {
  if ($process -and -not $process.HasExited) {
    Stop-Process -Id $process.Id -Force
  }
}
