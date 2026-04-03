extends VBoxContainer
class_name TableRow

signal on_table_row_double_clicked(table_row: TableRow)
signal on_table_row_single_clicked(table_row: TableRow)

@export var stack_index: int

var timer: Timer
var cards: Array[Card] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.timer = Timer.new()
	self.timer.one_shot = true
	self.timer.wait_time = 0.25
	self.timer.timeout.connect(_on_timer_timeout)
	self.add_child(self.timer)

## 当前牌列是否可以接收卡牌
func can_receive(card: Card) -> bool:
	if card == null:
		return false
	if self.cards.size() == 0:
		return true
		
	var row_card: Card = self.cards.back()
	return not row_card.is_same_suit(card) and row_card.card_value == card.card_value + 1
	
func push_card(card: Card) -> void:
	if card == null:
		return
	
	var parent_node: Control = card.get_parent_control()
	if parent_node != null:
		card.reparent(self)
	else:
		self.add_child(card)
	
	self.cards.append(card)
	card.z_index = self.get_child_count()
	
func clear_all_cards() -> void:
	while self.cards.size() > 0:
		var card: Card = self.pop_card(null)
		card.queue_free()
 	
func pop_card(parent: Control, zIndex: int = 60) -> Card:
	if self.cards.size() <= 0:
		return
	
	var card: Card = self.cards.pop_back()
	var origin_global_position: Vector2 = card.global_position
	
	if self.get_parent_control() != null:
		self.remove_child(card)
	if parent != null:
		card.z_index = zIndex
		parent.add_child(card)
		card.global_position = origin_global_position
		
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
