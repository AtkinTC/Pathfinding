extends Control
class_name UI

onready var text_display: RichTextLabel = get_node("UIPanel/VBoxContainer/ColorRect/TextDisplay")
onready var graph_type_selection: OptionButton = get_node("UIPanel/VBoxContainer/PanelContainer/GraphTypeSelection")
onready var nav_batch_size: SpinBox = get_node("UIPanel/VBoxContainer/PanelContainer/HBoxContainer/NavBatchSizeInput")

signal trigger_rebuild
signal graph_type_selection
signal trigger_navigation_batch
signal trigger_clear_navigation

func _ready():
	clear_text()
	text_display.scroll_following = true
	graph_type_selection.clear()
	for key in Utils.GRAPH_TYPE.keys():
		graph_type_selection.add_item(key, Utils.GRAPH_TYPE[key])

func clear_text():
	text_display.text = ""

func print_line(line: String):
	text_display.text += "\n" + line
	return text_display.get_line_count()

func print_lines(lines: Array):
	for line in lines:
		print_line(str(line))
	return text_display.get_line_count()

func _on_Rebuild_pressed() -> void:
	emit_signal("trigger_rebuild")

func _on_GraphTypeSelection_item_selected(index: int) -> void:
	var enum_value = Utils.GRAPH_TYPE.values()[index]
	emit_signal("graph_type_selection", enum_value)

func _on_RunNavBatch_pressed() -> void:
	nav_batch_size.apply()
	emit_signal("trigger_navigation_batch", nav_batch_size.value)

func _on_ClearNav_pressed() -> void:
	emit_signal("trigger_clear_navigation")
