param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FlutterArgs
)

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$tempRoot = Join-Path $projectRoot '.tooling-tmp'
$gradleUserHome = Join-Path $projectRoot '.gradle-user-home'
$pubCache = Join-Path $projectRoot '.pub-cache'

New-Item -ItemType Directory -Force $tempRoot, $gradleUserHome, $pubCache | Out-Null

$env:TEMP = $tempRoot
$env:TMP = $tempRoot
$env:TMPDIR = $tempRoot
$env:GRADLE_USER_HOME = $gradleUserHome
$env:PUB_CACHE = $pubCache

Write-Host "Using TEMP=$env:TEMP"
Write-Host "Using TMP=$env:TMP"
Write-Host "Using TMPDIR=$env:TMPDIR"
Write-Host "Using GRADLE_USER_HOME=$env:GRADLE_USER_HOME"
Write-Host "Using PUB_CACHE=$env:PUB_CACHE"

& flutter @FlutterArgs
exit $LASTEXITCODE