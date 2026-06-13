@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  QuickOpen Build Script
REM  Auto-detects JDK 17 or 21 (skips JDK 25)
REM ============================================================

set "JAVA_FOUND="

REM --- 0. Known JDK path ---
if exist "D:\java\jdk-21\bin\javac.exe" (
    set "JAVA_HOME=D:\java\jdk-21"
    set "JAVA_FOUND=yes"
    echo [INFO] Found JDK: D:\java\jdk-21
    goto :build
)

REM --- 1. Check JAVA_HOME environment variable ---
if defined JAVA_HOME (
    "%JAVA_HOME%\bin\javac" -version 2>nul | findstr /r "17\.\|21\." >nul 2>&1
    if !errorlevel! == 0 (
        set "JAVA_HOME=%JAVA_HOME%"
        set "JAVA_FOUND=yes"
        echo [INFO] Using JAVA_HOME: %JAVA_HOME%
        goto :build
    )
)

REM --- 2. Search common JDK install directories ---
for /d %%D in (
    "C:\Program Files\Java\jdk-21*"
    "C:\Program Files\Java\jdk-17*"
    "C:\Program Files\Eclipse Adoptium\jdk-21*"
    "C:\Program Files\Eclipse Adoptium\jdk-17*"
    "C:\Program Files\Microsoft\jdk-21*"
    "C:\Program Files\Microsoft\jdk-17*"
    "C:\Program Files\Zulu\zulu-21*"
    "C:\Program Files\Zulu\zulu-17*"
    "%USERPROFILE%\.jdks\jdk-21*"
    "%USERPROFILE%\.jdks\jdk-17*"
    "%LOCALAPPDATA%\Programs\Eclipse Adoptium\jdk-21*"
    "%LOCALAPPDATA%\Programs\Eclipse Adoptium\jdk-17*"
    "%APPDATA%\Java\jdk-21*"
    "%APPDATA%\Java\jdk-17*"
) do (
    if exist "%%~D\bin\javac.exe" (
        set "JAVA_HOME=%%~D"
        set "JAVA_FOUND=yes"
        echo [INFO] Found JDK: %%~D
        goto :build
    )
)

REM --- 3. Search entire Program Files tree (slower fallback) ---
for /f "delims=" %%D in ('dir /s /b /ad "C:\Program Files\*jdk*17*" 2^>nul ^| findstr /i "jdk"') do (
    if exist "%%D\bin\javac.exe" (
        set "JAVA_HOME=%%D"
        set "JAVA_FOUND=yes"
        echo [INFO] Found JDK: %%D
        goto :build
    )
)
for /f "delims=" %%D in ('dir /s /b /ad "C:\Program Files\*jdk*21*" 2^>nul ^| findstr /i "jdk"') do (
    if exist "%%D\bin\javac.exe" (
        set "JAVA_HOME=%%D"
        set "JAVA_FOUND=yes"
        echo [INFO] Found JDK: %%D
        goto :build
    )
)

REM --- 4. Try JAVA_HOME_17 / JAVA_HOME_21 env vars ---
if defined JAVA_HOME_17 (
    set "JAVA_HOME=%JAVA_HOME_17%"
    set "JAVA_FOUND=yes"
    echo [INFO] Using JAVA_HOME_17: %JAVA_HOME_17%
    goto :build
)
if defined JAVA_HOME_21 (
    set "JAVA_HOME=%JAVA_HOME_21%"
    set "JAVA_FOUND=yes"
    echo [INFO] Using JAVA_HOME_21: %JAVA_HOME_21%
    goto :build
)

REM --- Not found ---
echo [ERROR] Cannot find JDK 17 or 21.
echo.
echo Please install JDK 17 or 21, then either:
echo   1. Set JAVA_HOME to point to the JDK directory
echo   2. Set JAVA_HOME_17 or JAVA_HOME_21 environment variable
echo   3. Install to one of the standard directories:
echo      C:\Program Files\Java\jdk-17.x.x
echo      C:\Program Files\Java\jdk-21.x.x
echo.
exit /b 1

:build
echo.
echo ============================================================
echo  Building QuickOpen with: %JAVA_HOME%
echo ============================================================
echo.

REM --- Check for Maven ---
where mvn >nul 2>&1
if %errorlevel% == 0 (
    echo [INFO] Found Maven, building with mvn package...
    set "PATH=%JAVA_HOME%\bin;%PATH%"
    call mvn clean package -q
    if %errorlevel% == 0 (
        echo.
        echo [SUCCESS] Build complete! JAR is in target\ directory.
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

set "PATH=%JAVA_HOME%\bin;%PATH%"
set "SPOIGOT_JAR="

REM Search for Spigot API jar
for /f "delims=" %%F in ('dir /s /b "%USERPROFILE%\.m2\repository\org\spigotmc\spigot-api\*.jar" 2^>nul ^| findstr /v sources ^| findstr /v javadoc') do (
    set "SPOIGOT_JAR=%%F"
    goto :found_spigot
)
:found_spigot

if not defined SPOIGOT_JAR (
    echo [ERROR] Spigot API jar not found in local Maven cache.
    echo Please install Maven first and run this script again to download dependencies.
    echo Download: https://maven.apache.org/download.cgi
    exit /b 1
)

echo [INFO] Using Spigot API: %SPOIGOT_JAR%

if not exist "target\classes" mkdir target\classes

javac -cp "%SPOIGOT_JAR%" -d target\classes src\main\java\com\quickopen\QuickOpen.java
if %errorlevel% neq 0 (
    echo [ERROR] Compilation failed.
    exit /b 1
)

copy src\main\resources\plugin.yml target\classes\ >nul

jar cf target\QuickOpen-1.0.0.jar -C target\classes .
echo.
echo [SUCCESS] Build complete! JAR is at target\QuickOpen-1.0.0.jar

:done
echo.
pause
