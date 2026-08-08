class_name GameHUD
extends CanvasLayer

@onready var realm_label: Label = %RealmLabel
@onready var resource_label: Label = %ResourceLabel
@onready var status_label: Label = %StatusLabel
@onready var message_label: Label = %MessageLabel
@onready var message_panel: PanelContainer = %MessagePanel
@onready var inventory_panel: PanelContainer = %InventoryPanel
@onready var inventory_grid: GridContainer = %InventoryGrid
@onready var hotbar: HBoxContainer = %Hotbar

var item_database: ItemDatabase
var inventory: InventorySystem
var message_time: float = 0.0
var realm_name: String = "Cloverhold"
var day: int = 1
var clock_text: String = "08:00"
var health: int = 6
var max_health: int = 6
var reputation: int = 0

func configure(database: ItemDatabase, inventory_system: InventorySystem) -> void:
    item_database = database
    inventory = inventory_system
    inventory.inventory_changed.connect(refresh_inventory)
    inventory.hotbar_changed.connect(_on_hotbar_changed)
    refresh_inventory()
    _refresh_status()

func _process(delta: float) -> void:
    if message_time > 0.0:
        message_time -= delta
        if message_time <= 0.0:
            message_panel.visible = false

func set_time(new_day: int, new_clock_text: String) -> void:
    day = new_day
    clock_text = new_clock_text
    _refresh_status()

func set_health(new_health: int, new_max_health: int) -> void:
    health = new_health
    max_health = new_max_health
    _refresh_status()

func set_reputation(value: int) -> void:
    reputation = value
    _refresh_status()

func show_message(text: String) -> void:
    message_label.text = text
    message_panel.visible = true
    message_time = 3.4

func toggle_inventory() -> bool:
    inventory_panel.visible = not inventory_panel.visible
    return inventory_panel.visible

func refresh_inventory() -> void:
    if inventory == null or item_database == null:
        return
    resource_label.text = "Gold %d   Wood %d   Stone %d   Food %d" % [inventory.amount(&"gold"), inventory.amount(&"wood"), inventory.amount(&"stone"), inventory.amount(&"food")]
    for child: Node in inventory_grid.get_children():
        child.queue_free()
    var ids: Array[StringName] = [&"gold", &"wood", &"stone", &"food", &"egg", &"milk", &"clover_sword"]
    for item_id: StringName in ids:
        var definition := item_database.get_item(item_id)
        if definition == null:
            continue
        var label := Label.new()
        label.text = "%s\n%d" % [definition.display_name, inventory.amount(item_id)]
        label.custom_minimum_size = Vector2(112, 40)
        inventory_grid.add_child(label)
    _rebuild_hotbar()

func _rebuild_hotbar() -> void:
    for child: Node in hotbar.get_children():
        child.queue_free()
    for index: int in range(InventorySystem.HOTBAR_SIZE):
        var panel := PanelContainer.new()
        panel.custom_minimum_size = Vector2(54, 42)
        var label := Label.new()
        var item_id := inventory.hotbar[index]
        var item_name := "Empty"
        if not item_id.is_empty():
            var definition := item_database.get_item(item_id)
            item_name = definition.display_name if definition != null else String(item_id)
        label.text = "%d\n%s" % [index + 1, item_name]
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        panel.add_child(label)
        panel.modulate = Color(1.0, 0.95, 0.72, 1.0) if index == inventory.selected_hotbar_index else Color.WHITE
        hotbar.add_child(panel)

func _on_hotbar_changed(_selected_index: int) -> void:
    _rebuild_hotbar()

func _refresh_status() -> void:
    realm_label.text = "%s  •  Day %d  •  %s" % [realm_name, day, clock_text]
    status_label.text = "HP %d/%d   REP %d" % [health, max_health, reputation]
