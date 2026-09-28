import unittest
from verify_release import verify_badging
class VerifyReleaseTest(unittest.TestCase):
    def test_compiled_version(self):
        text = "package: name='app.moneyplant.money_plant' versionCode='4' versionName='2.0.1'"
        self.assertEqual(verify_badging(text, "2.0.1+4")["versionCode"], 4)
        for expected in ["2.0.0+4", "2.0.1+3"]:
            with self.assertRaises(ValueError):
                verify_badging(text, expected)
        with self.assertRaises(ValueError):
            verify_badging(text.replace("app.moneyplant.money_plant", "other.app"), "2.0.1+4")
    def test_invalid_metadata(self):
        with self.assertRaises(ValueError):
            verify_badging("", "2.0.1+4")
if __name__ == "__main__":
    unittest.main()
