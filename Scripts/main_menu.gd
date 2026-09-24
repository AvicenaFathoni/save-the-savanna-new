extends Control

func _ready() -> void:
	# focus first button for keyboard
	var play = get_node_or_null("Center/VBox/Play")
	if play is Button:
		play.grab_focus()

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Levels/test_level.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
