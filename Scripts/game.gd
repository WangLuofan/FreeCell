extends Control

const CardScene: PackedScene = preload("res://Scenes/card.tscn")

var stack_selected_index: int = -1

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
		
	self.stack_selected_index = -1
	
## 根据当前选择的顺序获取第一张卡牌
func get_top_card_by_index(stack_index: int) -> Card:
	if stack_index == -1:
		return null
		
	if int(stack_index / 8) == 0:
		return self.table_rows[stack_index].cards.back()
		
	return self.card_buffers[stack_index % 8].card
		
## 单击缓冲区
func _on_card_buffer_clicked(card_buffer: CardBuffer) -> void:
	var pending_stack: int = self.stack_selected_index
	self.cancel_all_selection()
	
	# 单击当前缓存区
	if pending_stack == card_buffer.stack_index:
		return
	
	# 如果当前没有选择，且缓存区可以被选中，则选中
	if pending_stack == -1 and card_buffer.can_selected():
		card_buffer.set_selected(true)
		self.stack_selected_index = card_buffer.stack_index
	elif pending_stack >= 0:
		var card: Card = self.get_top_card_by_index(pending_stack)
		if card != null:
			card_buffer.push_card(card)
		
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
	
## 计算当前可移动最大牌数
func calculate_max_card_can_move() -> int:
	# 计算最大可移动数量
	# 最大可移动牌数 = (空闲单元数 + 1) × 2^ 空列数
	var free_buffers: int = 0
	var free_columns: int = 0

	for card_buffer in self.card_buffers:
		if card_buffer.card == null:
			free_buffers += 1
	for table_row in self.table_rows:
		if table_row.cards.size() <= 0:
			free_columns += 1
			
	return int((free_buffers + 1) * pow(2, free_columns))
	
	
## 移动到当前牌列
func move_row_card_to_row_if_needed(to_table_row: TableRow, from_table_row: TableRow):
	var max_move_count: int = self.calculate_max_card_can_move()
	var moved_cards: Array[Card] = []
	
	# 先选出连续序列
	var card_index: int = from_table_row.cards.size() - 1
	for index in range(min(max_move_count, from_table_row.cards.size())):
		var receving_card: Card = from_table_row.cards.get(card_index)
		if moved_cards.is_empty() or receving_card.can_receive(moved_cards.back()):
			moved_cards.append(receving_card)
		else:
			break
			
		card_index -= 1
		
	if to_table_row.cards.size() == 0:
		for index in range(moved_cards.size() - 1, -1, -1):
			from_table_row.pop_card()
		for index in range(moved_cards.size() - 1, -1, -1):
			to_table_row.push_card(moved_cards[index])
	else:
		# 从连续序列中查找能被目标牌列接收的牌
		card_index = -1
		for index in range(moved_cards.size() - 1, -1, -1):
			if to_table_row.cards.back().can_receive(moved_cards[index]):
				card_index = index
				break
		
		if card_index != -1:
			for index in range(card_index, -1, -1):
				from_table_row.pop_card()
			for index in range(card_index, -1, -1):
				to_table_row.push_card(moved_cards[index])
	
## 移动到当前牌列
func move_card_to_row_if_needed(table_row: TableRow, pending_stack_index: int):
	if int(pending_stack_index / 8) != 0:
		# 检查缓存区的牌是否可以移动到牌堆
		var card: Card = self.card_buffers[pending_stack_index % 8].card
		if table_row.can_receive(card):
			self.card_buffers[pending_stack_index % 8].pop_card()
			table_row.push_card(card)
	else:
		var from_table_row: TableRow = self.table_rows[pending_stack_index]
		self.move_row_card_to_row_if_needed(table_row, from_table_row)
	
## 单击牌堆区
func _on_card_stack_clicked(card_stack: CardStack) -> void:
	# 没有选择的牌，不做任何处理
	if self.stack_selected_index == -1:
		return
	
	# 拿到牌堆的卡牌
	var card: Card = self.table_rows[self.stack_selected_index].cards.back()
	
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
	if self.table_rows[table_row.stack_index].cards.is_empty():
		return
	
	var matched_card_buffer: CardBuffer = null
	for card_buffer in self.card_buffers:
		if card_buffer.card == null:
			matched_card_buffer = card_buffer
			break
	
	if matched_card_buffer != null:
		var card: Card = self.table_rows[table_row.stack_index].cards.back()
		self.table_rows[table_row.stack_index].pop_card()
		matched_card_buffer.push_card(card)
		
## 单击牌面
func _on_table_row_single_clicked(table_row: TableRow) -> void:
	var pending_stack_index: int = self.stack_selected_index
	self.cancel_all_selection()
	
	if pending_stack_index == -1:
		self.table_row_masks[table_row.stack_index].global_position = table_row.cards.back().global_position
		self.table_row_masks[table_row.stack_index].visible = true
		self.stack_selected_index = table_row.stack_index
	else:
		self.move_card_to_row_if_needed(table_row, pending_stack_index)
