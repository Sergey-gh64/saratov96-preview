#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path


def fail(message: str) -> None:
    raise SystemExit(f"S96_WEB_RELEASE_FAIL: {message}")


def main() -> None:
    if len(sys.argv) != 4:
        fail("usage: prepare_web_release.py <web_dir> <commit> <version>")

    root = Path(sys.argv[1]).resolve()
    commit = sys.argv[2].strip()
    version = sys.argv[3].strip()

    index = root / "index.html"
    wasm = root / "index.wasm"
    pck = root / "index.pck"
    for required in (index, wasm, pck):
        if not required.is_file() or required.stat().st_size == 0:
            fail(f"missing export artifact: {required.name}")

    html = index.read_text(encoding="utf-8")
    viewport = '<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no,viewport-fit=cover">'
    html, count = re.subn(r'<meta\s+name=["\']viewport["\'][^>]*>', viewport, html, count=1, flags=re.I)
    if count == 0:
        html = html.replace("</head>", viewport + "\n</head>", 1)

    marker = f'<meta name="s96-build" content="{version}:{commit}">'
    if 'name="s96-build"' not in html:
        html = html.replace("</head>", marker + "\n</head>", 1)

    fresh_boot = """<script id="s96-fresh-build">
(function(){
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.getRegistrations().then(function(items){
      items.forEach(function(reg){ reg.unregister(); });
    }).catch(function(){});
  }
  if ('caches' in window) {
    caches.keys().then(function(keys){
      keys.forEach(function(key){ caches.delete(key); });
    }).catch(function(){});
  }
})();
</script>"""
    if 'id="s96-fresh-build"' not in html:
        html = html.replace("</body>", fresh_boot + "\n</body>", 1)

    index.write_text(html, encoding="utf-8")

    manifest = {
        "name": "Саратов ’96 GO",
        "short_name": "Саратов 96",
        "start_url": "./",
        "scope": "./",
        "display": "standalone",
        "orientation": "portrait",
        "background_color": "#071015",
        "theme_color": "#071015",
    }
    (root / "manifest.webmanifest").write_text(
        json.dumps(manifest, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    (root / "build.json").write_text(
        json.dumps(
            {
                "version": version,
                "commit": commit,
                "built_at": datetime.now(timezone.utc).isoformat(),
            },
            ensure_ascii=False,
            indent=2,
        ),
        encoding="utf-8",
    )
    (root / ".nojekyll").write_text("", encoding="utf-8")

    for legacy in ("sw.js", "service_worker.js", "service_worker.js.offline.html"):
        path = root / legacy
        if path.exists():
            path.unlink()

    final_html = index.read_text(encoding="utf-8")
    if "viewport-fit=cover" not in final_html:
        fail("safe-area viewport marker missing")
    if 'name="s96-build"' not in final_html:
        fail("build marker missing")
    if "serviceWorker.register" in final_html:
        fail("new build must not register a service worker")
    if not (root / "manifest.webmanifest").is_file():
        fail("manifest missing")
    if not (root / "build.json").is_file():
        fail("build marker file missing")

    print("S96_WEB_RELEASE_OK=1")
    print(f"S96_BUILD_VERSION={version}")
    print(f"S96_BUILD_COMMIT={commit}")


if __name__ == "__main__":
    main()
