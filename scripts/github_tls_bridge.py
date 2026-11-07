"""Plain-HTTP -> GitHub TLS bridge for the z/VM CMS Git client.

z/VM's CMS socket API and the cms-git HTTP client speak plain HTTP.  This
bridge accepts that traffic on 0.0.0.0:8443 and relays it to
github.com:443 over TLS.

Design notes:
* Relay bytes in both directions until EOF.  Do NOT try to detect the end of
  a chunked body: closing a socket as soon as the final chunk is seen can
  truncate a small response that arrived in the same read (observed as
  GITPOST "failed at HTTP-PARSE" for tiny packs).
* After one direction reaches EOF, shutdown() only the write side of the peer
  so queued bytes still drain, then wait for the other direction to finish.
* Log byte counts only; never log headers, which may contain credentials.
"""
from __future__ import annotations

import socket
import ssl
import threading
import time

LOG = "/private/var/folders/y0/hyjtc91x5071jc0gntk0pzcw0000gn/T/github-tls-bridge.log"
UPSTREAM_HOST = "github.com"
UPSTREAM_PORT = 443
LISTEN_PORT = 8443

_loglock = threading.Lock()


def log(text: str) -> None:
    with _loglock:
        with open(LOG, "a") as f:
            f.write(time.strftime("%H:%M:%S ") + text + "\n")


def pump(src: socket.socket, dst: socket.socket, label: str) -> None:
    total = 0
    try:
        while True:
            data = src.recv(65536)
            if not data:
                break
            dst.sendall(data)
            total += len(data)
    except Exception as exc:  # noqa: BLE001 - log and stop this direction
        log(f"{label} ERR {exc!r}")
    finally:
        log(f"{label} eof {total}")
        try:
            dst.shutdown(socket.SHUT_WR)
        except OSError:
            pass


def handle(client: socket.socket, addr: tuple[str, int]) -> None:
    log(f"accept {addr!r}")
    upstream = None
    relay = None
    try:
        raw = socket.create_connection((UPSTREAM_HOST, UPSTREAM_PORT), timeout=30)
        ctx = ssl.create_default_context()
        upstream = ctx.wrap_socket(raw, server_hostname=UPSTREAM_HOST)
        upstream.settimeout(None)
        relay = threading.Thread(
            target=pump, args=(upstream, client, "g>c"), daemon=True
        )
        relay.start()
        pump(client, upstream, "c>g")
        relay.join(timeout=300)
        if relay.is_alive():
            log("g>c still running after 300s; closing")
    except Exception as exc:  # noqa: BLE001
        log(f"handle ERR {exc!r}")
    finally:
        for sock in (upstream, client):
            if sock is None:
                continue
            try:
                sock.close()
            except OSError:
                pass


def main() -> None:
    with socket.socket() as server:
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server.bind(("0.0.0.0", LISTEN_PORT))
        server.listen(32)
        log(f"listen {LISTEN_PORT} -> {UPSTREAM_HOST}:{UPSTREAM_PORT}")
        while True:
            client, addr = server.accept()
            threading.Thread(target=handle, args=(client, addr), daemon=True).start()


if __name__ == "__main__":
    main()
