# * ReaScript Name: PSP_TTS Easy.py
# * Author: GU-on
# * Licence: GPL v3
# * REAPER: 6.28
# * Version: 1.3

# * Changelog:
# * v1.1 (2021-05-12)
#   + Initial Release
# * v1.3 (2021-06-08)
#	+ Defaults to voice 0

from datetime import date
from datetime import datetime

import reapy
import pyttsx3

project = reapy.Project()

engine = pyttsx3.init()
voices = engine.getProperty('voices')

engine.setProperty('voice', voices[0].id)

today = date.today()
now = datetime.now()

d1 = today.strftime("%d-%m-%Y") + "_" + now.strftime("%H%M%S")

path = project.path + r"\\" +str(d1) + ".mp3"

key_name = ['key']
user_input = reapy.get_user_inputs('Text Generator', key_name, 1048576)
out = user_input.get('key')

path = path.replace("\\\\", "\\")

engine.save_to_file(out, path)
engine.runAndWait()

RPR_InsertMedia(path, 0)

reapy.update_arrange()
