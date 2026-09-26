import unittest
from bump_version import bump


class VersionTests(unittest.TestCase):
    def test_patch_and_build(self):
        self.assertEqual(bump('1.0.0+1', 'patch'), '1.0.1+2')
        self.assertEqual(bump('2.0.0+19', 'patch'), '2.0.1+20')

    def test_manual_bumps(self):
        self.assertEqual(bump('1.2.3+7', 'minor'), '1.3.0+8')
        self.assertEqual(bump('1.2.3+7', 'major'), '2.0.0+8')

    def test_explicit_release_is_not_bumped(self):
        self.assertEqual(bump('2.0.0+3', 'current'), '2.0.0+3')

    def test_invalid(self):
        with self.assertRaises(ValueError):
            bump('1.0.0', 'patch')


if __name__ == '__main__':
    unittest.main()
