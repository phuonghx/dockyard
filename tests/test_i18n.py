import glob, importlib.util, os, re, subprocess, sys, unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def load_po2js():
    # tools/po2js.py runs main() on import; load only its parser
    src = open(os.path.join(ROOT, "tools/po2js.py"), encoding="utf-8").read().replace("\nmain()\n", "\n")
    ns = {"__file__": os.path.join(ROOT, "tools/po2js.py")}
    exec(compile(src, "po2js", "exec"), ns)
    return ns


class TranslationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.ns = load_po2js()
        cls.pot = sorted(glob.glob(os.path.join(ROOT, "po", "*.pot")))[0]
        cls.langs = sorted(glob.glob(os.path.join(ROOT, "po", "*.po")))

    def keys(self, path):
        # the .pot has empty msgstr, parse msgids directly
        text = open(path, encoding="utf-8").read()
        out = set()
        for block in text.split("\n\n")[1:]:
            ctx = re.search(r'^msgctxt "(.*)"$', block, re.M)
            ids = re.findall(r'^(?:msgid )?"(.*)"$', block.split("msgid_plural")[0].split("msgid", 1)[1], re.M)
            msgid = "".join(ids)
            if msgid:
                out.add((ctx.group(1) if ctx else "") + "\n" + msgid)
        return out

    def test_there_are_translations(self):
        self.assertGreaterEqual(len(self.langs), 1)

    def test_every_message_is_translated_in_every_language(self):
        wanted = self.keys(self.pot)
        for po in self.langs:
            have = set(self.ns["parse"](po))
            missing = sorted(wanted - have)
            self.assertEqual(missing, [], f"{os.path.basename(po)} is missing {len(missing)} message(s), e.g. {missing[:2]}")

    def test_placeholders_survive(self):
        # every translated form must keep every %1, %2 ... of the source message
        ph = lambda s: set(re.findall(r"%\d", s))
        for po in self.langs:
            for key, forms in self.ns["parse"](po).items():
                msgid = key.split("\n", 1)[1]
                for form in forms:
                    self.assertTrue(ph(msgid) <= ph(form), f"{os.path.basename(po)}: {key!r} -> {form!r}")

    def test_generated_table_is_current(self):
        r = subprocess.run([sys.executable, os.path.join(ROOT, "tools/po2js.py"), "--check"], capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)


if __name__ == "__main__":
    unittest.main()
