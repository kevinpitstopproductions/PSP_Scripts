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
subprocess.run("pip install SpeechRecognition")
subprocess.run("pip install google-api-python-client")
subprocess.run("pip install oauth2client")
subprocess.run("pip install python-oauth2")
subprocess.run("pip install pocketsphinx")
# For TTS:
subprocess.run("pip install pyttsx3")