class_name VillagerJobsSystem
extends Node

signal production_ready(summary: String)

var villagers: Array[Dictionary] = []

func setup_defaults() -> void:
    villagers = [
        _villager("Bram", "Blacksmith", Vector2(825, 980), "res://assets/villagers/MiniBlacksmith.png", "Bring me ore and I will forge stronger tools."),
        _villager("Tobin", "Merchant", Vector2(690, 780), "res://assets/villagers/MiniMerchant.png", "A wealthy kingdom needs trade, not only swords."),
        _villager("Milo", "Miner", Vector2(1010, 1050), "res://assets/villagers/MiniMiner.png", "There are strange crystals beneath Whispering Cave."),
        _villager("Rufus", "Lumberjack", Vector2(330, 820), "res://assets/villagers/MiniLumberjack.png", "The old forest regrows slowly. Take only what you need."),
        _villager("Elara", "Hunter", Vector2(1120, 760), "res://assets/villagers/MiniHunter.png", "Something has moved into the ruined village to the southeast."),
        _villager("Pip", "Gatherer", Vector2(560, 820), "res://assets/villagers/MiniGatherer.png", "Wild herbs are worth more after rain."),
        _villager("Sister Mae", "Healer", Vector2(1780, 760), "res://assets/villagers/MiniNun.png", "Eldermere welcomes peaceful rulers."),
    ]

func add_settler(position: Vector2) -> void:
    villagers.append(_villager("New Settler", "Gatherer", position, "res://assets/villagers/MiniGatherer.png", "I will help Cloverhold grow."))

func produce_daily(inventory: InventorySystem) -> void:
    var produced_any := false
    for villager: Dictionary in villagers:
        var job := str(villager.get("job", "Villager"))
        match job:
            "Lumberjack":
                inventory.add(&"wood", 2)
                produced_any = true
            "Miner":
                inventory.add(&"stone", 2)
                produced_any = true
            "Gatherer", "Hunter":
                inventory.add(&"food", 1)
                produced_any = true
            "Merchant":
                inventory.add(&"gold", 4)
                produced_any = true
    if produced_any:
        production_ready.emit("Villagers delivered today's work to the settlement.")

func _villager(villager_name: String, job_name: String, position: Vector2, texture_path: String, dialogue: String) -> Dictionary:
    return {
        "name": villager_name,
        "job": job_name,
        "pos": position,
        "texture_path": texture_path,
        "line": dialogue,
    }
