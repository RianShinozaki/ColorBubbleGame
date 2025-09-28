extends Control

@export var player_path: NodePath = NodePath("")
@onready var player_controller: Node = null
@export var circle_radius := 8.0
@export var row_gap := 8.0
@export var line_length := 100.0
@export var line_thickness := 2.0
@export var bg_color := Color(0, 0, 0, 0.35)
@export var bg_margin := Vector2(8, 8)


var _last_mask := -1
var _last_no_color := false
var _rows: Array = []

const RED   := Color(1, 0, 0, 1)
const GREEN := Color(0, 1, 0, 1)
const BLUE  := Color(0, 0, 1, 1)

const EAT_ORDER := [RED, BLUE, GREEN]

func _ready() -> void:
	anchors_preset = Control.PRESET_BOTTOM_LEFT
	offset_left = 16
	offset_bottom = 16
	size = Vector2(220, 100)

	if player_path != NodePath("") and has_node(player_path):
		player_controller = get_node(player_path)
	else:
		push_warning("ColorLegend: player_path is empty, please assign your player node in Inspector.")
	set_process(true)
	_refresh_rows(true)

func _process(_dt: float) -> void:
	var cur_mask := _current_color_mask()
	var cur_no_color := _player_has_no_color()
	if cur_mask != _last_mask or cur_no_color != _last_no_color:
		_refresh_rows()
		queue_redraw()

func _draw() -> void:
	var total_h := _content_height()
	var total_w := bg_margin.x * 2 + line_length + circle_radius * 2 * 2 + 32
	draw_rect(Rect2(Vector2.ZERO, Vector2(total_w, total_h)), bg_color, true)

	var y := bg_margin.y + circle_radius
	for row in _rows:
		var eat_c: Color = row.eat_color
		var res_c: Color = row.result_color

		var left_center := Vector2(bg_margin.x + circle_radius + 4, y)
		draw_circle(left_center, circle_radius, eat_c)

		var line_start := left_center + Vector2(circle_radius + 6, 0)
		var line_end := line_start + Vector2(line_length, 0)
		draw_line(line_start, line_end, Color(1, 1, 1, 0.6), line_thickness)

		var right_center := line_end + Vector2(circle_radius + 6, 0)
		draw_circle(right_center, circle_radius, res_c)

		y += circle_radius * 2 + row_gap

func _content_height() -> float:
	var rows: int = max(1, _rows.size())
	return bg_margin.y * 2 + rows * (circle_radius * 2) + (rows - 1) * row_gap

func _refresh_rows(_force := false) -> void:
	_rows.clear()

	var mask := _current_color_mask()
	var no_col := _player_has_no_color()

	for eat_c in EAT_ORDER:
		var result_c := _result_color(mask, no_col, eat_c)
		var result_mask := _mask_from_color(result_c)

		# Hide rows that wouldn't change anything
		if not no_col and result_mask == mask:
			continue

		_rows.append({ "eat_color": eat_c, "result_color": result_c })

	_last_mask = mask
	_last_no_color = no_col

# --- Color logic -------------------------------------------------------------

func _player_color() -> Color:
	if player_controller == null:
		return Color(0, 0, 0, 1)
	return player_controller.rgb_color

func _player_has_no_color() -> bool:
	if player_controller == null:
		return true
	return bool(player_controller.no_color)


# Quantize to a 3-bit mask (R=1, G=2, B=4)
func _current_color_mask() -> int:
	return _mask_from_color(_player_color())

func _mask_from_color(c: Color) -> int:
	var r := int(floor(clamp(c.r, 0.0, 1.0)))
	var g := int(floor(clamp(c.g, 0.0, 1.0)))
	var b := int(floor(clamp(c.b, 0.0, 1.0)))
	return (r) | (g << 1) | (b << 2)

func _color_from_mask(mask: int) -> Color:
	var r := 1.0 if ((mask & 1) != 0) else 0.0
	var g := 1.0 if ((mask & 2) != 0) else 0.0
	var b := 1.0 if ((mask & 4) != 0) else 0.0
	return Color(r, g, b, 1)

# Compute the outcome of eating a base color.
# If the player has `no_color` (neutral/white in your example), the result is exactly that base color.
# Otherwise, we bitwise-OR the current mask with the pickup (standard additive mixing):
# R+B=magenta(pink), R+G=yellow, B+G=cyan, all three=white.
func _result_color(cur_mask: int, no_col: bool, eat_c: Color) -> Color:
	var eat_mask := _mask_from_color(eat_c)  # 1, 2, or 4
	if no_col:
		return _color_from_mask(eat_mask)
	var out_mask := cur_mask | eat_mask
	return _color_from_mask(out_mask)
