extends Control
class_name CardStack

signal on_stack_clicked

var card: Card = null
@export var stack_index: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

##  推进卡片
func push_card(ori_card: Card) -> void:
	if self.card != null:
		self.remove_child(self.card)
		self.card.queue_free()
		self.card = null
	
	if ori_card.get_parent_control() != null:
		ori_card.reparent(self)
	else:
		self.add_child(ori_card)
	
	self.card = ori_card
	self.card.position = Vector2.ZERO
	self.card.z_index = 3

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		self.on_stack_clicked.emit(self)
