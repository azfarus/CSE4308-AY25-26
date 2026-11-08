#!/usr/bin/env bash
#
# compile_labs.sh — build every CSE 4308 lab manual in this folder into PDFs.
#
# Usage:
#   ./compile_labs.sh            compile all labs
#   ./compile_labs.sh lab_04     compile only labs whose folder name starts with "lab_04"
#   ./compile_labs.sh clean      delete every lab's pdf/ folder and build/
#
# Also builds manuals one level deeper, in a lab's group subfolder
# (e.g. lab_03_ddl_dml/lab_03_1a/lab_03_1a.tex -> lab_03_ddl_dml/lab_03_1a/pdf/).
#
# Output:
#   <lab folder>/pdf/<name>.pdf  one PDF per .tex file
#                                (e.g. lab_04_.../pdf/lab_04_monday_1.pdf)
#   build/logs/<name>.log        full LaTeX log, check this when a file fails
#   build/tmp/                   LaTeX scratch files (.aux, .toc, ...), safe to delete
#
# Each .tex file is compiled from inside its own lab folder, so images and
# other assets are referenced by plain file name (e.g. lab_04_schema.pdf).

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
LOG_DIR="$BUILD_DIR/logs"
AUX_DIR="$BUILD_DIR/tmp"   # not "aux": reserved name on NTFS/exFAT drives

FILTER="${1:-lab_}"

# ---------------------------------------------------------------- helpers

compile_one() {
    local tex_file="$1"
    local lab_dir name
    lab_dir="$(dirname "$tex_file")"
    name="$(basename "$tex_file" .tex)"

    # LuaLaTeX + fontspec: code listings copy out of the PDF as exact ASCII
    # (straight quotes, no stray spaces). latexmk re-runs as often as needed.
    if (cd "$lab_dir" && latexmk -lualatex -interaction=nonstopmode -halt-on-error \
            -outdir="$AUX_DIR/$name" "$name.tex") > "$LOG_DIR/$name.log" 2>&1; then
        mkdir -p "$lab_dir/pdf"
        cp "$AUX_DIR/$name/$name.pdf" "$lab_dir/pdf/$name.pdf"
        return 0
    fi
    return 1
}

# ---------------------------------------------------------------- main

if [[ "$FILTER" == "clean" ]]; then
    rm -rf "$BUILD_DIR" "$SCRIPT_DIR"/lab_*/pdf "$SCRIPT_DIR"/lab_*/lab_*/pdf
    echo "Removed build/ and every lab_*/pdf/ folder"
    exit 0
fi

if ! command -v latexmk > /dev/null; then
    echo "Error: latexmk not found. Install TeX Live (texlive-scheme-full or similar)." >&2
    exit 1
fi

mkdir -p "$BUILD_DIR" "$LOG_DIR" "$AUX_DIR"

passed=()
failed=()

for lab_dir in "$SCRIPT_DIR"/"$FILTER"*/; do
    [[ -d "$lab_dir" ]] || continue
    echo "== $(basename "$lab_dir")"

    for tex_file in "$lab_dir"lab_*.tex "$lab_dir"lab_*/lab_*.tex; do
        [[ -f "$tex_file" ]] || continue
        name="$(basename "$tex_file" .tex)"
        rel="${tex_file#"$lab_dir"}"     # lab_03_main.tex or lab_03_1a/lab_03_1a.tex

        if compile_one "$tex_file"; then
            echo "   OK    $(dirname "$rel" | sed 's|^\.$||;s|.$|&/|')pdf/$name.pdf"
            passed+=("$name")
        else
            echo "   FAIL  $name   (see build/logs/$name.log)"
            failed+=("$name")
        fi
    done
done

echo
echo "Compiled: ${#passed[@]}   Failed: ${#failed[@]}   (PDFs are in each lab's pdf/ folder)"

if (( ${#failed[@]} > 0 )); then
    printf '  failed: %s\n' "${failed[@]}"
    exit 1
fi
