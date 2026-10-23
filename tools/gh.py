#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""إدارة GitHub"""
import os

def login():
    return os.environ.get("GITHUB_USER", "")

def token():
    return os.environ.get("GITHUB_TOKEN", os.environ.get("GH_TOKEN", ""))

def repo():
    u = login()
    return f"{u}/{u}.github.io" if u else ""
