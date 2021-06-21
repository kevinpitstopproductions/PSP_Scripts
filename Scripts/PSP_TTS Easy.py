# * ReaScript Name: PSP_TTS Easy.py
# * Author: GU-on
# * Licence: GPL v3
# * REAPER: 6.28
# * Version: 1.4

# * Changelog:
# * v1.1 (2021-05-12)
#   + Initial Release
# * v1.3 (2021-06-08)
#  + Defaults to voice 0
# * v1.4 (2021-06-21)
#  + Prevented crashing on cancel, added voice selector

from datetime import date
from datetime import datetime

import reapy
import pyttsx3

get_input = True

project = reapy.Project()

engine = pyttsx3.init()
voices = engine.getProperty('voices')
indexes = 0

for voice in voices:
	indexes = indexes + 1

engine.setProperty('voice', voices[0].id)

today = date.today()
now = datetime.now()

d1 = today.strftime("%d-%m-%Y") + "_" + now.strftime("%H%M%S")

path = project.path + r"\\" +str(d1) + ".mp3"

while get_input:
	try:
		keys = ['Voice Index', 'Input Text']
		user_inputs = reapy.get_user_inputs('Text Generator [indexes available - ' + str(indexes) + ']', keys, 1024)
		input_string = user_inputs.get('Input Text')
		input_index = int(user_inputs.get('Voice Index'))

		get_input = False
		if input_index >= 0 and input_index <= indexes:
			path = path.replace("\\\\", "\\")

			engine.setProperty('voice', voices[input_index-1].id)
			engine.save_to_file(input_string, path)
			engine.runAndWait()

			RPR_InsertMedia(path, 0)

			reapy.update_arrange()
		else:
			reapy.show_message_box('Please enter Voice Index from 1 to ' + str(indexes),'Error','ok')

	except RuntimeError:
		get_input = False