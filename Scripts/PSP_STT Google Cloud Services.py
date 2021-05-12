import speech_recognition as sr
import reapy

ext_name = "PSP_JSONCREDENTIALS"
ext_save = "key"

project = reapy.Project()
item_count = project.n_selected_items

r = sr.Recognizer()
credentials = reapy.get_ext_state(ext_name, ext_save)

with reapy.inside_reaper():
    for i in range(item_count):
        item = project.get_selected_item(i)
        file_location = item.active_take.source.filename

        if item.active_take.source.type == "WAVE":
            with sr.AudioFile(file_location) as source:
                audio = r.record(source,
                                 duration=item.get_info_value("D_LENGTH"),
                                 offset=item.active_take.get_info_value("D_STARTOFFS"))  # read the entire audio file
            
            try:
                take_name = r.recognize_google_cloud(audio, credentials_json=credentials)
                project.add_marker(item.get_info_value("D_POSITION"),
                                   name=str(take_name),
                                   color=(255, 255, 255))

            except sr.UnknownValueError:
                project.add_marker(item.get_info_value("D_POSITION"),
                                   name="ERR: Could not understand audio",
                                   color=(128, 0, 0))

            except sr.RequestError as e:
                project.add_marker(item.get_info_value("D_POSITION"),
                                   name="ERR: {0}".format(e),
                                   color=(128, 0, 0))
        else:
            project.add_marker(item.get_info_value("D_POSITION"),
                               name="ERR: Source not WAVE",
                               color=(128, 0, 0))
