class_name SaveSystem
extends Node

const SAVE_PATH: String = "user://crown_and_clover_v04_save.json"

func has_save() -> bool:
    return FileAccess.file_exists(SAVE_PATH)

func save_game(data: Dictionary) -> bool:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        push_error("Could not open Crown & Clover save file for writing.")
        return false
    file.store_string(JSON.stringify(data, "  "))
    return true

func load_game() -> Dictionary:
    if not has_save():
        return {}
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        push_error("Could not open Crown & Clover save file for reading.")
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        push_warning("Ignoring invalid Crown & Clover save data.")
        return {}
    return parsed as Dictionary
