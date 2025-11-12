@echo off
setlocal enabledelayedexpansion

set "BASEDIR=%~dp0"
set "JAVA="

for /d %%D in ("%BASEDIR%zulu17*") do (
    if exist "%%D\bin\java.exe" (
        set "JAVA=%%D\bin\java.exe"
        goto :found
    )
)

:found
for /f %%t in ('powershell -NoProfile -Command "(Get-Date).ToString(\"yyyy-MM-dd_HH-mm-ss\")"') do set "STAMP=%%t"
set "LOGFILE=%BASEDIR%HML_Log-%STAMP%.txt"

del "%BASEDIR%HML_Log-*.txt" >nul 2>&1

echo [HML LOG - %date% %time%] > "%LOGFILE%"
echo Hello, Minimal Launcher started. >> "%LOGFILE%"
echo Version: 1.0.0 >> "%LOGFILE%"
echo Signature: BDQnS0gABabJAgpfVD8IAA1BQT9NLQ0ZTiAJEVJySFAJHQZFJUVOLA4HA1lWKB0cB08sRVBNWAB8Vw >> "%LOGFILE%"
echo. >> "%LOGFILE%"

if not defined JAVA (
    echo [ERROR] Java not found in any "zulu17*" folder. >> "%LOGFILE%"
    echo Java 17 not found! Did you delete the Azul Zulu folder?
    pause
    exit /b 1
)

if not exist "%BASEDIR%hmcl.jar" (
    echo [ERROR] HMCL jar not found. >> "%LOGFILE%"
    echo HMCL not found in folder:
    echo %BASEDIR%
    pause
    exit /b 1
)

echo Using Java: %JAVA%
echo [INFO] Using Java: %JAVA% >> "%LOGFILE%"
"%JAVA%" -version >> "%LOGFILE%" 2>&1

echo [INFO] Launching Hello Minecraft! Launcher... >> "%LOGFILE%"
echo Running Hello, Minimal Launcher...
"%JAVA%" -jar "%BASEDIR%hmcl.jar" >> "%LOGFILE%" 2>&1

if errorlevel 1 (
    echo.
    echo HML encountered a critical error. Please send "%LOGFILE%" to Lykke.
    echo [CRASH] HMCL exited with error code %errorlevel%. >> "%LOGFILE%"
    pause
    exit /b %errorlevel%
)

echo [INFO] Hello Minecraft! Launcher exited normally. >> "%LOGFILE%"
echo Hello, Minimal Launcher exited normally. >> "%LOGFILE%"
pause
