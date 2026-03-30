extends Control

const CardScene: PackedScene = preload("res://Scenes/card.tscn")

var row_selected_index: int = -1

@onready var table_rows: Array[TableRow] = [
	$TableContainer/Table/Row0,
	$TableContainer/Table/Row1,
	$TableContainer/Table/Row2,
	$TableContainer/Table/Row3,
	$TableContainer/Table/Row4,
	$TableContainer/Table/Row5,
	$TableContainer/Table/Row6,
	$TableContainer/Table/Row7
]

@onready var table_row_masks: Array[ColorRect] = [
	$TableContainer/TableMask0, 
	$TableContainer/TableMask1, 
	$TableContainer/TableMask2, 
	$TableContainer/TableMask3, 
	$TableContainer/TableMask4, 
	$TableContainer/TableMask5, 
	$TableContainer/TableMask6, 
	$TableContainer/TableMask7
]

@onready var card_stacks: Array[CardStack] = [
	$StackBoxContainer/Stack0, 
	$StackBoxContainer/Stack1, 
	$StackBoxContainer/Stack2, 
	$StackBoxContainer/Stack3
]

@onready var card_buffers: Array[CardBuffer] = [
	$BufferContainer/Buffers/Buffer0, 
	$BufferContainer/Buffers/Buffer1, 
	$BufferContainer/Buffers/Buffer2,
	$BufferContainer/Buffers/Buffer3
]

func _ready() -> void:
	for table_row in self.table_rows:
		table_row.on_table_row_single_clicked.connect(_on_table_row_single_clicked)
		table_row.on_table_row_double_clicked.connect(_on_table_row_double_clicked)
		
	for card_buffer in self.card_buffers:
		card_buffer.on_card_buffer_clicked.connect(_on_card_buffer_clicked)
		
	for card_stack in self.card_stacks:
		card_stack.on_stack_clicked.connect(_on_card_stack_clicked)
		
	self.start_new_game()

## 开始新游戏
func start_new_game() -> void:
	var all_cards: Array[Card] = []
	for suit in range(Consts.CARD_SUIT_TOTAL_COUNT):
		for value in range(1, Consts.CARD_VALUE_TOTAL_COUNT + 1):
			var card: Card = CardScene.instantiate()
			card.set_card(suit, value)
			all_cards.append(card)
			
	all_cards.shuffle()
	var card_index: int = 0
	for index in range(Consts.CARD_SUIT_TOTAL_COUNT * Consts.CARD_VALUE_TOTAL_COUNT):
		table_rows[card_index % Consts.CARD_TABLE_COL_COUNT].push_card(all_cards[index])
		card_index += 1

## 取消所有选择
func cancel_all_selection() -> void:
	for table_row_mask in self.table_row_masks:
		table_row_mask.visible = false
	for card_buffer in self.card_buffers:
		card_buffer.set_selected(false)
		
	self.row_selected_index = -1
		
## 单击缓冲区
func _on_card_buffer_clicked(card_buffer: CardBuffer) -> void:
	self.cancel_all_selection()
	if card_buffer.can_selected():
		card_buffer.set_selected(true)
		
func check_card_can_move_to_stack(card: Card, card_stack: CardStack) -> bool:
	# 如果点击的堆不符合当前牌的花色，返回False
	if card.card_suit != card_stack.stack_index:
		return false
	
	if card_stack.card == null and card.card_value == 1:
		# 如果牌堆没有牌，只能移动A
		return true
	elif card_stack.card != null and card.card_value == card_stack.card.card_value + 1:
		# 如果牌堆中有牌，只能移动当前牌堆中牌值的下一张牌
		return true
		
	return false
	
## 单击牌堆区
func _on_card_stack_clicked(card_stack: CardStack) -> void:
	# 没有选择的牌，不做任何处理
	if self.row_selected_index == -1:
		return
	
	# 拿到牌堆的卡牌
	var card: Card = self.table_rows[self.row_selected_index].get_children().back()
	
	# 检查是否可以移动到牌堆
	if self.check_card_can_move_to_stack(card, card_stack):
		card_stack.push_card(card)
		self.cancel_all_selection()
		
## 将卡牌放入堆栈
func push_card_to_stack(card: Card) -> void:
	var card_stack: CardStack = self.card_stacks[card.card_suit]
	
	if card_stack != null:
		card_stack.push_card(card)

## 双击牌面
func _on_table_row_double_clicked(table_row: TableRow) -> void:
	self.cancel_all_selection()
	if self.table_rows[table_row.row_index].get_children().is_empty():
		return
	
	var matched_card_buffer: CardBuffer = null
	for card_buffer in self.card_buffers:
		if card_buffer.card == null:
			matched_card_buffer = card_buffer
			break
	
	if matched_card_buffer != null:
		var card: Card = self.table_rows[table_row.row_index].get_children().back()
		matched_card_buffer.push_card(card)
		
## 单击牌面
func _on_table_row_single_clicked(table_row: TableRow) -> void:
	self.cancel_all_selection()
	
	if self.row_selected_index == -1:
		self.table_row_masks[table_row.row_index].global_position = table_row.get_children().back().global_position
		self.table_row_masks[table_row.row_index].visible = true
		self.row_selected_index = table_row.row_index
	else:
		pass
