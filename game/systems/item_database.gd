class_name ItemDatabase
extends Node

var _items: Dictionary[StringName, ItemDefinition] = {}

func _ready() -> void:
    _register_defaults()

func get_item(item_id: StringName) -> ItemDefinition:
    return _items.get(item_id) as ItemDefinition

func has_item(item_id: StringName) -> bool:
    return _items.has(item_id)

func _register_defaults() -> void:
    _register(&"gold", "Gold", "Currency used for trade and construction.", &"currency", 9999, 1)
    _register(&"wood", "Wood", "A basic building material gathered from trees.", &"resource", 999, 2)
    _register(&"stone", "Stone", "A durable building and crafting material.", &"resource", 999, 3)
    _register(&"food", "Food", "Keeps the settlement supplied.", &"resource", 999, 4)
    _register(&"egg", "Egg", "Fresh produce from chickens.", &"produce", 99, 6)
    _register(&"milk", "Milk", "Fresh produce from cows.", &"produce", 99, 8)
    _register(&"clover_sword", "Clover Sword", "A dependable blade for early adventures.", &"weapon", 1, 45, &"weapon")
    _register(&"woodcutter_axe", "Woodcutter Axe", "A sturdy axe for gathering timber.", &"tool", 1, 35, &"tool")
    _register(&"mining_pick", "Mining Pick", "A practical pick for breaking stone and ore.", &"tool", 1, 35, &"tool")

func _register(item_id: StringName, item_name: String, item_description: String, item_category: StringName, stack_size: int, value: int, slot: StringName = &"") -> void:
    var definition := ItemDefinition.new()
    definition.id = item_id
    definition.display_name = item_name
    definition.description = item_description
    definition.category = item_category
    definition.max_stack = stack_size
    definition.sell_value = value
    definition.equipment_slot = slot
    _items[item_id] = definition
