extends Control
class_name Dialog

@onready var color_rect: ColorRect = $ColorRect
@onready var label: Label = $PopupPanel/VBoxContainer/Label
@onready var confirm: Button = $PopupPanel/VBoxContainer/Confirm
@onready var exit: Button = $PopupPanel/VBoxContainer/Exit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.color_rect.size = get_viewport().get_visible_rect().size

func show_dialog(won: bool, confirm_action: Callable) -> void:
	self.label.text = 'You Won!' if won else 'You Lose!'
	self.visible = true
	self.confirm.pressed.connect(func(): 
		confirm_action.call()
		self.visible = false
		self.queue_free()
	)
	
	self.exit.pressed.connect(func(): 
		self.visible = false;
		self.queue_free()
		get_tree().quit()
	)

func hide_dialog() -> void:
	if self.get_parent_control() != null:
		self.get_parent_control().remove_child(self)
	self.queue_free()
