class_name Record

var original_stack_index: int
var target_stack_index: int
var card_removed_count: int

static func newRecord(origin_index: int, target_index: int, removed_count: int) -> Record:
	var record: Record = Record.new()
	
	record.original_stack_index = origin_index
	record.target_stack_index = target_index
	record.card_removed_count = removed_count
	
	return record
