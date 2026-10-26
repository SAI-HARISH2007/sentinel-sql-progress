#!/usr/bin/env bash
# Starts the Sentinel web app on http://127.0.0.1:5000
# Needs the database already running (see ../LAB_SETUP.md).
cd "$(dirname "$0")"
[ -d .venv ] || python3 -m venv .venv
if [ -d wheels ]; then
  .venv/bin/pip install -q --no-index --find-links wheels -r requirements.txt
else
  .venv/bin/pip install -q -r requirements.txt
fi
exec .venv/bin/python app.py
