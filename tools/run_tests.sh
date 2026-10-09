#!/usr/bin/env bash
# Lance toute la verification du projet en ligne de commande :
#   1. assemblage du jeu (src/main.s) et des tests visuels ;
#   2. tests unitaires (tests/test_unitaires.s) ;
#   3. partie complete jouee par le pilote automatique (tests/capture.s).
#
# RARS est telecharge dans tools/rars.jar s'il n'est pas deja present.
# Une autre copie peut etre utilisee : RARS_JAR=/chemin/vers/rars.jar tools/run_tests.sh

set -euo pipefail

cd "$(dirname "$0")/.."

RARS_VERSION="1.6"
RARS_URL="https://github.com/TheThirdOne/rars/releases/download/v${RARS_VERSION}/rars1_6.jar"
RARS_JAR="${RARS_JAR:-tools/rars.jar}"

if [ ! -f "$RARS_JAR" ]; then
    echo "Telechargement de RARS ${RARS_VERSION}..."
    curl -fsSL -o "$RARS_JAR" "$RARS_URL"
fi

rars() {
    java -jar "$RARS_JAR" nc "$@"
}

echo "== Assemblage =="
for file in src/main.s tests/test_affichage.s tests/test_scene.s; do
    output="$(rars a "$file" 2>&1)"
    if echo "$output" | grep -qi "error"; then
        echo "$output"
        echo "ECHEC : $file ne s'assemble pas."
        exit 1
    fi
    echo "[OK]     $file"
done

echo
echo "== Tests unitaires =="
rars tests/test_unitaires.s | grep -v "^$"

echo
echo "== Partie complete (pilote automatique) =="
capture="$(mktemp)"
rars tests/capture.s > "$capture"
if ! grep -qE "VICTOIRE|DEFAITE" "$capture"; then
    grep -v "^#F" "$capture" | tail -n 20
    echo "ECHEC : la partie ne s'est pas terminee normalement."
    exit 1
fi
grep -v "^#F" "$capture" | grep -E "VICTOIRE|DEFAITE|Score final"
echo "[OK]     $(grep -c '^#F' "$capture") frames simulees"

if [ "${1:-}" = "--demo" ]; then
    python3 tools/render_capture.py "$capture" --gif docs/demo.gif --png docs/screenshot.png
fi
rm -f "$capture"

echo
echo "Tout est correct."
