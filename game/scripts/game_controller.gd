class_name GameController
extends Node2D

const HOTBAR_KEYS: Array[Key] = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8]

@onready var item_database: ItemDatabase = %ItemDatabase
@onready var inventory: InventorySystem = %InventorySystem
@onready var day_night: DayNightSystem = %DayNightSystem
@onready var villager_jobs: VillagerJobsSystem = %VillagerJobsSystem
@onready var save_system: SaveSystem = %SaveSystem
@onready var assets: AssetCatalog = %AssetCatalog
@onready var world: WorldController = %World
@onready var player: PlayerCharacter = %Player
@onready var hud: GameHUD = %HUD

var inventory_open: bool = false

func _ready() -> void:
    inventory.reset_to_new_game()
    villager_jobs.setup_defaults()
    hud.configure(item_database, inventory)
    world.configure(assets, inventory, villager_jobs, player)

    player.position = Vector2(760, 720)
    player.interact_requested.connect(world.interact)
    player.attack_requested.connect(world.attack)
    world.message_requested.connect(hud.show_message)
    world.reputation_changed.connect(hud.set_reputation)
    world.player_health_changed.connect(hud.set_health)
    day_night.day_started.connect(_on_day_started)
    villager_jobs.production_ready.connect(hud.show_message)

    hud.set_health(world.player_health, world.max_player_health)
    hud.set_reputation(world.reputation)
    hud.set_time(day_night.day, day_night.clock_text())
    hud.show_message("Welcome to Cloverhold. Gather, build, explore, fight, expand, and rule.")

    if save_system.has_save():
        hud.show_message("A previous save is available. Press L to load it.")

func _process(delta: float) -> void:
    if Input.is_action_just_pressed("inventory"):
        inventory_open = hud.toggle_inventory()
        player.movement_enabled = not inventory_open
        day_night.paused = inventory_open

    if inventory_open:
        return

    day_night.advance(delta)
    hud.set_time(day_night.day, day_night.clock_text())
    world.set_night(day_night.is_night())
    world.process_build_input()
    world.update_world(delta)
    _handle_hotbar_input()

    if Input.is_action_just_pressed("save_game"):
        _save_game()
    if Input.is_action_just_pressed("load_game"):
        _load_game()

func _handle_hotbar_input() -> void:
    for index: int in range(HOTBAR_KEYS.size()):
        if Input.is_physical_key_pressed(HOTBAR_KEYS[index]):
            inventory.select_hotbar(index)
            break
    if Input.is_action_just_pressed("hotbar_next"):
        inventory.select_hotbar(inventory.selected_hotbar_index + 1)
    elif Input.is_action_just_pressed("hotbar_previous"):
        inventory.select_hotbar(inventory.selected_hotbar_index - 1)

func _on_day_started(_day: int) -> void:
    world.on_new_day()
    villager_jobs.produce_daily(inventory)

func _save_game() -> void:
    var data := {
        "version": "0.4-foundation",
        "inventory": inventory.serialize(),
        "day": day_night.day,
        "minutes": day_night.minutes,
        "world": world.serialize(),
    }
    if save_system.save_game(data):
        hud.show_message("Game saved.")
    else:
        hud.show_message("The game could not be saved.")

func _load_game() -> void:
    var data := save_system.load_game()
    if data.is_empty():
        hud.show_message("No valid save was found.")
        return
    inventory.deserialize(data.get("inventory", {}) as Dictionary)
    day_night.set_time(int(data.get("day", 1)), float(data.get("minutes", 480.0)))
    world.deserialize(data.get("world", {}) as Dictionary)
    hud.set_time(day_night.day, day_night.clock_text())
    hud.show_message("Save loaded.")
