# Vercel entry point (Flask zero-config): exposes the app from report/app.py
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "report"))

from app import app  # noqa: E402,F401
