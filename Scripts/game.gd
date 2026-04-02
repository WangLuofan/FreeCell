extends Control

const CardScene: PackedScene = preload("res://Scenes/card.tscn")
const DialogScene: PackedScene = preload("res://Scenes/dialog.tscn")

var stack_selected_index: int = -1
var game_step = 0
var card_buffers: Array[CardBuffer] = []
var records: Array[Record] = []

@onready var table_rows: Array = [
	$TableContainer/Table/Row0,
	$TableContainer/Table/Row1,
	$TableContainer/Table/Row2,
	$TableContainer/Table/Row3,
	$TableContainer/Table/Row4,
	$TableContainer/Table/Row5,
	$TableContainer/Table/Row6,
	$TableContainer/Table/Row7,
	$BufferContainer/Buffers/Buffer0, 
	$BufferContainer/Buffers/Buffer1, 
	$BufferContainer/Buffers/Buffer2,
	$BufferContainer/Buffers/Buffer3
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

func _ready() -> void:
	# 初始化 card_buffers
	self.card_buffers = self.get_card_buffers()

	for table_row in self.table_rows:
		if table_row is TableRow:
			(table_row as TableRow).on_table_row_single_clicked.connect(_on_table_row_single_clicked)
			(table_row as TableRow).on_table_row_double_clicked.connect(_on_table_row_double_clicked)
		elif table_row is CardBuffer:
			table_row.on_card_buffer_clicked.connect(_on_card_buffer_clicked)
		
	for card_stack in self.card_stacks:
		card_stack.on_stack_clicked.connect(_on_card_stack_clicked)
		
	self.start_new_game()
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("revoke"):
		self.do_revoke()
	elif Input.is_action_just_pressed("new_game"):
		self.start_new_game()

func get_card_buffers() -> Array[CardBuffer]:
	var buffers: Array[CardBuffer] = []
	for i in range(8, self.table_rows.size()):
		buffers.append(self.table_rows[i])
	return buffers
	
func do_revoke() -> void:
	print("do_revoke")
	if self.records.is_empty():
		return
	var record: Record = self.records.pop_back()
	
	if record.target_stack_index / 12 != 0:
		for card_index: int in record.card_removed_count:
			var card: Card = self.card_stacks[record.target_stack_index % 12].pop_card()
			self.table_rows[record.original_stack_index].push_card(card)
	else:
		var moved_cards: Array[Card] = []
		for card_index: int in record.card_removed_count:
			var card: Card = self.table_rows[record.target_stack_index].pop_card()
			moved_cards.append(card)
		moved_cards.reverse()
		for card: Card in moved_cards:
			self.table_rows[record.original_stack_index].push_card(card)
	
	self.cancel_all_selection()
	
## 清理资源
func clean_resource() -> void:
	for table_row in table_rows:
		table_row.clear_all_cards()  # 需要在 TableRow 中添加这个方法

	for card_stack in card_stacks:
		while not card_stack.cards.is_empty():
			var card: Card = card_stack.cards.pop_back()
			card.queue_free()

## 开始新游戏
func start_new_game() -> void:
	self.clean_resource()
	
	var all_cards: Array[Card] = []
	for suit in range(Consts.CARD_SUIT_TOTAL_COUNT):
		for value in range(1, Consts.CARD_VALUE_TOTAL_COUNT + 1):
			var card: Card = CardScene.instantiate()
			card.set_card(suit, value)
			all_cards.append(card)
			
	all_cards.shuffle()
	var card_index: int = 0
	for index in range(Consts.CARD_SUIT_TOTAL_COUNT * Consts.CARD_VALUE_TOTAL_COUNT):
		table_rows[card_index].push_card(all_cards[index])
		card_index = (card_index + 1) % Consts.CARD_TABLE_COL_COUNT

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
	
	if self.table_rows[stack_index].cards.is_empty():
		return
		
	return self.table_rows[stack_index].cards.back()
		
## 单击缓冲区
func _on_card_buffer_clicked(card_buffer: CardBuffer) -> void:
	var pending_stack_index: int = self.stack_selected_index
	self.cancel_all_selection()
	
	# 单击当前缓存区
	if pending_stack_index == card_buffer.stack_index:
		return
	
	# 如果当前没有选择，且缓存区可以被选中，则选中
	if pending_stack_index == -1 and card_buffer.can_selected():
		card_buffer.set_selected(true)
		self.stack_selected_index = card_buffer.stack_index
	elif pending_stack_index >= 0:
		var card: Card = self.get_top_card_by_index(pending_stack_index)
		
		if card != null and card_buffer.can_receive(card):
			self.table_rows[pending_stack_index].pop_card()
			card_buffer.push_card(card)

## 检查牌是否可以移动到牌堆		
func check_card_can_move_to_stack(card: Card, card_stack: CardStack) -> bool:
	# 如果点击的堆不符合当前牌的花色，返回False
	if card.card_suit != (card_stack.stack_index % 12):
		return false
	
	if card_stack.cards.is_empty() and card.card_value == 1:
		# 如果牌堆没有牌，只能移动A
		return true
	elif not card_stack.cards.is_empty() and card.card_value == card_stack.cards.back().card_value + 1:
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
		if card_buffer.cards.is_empty():
			free_buffers += 1
	for table_row in self.table_rows:
		if table_row.stack_index < 8 and table_row.cards.size() <= 0:
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
			
		self.records.append(Record.newRecord(from_table_row.stack_index, to_table_row.stack_index, moved_cards.size()))
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
				
			self.records.append(Record.newRecord(from_table_row.stack_index, to_table_row.stack_index, moved_cards.size()))
				
## 检查堆列是否有牌可以移动到牌堆
func move_card_to_stack_if_needed() -> void:
	var is_moved: bool = true
	while is_moved:
		is_moved = false
		for table_row in self.table_rows:
			if table_row.cards.size() <= 0:
				continue
				
			var card: Card = table_row.cards.back()
			var stack: CardStack = self.card_stacks[card.card_suit]
			
			if self.check_card_can_move_to_stack(card, stack):
				table_row.pop_card()
				stack.push_card(card)
				
				is_moved = true
				self.records.append(Record.newRecord(table_row.stack_index, stack.stack_index, 1))
		
		if not is_moved:
			break
	
	self.check_game_is_end()
	
## 检查游戏是否结束
func check_game_is_end() -> void:
	# 0: 游戏继续，1： 游戏失败，2： 游戏成功
	var game_state: int = 2
	for stack in self.card_stacks:
		if stack.cards.is_empty() or stack.cards.back().card_value != 13:
			game_state = 0
			break
	
	if game_state == 0:
		# 检查卡牌是否有可以接收的牌，如果有，游戏可以继续，返回
		for table_row in self.table_rows:
			for recv_table_row in self.table_rows:
				if table_row == recv_table_row:
					continue
				if recv_table_row.can_receive(table_row.cards.back()):
					return
		game_state = 1
					
	if game_state == 0:
		return
	
	var dialog: Dialog = DialogScene.instantiate()
	self.add_child(dialog)
	dialog.show_dialog(game_state == 2, func(): dialog.hide_dialog(); start_new_game())
	
## 移动到当前牌列
func move_card_to_row_if_needed(table_row: TableRow, pending_stack_index: int):
	if int(pending_stack_index / 8) != 0:
		# 检查缓存区的牌是否可以移动到牌堆
		if self.table_rows[pending_stack_index].cards.is_empty():
			return
		
		var card: Card = self.table_rows[pending_stack_index].cards.back()
		if table_row.can_receive(card):
			self.table_rows[pending_stack_index].pop_card()
			table_row.push_card(card)
			
			self.records.append(Record.newRecord(pending_stack_index, table_row.stack_index, 1))
	else:
		var from_table_row: TableRow = self.table_rows[pending_stack_index]
		self.move_row_card_to_row_if_needed(table_row, from_table_row)
		
	self.move_card_to_stack_if_needed()
	
## 单击牌堆区
func _on_card_stack_clicked(card_stack: CardStack) -> void:
	# 没有选择的牌，不做任何处理
	if self.stack_selected_index == -1:
		return
	
	# 拿到牌堆的卡牌
	var card: Card = null
	if self.stack_selected_index / 8 == 0:
		card = self.table_rows[self.stack_selected_index].cards.back()
	else:
		card = self.card_buffers[self.stack_selected_index % 8].card
		
	if card == null:
		return
	
	# 检查是否可以移动到牌堆
	if self.check_card_can_move_to_stack(card, card_stack):
		card_stack.push_card(card)
		self.cancel_all_selection()
		
	self.move_card_to_stack_if_needed()
	self.cancel_all_selection()
		
## 双击牌面
func _on_table_row_double_clicked(table_row: TableRow) -> void:
	self.cancel_all_selection()
	if self.table_rows[table_row.stack_index].cards.is_empty():
		return
	
	var matched_card_buffer: CardBuffer = null
	for card_buffer in self.card_buffers:
		if card_buffer.cards.is_empty():
			matched_card_buffer = card_buffer
			break
	
	if matched_card_buffer != null:
		var card: Card = self.table_rows[table_row.stack_index].cards.back()
		self.table_rows[table_row.stack_index].pop_card()
		matched_card_buffer.push_card(card)
		
		self.records.append(Record.newRecord(table_row.stack_index, matched_card_buffer.stack_index, 1))
	
	self.move_card_to_stack_if_needed()
		
## 单击牌面
func _on_table_row_single_clicked(table_row: TableRow) -> void:
	var pending_stack_index: int = self.stack_selected_index
	self.cancel_all_selection()
	
	if pending_stack_index == -1:
		if table_row.cards.size() <= 0:
			return
		
		self.table_row_masks[table_row.stack_index].global_position = table_row.cards.back().global_position
		self.table_row_masks[table_row.stack_index].visible = true
		self.stack_selected_index = table_row.stack_index
	else:
		self.move_card_to_row_if_needed(table_row, pending_stack_index)
