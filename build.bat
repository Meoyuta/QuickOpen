@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  QuickOpen Build Script
REM  Uses JDK 17 or 21 from PATH, then JAVA_HOME.
REM ============================================================

set "JAVA_FOUND="
set "JAVA_BIN="
set "PATH_JAVAC_FOUND="

REM --- 1. Check javac from PATH ---
for /f "delims=" %%J in ('where javac 2^>nul') do (
    set "PATH_JAVAC_FOUND=yes"
    if not defined JAVA_FOUND (
        "%%J" -version 2>&1 | findstr /c:"17." /c:"21." >nul 2>&1
        if !errorlevel! == 0 (
            for %%P in ("%%~dpJ..") do set "JAVA_HOME=%%~fP"
            set "JAVA_BIN=%%~dpJ"
            set "JAVA_FOUND=yes"
            echo [INFO] Using JDK from PATH: %%J
        )
    )
)

if defined JAVA_FOUND goto :build
if defined PATH_JAVAC_FOUND (
    echo [WARN] javac was found in PATH, but it is not JDK 17 or 21.
)

REM --- 2. Check JAVA_HOME environment variable ---
if defined JAVA_HOME (
    if exist "%JAVA_HOME%\bin\javac.exe" (
        "%JAVA_HOME%\bin\javac.exe" -version 2>&1 | findstr /c:"17." /c:"21." >nul 2>&1
        if !errorlevel! == 0 (
            set "JAVA_BIN=%JAVA_HOME%\bin"
            set "JAVA_FOUND=yes"
            echo [INFO] Using JAVA_HOME: %JAVA_HOME%
            goto :build
        ) else (
            echo [WARN] JAVA_HOME is set, but it is not JDK 17 or 21: %JAVA_HOME%
        )
    ) else (
        echo [WARN] JAVA_HOME is set, but javac was not found: %JAVA_HOME%\bin\javac.exe
    )
)

REM --- Not found ---
echo [ERROR] Cannot find JDK 17 or 21.
echo.
echo Please either:
echo   1. Add JDK 17 or 21 javac to PATH
echo   2. Set JAVA_HOME to point to a JDK 17 or 21 directory
echo.
exit /b 1

:build
if defined JAVA_BIN (
    set "PATH=%JAVA_BIN%;%PATH%"
)

echo.
echo ============================================================
if defined JAVA_HOME (
    echo  Building QuickOpen with: %JAVA_HOME%
) else (
    echo  Building QuickOpen with javac from PATH
)
echo ============================================================
echo.

REM --- Check for Maven ---
where mvn >nul 2>&1
if %errorlevel% == 0 (
    echo [INFO] Found Maven, building with mvn package...
    call mvn clean package -q
    if %errorlevel% == 0 (
        echo.
        echo [SUCCESS] Build complete. JAR is in target\ directory.
        dir /b target\QuickOpen-*.jar 2>nul
    ) else (
        echo.
        echo [ERROR] Maven build failed.
        exit /b 1
    )
    goto :done
)

REM --- Maven not found, manual compile ---
echo [WARN] Maven not found. Attempting manual compilation...

set "SPIGOT_JAR="
set "PLUGIN_VERSION=1.0.0"

for /f "tokens=2 delims=: " %%V in ('findstr /b "version:" src\main\resources\plugin.yml') do (
    set "PLUGIN_VERSION=%%V"
)

REM Search for Spigot API jar
for /f "delims=" %%F in ('dir /s /b "%USERPROFILE%\.m2\repository\org\spigotmc\spigot-api\*.jar" 2^>nul ^| findstr /v sources ^| findstr /v javadoc') do (
    set "SPIGOT_JAR=%%F"
    goto :found_spigot
)
:found_spigot

if not defined SPIGOT_JAR (
    echo [ERROR] Spigot API jar not found in local Maven cache.
    echo Please install Maven first and run this script again to download dependencies.
    echo Download: https://maven.apache.org/download.cgi
    exit /b 1
)

echo [INFO] Using Spigot API: %SPIGOT_JAR%

if not exist "target\classes" mkdir target\classes

javac -cp "%SPIGOT_JAR%" -d target\classes src\main\java\com\quickopen\QuickOpen.java
if %errorlevel% neq 0 (
    echo [ERROR] Compilation failed.
    exit /b 1
)

copy src\main\resources\plugin.yml target\classes\ >nul

jar cf target\QuickOpen-%PLUGIN_VERSION%.jar -C target\classes .
echo.
echo [SUCCESS] Build complete. JAR is at target\QuickOpen-%PLUGIN_VERSION%.jar

:done
echo.
pause
