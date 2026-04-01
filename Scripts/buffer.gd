extends Control
class_name CardBuffer

var cards: Array[Card] = []

@export var stack_index: int
@onready var mask: ColorRect = $Mask

signal on_card_buffer_clicked(card_buffer: CardBuffer)

func _ready() -> void:
	pass
	
func clear_all_cards() -> void:
	while self.cards.size() > 0:
		var card: Card = self.pop_card()
		card.queue_free()
		
func can_receive(card: Card) -> bool:
	return self.cards.is_empty()

##  推进卡片
func push_card(ori_card: Card) -> void:
	if not self.cards.is_empty():
		return
		
	var parent_node: Control = ori_card.get_parent_control()
	if parent_node != null:
		ori_card.reparent(self)
	else:
		self.add_child(ori_card)

	self.cards.append(ori_card)
	self.cards.back().position = Vector2.ZERO
	self.cards.back().z_index = 3

## 推出卡片
func pop_card() -> Card:
	if self.cards.is_empty():
		return
	
	var card: Card = self.cards.pop_back()
	if card.get_parent_control() == self:
		self.remove_child(self.cards.back())
		
	return card
	
## 是否可以选择
func can_selected() -> bool:
	return not self.cards.is_empty()
	
## 设置选中状态
func set_selected(selected: bool) -> void:
	if not self.can_selected():
		return
	self.mask.visible = selected

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		self.on_card_buffer_clicked.emit(self)
