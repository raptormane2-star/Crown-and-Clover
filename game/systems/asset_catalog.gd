class_name AssetCatalog
extends Node

const PATHS: Dictionary[StringName, String] = {
    &"grass": "res://assets/cute/grass.png",
    &"path": "res://assets/cute/path.png",
    &"water": "res://assets/cute/water.png",
    &"farmland": "res://assets/cute/farmland.png",
    &"house": "res://assets/cute/house_blue.png",
    &"chest": "res://assets/cute/chest.png",
    &"bridge": "res://assets/cute/bridge.png",
    &"slime": "res://assets/cute/slime_sheet.png",
    &"skeleton": "res://assets/cute/skeleton_sheet.png",
    &"player_idle": "res://assets/farm/player_idle.png",
    &"player_walk": "res://assets/farm/player_walk.png",
    &"crops": "res://assets/farm/crops.png",
    &"maple_tree": "res://assets/farm/maple_tree.png",
    &"chicken": "res://assets/farm/chicken.png",
    &"cow": "res://assets/farm/cow.png",
    &"ruin_1": "res://assets/ruins/ruin_1.png",
    &"ruin_2": "res://assets/ruins/ruin_2.png",
    &"ruin_3": "res://assets/ruins/ruin_3.png",
    &"ruin_4": "res://assets/ruins/ruin_4.png",
    &"ruin_5": "res://assets/ruins/ruin_5.png",
    &"ruin_6": "res://assets/ruins/ruin_6.png",
    &"ruin_7": "res://assets/ruins/ruin_7.png",
}

var _textures: Dictionary[StringName, Texture2D] = {}
var _missing: Array[String] = []

func _ready() -> void:
    for asset_id: StringName in PATHS:
        var path: String = PATHS[asset_id]
        if not ResourceLoader.exists(path, "Texture2D"):
            _missing.append(path)
            continue
        var resource := ResourceLoader.load(path, "Texture2D") as Texture2D
        if resource != null:
            _textures[asset_id] = resource
    if not _missing.is_empty():
        print("Crown & Clover: third-party art not installed. See game/assets/README.md")

func texture(asset_id: StringName) -> Texture2D:
    return _textures.get(asset_id) as Texture2D

func missing_paths() -> Array[String]:
    return _missing.duplicate()
