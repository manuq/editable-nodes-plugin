# Editable Nodes

A Godot editor plugin that shows only some nodes of a scene in the
Scene dock. It lets you hand a scene to someone and point them to the
few nodes they are meant to change, without the dozens of other nodes
getting in the way.

It does the same as the "show only editable nodes" feature of the
[Filament Games fork of Godot](https://github.com/FilamentGames/godot/tree/feature/show-only-editable-nodes),
but as a regular plugin written in GDScript, so it works with the
official Godot editor.

## Requirements

Godot 4.7.

Warning: The plugin reaches parts of the editor UI that have no public API,
through the
[Editor Interface Access](https://github.com/GDQuest/godot_editor_interface_access)
library. Those parts can change between Godot versions, even in patch
releases, so other versions may not work!

## Installation

1. Copy `addons/editable_nodes/` and `addons/gdquest_editor_interface/`
   to the `addons/` folder of your project.
2. Enable "Editable Nodes" in Project > Project Settings > Plugins.

## Usage

1. Add an `EditableNodeList` node as a direct child of the scene
   root. Keep its name as `EditableNodeList`.
2. In the inspector, add the nodes that can be edited to its `nodes`
   property.

The Scene dock then changes like this:

- Listed nodes are shown and can be selected as usual.
- Their ancestors are shown grayed out, and can't be selected.
- All other nodes are hidden.

Selecting a node that isn't listed, for example by clicking it in the
2D editor, is undone. So it can't be edited in the inspector either.

A lock button appears in the Scene dock toolbar when the scene has an
`EditableNodeList`. Turn it off to see and edit the whole scene,
including the list itself. Its state is saved per project.

The plugin only looks for a node named `EditableNodeList` with a
`nodes` property holding an array of nodes. Any node with that name
and property works, not only the provided `EditableNodeList` class.
This is the same format the Filament Games fork uses.

### Moving the 2D editor view

The plugin also provides a way to move the 2D editor view from a
script, which the fork adds to the engine too:

```gdscript
EditableNodesPlugin.focus_2d_view(Vector2(400, 300), 2.0)
```

This puts the given scene position at the center of the 2D editor
view, at the given zoom level. Setting the
`global_canvas_transform` of the edited scene doesn't work for this,
because the 2D editor overwrites it on every redraw.

## Example

Open this folder as a Godot project. The main scene,
`example/example.tscn`, lists Player, Door and Enemy as editable.

To try `focus_2d_view()`, keep the example scene open, open
`example/focus_on_door.gd` in the Script editor and run it with
File > Run (Ctrl+Shift+X). The 2D editor view moves to the door and
zooms in.

## How it works

The Scene dock rebuilds its items in many situations, and that resets
them. It always redraws afterwards, so the plugin applies the
restrictions after each redraw of the tree. It only changes the items
that need it, so it doesn't redraw in a loop.

## Limitations

- Only the Scene dock is filtered. Other node pickers, like the
  Reparent dialog, show all nodes.
- Clicking a node in the 2D editor that isn't listed deselects it. It
  doesn't select a listed node behind it or a listed ancestor.
- With the "Hide Filtered Out Parents" option of the Scene dock
  enabled and a search filter typed, the dock moves items around, and
  the grayed out ancestors may not look right.
- The fork also hides the lock icon of locked nodes in the 2D editor
  by default. This plugin doesn't, because that option is saved per
  scene and changing it would override your own choice.

## AI disclosure

This plugin was written with Claude under my direction. I used Claude
also to study the Godot editor sources and the Filament Godot fork, and
is only a test to compare the same behavior from a plugin.

## License

This project is provided under the [GPL v3](LICENSE).

It bundles the Editor Interface Access library by GDQuest in
`addons/gdquest_editor_interface/`, also under the GPL v3.

The images in `example/assets` come from
[Threadbare](https://github.com/endlessm/threadbare), by The
Threadbare Authors, under
[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).
