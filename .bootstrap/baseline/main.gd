extends Node2D

const SAVE_PATH := "user://crown_and_clover_v03.save"
const WORLD_SIZE := Vector2i(30, 18)
const TILE_SIZE := 16
const PLAYER_SPEED := 92.0

var player: CharacterBody2D
var world_root: Node2D
var settlement_root: Node2D
var resource_root: Node2D
var villager_root: Node2D
var enemy_root: Node2D
var animal_root: Node2D
var crop_root: Node2D
var hud_text: Label
var message_text: Label
var night_overlay: ColorRect

var resources: Dictionary = {"wood": 14, "stone": 10, "food": 8, "gold": 0}
var inventory: Dictionary = {"Wood": 14, "Stone": 10, "Food": 8}
var buildings: Array[Dictionary] = []
var villagers: Array[Dictionary] = []
var crops: Array[Dictionary] = []
var day_number := 1
var day_clock := 8.0
var selected_building := 0
var message_timer := 0.0

var grass_texture: Texture2D
var path_texture: Texture2D
var farmland_texture: Texture2D
var player_texture: Texture2D
var house_texture: Texture2D
var tree_texture: Texture2D
var chest_texture: Texture2D
var slime_texture: Texture2D
var skeleton_texture: Texture2D
var chicken_texture: Texture2D
var cow_texture: Texture2D
var crop_texture: Texture2D

func _ready() -> void:
	grass_texture = load("res://assets/cute/grass.png") as Texture2D
	path_texture = load("res://assets/cute/path.png") as Texture2D
	farmland_texture = load("res://assets/cute/farmland.png") as Texture2D
	player_texture = load("res://assets/farm/character/player_idle.png") as Texture2D
	house_texture = load("res://assets/cute/house_blue.png") as Texture2D
	tree_texture = load("res://assets/cute/tree.png") as Texture2D
	chest_texture = load("res://assets/cute/chest.png") as Texture2D
	slime_texture = load("res://assets/cute/slime_sheet.png") as Texture2D
	skeleton_texture = load("res://assets/cute/skeleton_sheet.png") as Texture2D
	chicken_texture = load("res://assets/farm/animals/chicken.png") as Texture2D
	cow_texture = load("res://assets/farm/animals/cow.png") as Texture2D
	crop_texture = load("res://assets/farm/crops/spring_crops.png") as Texture2D
	_build_world()
	_build_player()
	_build_locations()
	_build_resources()
	_build_villagers()
	_build_animals()
	_build_enemies()
	_build_ui()
	_show_message("Welcome to Crown & Clover — build a realm worth ruling.")

func _process(delta: float) -> void:
	_update_day_night(delta)
	_update_crops(delta)
	if message_timer > 0.0:
		message_timer -= delta
		if message_timer <= 0.0:
			message_text.text = ""
	_update_hud()

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player.velocity = direction * PLAYER_SPEED
	player.move_and_slide()
	player.position.x = clampf(player.position.x, 12.0, float(WORLD_SIZE.x * TILE_SIZE - 12))
	player.position.y = clampf(player.position.y, 12.0, float(WORLD_SIZE.y * TILE_SIZE - 12))
	if Input.is_action_just_pressed("interact"):
		_interact()
	if Input.is_action_just_pressed("build"):
		_try_build()
	if Input.is_action_just_pressed("save_game"):
		save_game()
	if Input.is_action_just_pressed("load_game"):
		load_game()
	if Input.is_key_pressed(KEY_1):
		selected_building = 0
	elif Input.is_key_pressed(KEY_2):
		selected_building = 1
	elif Input.is_key_pressed(KEY_3):
		selected_building = 2

func _build_world() -> void:
	world_root = Node2D.new()
	world_root.name = "World"
	add_child(world_root)
	for y in range(WORLD_SIZE.y):
		for x in range(WORLD_SIZE.x):
			var tile := Sprite2D.new()
			tile.texture = grass_texture
			tile.position = Vector2(x * TILE_SIZE + 8, y * TILE_SIZE + 8)
			tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			world_root.add_child(tile)
	for x in range(4, 26):
		_add_world_sprite(path_texture, Vector2(x * TILE_SIZE + 8, 9 * TILE_SIZE + 8), 0)
	settlement_root = Node2D.new()
	settlement_root.name = "Settlement"
	add_child(settlement_root)
	resource_root = Node2D.new()
	resource_root.name = "Gatherables"
	add_child(resource_root)
	villager_root = Node2D.new()
	villager_root.name = "Villagers"
	add_child(villager_root)
	enemy_root = Node2D.new()
	enemy_root.name = "Enemies"
	add_child(enemy_root)
	animal_root = Node2D.new()
	animal_root.name = "Animals"
	add_child(animal_root)
	crop_root = Node2D.new()
	crop_root.name = "Crops"
	add_child(crop_root)

func _build_player() -> void:
	player = CharacterBody2D.new()
	player.name = "Player"
	player.position = Vector2(240, 150)
	var sprite := Sprite2D.new()
	sprite.texture = player_texture
	sprite.hframes = 4
	sprite.frame = 0
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player.add_child(sprite)
	var collision := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 4.0
	shape.height = 10.0
	collision.shape = shape
	collision.position = Vector2(0, 3)
	player.add_child(collision)
	add_child(player)
	var camera := Camera2D.new()
	camera.position = Vector2.ZERO
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	player.add_child(camera)

func _build_locations() -> void:
	_add_location("Starter Homestead", Vector2(216, 128), house_texture, Color.WHITE)
	_add_location("Bramblefall Ruins", Vector2(72, 64), house_texture, Color(0.55, 0.48, 0.50))
	_add_location("Mossdeep Cave", Vector2(420, 54), chest_texture, Color(0.55, 0.55, 0.68))
	_add_location("Kingdom of Alderwatch", Vector2(402, 226), house_texture, Color(0.78, 0.88, 1.0))
	_add_location("Old Treasure", Vector2(56, 226), chest_texture, Color.WHITE)

func _build_resources() -> void:
	var tree_positions := [Vector2(54, 118), Vector2(92, 142), Vector2(124, 62), Vector2(342, 82), Vector2(382, 116), Vector2(430, 154)]
	for pos in tree_positions:
		_add_gatherable("Wood", pos, tree_texture, 3)
	var stone_positions := [Vector2(120, 220), Vector2(158, 236), Vector2(326, 214), Vector2(365, 198)]
	for pos in stone_positions:
		_add_gatherable("Stone", pos, chest_texture, 2, Color(0.62, 0.67, 0.72))
	var food_positions := [Vector2(184, 72), Vector2(296, 62), Vector2(276, 230)]
	for pos in food_positions:
		_add_gatherable("Food", pos, tree_texture, 2, Color(0.72, 1.0, 0.72))

func _build_villagers() -> void:
	var jobs := ["Lumberjack", "Miner", "Farmer", "Blacksmith", "Merchant", "Gatherer"]
	for index in range(jobs.size()):
		var pos := Vector2(198 + (index % 3) * 22, 174 + (index / 3) * 24)
		var villager := Sprite2D.new()
		villager.texture = player_texture
		villager.hframes = 4
		villager.frame = index % 4
		villager.position = pos
		villager.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		villager.modulate = Color.from_hsv(float(index) / float(jobs.size()), 0.28, 1.0)
		villager.set_meta("job", jobs[index])
		villager_root.add_child(villager)
		villagers.append({"job": jobs[index], "position": pos})

func _build_animals() -> void:
	_add_animal(chicken_texture, Vector2(272, 178), "Chicken")
	_add_animal(chicken_texture, Vector2(289, 184), "Chicken")
	_add_animal(cow_texture, Vector2(306, 170), "Cow")
	_add_crop(Vector2(270, 205))
	_add_crop(Vector2(286, 205))
	_add_crop(Vector2(302, 205))

func _build_enemies() -> void:
	_add_enemy("Slime", Vector2(365, 52), slime_texture, 3)
	_add_enemy("Slime", Vector2(395, 74), slime_texture, 3)
	_add_enemy("Skeleton", Vector2(88, 86), skeleton_texture, 5)

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "UI"
	add_child(canvas)
	var top_panel := PanelContainer.new()
	top_panel.position = Vector2(8, 8)
	top_panel.size = Vector2(286, 48)
	canvas.add_child(top_panel)
	hud_text = Label.new()
	hud_text.add_theme_font_size_override("font_size", 11)
	top_panel.add_child(hud_text)
	var help_panel := PanelContainer.new()
	help_panel.position = Vector2(8, 228)
	help_panel.size = Vector2(464, 34)
	canvas.add_child(help_panel)
	var help := Label.new()
	help.text = "E Gather/Fight/Talk   B Build   1 House  2 Farm  3 Smithy   F5 Save   F6 Load"
	help.add_theme_font_size_override("font_size", 10)
	help_panel.add_child(help)
	message_text = Label.new()
	message_text.position = Vector2(86, 62)
	message_text.size = Vector2(310, 44)
	message_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_text.add_theme_font_size_override("font_size", 11)
	canvas.add_child(message_text)
	night_overlay = ColorRect.new()
	night_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	night_overlay.position = Vector2.ZERO
	night_overlay.size = Vector2(480, 270)
	night_overlay.color = Color(0.08, 0.12, 0.28, 0.0)
	canvas.add_child(night_overlay)
	night_overlay.move_to_front()
	message_text.move_to_front()

func _add_world_sprite(texture: Texture2D, pos: Vector2, z_value: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = pos
	sprite.z_index = z_value
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world_root.add_child(sprite)
	return sprite

func _add_location(title: String, pos: Vector2, texture: Texture2D, tint: Color) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = pos
	sprite.modulate = tint
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.set_meta("location_name", title)
	settlement_root.add_child(sprite)
	var label := Label.new()
	label.text = title
	label.position = pos + Vector2(-48, -38)
	label.size = Vector2(96, 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 9)
	settlement_root.add_child(label)

func _add_gatherable(kind: String, pos: Vector2, texture: Texture2D, amount: int, tint: Color = Color.WHITE) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = pos
	sprite.modulate = tint
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.set_meta("kind", kind)
	sprite.set_meta("amount", amount)
	resource_root.add_child(sprite)

func _add_animal(texture: Texture2D, pos: Vector2, animal_name: String) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = pos
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.set_meta("animal_name", animal_name)
	animal_root.add_child(sprite)

func _add_crop(pos: Vector2) -> void:
	var soil := Sprite2D.new()
	soil.texture = farmland_texture
	soil.position = pos
	soil.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	crop_root.add_child(soil)
	var plant := Sprite2D.new()
	plant.texture = crop_texture
	plant.position = pos
	plant.hframes = 8
	plant.vframes = 8
	plant.frame = 0
	plant.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	plant.set_meta("growth", 0.0)
	crop_root.add_child(plant)
	crops.append({"node": plant, "growth": 0.0})

func _add_enemy(enemy_name: String, pos: Vector2, texture: Texture2D, health: int) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = pos
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.set_meta("enemy_name", enemy_name)
	sprite.set_meta("health", health)
	enemy_root.add_child(sprite)

func _interact() -> void:
	var nearest_resource := _nearest_child(resource_root, 24.0)
	if nearest_resource != null:
		var kind := String(nearest_resource.get_meta("kind"))
		var amount := int(nearest_resource.get_meta("amount"))
		var key := kind.to_lower()
		resources[key] = int(resources.get(key, 0)) + amount
		inventory[kind] = int(inventory.get(kind, 0)) + amount
		nearest_resource.queue_free()
		_show_message("Gathered %d %s." % [amount, kind])
		return
	var nearest_enemy := _nearest_child(enemy_root, 26.0)
	if nearest_enemy != null:
		var health := int(nearest_enemy.get_meta("health")) - 2
		if health <= 0:
			var defeated := String(nearest_enemy.get_meta("enemy_name"))
			resources["gold"] = int(resources["gold"]) + 2
			inventory["Gold"] = int(inventory.get("Gold", 0)) + 2
			nearest_enemy.queue_free()
			_show_message("Defeated %s. Looted 2 Gold." % defeated)
		else:
			nearest_enemy.set_meta("health", health)
			nearest_enemy.modulate = Color(1.0, 0.65, 0.65)
			_show_message("Hit %s — %d HP remains." % [String(nearest_enemy.get_meta("enemy_name")), health])
		return
	var nearest_villager := _nearest_child(villager_root, 26.0)
	if nearest_villager != null:
		_show_message("%s: The settlement is growing. Keep building." % String(nearest_villager.get_meta("job")))
		return
	var nearest_animal := _nearest_child(animal_root, 24.0)
	if nearest_animal != null:
		_show_message("The %s looks content." % String(nearest_animal.get_meta("animal_name")))
		return
	_show_message("Nothing nearby to interact with.")

func _try_build() -> void:
	var names := ["House", "Farm", "Smithy"]
	var costs := [{"wood": 6, "stone": 2}, {"wood": 4, "stone": 1}, {"wood": 5, "stone": 6}]
	var name := names[selected_building]
	var cost: Dictionary = costs[selected_building]
	if int(resources["wood"]) < int(cost["wood"]) or int(resources["stone"]) < int(cost["stone"]):
		_show_message("Not enough resources for %s." % name)
		return
	resources["wood"] = int(resources["wood"]) - int(cost["wood"])
	resources["stone"] = int(resources["stone"]) - int(cost["stone"])
	inventory["Wood"] = int(resources["wood"])
	inventory["Stone"] = int(resources["stone"])
	var grid_pos := Vector2(round(player.position.x / 16.0) * 16.0, round(player.position.y / 16.0) * 16.0)
	var sprite := Sprite2D.new()
	sprite.texture = house_texture if name != "Farm" else farmland_texture
	sprite.position = grid_pos
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if name == "Smithy":
		sprite.modulate = Color(0.82, 0.72, 0.68)
	settlement_root.add_child(sprite)
	buildings.append({"type": name, "x": grid_pos.x, "y": grid_pos.y})
	_show_message("Built %s." % name)

func _nearest_child(parent: Node, maximum_distance: float) -> Node2D:
	var result: Node2D = null
	var best := maximum_distance
	for child in parent.get_children():
		if child is Node2D:
			var node := child as Node2D
			var distance := player.position.distance_to(node.position)
			if distance < best and node.has_meta("kind") or distance < best and node.has_meta("enemy_name") or distance < best and node.has_meta("job") or distance < best and node.has_meta("animal_name"):
				best = distance
				result = node
	return result

func _update_day_night(delta: float) -> void:
	day_clock += delta * 0.08
	if day_clock >= 24.0:
		day_clock -= 24.0
		day_number += 1
	var darkness := 0.0
	if day_clock >= 19.0:
		darkness = minf(0.48, (day_clock - 19.0) * 0.11)
	elif day_clock < 6.0:
		darkness = 0.48 - day_clock * 0.05
	night_overlay.color = Color(0.08, 0.12, 0.28, darkness)

func _update_crops(delta: float) -> void:
	for crop in crops:
		var growth := minf(1.0, float(crop["growth"]) + delta * 0.003)
		crop["growth"] = growth
		var node := crop["node"] as Sprite2D
		if is_instance_valid(node):
			node.frame = mini(7, int(floor(growth * 7.0)))

func _update_hud() -> void:
	var build_name := ["House", "Farm", "Smithy"][selected_building]
	hud_text.text = "Day %d  %02d:00    Wood %d  Stone %d  Food %d  Gold %d\nBuild: %s    Settlement: %d buildings / %d villagers" % [day_number, int(day_clock), int(resources["wood"]), int(resources["stone"]), int(resources["food"]), int(resources["gold"]), build_name, buildings.size(), villagers.size()]

func _show_message(text: String) -> void:
	message_text.text = text
	message_timer = 3.2

func save_game() -> void:
	var payload := {
		"version": 3,
		"player": {"x": player.position.x, "y": player.position.y},
		"resources": resources,
		"inventory": inventory,
		"buildings": buildings,
		"day": day_number,
		"time": day_clock
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		_show_message("Save failed.")
		return
	file.store_string(JSON.stringify(payload))
	_show_message("Realm saved.")

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_show_message("No save file found.")
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		_show_message("Load failed.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_show_message("Save file is invalid.")
		return
	var payload := parsed as Dictionary
	resources = payload.get("resources", resources)
	inventory = payload.get("inventory", inventory)
	day_number = int(payload.get("day", day_number))
	day_clock = float(payload.get("time", day_clock))
	var player_data: Dictionary = payload.get("player", {})
	player.position = Vector2(float(player_data.get("x", player.position.x)), float(player_data.get("y", player.position.y)))
	for child in settlement_root.get_children():
		if child.has_meta("player_building"):
			child.queue_free()
	buildings.clear()
	var loaded_buildings: Array = payload.get("buildings", [])
	for entry_variant in loaded_buildings:
		if entry_variant is Dictionary:
			var entry := entry_variant as Dictionary
			var name := String(entry.get("type", "House"))
			var sprite := Sprite2D.new()
			sprite.texture = house_texture if name != "Farm" else farmland_texture
			sprite.position = Vector2(float(entry.get("x", 240.0)), float(entry.get("y", 150.0)))
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.set_meta("player_building", true)
			settlement_root.add_child(sprite)
			buildings.append(entry)
	_show_message("Realm loaded.")
