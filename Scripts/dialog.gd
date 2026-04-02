extends Control
class_name Dialog

@onready var color_rect: ColorRect = $ColorRect
@onready var popup_panel: PopupPanel = $PopupPanel
@onready var label: Label = $PopupPanel/VBoxContainer/Label
@onready var confirm: Button = $PopupPanel/VBoxContainer/Confirm
@onready var exit: Button = $PopupPanel/VBoxContainer/Exit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 让 Dialog 根节点填满整个视口
	self.set_anchors_preset(Control.PRESET_FULL_RECT)
	self.size = get_viewport().get_visible_rect().size
	self.mouse_filter = Control.MOUSE_FILTER_STOP

	# 让 ColorRect 填满整个父节点
	self.color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	self.color_rect.size = self.size

	# 让 ColorRect 拦截所有鼠标事件，防止穿透到下层
	self.color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	self.color_rect.gui_input.connect(_on_color_rect_input)

	# 禁用 PopupPanel 点击外部关闭的行为
	popup_panel.set_flag(Window.FLAG_POPUP, false)

# 拦截背景点击事件，防止穿透
func _on_color_rect_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# 消耗掉这个事件，不让它传递到下层
		get_viewport().set_input_as_handled()

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
