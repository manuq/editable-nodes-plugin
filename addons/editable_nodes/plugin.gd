@tool
class_name EditableNodesPlugin
extends EditorPlugin
## Show only the editable nodes of a scene in the Scene dock.
##
## If the edited scene root has a child named [code]EditableNodeList[/code] with
## a [code]nodes[/code] property holding an array of nodes, like
## [EditableNodeList], only those nodes can be seen and selected in the Scene
## dock. Their ancestors are shown grayed out and can't be selected. The rest
## are hidden. Selecting a node that isn't editable, for example by clicking it
## in the 2D editor, is undone, so it can't be edited in the inspector.
## [br][br]
## A toggle button in the Scene dock toolbar turns this off, to edit the whole
## scene, including the list itself.
## [br][br]
## This does the same as the "show only editable nodes" feature of the Godot
## fork by Filament Games, without changing the engine. The editor UI is
## reached through the Editor Interface Access library, which depends on the
## internals of the Godot version it was written for.

enum Restriction {
	NONE,
	DISABLED,
	HIDDEN,
}

const EditorInterfaceAccess := preload(
	"res://addons/gdquest_editor_interface/editor_interface_access.gd"
)
const Enums := preload("res://addons/gdquest_editor_interface/utils/eia_enums.gd")

## Path from the scene root to the node that lists the editable nodes.
const LIST_NODE_PATH := ^"EditableNodeList"
## Property of the list node that holds the editable nodes.
const LIST_PROPERTY := &"nodes"
## [TreeItem] metadata with the [enum Restriction] applied by this plugin.
const RESTRICTION_META := &"editable_nodes_restriction"
## Project metadata where the state of the toggle button is kept.
const PROJECT_METADATA_SECTION := "editable_nodes"
const PROJECT_METADATA_KEY := "enabled"

var _enabled := true
var _apply_queued := false
var _scene_tree: Tree
var _toggle_button: Button


func _enter_tree() -> void:
	_enabled = EditorInterface.get_editor_settings().get_project_metadata(
		PROJECT_METADATA_SECTION,
		PROJECT_METADATA_KEY,
		true,
	)

	_scene_tree = EditorInterfaceAccess.get_node(Enums.NodePoint.SCENE_TREE_LOCAL_TREE) as Tree
	if not _scene_tree:
		push_error("Editable Nodes: Can't find the tree of the Scene dock.")
		return

	# The Scene dock updates its items in many situations, and that resets
	# them. It always redraws afterwards, so apply the restrictions then.
	_scene_tree.draw.connect(_queue_apply)

	var toolbar := EditorInterfaceAccess.get_node(Enums.NodePoint.SCENE_TREE_TOOLBAR)
	if toolbar:
		_toggle_button = Button.new()
		_toggle_button.theme_type_variation = &"FlatButton"
		_toggle_button.icon = EditorInterface.get_editor_theme().get_icon(&"Lock", &"EditorIcons")
		_toggle_button.tooltip_text = "Show only the nodes listed in EditableNodeList."
		_toggle_button.toggle_mode = true
		_toggle_button.button_pressed = _enabled
		_toggle_button.visible = false
		_toggle_button.toggled.connect(_on_toggle_button_toggled)
		toolbar.add_child(_toggle_button)

	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)
	scene_changed.connect(_on_scene_changed)
	_queue_apply()


func _exit_tree() -> void:
	if is_instance_valid(_scene_tree):
		_scene_tree.draw.disconnect(_queue_apply)
		var root_item := _scene_tree.get_root()
		if root_item:
			_apply_to_item(root_item, { }, true)

	var selection := EditorInterface.get_selection()
	if selection.selection_changed.is_connected(_on_selection_changed):
		selection.selection_changed.disconnect(_on_selection_changed)

	if is_instance_valid(_toggle_button):
		_toggle_button.queue_free()


## Move the 2D editor view so [param target_position], in scene coordinates, is
## at its center, with [param target_zoom] as the zoom level.
## [br][br]
## The 2D editor keeps the view offset and zoom internally, and overwrites
## [member Viewport.global_canvas_transform] of the edited scene with them on
## every redraw. So that transform can't be set directly.
static func focus_2d_view(target_position: Vector2, target_zoom: float) -> void:
	var canvas_item_editor := EditorInterfaceAccess.get_node(Enums.NodePoint.CANVAS_ITEM_EDITOR)
	var zoom_widget := EditorInterfaceAccess.get_node(
		Enums.NodePoint.CANVAS_ITEM_EDITOR_VIEWPORT_ZOOM_WIDGET
	)
	if not canvas_item_editor or not zoom_widget:
		push_error("Editable Nodes: Can't find the 2D editor.")
		return

	# Center first: center_at() uses the transform of the last redraw, which a
	# zoom change would leave out of date. Zooming keeps the center in place.
	canvas_item_editor.call(&"center_at", target_position)
	zoom_widget.emit_signal(&"zoom_changed", target_zoom)


func _queue_apply() -> void:
	if _apply_queued:
		return
	_apply_queued = true
	_apply.call_deferred()


func _apply() -> void:
	_apply_queued = false
	if not is_instance_valid(_scene_tree):
		return

	if is_instance_valid(_toggle_button):
		_toggle_button.visible = _get_list_node() != null

	var root_item := _scene_tree.get_root()
	if root_item:
		_apply_to_item(root_item, _get_editable_nodes(), true)


## Restrict [param item] and its descendants depending on [param editable].
## Returns true if the node of [param item], or any descendant, is editable.
func _apply_to_item(item: TreeItem, editable: Dictionary[Node, bool], is_root: bool) -> bool:
	var has_editable_descendant := false
	for child: TreeItem in item.get_children():
		if _apply_to_item(child, editable, false):
			has_editable_descendant = true

	var restriction := Restriction.NONE
	if not editable.is_empty() and _get_item_node(item) not in editable:
		if has_editable_descendant or is_root:
			restriction = Restriction.DISABLED
		else:
			restriction = Restriction.HIDDEN
	_set_restriction(item, restriction)

	return restriction == Restriction.NONE or has_editable_descendant


func _set_restriction(item: TreeItem, restriction: Restriction) -> void:
	var previous_restriction: Restriction = item.get_meta(RESTRICTION_META, Restriction.NONE)

	if restriction == Restriction.NONE:
		if previous_restriction == Restriction.NONE:
			return
		item.remove_meta(RESTRICTION_META)
		item.visible = true
		item.set_selectable(0, true)
		# The Scene dock keeps the custom color of the item in this metadata.
		var custom_color: Color = item.get_meta(&"custom_color", Color(0, 0, 0, 0))
		if custom_color == Color(0, 0, 0, 0):
			item.clear_custom_color(0)
		else:
			item.set_custom_color(0, custom_color)
		return

	if previous_restriction != restriction:
		item.set_meta(RESTRICTION_META, restriction)

	# Only change what is needed. Each change redraws the tree, which applies
	# the restrictions again.
	if restriction == Restriction.HIDDEN and item.visible:
		item.visible = false
	elif restriction == Restriction.DISABLED and previous_restriction == Restriction.HIDDEN:
		# Otherwise leave the visibility to the Scene dock filter.
		item.visible = true

	# Check the item rather than the metadata, because the Scene dock may have
	# reset the item since the restriction was applied.
	if item.is_selectable(0):
		item.set_selectable(0, false)
		if item.is_selected(0):
			item.deselect(0)
		item.set_custom_color(
			0,
			EditorInterface.get_editor_theme().get_color(&"font_disabled_color", &"Editor"),
		)


func _get_item_node(item: TreeItem) -> Node:
	# The Scene dock stores the absolute path of the node in the item.
	var node_path: Variant = item.get_metadata(0)
	if node_path is NodePath:
		return get_node_or_null(node_path)
	return null


func _get_list_node() -> Node:
	var scene_root := EditorInterface.get_edited_scene_root()
	return scene_root.get_node_or_null(LIST_NODE_PATH) if scene_root else null


## Returns the editable nodes of the edited scene. If empty, all nodes are
## editable.
func _get_editable_nodes() -> Dictionary[Node, bool]:
	var editable: Dictionary[Node, bool] = { }
	var list_node := _get_list_node()
	if not _enabled or not list_node:
		return editable

	var listed_nodes: Variant = list_node.get(LIST_PROPERTY)
	if listed_nodes is Array:
		for listed_node: Variant in listed_nodes:
			if listed_node is Node:
				editable[listed_node] = true
	return editable


func _on_selection_changed() -> void:
	var editable := _get_editable_nodes()
	if editable.is_empty():
		return

	var selection := EditorInterface.get_selection()
	for selected_node in selection.get_selected_nodes():
		if selected_node not in editable:
			selection.remove_node(selected_node)


func _on_scene_changed(_scene_root: Node) -> void:
	_queue_apply()


func _on_toggle_button_toggled(toggled_on: bool) -> void:
	_enabled = toggled_on
	EditorInterface.get_editor_settings().set_project_metadata(
		PROJECT_METADATA_SECTION,
		PROJECT_METADATA_KEY,
		_enabled,
	)
	_queue_apply()
	_on_selection_changed()
