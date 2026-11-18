@tool
extends EditorScript
## Moves the 2D editor view to the door of the example scene.
##
## Open example.tscn, then open this script in the Script editor and run it
## with File > Run (Ctrl+Shift+X).

const DOOR_PATH := ^"%Door"
const ZOOM := 2.0


func _run() -> void:
	var scene_root := get_scene()
	var door := scene_root.get_node_or_null(DOOR_PATH) as Node2D if scene_root else null
	if not door:
		push_error("Open example/example.tscn first.")
		return

	EditorInterface.set_main_screen_editor("2D")
	EditableNodesPlugin.focus_2d_view(door.global_position, ZOOM)
