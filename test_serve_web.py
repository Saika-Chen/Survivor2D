import tempfile
import unittest
from pathlib import Path
from unittest import mock

import serve_web


class ServeWebConfigTests(unittest.TestCase):
    def test_default_config_uses_https(self):
        config = serve_web.parse_args([])

        self.assertTrue(config.https)
        self.assertEqual(config.port, 8080)

    def test_http_flag_disables_https(self):
        config = serve_web.parse_args(["--http"])

        self.assertFalse(config.https)

    def test_generates_self_signed_certificate_when_missing(self):
        with tempfile.TemporaryDirectory() as tmp:
            cert_dir = Path(tmp)
            with mock.patch("serve_web.subprocess.run") as run:
                cert_file, key_file = serve_web.ensure_certificate(cert_dir, ["127.0.0.1"])

        self.assertEqual(cert_file, cert_dir / "server.crt")
        self.assertEqual(key_file, cert_dir / "server.key")
        run.assert_called_once()

    def test_falls_back_to_embedded_certificate_without_openssl(self):
        with tempfile.TemporaryDirectory() as tmp:
            cert_dir = Path(tmp)
            with mock.patch("serve_web.subprocess.run", side_effect=FileNotFoundError):
                cert_file, key_file = serve_web.ensure_certificate(cert_dir, ["127.0.0.1"])

            self.assertIn("BEGIN CERTIFICATE", cert_file.read_text(encoding="utf-8"))
            self.assertIn("BEGIN PRIVATE KEY", key_file.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
