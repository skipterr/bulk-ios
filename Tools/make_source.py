#!/usr/bin/env python3
# Собирает apps.json — каталог для AltStore. Ссылка на него постоянная:
# https://github.com/skipterr/bulk-ios/releases/latest/download/apps.json
# Запуск: make_source.py <версия> <тег релиза> <путь к Bulk.ipa> <что нового> <куда записать>
import datetime
import hashlib
import json
import os
import sys

REPO = "https://github.com/skipterr/bulk-ios"

version, tag, ipa, notes, out = sys.argv[1:6]

with open(ipa, "rb") as f:
    sha256 = hashlib.sha256(f.read()).hexdigest()

source = {
    "name": "Бульк",
    "identifier": "com.bulk.source",
    "subtitle": "Живой персонаж для iPhone",
    "description": "Бульк живёт на виджете и в приложении.",
    "website": REPO,
    "apps": [{
        "name": "Bulk",
        "bundleIdentifier": "com.bulk.app",
        "developerName": "Bulk",
        "subtitle": "Живой персонаж на виджете",
        "localizedDescription": "Бульк живёт своей жизнью на виджете, а в приложении с ним можно болтать, "
                                "наливать ему и обустраивать комнату. Для чата нужен свой бесплатный ключ Gemini.",
        "iconURL": f"{REPO}/releases/latest/download/icon.png",
        "tintColor": "#6CC33A",
        "versions": [{
            "version": version,
            "date": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S+00:00"),
            "localizedDescription": notes,
            "downloadURL": f"{REPO}/releases/download/{tag}/Bulk.ipa",
            "size": os.path.getsize(ipa),
            "sha256": sha256,
            "minOSVersion": "17.0",
        }],
        "appPermissions": {
            "entitlements": [{"name": "com.apple.security.application-groups"}],
            "privacy": [],
        },
    }],
    "news": [],
}

with open(out, "w", encoding="utf-8") as f:
    json.dump(source, f, ensure_ascii=False, indent=2)
