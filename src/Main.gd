extends Node2D

var grids = [{}, {}]
var cells = {}

func _ready():
	$Cell.hide()

func _on_Timer_timeout():
	grids.invert()
	grids[1].clear()

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

var zoom = 1.0

func change_zoom(dz: float):
	zoom = clamp(zoom + dz, 0.1, 8.0)
	$Camera2D.zoom = Vector2(zoom, zoom)

func move_camera(dv: Vector2):
	$Camera2D.offset -= dv

func place_cell(pos: Vector2):
	var cell = $Cell.duplicate()
	cell.position = get_snapped_pos(pos)
	add_child(cell)
	cell.show()
	cells[get_key(cell.position)] = cell

func remove_cell(pos: Vector2):
	var key = get_key(get_snapped_pos(pos))
	if cells.has(key):
		cells[key].queue_free()
		cells.erase(key)

func get_snapped_pos(pos: Vector2) -> Vector2:
	return pos.snapped(Vector2(32, 32))

func get_key(pos: Vector2) -> int:
	return int(pos.x) + 0x10000 * int(pos.y)
