class_name InventorySystem
extends Node

signal inventory_changed
signal hotbar_changed(selected_index: int)

const HOTBAR_SIZE: int = 8

var quantities: Dictionary[StringName, int] = {}
var hotbar: Array[StringName] = [&"wood", &"stone", &"food", &"egg", &"milk", &"clover_sword", &"", &""]
var selected_hotbar_index: int = 0

func reset_to_new_game() -> void:
    quantities = {
        &"gold": 60,
        &"wood": 18,
        &"stone": 12,
        &"food": 4,
        &"egg": 0,
        &"milk": 0,
        &"clover_sword": 1,
    }
    selected_hotbar_index = 0
    inventory_changed.emit()
    hotbar_changed.emit(selected_hotbar_index)

func amount(item_id: StringName) -> int:
    return quantities.get(item_id, 0)

func add(item_id: StringName, quantity: int) -> void:
    if quantity <= 0:
        return
    quantities[item_id] = amount(item_id) + quantity
    inventory_changed.emit()

func has(item_id: StringName, quantity: int) -> bool:
    return amount(item_id) >= quantity

func remove(item_id: StringName, quantity: int) -> bool:
    if quantity <= 0 or not has(item_id, quantity):
        return false
    quantities[item_id] = amount(item_id) - quantity
    inventory_changed.emit()
    return true

func spend(costs: Dictionary[StringName, int]) -> bool:
    for item_id: StringName in costs:
        if not has(item_id, costs[item_id]):
            return false
    for item_id: StringName in costs:
        quantities[item_id] = amount(item_id) - costs[item_id]
    inventory_changed.emit()
    return true

func select_hotbar(index: int) -> void:
    selected_hotbar_index = wrapi(index, 0, HOTBAR_SIZE)
    hotbar_changed.emit(selected_hotbar_index)

func selected_item() -> StringName:
    return hotbar[selected_hotbar_index]

func serialize() -> Dictionary:
    var stored: Dictionary = {}
    for item_id: StringName in quantities:
        stored[String(item_id)] = quantities[item_id]
    return {"quantities": stored, "selected_hotbar_index": selected_hotbar_index}

func deserialize(data: Dictionary) -> void:
    quantities.clear()
    var stored: Dictionary = data.get("quantities", {}) as Dictionary
    for key: Variant in stored:
        quantities[StringName(str(key))] = int(stored[key])
    selected_hotbar_index = clampi(int(data.get("selected_hotbar_index", 0)), 0, HOTBAR_SIZE - 1)
    inventory_changed.emit()
    hotbar_changed.emit(selected_hotbar_index)
