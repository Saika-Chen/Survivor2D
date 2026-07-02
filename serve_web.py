#!/usr/bin/env python3
"""Godot 4 Web Export Server with HTTPS and required COOP/COEP headers."""
import argparse
import http.server
import os
import socket
import ssl
import subprocess
import textwrap
from pathlib import Path

PORT = 8080
DIR = os.path.dirname(os.path.abspath(__file__))
CERT_DIR = Path(DIR) / ".web_cert"
FALLBACK_CERT = """\
-----BEGIN CERTIFICATE-----
MIICyTCCAbGgAwIBAgIJAKhxmnXrpV8hMA0GCSqGSIb3DQEBCwUAMBQxEjAQBgNV
BAMMCWxvY2FsaG9zdDAeFw0yNjA2MzAxODEwMTBaFw0zNjA2MjcxODEwMTBaMBQx
EjAQBgNVBAMMCWxvY2FsaG9zdDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
ggEBAOiTBWXYsHKDMYyzFFTcXAcgRxUlgAehN6bmdjWUU4JRr4MGPkyyu0gg9+SB
7wTlum76dAfgV+2lPm4jX0IYbshQf1FotS3EkYdkOAnjZeC2TCVAJpYCP3fvWAP+
y8iXLwamztsAPD1YHEJkXG6Qc4MfdE6U01NEwf5ZuVG0Lo1KcwyHk4gnxABK2h3c
jNW3fJVQOQlmdMqLSIjdKmH52zY5nU2H3c4R3pE1hd6Vm3mLF1eMzxeRoobAuWl9
3/AS1ugnYWcKPrmwdBuqGfZVHppqn/bEbKtUsrZrFpIB9TBFw7OKjfV3/Mrhld/6
OX5rEpXk8BvylaUy32pV0LVIAh0CAwEAAaMeMBwwGgYDVR0RBBMwEYIJbG9jYWxo
b3N0hwR/AAABMA0GCSqGSIb3DQEBCwUAA4IBAQCiIvao1boLyjVrtIGX2kt+tLuy
QT0nHavCT1Tz9DVdhekJ+B7mq+cTZxIsdkyOMnkaXGJbSzUQ44L4hLVDMEHWfkmL
P05lNrKBYWAELqJapiBqyMQZw+cA5DeKL3xOE5HdnEKRaGyhBP66IC5G+UUySViC
pv/52+Xx/0h96fj0TmducBlWBLuZfKi1A3G/WWAakoC5tqOd2hHSA7gxmWqyr17D
9RyqVbeJIIIeZ7YjBdVeGe5TjoKRDR2yQboPVfw3ZG3UqhdMaVmKAD5+lWtvIg/c
9ihkpI60anLlX14Or/4FROcrb3VweG+TP4uBif/xs74w+8c8rJHEY36pUb7g
-----END CERTIFICATE-----
"""
FALLBACK_KEY = """\
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDokwVl2LBygzGM
sxRU3FwHIEcVJYAHoTem5nY1lFOCUa+DBj5MsrtIIPfkge8E5bpu+nQH4FftpT5u
I19CGG7IUH9RaLUtxJGHZDgJ42XgtkwlQCaWAj9371gD/svIly8Gps7bADw9WBxC
ZFxukHODH3ROlNNTRMH+WblRtC6NSnMMh5OIJ8QAStod3IzVt3yVUDkJZnTKi0iI
3Sph+ds2OZ1Nh93OEd6RNYXelZt5ixdXjM8XkaKGwLlpfd/wEtboJ2FnCj65sHQb
qhn2VR6aap/2xGyrVLK2axaSAfUwRcOzio31d/zK4ZXf+jl+axKV5PAb8pWlMt9q
VdC1SAIdAgMBAAECggEBAKvDUPw7wWyBCcogw8Y8jFbS9sxeSqTX4vMHR4wghGA9
lcLNjJs2cOw/NPT1JSJXy42EuMbMYAPpwyayRvrYcpDMKotkKlKn1tbIJD7hS29f
EvN74kNtW5RnFni056m4RgnCjgjdrp+bgBtkZYNeeYEAbPRQI5ZetGr1ttDpomvD
hGAxhQueTrLhZlbWV/1YtoXCG+x1UfCv7d1t7hfcD+4RBYxYkJfLBW0+iD1IbzpS
0gifndxnIPX89enK2HAjJe7Y5T3d4AidRP5sWPOiY4OmgOGaUvyteRvnKmrV8d+/
8SKf5r90XALk2fp9jc20go5df3Lzislq5ZXi6x9Y3R0CgYEA/pseHXXgbRqxvQe5
9zBu6yW8/xu4p48HFPdT5OTcgZQ59adDMxhTf2o6DaA6+9+z5pUe5Tdb3y/vJXbF
UfjDpoN4Qgakpg7bAhHrwSUOcYImaEKj8wS3jjOKLTlUt4ArX/PNS5UWtgXN3gLp
DYJudIZ5zhPnYqvoC8+GphBpYvsCgYEA6dkFiDe9ZZV2MuRx+xkxABfG92YG4R/7
V4L7SBIpd/szS3vxogHkvkgOOPMHFtiV4ivGb3rE/xsax72ikPx6oOCq+bQF37gY
69KB1k12pIP9jUFIU2euXtk6S+C+T4I3JbhcWXz4+NU5u2O8jJgx3f8ALUIF/vib
O2/mqTIvY8cCgYBiaqmQb8FJy1jLHhJ3h6RIhzTwU9HkCziMlTI7t2+5MwfYekhS
luOny/MW00oZlJZg2mGv7t83fbrue2O41PUkB4vT0eeRPQrRWQYNifp0S//2q1Pe
m4Msl6Wg55lkuUmK9J31ynKV99ZlLDDUBQgXSOgKjc0Sairvbc+5n3xtQwKBgFC1
aVZhPon/8sKP29L5F9NbYX1jhj5OxnWmrElsk0lotoR366aplqQhxF7dafX1nI1p
5Fv3eGQ/m5eSmLgHm99Ii1oRSvGy3U8O4WbwZ2FSeME25dp7b1AnExq7H5PbcmMf
ZSgxnNBs7zcArkOsB5IB/7KfFeixLwptjaOZwYdjAoGBAOXuG/R4NZEoXC6JTglu
vM/AEqqsWsK3XK2GKA9xOCeehzvooR/3J+xIGeMzWoafNLOo8cwMvDrrhEyhuqbu
BjxlJDVendt/NXT++0yZLpx7RqDy9MdqeNSQa3XHTs1LYtMT/cQbkN5wdbxPsRQr
nuDgM+Iu6w3BQbSOORBD2LiZ
-----END PRIVATE KEY-----
"""


class GodotHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()

    def log_message(self, format, *args):
        print(f"[{self.client_address[0]}] {args[0]}")


def parse_args(argv=None):
    parser = argparse.ArgumentParser(
        description="Serve Godot Web exports for local/LAN testing."
    )
    parser.add_argument("--port", type=int, default=PORT)
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument(
        "--http",
        action="store_true",
        help="Use plain HTTP. LAN clients may fail Godot's Secure Context check.",
    )
    parser.add_argument(
        "--cert-dir",
        type=Path,
        default=CERT_DIR,
        help="Directory for the generated HTTPS certificate.",
    )
    args = parser.parse_args(argv)
    args.https = not args.http
    return args


def get_lan_ips():
    ips = set()
    try:
        hostname = socket.gethostname()
        for ip in socket.gethostbyname_ex(hostname)[2]:
            if not ip.startswith("127."):
                ips.add(ip)
    except OSError:
        pass

    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.connect(("8.8.8.8", 80))
        ip = sock.getsockname()[0]
        if not ip.startswith("127."):
            ips.add(ip)
    except OSError:
        pass
    finally:
        try:
            sock.close()
        except UnboundLocalError:
            pass

    return sorted(ips)


def ensure_certificate(cert_dir, lan_ips):
    cert_dir.mkdir(parents=True, exist_ok=True)
    cert_file = cert_dir / "server.crt"
    key_file = cert_dir / "server.key"
    if cert_file.exists() and key_file.exists():
        return cert_file, key_file

    san_entries = ["DNS:localhost", "IP:127.0.0.1"]
    san_entries.extend(f"IP:{ip}" for ip in lan_ips)
    config_file = cert_dir / "openssl.cnf"
    config_file.write_text(
        "\n".join(
            [
                "[req]",
                "distinguished_name=req_distinguished_name",
                "x509_extensions=v3_req",
                "prompt=no",
                "",
                "[req_distinguished_name]",
                "CN=localhost",
                "",
                "[v3_req]",
                f"subjectAltName={','.join(san_entries)}",
                "",
            ]
        ),
        encoding="utf-8",
    )

    try:
        subprocess.run(
            [
                "openssl",
                "req",
                "-x509",
                "-newkey",
                "rsa:2048",
                "-nodes",
                "-keyout",
                str(key_file),
                "-out",
                str(cert_file),
                "-days",
                "365",
                "-config",
                str(config_file),
            ],
            check=True,
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        write_embedded_certificate(cert_file, key_file)
    return cert_file, key_file


def write_embedded_certificate(cert_file, key_file):
    cert_file.write_text(textwrap.dedent(FALLBACK_CERT), encoding="utf-8")
    key_file.write_text(textwrap.dedent(FALLBACK_KEY), encoding="utf-8")
    print("OpenSSL was not available; using bundled local-test HTTPS certificate.")


def print_urls(scheme, port, lan_ips):
    print(f"Godot 4 Web Server running at {scheme}://localhost:{port}")
    for ip in lan_ips:
        print(f"LAN URL: {scheme}://{ip}:{port}")


if __name__ == "__main__":
    args = parse_args()
    lan_ips = get_lan_ips()
    os.chdir(DIR)
    scheme = "https" if args.https else "http"
    print_urls(scheme, args.port, lan_ips)
    print(f"Serving: {DIR}")
    print("Headers: COOP=same-origin, COEP=require-corp")
    if not args.https:
        print("Warning: LAN browsers may reject Godot Web exports without HTTPS.")

    server = http.server.HTTPServer((args.host, args.port), GodotHandler)
    if args.https:
        cert_file, key_file = ensure_certificate(args.cert_dir, lan_ips)
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        context.load_cert_chain(cert_file, key_file)
        server.socket = context.wrap_socket(server.socket, server_side=True)
        print(f"HTTPS certificate: {cert_file}")
        print("If the browser warns about the certificate, choose Advanced/Continue for testing.")
        print("This certificate is for local testing only, not public deployment.")

    server.serve_forever()
