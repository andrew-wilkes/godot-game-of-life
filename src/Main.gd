extends Node2D

var grids = [{}, {}]
var cells = {}
var alive_color: Color
export(Color) var dead_color = Color(32)

func _ready():
	$Cell.hide()
	alive_color = $Cell.modulate

const ZOOM_STEP = 0.1

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			print(event.position, " ", $Camera2D.offset, " ", $Camera2D.zoom)
			place_cell(event.position)
		if event.button_index == BUTTON_RIGHT and event.pressed:
			remove_cell(event.position)
		if event.button_index == BUTTON_WHEEL_DOWN:
			change_zoom(ZOOM_STEP)
		if event.button_index == BUTTON_WHEEL_UP:
			change_zoom(-ZOOM_STEP)
	if event is InputEventMouseMotion and event.button_mask == BUTTON_MASK_MIDDLE:
			move_camera(event.relative)
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if event.is_action_pressed("ui_accept"):
		start_stop()
	if event.is_action_pressed("ui_reset"):
		reset()

var zoom = 1.0

func change_zoom(dz: float):
	zoom = clamp(zoom + dz, 0.1, 8.0)
	$Camera2D.zoom = Vector2(zoom, zoom)

func move_camera(dv: Vector2):
	$Camera2D.offset -= dv

func place_cell(pos: Vector2):
	# Convert mouse position to camera view coordinates
	pos = pos + $Camera2D.offset / $Camera2D.zoom - get_viewport_rect().size / 2
	var grid_pos = get_grid_pos(pos)
	var key = get_key(grid_pos)
	if not cells.has(key):
		add_new_cell(grid_pos, key)

func add_new_cell(grid_pos, key, _by_player = true):
	# Adjust position
	var pos = grid_pos * 32.0
	# Scale it
	#pos *= $Camera2D.zoom
	print(pos)
	var cell = $Cell.duplicate()
	cell.position = pos
	add_child(cell)
	cell.show()
	cells[key] = cell
	grids[1][key] = true

func remove_cell(pos: Vector2):
	var key = get_key(get_grid_pos(pos))
	# Check if user clicked in occupied position
	if cells.has(key):
		cells[key].queue_free()
		cells.erase(key)
		grids[1].erase(key)

func get_grid_pos(pos: Vector2) -> Vector2:
	var pixels = 32.0 / $Camera2D.zoom.x
	return pos.snapped(Vector2(pixels, pixels)) / pixels

func get_key(pos: Vector2) -> int:
	return 0x8000 + int(pos.x) + 0x10000 * (int(pos.y) + 0x8000) 

func start_stop():
	if $Timer.is_stopped() and cells.size() > 0:
		$Timer.start()
		$c/Running.show()
		$c/Stopped.hide()
	else:
		$Timer.stop()
		$c/Running.hide()
		$c/Stopped.show()

func reset():
	$Timer.stop()
	$c/Running.hide()
	$c/Stopped.show()
	for key in cells.keys():
		cells[key].queue_free()
	grids[0].clear()
	cells.clear()

func _on_Timer_timeout():
	grids.invert()
	grids[1].clear()
	regenerate()
	add_new_cells()
	update_cells()

func regenerate():
	for key in cells.keys():
		var n = get_num_live_cells(key)
		if grids[0][key]: # Alive
			grids[1][key] = (n == 2 or n == 3)
		else: # Dead
			grids[1][key] = (n == 3)

func update_cells():
	for key in cells.keys():
		cells[key].modulate = alive_color if grids[1][key] else dead_color

var to_check = []

func get_num_live_cells(key: int, first_pass = true):
	var num_live_cells = 0
	for y in [-1, 0, 1]:
		for x in [-1, 0, 1]:
			if x != 0 or y != 0:
				var nkey = key + x + 0x10000 * y
				if grids[0].has(nkey):
					if grids[0][nkey]:
						num_live_cells += 1
				else:
					if first_pass:
						to_check.append(nkey)
	return num_live_cells

func add_new_cells():
	for key in to_check:
		var n = get_num_live_cells(key, false)
		if n == 3 and not grids[1].has(key):
			add_new_cell(get_pos_from_key(key), key, false)
	to_check = []

func get_pos_from_key(key):
	return Vector2(key % 0x10000, key / 0x10000)
