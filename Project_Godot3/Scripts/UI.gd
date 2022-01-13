extends Control
class_name UI

onready var text_display: RichTextLabel = get_node("UIPanel/TextDisplay")

func _ready():
	clear_text()
	text_display.scroll_following = true

func clear_text():
	text_display.text = ""

func print_line(line: String):
	text_display.text += "\n" + line
	return text_display.get_line_count()

func print_lines(lines: Array):
	for line in lines:
		print_line(str(line))
	return text_display.get_line_count()
