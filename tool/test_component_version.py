import unittest
from unittest.mock import patch
from component_version import parse_manifest, changed, manifest_at, unpublished, app_release
class VersionTest(unittest.TestCase):
    def test_independent_manifests(self):
        self.assertEqual(parse_manifest("version: 1.2.3\nbuild: 7\n", "app"), {"version":"1.2.3","build":"7"})
        self.assertEqual(parse_manifest("# site\nversion: 1.2.3\n", "site"), {"version":"1.2.3"})
    def test_invalid_manifest(self):
        for text in ["version: 1.2", "version: 01.2.3", "version: 1.2.3-rc.1", "version: 1.2.3\nversion: 2.0.0", "version: 1.2.3\nunknown: x"]:
            with self.assertRaises(ValueError): parse_manifest(text,"site")
        for build in ["0","-1","2100000001"]:
            with self.assertRaises(ValueError): parse_manifest("version: 1.2.3\nbuild: "+build,"app")
    def test_no_change_and_bootstrap(self):
        v={"version":"1.0.0"}
        self.assertFalse(changed(v,v));self.assertTrue(changed(v,None))
    def test_monotonic_versions(self):
        old={"version":"1.9.0","build":"4"}
        self.assertTrue(changed({"version":"1.10.0","build":"5"},old))
        for new in [{"version":"1.8.0","build":"5"},{"version":"1.10.0","build":"4"}]:
            with self.assertRaises(ValueError):changed(new,old)
    def test_beta_candidates_and_stable_promotion(self):
        v = {'version': '2.1.0', 'build': '5'}
        tags = ['v2.0.1']
        beta = app_release(v, 'beta', tags)
        self.assertEqual(beta['tag'], 'v2.1.0-beta.5')
        self.assertEqual(beta['package'], 'app.moneyplant.money_plant.beta')
        self.assertTrue(beta['allowed'])
        tags.append(beta['tag'])
        self.assertFalse(app_release(v, 'beta', tags)['allowed'])
        self.assertTrue(app_release(v, 'main', tags)['allowed'])
        self.assertTrue(changed(dict(v, build='6'), v))
        self.assertTrue(app_release(dict(v, build='6'), 'beta', tags)['allowed'])
        tags.append('v2.1.0')
        self.assertFalse(app_release(dict(v, build='7'), 'beta', tags)['allowed'])
        self.assertFalse(app_release(v, 'main', tags)['allowed'])
        with self.assertRaises(ValueError):
            app_release({'version':'2.0.0','build':'3'}, 'beta', tags)
    def test_older_beta_candidate_is_rejected(self):
        with self.assertRaises(ValueError):
            app_release({'version':'2.1.0','build':'5'}, 'beta', ['v2.1.0-beta.6'])
    def test_published_tag_guards_and_component_independence(self):
        tags = ['v2.0.1', 'site-v9.0.0']
        self.assertFalse(unpublished('2.0.1', 'v', tags))
        self.assertTrue(unpublished('2.0.2', 'v', tags))
        with self.assertRaises(ValueError):
            unpublished('2.0.0', 'v', tags)
        self.assertFalse(unpublished('9.0.0', 'site-v', tags))
        self.assertTrue(unpublished('10.0.0', 'site-v', tags))
    def test_missing_manifest_is_bootstrap_but_missing_commit_fails(self):
        with patch('component_version.git', side_effect=['commit', '']):
            self.assertIsNone(manifest_at('base', 'versions/app.yaml'))
        with patch('component_version.git', side_effect=RuntimeError('missing history')):
            with self.assertRaises(RuntimeError):
                manifest_at('base', 'versions/app.yaml')
    def test_existing_manifest_and_new_branch(self):
        with patch('component_version.git', side_effect=['commit', 'versions/site.yaml', 'version: 1.0.0']):
            self.assertEqual(manifest_at('base', 'versions/site.yaml'), 'version: 1.0.0')
        with patch('component_version.git') as git:
            self.assertIsNone(manifest_at('0' * 40, 'versions/site.yaml'))
            git.assert_not_called()
if __name__=="__main__":unittest.main()
