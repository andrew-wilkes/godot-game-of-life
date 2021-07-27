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
	pos = mouse_pos_to_cam_pos(pos)
	var grid_pos = get_grid_pos(pos)
	if not cells.has(grid_pos):
		add_new_cell(grid_pos)

func mouse_pos_to_cam_pos(pos):
	return pos + $Camera2D.offset / $Camera2D.zoom - get_viewport_rect().size / 2

func add_new_cell(grid_pos):
	var pos = grid_pos * 32.0
	var cell = $Cell.duplicate()
	cell.position = pos
	add_child(cell)
	cell.show()
	cells[grid_pos] = cell
	grids[1][grid_pos] = true

func remove_cell(pos: Vector2):
	var key = get_grid_pos(mouse_pos_to_cam_pos(pos))
	# Check if user clicked in occupied position
	if cells.has(key):
		cells[key].queue_free()
		cells.erase(key)
		grids[1].erase(key)

func get_grid_pos(pos: Vector2) -> Vector2:
	var pixels = 32.0 / $Camera2D.zoom.x
	return pos.snapped(Vector2(pixels, pixels)) / pixels


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
	grids[1].clear()
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

func get_num_live_cells(pos: Vector2, first_pass = true):
	var num_live_cells = 0
	for y in [-1, 0, 1]:
		for x in [-1, 0, 1]:
			if x != 0 or y != 0:
				var new_pos = pos + Vector2(x, y)
				if grids[0].has(new_pos):
					if grids[0][new_pos]: # If alive
						num_live_cells += 1
				else:
					if first_pass:
						to_check.append(new_pos)
	return num_live_cells

func add_new_cells():
	for pos in to_check:
		var n = get_num_live_cells(pos, false)
		if n == 3 and not grids[1].has(pos):
			add_new_cell(pos)
	to_check = []
