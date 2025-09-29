extends Control

@export var player_path: NodePath = NodePath("")
@onready var player_controller: Node = null
@export var bg_color := Color(0, 0, 0, 0.5)
@export var bg_margin := Vector2(12, 12)
@export var bar_height := 24.0
@export var bar_width := 180.0
@export var bar_spacing := 10.0

var _last_rgb_values := Vector3(-1, -1, -1)

func _ready() -> void:
	anchors_preset = Control.PRESET_BOTTOM_LEFT
	offset_left = 16
	offset_bottom = -150  # Push up from bottom to ensure all bars are visible
	size = Vector2(240, 120)

	if player_path != NodePath("") and has_node(player_path):
		player_controller = get_node(player_path)
	else:
		push_warning("ColorLegend: player_path is empty, please assign your player node in Inspector.")
	set_process(true)

func _process(_dt: float) -> void:
	var cur_rgb := _get_current_rgb_values()
	
	# Only redraw if values changed
	if cur_rgb != _last_rgb_values:
		queue_redraw()
		_last_rgb_values = cur_rgb

func _draw() -> void:
	# Calculate total height
	var total_h: float = bg_margin.y * 2 + 3 * (bar_height + bar_spacing) - bar_spacing
	var total_w: float = bg_margin.x * 2 + bar_width + 40
	
	# Draw background
	draw_rect(Rect2(Vector2.ZERO, Vector2(total_w, total_h)), bg_color, true)
	
	# Draw title
	var font := ThemeDB.fallback_font
	var title_size := 16
	
	# Draw RGB progress bars
	var bar_start_y := bg_margin.y + 24
	_draw_rgb_progress_bars(bar_start_y)

func _draw_rgb_progress_bars(start_y: float) -> void:
	var rgb_values := _get_current_rgb_values()
	var labels := ["R", "G", "B"]
	# Pure colors for the bars
	var bar_colors := [Color(1, 0, 0, 1), Color(0, 1, 0, 1), Color(0, 0, 1, 1)]
	var values := [rgb_values.x, rgb_values.y, rgb_values.z]
	
	var font := ThemeDB.fallback_font
	var font_size := 14
	
	for i in range(3):
		var y_pos := start_y + i * (bar_height + bar_spacing)
		var label_x := bg_margin.x
		
		# Draw label with bright color
		var label_color: Color = bar_colors[i]
		label_color = label_color.lightened(0.2)
		draw_string(font, Vector2(label_x, y_pos + bar_height * 0.65), 
		           labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2, label_color)
		
		# Progress bar position
		var bar_x := label_x + 20
		var actual_bar_width := bar_width
		var bar_rect := Rect2(bar_x, y_pos, actual_bar_width, bar_height)
		
		# Draw progress bar background (dark gray)
		draw_rect(bar_rect, Color(0.15, 0.15, 0.15, 1), true)
		
		# Draw progress bar fill if value > 0
		if values[i] > 0.001:  # Small threshold to avoid floating point issues
			var fill_width: float = actual_bar_width * values[i]
			var fill_rect := Rect2(bar_x, y_pos, fill_width, bar_height)
			
			# Main fill color
			var fill_color: Color = bar_colors[i]
			fill_color.a = 0.9
			draw_rect(fill_rect, fill_color, true)
			
			# Top highlight for 3D effect
			var highlight_rect := Rect2(bar_x, y_pos, fill_width, 4)
			var highlight_color := fill_color.lightened(0.3)
			highlight_color.a = 0.6
			draw_rect(highlight_rect, highlight_color, true)
			
			# Bottom shadow for 3D effect  
			var shadow_rect := Rect2(bar_x, y_pos + bar_height - 3, fill_width, 3)
			var shadow_color := fill_color.darkened(0.3)
			shadow_color.a = 0.7
			draw_rect(shadow_rect, shadow_color, true)
		
		# Draw border around entire bar
		draw_rect(bar_rect, Color(0.6, 0.6, 0.6, 1), false, 2.0)
		
		# Draw percentage text (always visible)
		var percentage := roundi(values[i] * 100)
		var percent_text := str(percentage) + "%"
		var text_color := Color.WHITE if values[i] < 0.5 else Color.BLACK
		text_color.a = 0.9
		
		# Center text in the bar
		var text_x := bar_x + actual_bar_width / 2
		var text_y := y_pos + bar_height * 0.65
		draw_string(font, Vector2(text_x - 15, text_y), 
		           percent_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)

func _get_current_rgb_values() -> Vector3:
	if player_controller == null:
		return Vector3.ZERO
	
	# Get the rgb_color from the player
	var color: Color = player_controller.rgb_color
	
	# If the player has no_color flag set, return zeros
	if player_controller.no_color:
		return Vector3.ZERO
		
	return Vector3(color.r, color.g, color.b)
