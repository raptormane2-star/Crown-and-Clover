class_name WorldController
extends Node2D

signal message_requested(text: String)
signal reputation_changed(value: int)
signal player_health_changed(value: int, maximum: int)

const WORLD_SIZE := Vector2(2300.0, 1500.0)
const CAVE_SIZE := Vector2(1050.0, 650.0)
const BUILDING_SIZE := Vector2(96.0, 72.0)
const CAVE_ENTRANCE := Vector2(1260.0, 390.0)
const CAVE_EXIT := Vector2(120.0, 500.0)

var assets: AssetCatalog
var inventory: InventorySystem
var villagers: VillagerJobsSystem
var player: PlayerCharacter

var buildings: Array[Dictionary] = []
var trees: Array[Dictionary] = []
var rocks: Array[Dictionary] = []
var crops: Array[Dictionary] = []
var animals: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var cave_enemies: Array[Dictionary] = []
var cave_chest_opened: bool = false
var ruins_chest_opened: bool = false
var in_cave: bool = false
var night_mode: bool = false
var reputation: int = 0
var player_health: int = 6
var max_player_health: int = 6
var animation_time: float = 0.0

var _collision_root: Node2D

func configure(asset_catalog: AssetCatalog, inventory_system: InventorySystem, villager_system: VillagerJobsSystem, player_character: PlayerCharacter) -> void:
    assets = asset_catalog
    inventory = inventory_system
    villagers = villager_system
    player = player_character
    _collision_root = Node2D.new()
    _collision_root.name = "BuildingCollisions"
    add_child(_collision_root)
    _setup_world()

func _setup_world() -> void:
    buildings = [
        {"type": "house", "pos": Vector2(700, 850)},
        {"type": "house", "pos": Vector2(840, 850)},
        {"type": "smithy", "pos": Vector2(980, 900)},
        {"type": "farm", "pos": Vector2(550, 980)},
    ]
    trees.clear()
    for position: Vector2 in [Vector2(250, 260), Vector2(350, 330), Vector2(470, 250), Vector2(220, 650), Vector2(380, 1180), Vector2(1120, 1180), Vector2(1450, 230), Vector2(1540, 300), Vector2(2120, 1050)]:
        trees.append({"pos": position, "health": 3})
    rocks = [
        {"pos": Vector2(1080, 300), "health": 3},
        {"pos": Vector2(1180, 260), "health": 3},
        {"pos": Vector2(1340, 1120), "health": 3},
        {"pos": Vector2(1510, 1180), "health": 3},
    ]
    crops = [
        {"pos": Vector2(520, 1010), "growth": 2},
        {"pos": Vector2(565, 1010), "growth": 1},
        {"pos": Vector2(610, 1010), "growth": 0},
    ]
    animals = [
        {"type": "chicken", "pos": Vector2(460, 900), "ready": true},
        {"type": "chicken", "pos": Vector2(500, 920), "ready": false},
        {"type": "cow", "pos": Vector2(430, 1030), "ready": true},
    ]
    enemies = [
        {"type": "slime", "pos": Vector2(1320, 760), "health": 3},
        {"type": "slime", "pos": Vector2(1430, 860), "health": 3},
        {"type": "skeleton", "pos": Vector2(1880, 1180), "health": 4},
    ]
    cave_enemies = [
        {"type": "slime", "pos": Vector2(500, 270), "health": 3},
        {"type": "skeleton", "pos": Vector2(760, 360), "health": 4},
    ]
    _rebuild_building_collisions()
    queue_redraw()

func update_world(delta: float) -> void:
    animation_time += delta
    if in_cave:
        player.position.x = clampf(player.position.x, 35.0, CAVE_SIZE.x - 35.0)
        player.position.y = clampf(player.position.y, 35.0, CAVE_SIZE.y - 35.0)
    else:
        player.position.x = clampf(player.position.x, 30.0, WORLD_SIZE.x - 30.0)
        player.position.y = clampf(player.position.y, 30.0, WORLD_SIZE.y - 30.0)
    _update_enemy_contacts(delta)
    _check_region_transitions()
    queue_redraw()

func set_night(enabled: bool) -> void:
    night_mode = enabled
    queue_redraw()

func on_new_day() -> void:
    for crop: Dictionary in crops:
        crop["growth"] = mini(int(crop.get("growth", 0)) + 1, 3)
    for animal: Dictionary in animals:
        animal["ready"] = true
    queue_redraw()

func process_build_input() -> void:
    if Input.is_action_just_pressed("build_house"):
        _try_build("house", {&"wood": 10, &"stone": 4})
    elif Input.is_action_just_pressed("build_farm"):
        _try_build("farm", {&"wood": 6, &"stone": 2})
    elif Input.is_action_just_pressed("build_smithy"):
        _try_build("smithy", {&"wood": 14, &"stone": 12})

func interact() -> void:
    if in_cave:
        if player.position.distance_to(CAVE_EXIT) < 75.0:
            _leave_cave()
            return
        if not cave_chest_opened and player.position.distance_to(Vector2(880, 170)) < 70.0:
            cave_chest_opened = true
            inventory.add(&"gold", 45)
            inventory.add(&"stone", 8)
            _message("You found an old miner's cache: 45 Gold and 8 Stone.")
            return
        return

    if player.position.distance_to(CAVE_ENTRANCE) < 85.0:
        _enter_cave()
        return

    if not ruins_chest_opened and player.position.distance_to(Vector2(1880, 1040)) < 75.0:
        ruins_chest_opened = true
        inventory.add(&"gold", 80)
        reputation += 2
        reputation_changed.emit(reputation)
        _message("Bramblefall's lost coffer held 80 Gold. Your discovery spreads across the realm.")
        return

    for villager: Dictionary in villagers.villagers:
        if player.position.distance_to(villager["pos"] as Vector2) < 72.0:
            _message("%s — %s\n%s" % [str(villager["name"]), str(villager["job"]), str(villager["line"])])
            return

    for crop: Dictionary in crops:
        if player.position.distance_to(crop["pos"] as Vector2) < 60.0 and int(crop.get("growth", 0)) >= 3:
            crop["growth"] = 0
            inventory.add(&"food", 3)
            _message("Harvested 3 Food.")
            return

    for animal: Dictionary in animals:
        if player.position.distance_to(animal["pos"] as Vector2) < 62.0 and bool(animal.get("ready", false)):
            animal["ready"] = false
            if str(animal["type"]) == "cow":
                inventory.add(&"milk", 1)
                _message("Collected fresh Milk.")
            else:
                inventory.add(&"egg", 1)
                _message("Collected a fresh Egg.")
            return

    for tree: Dictionary in trees:
        if player.position.distance_to(tree["pos"] as Vector2) < 70.0:
            tree["health"] = int(tree["health"]) - 1
            if int(tree["health"]) <= 0:
                inventory.add(&"wood", 5)
                tree["pos"] = Vector2(-1000, -1000)
                _message("Gathered 5 Wood.")
            else:
                _message("Chop... %d hits remaining." % int(tree["health"]))
            return

    for rock: Dictionary in rocks:
        if player.position.distance_to(rock["pos"] as Vector2) < 65.0:
            rock["health"] = int(rock["health"]) - 1
            if int(rock["health"]) <= 0:
                inventory.add(&"stone", 5)
                rock["pos"] = Vector2(-1000, -1000)
                _message("Mined 5 Stone.")
            else:
                _message("Clink... %d hits remaining." % int(rock["health"]))
            return

    _message("Nothing nearby to interact with.")

func attack() -> void:
    var targets: Array[Dictionary] = cave_enemies if in_cave else enemies
    var attack_point := player.position + player.facing_vector * 38.0
    var hit := false
    for enemy: Dictionary in targets:
        if int(enemy.get("health", 0)) > 0 and attack_point.distance_to(enemy["pos"] as Vector2) < 62.0:
            enemy["health"] = int(enemy["health"]) - 1
            hit = true
            if int(enemy["health"]) <= 0:
                inventory.add(&"gold", 8)
                if randf() < 0.55:
                    inventory.add(&"food", 1)
                reputation += 1
                reputation_changed.emit(reputation)
                _message("Enemy defeated. +8 Gold, +1 Reputation.")
            break
    if not hit:
        _message("Your attack cuts through empty air.")

func serialize() -> Dictionary:
    return {
        "buildings": buildings,
        "crops": crops,
        "cave_chest_opened": cave_chest_opened,
        "ruins_chest_opened": ruins_chest_opened,
        "reputation": reputation,
        "player_health": player_health,
        "player_position": {"x": player.position.x, "y": player.position.y},
        "in_cave": in_cave,
    }

func deserialize(data: Dictionary) -> void:
    if data.has("buildings"):
        buildings = data["buildings"] as Array[Dictionary]
    if data.has("crops"):
        crops = data["crops"] as Array[Dictionary]
    cave_chest_opened = bool(data.get("cave_chest_opened", false))
    ruins_chest_opened = bool(data.get("ruins_chest_opened", false))
    reputation = int(data.get("reputation", 0))
    player_health = clampi(int(data.get("player_health", max_player_health)), 1, max_player_health)
    in_cave = bool(data.get("in_cave", false))
    var saved_position: Dictionary = data.get("player_position", {}) as Dictionary
    if not saved_position.is_empty():
        player.position = Vector2(float(saved_position.get("x", 760.0)), float(saved_position.get("y", 720.0)))
    _rebuild_building_collisions()
    reputation_changed.emit(reputation)
    player_health_changed.emit(player_health, max_player_health)
    queue_redraw()

func _try_build(building_type: String, costs: Dictionary[StringName, int]) -> void:
    if in_cave:
        _message("You cannot build inside a cave.")
        return
    var build_position := player.position + player.facing_vector * 110.0
    for building: Dictionary in buildings:
        if build_position.distance_to(building["pos"] as Vector2) < 115.0:
            _message("There is not enough room to build here.")
            return
    if not inventory.spend(costs):
        _message("You do not have enough resources for that building.")
        return
    buildings.append({"type": building_type, "pos": build_position})
    if building_type == "house":
        villagers.add_settler(build_position + Vector2(48, 80))
        reputation += 1
        reputation_changed.emit(reputation)
        _message("House completed. A new settler has joined Cloverhold.")
    elif building_type == "farm":
        crops.append({"pos": build_position + Vector2(-22, 32), "growth": 0})
        crops.append({"pos": build_position + Vector2(22, 32), "growth": 0})
        _message("Farm plot completed. Crops will grow each morning.")
    else:
        max_player_health += 1
        player_health = max_player_health
        player_health_changed.emit(player_health, max_player_health)
        _message("Smithy completed. Better equipment is now possible.")
    _rebuild_building_collisions()
    queue_redraw()

func _enter_cave() -> void:
    in_cave = true
    player.position = Vector2(150, 500)
    _message("Whispering Cave — the air is cold and still.")

func _leave_cave() -> void:
    in_cave = false
    player.position = CAVE_ENTRANCE + Vector2(0, 110)
    _message("You return to the overworld.")

func _check_region_transitions() -> void:
    if in_cave and player.position.distance_to(CAVE_EXIT) < 45.0:
        _leave_cave()

func _update_enemy_contacts(_delta: float) -> void:
    var targets: Array[Dictionary] = cave_enemies if in_cave else enemies
    for enemy: Dictionary in targets:
        if int(enemy.get("health", 0)) <= 0:
            continue
        var enemy_position: Vector2 = enemy["pos"] as Vector2
        if enemy_position.distance_to(player.position) < 34.0 and player.attack_time <= 0.0:
            player_health = maxi(1, player_health - 1)
            player_health_changed.emit(player_health, max_player_health)
            player.position -= player.facing_vector * 28.0
            _message("You were hit! Find space and strike back.")
            break

func _rebuild_building_collisions() -> void:
    if _collision_root == null:
        return
    for child: Node in _collision_root.get_children():
        child.queue_free()
    if in_cave:
        return
    for building: Dictionary in buildings:
        if str(building.get("type", "")) == "farm":
            continue
        var body := StaticBody2D.new()
        body.position = building["pos"] as Vector2
        var shape_node := CollisionShape2D.new()
        var shape := RectangleShape2D.new()
        shape.size = BUILDING_SIZE
        shape_node.shape = shape
        body.add_child(shape_node)
        _collision_root.add_child(body)

func _message(text: String) -> void:
    message_requested.emit(text)

func _draw() -> void:
    if assets == null or player == null:
        return
    if in_cave:
        _draw_cave()
    else:
        _draw_overworld()

func _draw_overworld() -> void:
    draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color(0.18, 0.47, 0.24), true)
    _tile_texture(assets.texture(&"grass"), Rect2(Vector2.ZERO, WORLD_SIZE), Vector2(64, 64))
    _tile_texture(assets.texture(&"path"), Rect2(0, 710, WORLD_SIZE.x, 115), Vector2(64, 64))
    draw_rect(Rect2(0, 430, WORLD_SIZE.x, 165), Color(0.10, 0.34, 0.55), true)
    _tile_texture(assets.texture(&"water"), Rect2(0, 430, WORLD_SIZE.x, 165), Vector2(64, 64))
    _draw_texture_centered(assets.texture(&"bridge"), Vector2(830, 510), Vector2(112, 180))

    draw_rect(Rect2(1620, 610, 520, 380), Color(0.23, 0.52, 0.28, 0.48), true)
    draw_string(ThemeDB.fallback_font, Vector2(1730, 645), "KINGDOM OF ELDERMERE", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.96, 0.88, 0.55))
    draw_rect(Rect2(1660, 950, 470, 315), Color(0.25, 0.20, 0.18, 0.42), true)
    draw_string(ThemeDB.fallback_font, Vector2(1745, 980), "BRAMBLEFALL RUINS", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.86, 0.73, 0.53))

    for index: int in range(7):
        var ruin_texture := assets.texture(StringName("ruin_%d" % (index + 1)))
        var ruin_position := Vector2(1690 + (index % 4) * 105, 1015 + (index / 4) * 115)
        _draw_texture_centered(ruin_texture, ruin_position, Vector2(92, 92))

    for tree: Dictionary in trees:
        var position: Vector2 = tree["pos"] as Vector2
        if position.x > -500.0:
            _draw_texture_centered(assets.texture(&"maple_tree"), position, Vector2(84, 112))
    for rock: Dictionary in rocks:
        var position: Vector2 = rock["pos"] as Vector2
        if position.x > -500.0:
            draw_circle(position, 25.0, Color(0.40, 0.43, 0.46))
            draw_circle(position + Vector2(-7, -7), 10.0, Color(0.55, 0.57, 0.58))

    for building: Dictionary in buildings:
        var position: Vector2 = building["pos"] as Vector2
        var kind := str(building.get("type", "house"))
        if kind == "farm":
            _tile_texture(assets.texture(&"farmland"), Rect2(position - Vector2(55, 38), Vector2(110, 76)), Vector2(32, 32))
        else:
            _draw_texture_centered(assets.texture(&"house"), position, Vector2(110, 96))
            draw_string(ThemeDB.fallback_font, position + Vector2(-35, 61), kind.capitalize(), HORIZONTAL_ALIGNMENT_CENTER, 70, 14, Color.WHITE)

    for crop: Dictionary in crops:
        _draw_crop(crop["pos"] as Vector2, int(crop.get("growth", 0)))
    for animal: Dictionary in animals:
        var animal_texture := assets.texture(&"cow") if str(animal["type"]) == "cow" else assets.texture(&"chicken")
        _draw_texture_centered(animal_texture, animal["pos"] as Vector2, Vector2(48, 48))
    for villager: Dictionary in villagers.villagers:
        _draw_resource_path(str(villager.get("texture_path", "")), villager["pos"] as Vector2, Vector2(44, 54))
    for enemy: Dictionary in enemies:
        _draw_enemy(enemy)

    draw_rect(Rect2(CAVE_ENTRANCE - Vector2(55, 35), Vector2(110, 70)), Color(0.10, 0.09, 0.12), true)
    draw_string(ThemeDB.fallback_font, CAVE_ENTRANCE + Vector2(-65, 62), "Whispering Cave", HORIZONTAL_ALIGNMENT_CENTER, 130, 16, Color(0.88, 0.83, 0.70))
    if not ruins_chest_opened:
        _draw_texture_centered(assets.texture(&"chest"), Vector2(1880, 1040), Vector2(48, 48))
    _draw_player()
    if night_mode:
        draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color(0.05, 0.08, 0.20, 0.38), true)

func _draw_cave() -> void:
    draw_rect(Rect2(Vector2.ZERO, CAVE_SIZE), Color(0.08, 0.08, 0.10), true)
    draw_rect(Rect2(30, 30, CAVE_SIZE.x - 60, CAVE_SIZE.y - 60), Color(0.18, 0.17, 0.20), true)
    draw_string(ThemeDB.fallback_font, Vector2(390, 55), "WHISPERING CAVE", HORIZONTAL_ALIGNMENT_CENTER, 300, 24, Color(0.82, 0.78, 0.70))
    for enemy: Dictionary in cave_enemies:
        _draw_enemy(enemy)
    if not cave_chest_opened:
        _draw_texture_centered(assets.texture(&"chest"), Vector2(880, 170), Vector2(52, 52))
    draw_rect(Rect2(CAVE_EXIT - Vector2(45, 35), Vector2(90, 70)), Color(0.36, 0.29, 0.20), true)
    draw_string(ThemeDB.fallback_font, CAVE_EXIT + Vector2(-40, 58), "Exit", HORIZONTAL_ALIGNMENT_CENTER, 80, 15, Color.WHITE)
    _draw_player()

func _draw_player() -> void:
    var texture := assets.texture(&"player_walk") if player.velocity.length() > 1.0 else assets.texture(&"player_idle")
    _draw_texture_centered(texture, player.position, Vector2(54, 66))
    if player.attack_time > 0.0:
        draw_line(player.position, player.position + player.facing_vector * 48.0, Color(1.0, 0.92, 0.58), 5.0)

func _draw_enemy(enemy: Dictionary) -> void:
    if int(enemy.get("health", 0)) <= 0:
        return
    var enemy_id := StringName(str(enemy.get("type", "slime")))
    _draw_texture_centered(assets.texture(enemy_id), enemy["pos"] as Vector2, Vector2(56, 56))

func _draw_crop(position: Vector2, growth: int) -> void:
    var crop_texture := assets.texture(&"crops")
    if crop_texture != null:
        _draw_texture_centered(crop_texture, position, Vector2(40, 40))
    else:
        var radius := 4.0 + float(growth) * 2.5
        draw_circle(position, radius, Color(0.36, 0.72, 0.25))

func _draw_resource_path(path: String, position: Vector2, size: Vector2) -> void:
    if path.is_empty() or not ResourceLoader.exists(path, "Texture2D"):
        return
    var texture := ResourceLoader.load(path, "Texture2D") as Texture2D
    _draw_texture_centered(texture, position, size)

func _draw_texture_centered(texture: Texture2D, position: Vector2, size: Vector2) -> void:
    if texture == null:
        return
    draw_texture_rect(texture, Rect2(position - size * 0.5, size), false)

func _tile_texture(texture: Texture2D, area: Rect2, tile_size: Vector2) -> void:
    if texture == null:
        return
    var y := area.position.y
    while y < area.end.y:
        var x := area.position.x
        while x < area.end.x:
            draw_texture_rect(texture, Rect2(Vector2(x, y), tile_size), false)
            x += tile_size.x
        y += tile_size.y
