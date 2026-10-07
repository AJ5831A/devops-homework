import json
import os
import unittest
from unittest.mock import patch
import app


class AppTests(unittest.TestCase):
    def test_health(self):
        self.assertEqual(json.loads(app.response('/healthz')[2]), {'status': 'ok'})

    def test_readiness_requires_secret(self):
        with patch.dict(os.environ, {}, clear=True):
            self.assertEqual(app.response('/readyz')[0], 503)
        with patch.dict(os.environ, {'API_TOKEN': 'test-only'}):
            self.assertEqual(app.response('/readyz')[0], 200)

    def test_auth_denies_missing_and_wrong_tokens(self):
        with patch.dict(os.environ, {'API_TOKEN': 'test-only'}):
            for headers in [{}, {'Authorization': 'Bearer wrong'}]:
                self.assertEqual(app.response('/api/info', headers)[0], 401)
            status, _, body = app.response('/api/info', {'Authorization': 'Bearer test-only'})
            self.assertEqual(status, 200)
            self.assertEqual(json.loads(body)['app'], 'devops-demo')
            self.assertNotIn('test-only', body)

    def test_non_ascii_auth_is_rejected_without_crashing(self):
        with patch.dict(os.environ, {'API_TOKEN': 'test-only'}):
            self.assertEqual(app.response('/api/info', {'Authorization': 'Bearer café'})[0], 401)
        with patch.dict(os.environ, {'API_TOKEN': 'café'}):
            self.assertEqual(app.response('/api/info', {'Authorization': 'Bearer wrong'})[0], 401)

    def test_malformed_path_returns_client_error(self):
        self.assertEqual(app.response('//[broken')[0], 400)

    def test_empty_secret_never_authorizes(self):
        with patch.dict(os.environ, {'API_TOKEN': ''}):
            self.assertEqual(app.response('/api/info', {'Authorization': 'Bearer '})[0], 401)

    def test_html_escapes_configuration(self):
        with patch.dict(os.environ, {'APP_MESSAGE': '<script>alert(1)</script>'}):
            self.assertIn('&lt;script&gt;', app.response('/')[2])

    def test_work_validates_bounds(self):
        for value in ['0', '-1', '100001', 'bad']:
            self.assertEqual(app.response('/work?rounds=' + value)[0], 400)
        self.assertEqual(json.loads(app.response('/work?rounds=1')[2])['rounds'], 1)

    def test_metrics_are_prometheus_text(self):
        status, mime, body = app.response('/metrics')
        self.assertEqual(status, 200)
        self.assertIn('text/plain', mime)
        for metric in ['demo_requests_total', 'process_cpu_seconds_total', 'demo_peak_resident_memory_bytes']:
            self.assertIn(metric, body)

    def test_not_found(self):
        self.assertEqual(app.response('/missing')[0], 404)


if __name__ == '__main__':
    unittest.main()
