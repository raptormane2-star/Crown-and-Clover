class_name ItemDefinition
extends Resource

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var category: StringName = &"misc"
@export var max_stack: int = 99
@export var sell_value: int = 0
@export var equipment_slot: StringName = &""

func is_equipment() -> bool:
    return not equipment_slot.is_empty()
