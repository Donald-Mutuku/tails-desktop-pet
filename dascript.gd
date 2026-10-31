extends Node2D

enum State {WALK, DRAG, DANCE, IDLE, FALL, FOLLOW, SLEEP}
var state = State.WALK

var speed = 300
var direction = Vector2(1,0)
var screen_size = Vector2()
var window_size = Vector2(128,128)

var initial_pos = Vector2()

var idle_timer = 0.0
var is_idling = false

@onready var animated_sprite = $AnimatedSprite2D
@onready var area = $Area2D

var is_dragging = false
var drag_offset = Vector2()

var is_falling = false
var usable = DisplayServer.screen_get_usable_rect()
var taskbar_y = usable.end.y

var is_following = false
var lift_timer = 0.0
var is_holding = false

func _ready():
	screen_size = Vector2(DisplayServer.screen_get_size())
	animated_sprite.play("walk")
	area.input_event.connect(_on_area_input)
	animated_sprite.animation_finished.connect(_on_animation_finished)

func maybe_idle():
	if randf() < 0.3:
		is_idling = true
		state = State.IDLE
		animated_sprite.play("idle")
		speed = 0
		
func maybe_follow():
	if randf() < 0.2:
		lift_timer = 4.0
		is_following = true
		is_holding = false
		state = State.FOLLOW
		animated_sprite.play("fly")
		speed = 300
		

func _on_area_input(_viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			animated_sprite.speed_scale = 1.5
			
			if event.double_click:
				state = State.DANCE
				speed = 0
				is_dragging = false
				animated_sprite.play("dance")
			else:
				state = State.DRAG
				initial_pos = Vector2(DisplayServer.mouse_get_position())
				var window_pos = Vector2(DisplayServer.window_get_position())
				drag_offset = initial_pos - window_pos
				is_dragging = true
				animated_sprite.play("hang")
		else:
			if is_dragging:
				is_dragging = false
				is_falling = true
				state = State.FALL
			
	
func _on_animation_finished():
	if state == State.DANCE:
		state = State.WALK
		animated_sprite.play("walk")
		speed = 300	
	elif state == State.IDLE:
		if randf() < 0.65:
			state = State.SLEEP
			animated_sprite.speed_scale = 0.8
			animated_sprite.play("sleep")
		else:
			state = State.WALK
			animated_sprite.play("walk")
			speed = 300

func _physics_process(delta: float) -> void:
	match state:
		State.DRAG:
			var mouse_pos = Vector2(DisplayServer.mouse_get_position())
			var new_win_pos = mouse_pos - drag_offset
			DisplayServer.window_set_position(Vector2i(new_win_pos))
		
		State.IDLE:
			speed = 0
			pass
		
		State.DANCE:
			speed = 0
			pass
		
		State.WALK:
			var window_position = Vector2(DisplayServer.window_get_position())
			window_position += direction * speed * delta
			print(window_position)
			window_position.x = clamp(window_position.x, 0, screen_size.x - window_size.x)
			window_position.y = taskbar_y - window_size.y
			
			DisplayServer.window_set_position(Vector2i(window_position))
			
			if window_position.x <= 0 or window_position.x >= screen_size.x - window_size.x:
				direction.x *= -1
				animated_sprite.flip_h = !animated_sprite.flip_h
				maybe_idle()
				maybe_follow()
				
		
		State.FALL:
			var window_position = Vector2(DisplayServer.window_get_position())
			var taskbar_surface = Vector2(window_position.x, taskbar_y - window_size.y)
			var to_target = taskbar_surface - window_position
			speed = 300
			if to_target.length() <= speed * delta:
				DisplayServer.window_set_position(Vector2i(taskbar_surface))	
				is_falling = false
				state = State.WALK
				animated_sprite.play("walk")
				speed = 300
				
				direction = Vector2(1,0)
				if animated_sprite.flip_h:
					direction *= -1
			else:
				direction = to_target.normalized()
				window_position += direction * speed * delta
				DisplayServer.window_set_position(Vector2i(window_position))
		
		State.FOLLOW:
			var window_position = Vector2(DisplayServer.window_get_position())
			var mouse_pos = Vector2(DisplayServer.mouse_get_position())
			
			var pet_screen_pos = Vector2(DisplayServer.window_get_position()) + Vector2(window_size / 2) - Vector2(10,-15)
			
			if not is_holding:
				if pet_screen_pos.distance_to(mouse_pos) > 10:
					var direction = (mouse_pos - pet_screen_pos).normalized()
					window_position += direction * speed * delta
					DisplayServer.window_set_position(Vector2i(window_position))
				else:
					is_holding = true
					speed = 0
					animated_sprite.play("lift")
			else:
				var pet_local_pos = (window_size / 2) - Vector2(10,-15)
				
				Input.warp_mouse(pet_local_pos)
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				
				lift_timer -= delta
				if lift_timer <= 0:
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
					state = State.FALL
					animated_sprite.play("hang")
					speed = 300
					is_holding = false
		
		State.SLEEP:
			speed = 0
			pass
				
				
			
			
				
