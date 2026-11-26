import importlib.util, json, os, sys, tempfile, threading, unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load(name, rel):
    spec = importlib.util.spec_from_file_location(name, os.path.join(ROOT, rel))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


dockyard = load("dockyard", "package/contents/scripts/dockyard.py")
fake = load("fake_engine", "tools/fake_engine.py")


class EngineTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dir = tempfile.mkdtemp()
        cls.sock = os.path.join(cls.dir, "e.sock")
        cls.srv = fake.serve(cls.sock)
        threading.Thread(target=cls.srv.serve_forever, daemon=True).start()
        cls.engine = dockyard.connect(cls.sock)

    @classmethod
    def tearDownClass(cls):
        cls.srv.shutdown()

    def test_snapshot_shape(self):
        s = dockyard.snapshot(self.engine)
        self.assertTrue(s["ok"])
        self.assertEqual(s["engine"]["name"], "Docker Engine")
        self.assertEqual(s["engine"]["ncpu"], 16)
        db = next(c for c in s["containers"] if c["name"] == "shop-db")
        self.assertEqual(db["health"], "unhealthy")
        self.assertEqual(db["project"], "shop")
        self.assertTrue(10 < db["cpu"] < 35, db["cpu"])   # fake engine jitters around 21.5%
        self.assertEqual(db["ports"], [{"pub": 5432, "priv": 5432, "proto": "tcp"}])
        stopped = next(c for c in s["containers"] if c["name"] == "migrate-once")
        self.assertEqual(stopped["cpu"], 0)

    def test_usage_links(self):
        s = dockyard.snapshot(self.engine)
        vols = {v["name"]: v for v in s["volumes"]}
        self.assertEqual(vols["shop_pgdata"]["used"], 1)
        self.assertEqual(vols["old_experiment"]["used"], 0)
        self.assertTrue(vols["a" * 64]["anonymous"])
        nets = {n["name"]: n for n in s["networks"]}
        self.assertTrue(nets["bridge"]["system"])
        self.assertGreater(nets["shop_default"]["used"], 0)
        self.assertTrue(any(i["dangling"] for i in s["images"]))

    def test_actions_change_state_and_report_errors(self):
        cid = next(c["id"] for c in dockyard.snapshot(self.engine)["containers"] if c["name"] == "loki")
        self.assertTrue(dockyard.act(self.engine, "unpause", [cid])["ok"])
        after = next(c for c in dockyard.snapshot(self.engine)["containers"] if c["id"] == cid)
        self.assertEqual(after["state"], "running")
        bad = dockyard.act(self.engine, "stop", ["nope"])
        self.assertFalse(bad["ok"])
        self.assertIn("No such container", bad["results"][0]["message"])

    def test_logs_are_demuxed(self):
        cid = dockyard.snapshot(self.engine)["containers"][0]["id"]
        out = dockyard.logs(self.engine, cid, 50)
        self.assertTrue(out["text"].startswith("2026-11-26T09:58:01Z INFO"))
        self.assertNotIn("\x01", out["text"])

    def test_df_and_inspect(self):
        d = dockyard.disk_usage(self.engine)
        self.assertGreater(d["imagesReclaimable"], 0)
        self.assertEqual(d["volumeSizes"]["old_experiment"], 512 * 1024**2)
        cid = dockyard.snapshot(self.engine)["containers"][0]["id"]
        self.assertEqual(dockyard.inspect(self.engine, cid)["restartPolicy"], "unless-stopped")

    def test_errors_are_json_not_tracebacks(self):
        with self.assertRaises(dockyard.EngineError) as cm:
            dockyard.connect(os.path.join(self.dir, "missing.sock"))
        self.assertEqual(cm.exception.kind, "no_socket")
        open(os.path.join(self.dir, "dead.sock"), "w").close()
        with self.assertRaises(dockyard.EngineError) as cm:
            dockyard.connect(os.path.join(self.dir, "dead.sock"))
        self.assertEqual(cm.exception.kind, "not_running")


if __name__ == "__main__":
    unittest.main()
