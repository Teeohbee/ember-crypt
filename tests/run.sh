#!/usr/bin/env bash
# Runs every gdUnit4 suite in tests/ headless. -c keeps going after a failure so you see them all.
# Pass a suite path to run just that one: tests/run.sh res://tests/test_game_settings.gd
cd "$(dirname "$0")/.." || exit 1
if [ ! -d addons/gdUnit4 ]; then
	echo "gdUnit4 isn't installed. Run: godot --headless -s plug.gd install" >&2
	exit 1
fi
# Import first so Godot knows every class_name on a fresh clone or after adding a file
godot --headless --path . --import >/dev/null 2>&1
godot --headless --path . -s -d --remote-debug tcp://127.0.0.1:0 \
	res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a "${1:-res://tests}" -c --ignoreHeadlessMode
