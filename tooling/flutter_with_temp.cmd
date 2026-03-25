@echo off
setlocal

for %%I in ("%~dp0..") do set "PROJECT_ROOT=%%~fI"
set "TEMP_DIR=%PROJECT_ROOT%\.tooling-tmp"
set "GRADLE_HOME=%PROJECT_ROOT%\.gradle-user-home"
set "PUB_CACHE_DIR=%PROJECT_ROOT%\.pub-cache"

if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%" >NUL 2>&1
if not exist "%GRADLE_HOME%" mkdir "%GRADLE_HOME%" >NUL 2>&1
if not exist "%PUB_CACHE_DIR%" mkdir "%PUB_CACHE_DIR%" >NUL 2>&1

set "TEMP=%TEMP_DIR%"
set "TMP=%TEMP_DIR%"
set "TMPDIR=%TEMP_DIR%"
set "GRADLE_USER_HOME=%GRADLE_HOME%"
set "PUB_CACHE=%PUB_CACHE_DIR%"

echo Using TEMP=%TEMP%
echo Using TMP=%TMP%
echo Using TMPDIR=%TMPDIR%
echo Using GRADLE_USER_HOME=%GRADLE_USER_HOME%
echo Using PUB_CACHE=%PUB_CACHE%

flutter %*
exit /b %ERRORLEVEL%