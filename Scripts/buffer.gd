extends Control
class_name CardBuffer

var card: Card = null

@export var buffer_index: int
@onready var mask: ColorRect = $Mask

signal on_card_buffer_clicked

func _ready() -> void:
	pass

##  推进卡片
func push_card(ori_card: Card) -> void:
	if self.card != null:
		return
		
	var parent_node: Control = ori_card.get_parent_control()
	if parent_node != null:
		ori_card.reparent(self)
	else:
		self.add_child(ori_card)

	self.card = ori_card
	self.card.position = Vector2.ZERO
	self.card.z_index = 3

## 推出卡片
func pop_card() -> void:
	if self.card == null:
		return
	
	self.remove_child(self.card)
	self.card = null
	
## 是否可以选择
func can_selected() -> bool:
	return self.card != null
	
## 设置选中状态
func set_selected(selected: bool) -> void:
	if not self.can_selected():
		return
	self.mask.visible = selected

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		self.on_card_buffer_clicked.emit(self)
