extends Control
class_name CardStack

signal on_stack_clicked

var cards: Array[Card] = []
@export var stack_index: int

##  推进卡片
func push_card(ori_card: Card) -> void:
	if ori_card.get_parent_control() != null:
		ori_card.reparent(self)
	else:
		self.add_child(ori_card)
	
	ori_card.position = Vector2.ZERO
	ori_card.z_index = self.cards.size()
	self.cards.append(ori_card)
	
func pop_card(parent: Control = null, zIndex: int = 60) -> Card:
	if self.cards.is_empty():
		return
	var card: Card = self.cards.pop_back()
	var origin_global_position: Vector2 = card.global_position
	
	if card.get_parent_control() == self:
		self.remove_child(card)
	
	if parent != null:
		card.z_index = zIndex
		parent.add_child(card)
		card.global_position = origin_global_position	
	
	return card

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		self.on_stack_clicked.emit(self)
