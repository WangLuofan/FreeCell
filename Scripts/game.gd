extends Control

const CardScene: PackedScene = preload("res://Scenes/card.tscn")
const DialogScene: PackedScene = preload("res://Scenes/dialog.tscn")

var stack_selected_index: int = -1
var game_step = 0

var table_rows: Array[TableRow] = []
var card_stacks: Array[CardStack] = []
var card_buffers: Array[CardBuffer] = []

var records: Array[Record] = []
var is_revoking: bool = false
var is_auto_moving: bool = false
var is_game_over: bool = false

var all_cards: Array[Card] = []

@onready var revoke_button: Button = $VBoxContainer/revoke
@onready var table_container: Control = $TableContainer

@onready var all_panels: Array = [
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
	$BufferContainer/Buffers/Buffer3,
	$StackBoxContainer/Stack0, 
	$StackBoxContainer/Stack1, 
	$StackBoxContainer/Stack2, 
	$StackBoxContainer/Stack3
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

func _ready() -> void:
	# 初始化 card_buffers
	self.table_rows = self.get_card_rows()
	self.card_buffers = self.get_card_buffers()
	self.card_stacks = self.get_card_stacks()
	
	# 初始化卡牌
	for suit in range(Consts.CARD_SUIT_TOTAL_COUNT):
		for value in range(1, Consts.CARD_VALUE_TOTAL_COUNT + 1):
			var card: Card = CardScene.instantiate()
			card.set_card(suit, value)
			all_cards.append(card)

	for table_row in self.table_rows:
		table_row.on_table_row_single_clicked.connect(_on_table_row_single_clicked)
		table_row.on_table_row_double_clicked.connect(_on_table_row_double_clicked)
		
	for card_buffer in self.card_buffers:
		card_buffer.on_card_buffer_clicked.connect(_on_card_buffer_clicked)
		
	self.start_new_game()
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("revoke"):
		self.do_revoke()
	elif Input.is_action_just_pressed("new_game"):
		self.start_new_game()

func get_card_rows() -> Array[TableRow]:
	var rows: Array[TableRow] = []
	for i in range(0, Consts.CARD_STACK_START_INDEX):
		rows.append(self.all_panels[i])
	return rows

func get_card_stacks() -> Array[CardStack]:
	var stacks: Array[CardStack] = []
	for i in range(Consts.CARD_STACK_START_INDEX, Consts.CARD_STACK_START_INDEX + Consts.CARD_STACK_COUNT):
		stacks.append(self.all_panels[i])
	return stacks

func get_card_buffers() -> Array[CardBuffer]:
	var buffers: Array[CardBuffer] = []
	for i in range(Consts.CARD_BUFFER_START_INDEX, Consts.CARD_BUFFER_START_INDEX + Consts.CARD_BUFFER_COUNT):
		buffers.append(self.all_panels[i])
	return buffers
	
func move_card_to_position_animated(cards: Array[Card], global_positions: Array[Vector2]) -> void:
	assert(cards.size() == global_positions.size(), "cards的长度不等于global_positions的长度")

	if cards.is_empty():
		return

	var tween: Tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	for index in cards.size():
		var card: Card = cards[index]
		var pos: Vector2 = global_positions[index]

		if index == 0:
			# 第一个动画不能用 parallel()
			tween.tween_property(card, "global_position", pos, 0.25)
		else:
			# 后续动画并行执行
			tween.parallel().tween_property(card, "global_position", pos, 0.25)

	await tween.finished

# 将卡牌从一个容器移动到另外一个容器
func move_cards_from_panel_to_panel(from_index: int, to_index: int, moved_count: int) -> void:
	if from_index < 0 or from_index == to_index or \
		to_index >= Consts.CARD_STACK_START_INDEX + Consts.CARD_STACK_COUNT or \
		moved_count <= 0:
		return
	
	var moved_cards: Array[Card] = []
	var moved_positions: Array[Vector2] = []
	
	var to = self.all_panels[to_index]
	var from = self.all_panels[from_index]
	
	for index in range(moved_count):
		var card: Card = from.pop_card(self.table_container, 60 + moved_count - index)
		moved_cards.insert(0, card)
		
		var pos: Vector2 = to.global_position
		
		if to.stack_index < Consts.CARD_BUFFER_START_INDEX:
			pos.y = to.global_position.y + (Consts.CARD_VISIBLE_HEIGHT * (to.cards.size() + (moved_count - index - 1)))
				
		moved_positions.insert(0, pos)
	
	await self.move_card_to_position_animated(moved_cards, moved_positions)
	for card in moved_cards:
		to.push_card(card)

	if not self.is_revoking:
		self.records.append(Record.newRecord(from_index, to_index, moved_count))
		if not self.is_auto_moving:
			await self.auto_move_card_to_stack_if_needed()
	
func do_revoke() -> void:
	if self.records.is_empty() or self.is_auto_moving:
		return

	if self.is_revoking:
		print("警告：撤销操作正在进行中，跳过本次调用")
		return

	var record: Record = self.records.pop_back()

	# 验证数据有效性，如果无效就提前返回（不加锁）
	if record.target_stack_index < 0 or record.target_stack_index >= self.all_panels.size() or \
	   record.original_stack_index < 0 or record.original_stack_index >= self.all_panels.size() or \
	   record.card_moved_count <= 0:
		print("撤销数据无效: ", record.target_stack_index, " -> ", record.original_stack_index, " count: ", record.card_moved_count)
		return

	print("开始撤销: ", record.target_stack_index, " -> ", record.original_stack_index)
	self.is_revoking = true

	await self.move_cards_from_panel_to_panel(record.target_stack_index, record.original_stack_index, record.card_moved_count)

	self.cancel_all_selection()
	self.revoke_button.disabled = self.records.is_empty()
	self.is_revoking = false
	print("撤销完成")
	
## 清理资源
func clean_resource() -> void:
	self.is_revoking = false
	for panel in self.all_panels:
		while not panel.cards.is_empty():
			panel.pop_card()

	self.records.clear()

## 开始新游戏
func start_new_game() -> void:
	if self.is_auto_moving:
		return
	
	self.is_game_over = false
	self.is_revoking = false
	self.clean_resource()
	self.cancel_all_selection()
			
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
	if self.is_auto_moving:
		return
	
	var max_move_count: int = min(self.calculate_max_card_can_move(), from_table_row.cards.size())
	var moved_count: int = 0
	
	var target_receving_card: Card = to_table_row.cards.back() if not to_table_row.cards.is_empty() else null
	var pre_card: Card = null
	for index in range(from_table_row.cards.size() - 1, from_table_row.cards.size() - 1 - max_move_count, -1):
		var card: Card = from_table_row.cards.get(index)
		if pre_card == null or card.can_receive(pre_card):
			moved_count += 1
			pre_card = card
		else:
			break
		
		if target_receving_card != null and target_receving_card.can_receive(card):
			break
	
	if target_receving_card == null or target_receving_card.can_receive(pre_card):
		await self.move_cards_from_panel_to_panel(from_table_row.stack_index, to_table_row.stack_index, moved_count)
	
## 自动移动牌到牌堆
func auto_move_card_to_stack_if_needed() -> void:
	self.is_auto_moving = true
	var has_moved: bool = true

	while has_moved:
		has_moved = false

		for panel in self.table_rows + self.card_buffers:
			if panel.cards.size() <= 0:
				continue

			var card: Card = panel.cards.back()
			var stack: CardStack = self.card_stacks[card.card_suit]

			if self.check_card_can_move_to_stack(card, stack):
				await self.move_cards_from_panel_to_panel(panel.stack_index, stack.stack_index, 1)
				
				has_moved = true
				break  # 移动一张后重新检查

	# 所有自动移动完成后，检查游戏是否结束
	self.is_auto_moving = false
	self.check_game_is_end()
	
func show_dialog(success: bool) -> void:
	var dialog: Dialog = DialogScene.instantiate()
	self.add_child(dialog)
	dialog.show_dialog(success, func(): dialog.hide_dialog(); start_new_game())
	
## 检查游戏是否结束
func check_game_is_end() -> void:
	if self.is_game_over:
		return

	var is_game_success: bool = true
	for stack in self.card_stacks:
		if stack.cards.is_empty() or stack.cards.back().card_value != 13:
			is_game_success = false
			break

	if is_game_success:
		self.is_game_over = true
		self.show_dialog(true)
		return
		
	# 检查是否有空缓存区
	for buffer in self.card_buffers:
		if buffer.cards.is_empty():
			return
			
	# 检查是否有空列
	for table_row in self.table_rows:
		if table_row.cards.is_empty():
			return
	
	# 检查牌列是否有可以接收的牌，如果有，游戏可以继续，返回
	for table_row in self.table_rows + self.card_buffers:
		for recv_table_row in self.table_rows:
			if table_row == recv_table_row:
				continue
			if recv_table_row.can_receive(table_row.cards.back()):
				return
	
	# 游戏失败
	self.is_game_over = true
	self.show_dialog(false)

#region signals
## 双击牌面
func _on_table_row_double_clicked(table_row: TableRow) -> void:
	
	self.cancel_all_selection()
	if self.table_rows[table_row.stack_index].cards.is_empty() or self.is_auto_moving:
		return
	
	var card: Card = table_row.cards.back()
	var stack: CardStack = self.card_stacks[card.card_suit]
	if self.check_card_can_move_to_stack(card, stack):
		await self.move_cards_from_panel_to_panel(table_row.stack_index, stack.stack_index, 1)
		return
	
	var matched_card_buffer: CardBuffer = null
	for card_buffer in self.card_buffers:
		if card_buffer.cards.is_empty():
			matched_card_buffer = card_buffer
			break
	if matched_card_buffer != null:
		await self.move_cards_from_panel_to_panel(table_row.stack_index, matched_card_buffer.stack_index, 1)
		
## 单击牌面
func _on_table_row_single_clicked(table_row: TableRow) -> void:
	if self.is_auto_moving:
		return
	
	var pending_stack_index: int = self.stack_selected_index
	self.cancel_all_selection()
	
	if pending_stack_index == -1:
		if table_row.cards.size() <= 0:
			return
		
		self.table_row_masks[table_row.stack_index].global_position = table_row.cards.back().global_position
		self.table_row_masks[table_row.stack_index].visible = true
		self.stack_selected_index = table_row.stack_index
	else:
		if pending_stack_index >= Consts.CARD_BUFFER_START_INDEX:
			if self.all_panels[pending_stack_index].cards.size() <= 0:
				return
				
			var card: Card = self.all_panels[pending_stack_index].cards.back()
			if table_row.can_receive(card):
				await self.move_cards_from_panel_to_panel(pending_stack_index, table_row.stack_index, 1)
		else:
			await self.move_row_card_to_row_if_needed(table_row, self.all_panels[pending_stack_index])
			
## 单击缓冲区
func _on_card_buffer_clicked(card_buffer: CardBuffer) -> void:
	if self.is_auto_moving:
		return
	
	var pending_stack_index: int = self.stack_selected_index
	self.cancel_all_selection()
	
	# 单击当前缓存区
	if pending_stack_index == card_buffer.stack_index:
		return
	
	# 如果当前没有选择，且缓存区可以被选中，则选中
	if pending_stack_index == -1 and card_buffer.can_selected():
		card_buffer.set_selected(true)
		self.stack_selected_index = card_buffer.stack_index
	elif pending_stack_index >= 0 or not card_buffer.cards.is_empty():
		if self.all_panels[pending_stack_index].cards.is_empty() or not card_buffer.cards.is_empty():
			return
		
		await self.move_cards_from_panel_to_panel(pending_stack_index, card_buffer.stack_index, 1)

func _on_new_game_pressed() -> void:
	if self.is_auto_moving:
		return
	self.start_new_game()

func _on_revoke_pressed() -> void:
	if self.is_auto_moving:
		return
	await self.do_revoke()

func _on_exit_game_pressed() -> void:
	self.get_tree().quit()
#endregion
