extends Node2D

const MARGIN = 20
const BAT_STEP = 10
const SPEED = 300
const BALL_SIZE = 4.0
const BAT_SIZE = Vector2(4.0, 32.0)
const SERVE_WAIT_TIME = 1.0

var playarea: Vector2
var ball_pos = Vector2.ZERO
var ball_step = Vector2.ZERO
var game_bat_pos: Vector2
var player_bat_pos: Vector2
var game_score = 0
var player_score = 0

func _ready():
	playarea = get_window().size
	start_game()
	await get_tree().create_timer(3.0).timeout
	%Note.hide()


func start_game():
	serve_ball(true)
	game_score = 0
	player_score = 0
	set_score(%GameScore, game_score)
	set_score(%PlayerScore, player_score)


func serve_ball(player_to_serve):
	game_bat_pos = Vector2(MARGIN, playarea.y / 2)
	player_bat_pos = Vector2(playarea.x - MARGIN, playarea.y / 2)
	if player_to_serve:
		ball_pos.x = player_bat_pos.x
		ball_step.x = -1
	else:
		ball_pos.x = game_bat_pos.x
		ball_step.x = 1
	ball_step.y = 1 if randf() > 0.5 else -1
	ball_pos.y = (playarea.y - MARGIN * 4) * randf() + MARGIN * 2
	set_process(true)


func _input(event):
	if event is InputEventKey:
		if Input.is_key_pressed(KEY_ESCAPE):
			get_tree().quit()


func _process(delta):
	if Input.is_key_pressed(KEY_UP):
		if player_bat_pos.y > (BAT_SIZE.y / 2):
			player_bat_pos.y -= delta * SPEED * 2
	if Input.is_key_pressed(KEY_DOWN):
		if player_bat_pos.y < (playarea.y - BAT_SIZE.y / 2):
			player_bat_pos.y += delta * SPEED * 2

	# AI
	if ball_step.x < 0 and randf() > 0.2:
		game_bat_pos = auto_move_bat(game_bat_pos, delta, 1)
	if ball_step.x > 0 and randf() > 0.2 and Input.is_key_pressed(KEY_CTRL):
		player_bat_pos = auto_move_bat(player_bat_pos, delta, -1)
	
	# Bounce off bats
	if ball_pos.x < game_bat_pos.x:
		var hit_offset = ball_pos.y - game_bat_pos.y
		if abs(hit_offset) < (BAT_STEP * 2):
			ball_step.x *= -1
			ball_step.y = get_deflection(hit_offset)
		else:
			player_score += 1
			set_score(%PlayerScore, player_score)
			set_process(false)
			await get_tree().create_timer(SERVE_WAIT_TIME).timeout
			serve_ball(true)
	
	if ball_pos.x > player_bat_pos.x:
		var hit_offset = ball_pos.y - player_bat_pos.y
		if abs(hit_offset) < (BAT_STEP * 2):
			ball_step.x *= -1
			ball_step.y = get_deflection(hit_offset)
		else:
			game_score += 1
			set_score(%GameScore, game_score)
			set_process(false)
			await get_tree().create_timer(SERVE_WAIT_TIME).timeout
			serve_ball(false)
	
	# Bounce off walls
	if ball_pos.y < MARGIN or ball_pos.y > (playarea.y - MARGIN):
		ball_step.y *= -1
	
	ball_pos += ball_step * delta * SPEED
	queue_redraw()


func auto_move_bat(bat_pos: Vector2, delta, dir):
	var dy = delta * SPEED * 2 * lerp(0.0, 1.0, 1.0 - \
		(ball_pos.x - bat_pos.x) / playarea.x * dir)
	if ball_pos.y > bat_pos.y:
		bat_pos.y += dy
	else:
		bat_pos.y -= dy
	return bat_pos


func get_deflection(hit_offset):
	var step = 1 if hit_offset > 0 else -1
	if abs(hit_offset) > BAT_STEP:
		step *= 2
	return step


func _draw():
	# Draw ball
	draw_line(Vector2(ball_pos.x - BALL_SIZE, ball_pos.y),\
		Vector2(ball_pos.x + BALL_SIZE, ball_pos.y), Color.WHITE, BALL_SIZE * 2)
	# Draw bats
	draw_line(Vector2(game_bat_pos.x - BAT_SIZE.x / 2, game_bat_pos.y - BAT_SIZE.y / 2),\
		Vector2(game_bat_pos.x - BAT_SIZE.x / 2, game_bat_pos.y + BAT_SIZE.y / 2), Color.WHITE, BAT_SIZE.x)
	draw_line(Vector2(player_bat_pos.x - BAT_SIZE.x / 2, player_bat_pos.y - BAT_SIZE.y / 2),\
		Vector2(player_bat_pos.x - BAT_SIZE.x / 2, player_bat_pos.y + BAT_SIZE.y / 2), Color.WHITE, BAT_SIZE.x)


func set_score(label: Label, score: int):
	label.text = "%02d" % score


func _on_hb_resized():
	playarea = get_window().size
	player_bat_pos.x = playarea.x - MARGIN
