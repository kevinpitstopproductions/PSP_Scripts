# * ReaScript Name: PSP_Library Installer.py
# * Author: GU-on
# * Licence: GPL v3
# * REAPER: 6.28
# * Version: 1.3

# * Changelog:
# * v1.1 (2021-05-12)
# 	+ Initial Release
# * v1.3 (2021-06-07)
#   + Sphinx Removed

import subprocess
# For Reaper
subprocess.run("pip install python-reapy")
# For STT:
subprocess.run("pip install SpeechRecognition")
subprocess.run("pip install google-api-python-client")
subprocess.run("pip install oauth2client")
subprocess.run("pip install python-oauth2")
# For TTS:
subprocess.run("pip install pyttsx3")