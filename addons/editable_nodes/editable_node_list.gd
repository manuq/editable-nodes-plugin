@tool
class_name EditableNodeList
extends Node
## Lists the nodes of a scene that can be edited.
##
## Add it as a direct child of the scene root, named [code]EditableNodeList[/code].
## With the Editable Nodes plugin enabled, only the [member nodes] can be seen
## and selected in the Scene dock. See [EditableNodesPlugin].

## Nodes of the scene that can be seen and selected in the Scene dock.
@export var nodes: Array[Node]
