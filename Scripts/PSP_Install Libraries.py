# * ReaScript Name: Library Installer
# * Author: GU-on
# * Licence: GPL v3
# * REAPER: 6.28
# * Version: 1.0

# * Changelog:
# * v1.0 (2021-05-12)
# 	+ Initial Release

import subprocess
# For Reaper
subprocess.run("pip install python-reapy")
# For STT:
subprocess.run("SpeechRecognition")
subprocess.run("google-api-python-client")
subprocess.run("oauth2client")
subprocess.run("python-oauth2")
subprocess.run("pocketsphinx")
# For TTS:
subprocess.run("pip install pyttsx3")