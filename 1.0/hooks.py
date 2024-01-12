import shutil
import os

def on_post_build(config, **kwargs):
    site_dir = config['site_dir']
    shutil.copytree("integration_tests/target/", os.path.join(site_dir, 'dbt-docs'))
