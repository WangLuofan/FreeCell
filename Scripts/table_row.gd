extends VBoxContainer
class_name TableRow

signal on_table_row_double_clicked
signal on_table_row_single_clicked

@export var row_index: int
var timer: Timer
var cards: Array[Card] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.timer = Timer.new()
	self.timer.one_shot = true
	self.timer.wait_time = 0.25
	self.timer.timeout.connect(_on_timer_timeout)
	self.add_child(self.timer)
	
func push_card(card: Card) -> void:
	var parent_node: Control = card.get_parent_control()
	if parent_node != null:
		parent_node.remove_child(card)
	
	card.z_index = self.cards.size()
	self.cards.append(card)
	self.add_child(card)
	
func pop_card() -> Card:
	var card: Card = self.cards.pop_back()
	self.remove_child(card)
	return card

func _on_row_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and \
		event.is_pressed() and \
		event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click:
			self.timer.stop()
			self.on_table_row_double_clicked.emit(self)
		else:
			self.timer.start()

func _on_timer_timeout() -> void:
	self.on_table_row_single_clicked.emit(self)
