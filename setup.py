#!/usr/bin/env python3
r"""
                     _  __ _       _     _     _
                    (_)/ _(_)     | |   (_)   | |
  ((.))    __      ___| |_ _ _ __ | |__  _ ___| |__   ___ _ __
    |      \ \ /\ / / |  _| | '_ \| '_ \| / __| '_ \ / _ \ '__|
   /_\      \ V  V /| | | | | |_) | | | | \__ \ | | |  __/ |
  /___\      \_/\_/ |_|_| |_| .__/|_| |_|_|___/_| |_|\___|_|
 /     \                    | |
                            |_|  Version {}
"""


import os
import sys

from setuptools import Command, find_packages, setup

if sys.version_info[:2] < (3, 6):
    sys.exit("Please use Python 3.6+ to install Wifiphisher.")


class CleanCommand(Command):
    """Custom clean command to tidy up the project root."""
    user_options = []
    def initialize_options(self):
        pass
    def finalize_options(self):
        pass
    def run(self):
        os.system('rm -vrf ./build ./dist ./*.pyc ./*.tgz ./*.egg-info')

# runtime dependencies available on PyPI.
# roguehostapd and pyric are not published on PyPI and are installed
# separately from their GitHub repositories (see README / install script).
INSTALL_REQUIRES = ["pbkdf2", "six", "scapy>=2.5.0", "tornado>=5.0.0"]

# setup settings
NAME = "wifiphisher"
AUTHOR = "sophron"
AUTHOR_EMAIL = "sophron@latthi.com"
URL = "https://github.com/wifiphisher/wifiphisher"
DESCRIPTION = "Automated phishing attacks against Wi-Fi networks"
LICENSE = "GPL"
KEYWORDS = ["wifiphisher", "evil", "twin", "phishing"]
PACKAGES = find_packages(exclude=["docs", "tests"])
INCLUDE_PACKAGE_DATA = True
VERSION = "1.4"
CLASSIFIERS = ["Development Status :: 5 - Production/Stable",
               "License :: OSI Approved :: GNU General Public License v3 (GPLv3)",
               "Natural Language :: English", "Operating System :: Unix",
               "Programming Language :: Python :: 3",
               "Topic :: Security",
               "Topic :: System :: Networking"]
ENTRY_POINTS = {"console_scripts": ["wifiphisher = wifiphisher.pywifiphisher:run"]}
CMDCLASS = {"clean": CleanCommand,}

# run setup
setup(name=NAME, author=AUTHOR, author_email=AUTHOR_EMAIL, description=DESCRIPTION,
      license=LICENSE, keywords=KEYWORDS, packages=PACKAGES,
      include_package_data=INCLUDE_PACKAGE_DATA, version=VERSION, entry_points=ENTRY_POINTS,
      install_requires=INSTALL_REQUIRES,
      classifiers=CLASSIFIERS, url=URL, cmdclass=CMDCLASS)

print(__doc__.format(VERSION))  # print the docstring located at the top of this file
