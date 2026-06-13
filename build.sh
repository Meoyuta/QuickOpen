#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  QuickOpen Build Script
#  Uses JDK 17 or 21 from PATH, then JAVA_HOME.
# ============================================================

java_found=""
java_bin=""
path_javac_found=""

is_supported_javac() {
    local javac_cmd="$1"
    local version
    version="$("$javac_cmd" -version 2>&1 || true)"
    [[ "$version" =~ (17\.|21\.) ]]
}

# --- 1. Check javac from PATH ---
if command -v javac >/dev/null 2>&1; then
    path_javac_found="yes"
    javac_path="$(command -v javac)"
    if is_supported_javac "$javac_path"; then
        resolved_javac="$(readlink -f "$javac_path" 2>/dev/null || printf '%s' "$javac_path")"
        JAVA_HOME="$(dirname "$(dirname "$resolved_javac")")"
        export JAVA_HOME
        java_bin="$(dirname "$resolved_javac")"
        java_found="yes"
        echo "[INFO] Using JDK from PATH: $javac_path"
    fi
fi

if [[ -z "$java_found" && -n "$path_javac_found" ]]; then
    echo "[WARN] javac was found in PATH, but it is not JDK 17 or 21."
fi

# --- 2. Check JAVA_HOME environment variable ---
if [[ -z "$java_found" && -n "${JAVA_HOME:-}" ]]; then
    if [[ -x "$JAVA_HOME/bin/javac" ]]; then
        if is_supported_javac "$JAVA_HOME/bin/javac"; then
            java_bin="$JAVA_HOME/bin"
            java_found="yes"
            echo "[INFO] Using JAVA_HOME: $JAVA_HOME"
        else
            echo "[WARN] JAVA_HOME is set, but it is not JDK 17 or 21: $JAVA_HOME"
        fi
    else
        echo "[WARN] JAVA_HOME is set, but javac was not found: $JAVA_HOME/bin/javac"
    fi
fi

if [[ -z "$java_found" ]]; then
    echo "[ERROR] Cannot find JDK 17 or 21."
    echo
    echo "Please either:"
    echo "  1. Add JDK 17 or 21 javac to PATH"
    echo "  2. Set JAVA_HOME to point to a JDK 17 or 21 directory"
    exit 1
fi

export PATH="$java_bin:$PATH"

echo
echo "============================================================"
echo " Building QuickOpen with: $JAVA_HOME"
echo "============================================================"
echo

# --- Check for Maven ---
if command -v mvn >/dev/null 2>&1; then
    echo "[INFO] Found Maven, building with mvn package..."
    mvn clean package -q
    echo
    echo "[SUCCESS] Build complete! JAR is in target/ directory."
    find target -maxdepth 1 -type f -name "QuickOpen-*.jar" -printf "%f\n" 2>/dev/null || true
    exit 0
fi

# --- Maven not found, manual compile ---
echo "[WARN] Maven not found. Attempting manual compilation..."

plugin_version="$(awk -F ': *' '$1 == "version" { print $2; exit }' src/main/resources/plugin.yml)"
plugin_version="${plugin_version:-1.0.0}"

spigot_repo="$HOME/.m2/repository/org/spigotmc/spigot-api"
spigot_jar=""
if [[ -d "$spigot_repo" ]]; then
    spigot_jar="$(find "$spigot_repo" -type f -name "*.jar" ! -name "*sources*" ! -name "*javadoc*" | sort -V | tail -n 1 || true)"
fi

if [[ -z "$spigot_jar" ]]; then
    echo "[ERROR] Spigot API jar not found in local Maven cache."
    echo "Please install Maven first and run this script again to download dependencies."
    echo "Download: https://maven.apache.org/download.cgi"
    exit 1
fi

echo "[INFO] Using Spigot API: $spigot_jar"

mkdir -p target/classes

javac -cp "$spigot_jar" -d target/classes src/main/java/com/quickopen/QuickOpen.java
cp src/main/resources/plugin.yml target/classes/

jar cf "target/QuickOpen-$plugin_version.jar" -C target/classes .
echo
echo "[SUCCESS] Build complete! JAR is at target/QuickOpen-$plugin_version.jar"
