extends Node

class RowSorter:
	# sorting_column is a const array because it's a hacky workaround around needing static functions for sorting
	# the array cannot be reassigned, but it can be modified. Set sorting_column[0] to the desired column's name, 
	# and any subsequent values will be used to index further into the column's value (like for songs.levels which is an array)
	const sorting_column: Array = [""]
	
	static func sort_ascending(a: Dictionary, b: Dictionary) -> bool:
		var a_value = a
		var b_value = b
		for index in sorting_column:
			# invalid keys will always return true, preventing the game from crashing but silently leaving it unsorted
			if not a_value.has(index):
				return true
			if not b_value.has(index):
				return true
			a_value = a_value[index]
			b_value = b_value[index]
		if is_comparable(typeof(a_value)) and is_comparable(typeof(b_value)):
			return a_value < b_value
		elif typeof(a_value) == TYPE_STRING and typeof(b_value) == TYPE_STRING:
			return a[sorting_column[0]].nocasecmp_to(b[sorting_column[0]]) < 0
		else:
			return true
		
	static func sort_descending(a: Dictionary, b: Dictionary) -> bool:
		var a_value = a
		var b_value = b
		for index in sorting_column:
			# invalid keys will always return true, preventing the game from crashing but silently leaving it unsorted
			if not a_value.has(index):
				return true
			if not b_value.has(index):
				return true
			a_value = a_value[index]
			b_value = b_value[index]
		if is_comparable(typeof(a_value)) and is_comparable(typeof(b_value)):
			return a_value > b_value
		elif typeof(a_value) == TYPE_STRING and typeof(b_value) == TYPE_STRING:
			return a[sorting_column[0]].nocasecmp_to(b[sorting_column[0]]) > 0
		else:
			return true
			
	static func is_comparable(type_enum: int) -> bool:
		match type_enum:
			TYPE_BOOL: return true
			TYPE_INT: return true
			TYPE_REAL: return true
			TYPE_RID: return true
		return false

	static func is_container(type_enum: int) -> bool:
		match type_enum:
			TYPE_DICTIONARY: return true
			TYPE_ARRAY: return true
			TYPE_RAW_ARRAY: return true
			TYPE_INT_ARRAY: return true
			TYPE_REAL_ARRAY: return true
			TYPE_STRING_ARRAY: return true
			TYPE_VECTOR2_ARRAY: return true
			TYPE_VECTOR3_ARRAY: return true
			TYPE_COLOR_ARRAY: return true
		return false

var row_sorter = RowSorter.new()

# Database structure
var db: Dictionary = {
	"tables": {
		"songs": {
			"schema": {
				"title": TYPE_STRING, 
				"artist": TYPE_STRING, 
				"bpm": TYPE_STRING, 
				"path": TYPE_STRING, 
				"levels": TYPE_ARRAY, 
				"preview_start": TYPE_REAL, 
				"preview_end": TYPE_REAL, 
				"pack": TYPE_STRING},
			"rows": [] # each row is a dictionary with keys matching schema
		},
		"packs": {
			"schema": {"name": TYPE_STRING},
			"rows": [],
		}
	}
}

class FilterParam:
	var column: String
	var operator_enum: int
	var value
	var sub_indexes: Array
	var append_previous: bool

class SortParam:
	var column: String
	var descending: bool
	var sub_indexes: Array


# Called when the node enters the scene tree for the first time.
func _ready():

	load_database("res://songs/song_db.json")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func load_database(path) -> int:
	var file = File.new()
	if not file.file_exists(path):
		return ERR_FILE_NOT_FOUND
	var err = file.open(path, File.READ)
	if err != OK:
		return err
	var db_json = file.get_as_text()
	file.close()
	var result: JSONParseResult = JSON.parse(db_json)
	if result.error != OK:
		push_error("File parsing failed at line %s: %s" % [result.error_line, result.error_string])
		return result.error
	if typeof(result.result) != TYPE_DICTIONARY:
		push_error("chart data was not parsed as Dictionary")
		return FAILED
	if not is_db_data_valid(result.result):
		return FAILED
	db.tables.songs.rows = result.result.tables.songs.rows
	db.tables.packs.rows = result.result.tables.packs.rows
	return OK


func is_db_data_valid(data: Dictionary) -> bool:
	# check that the necessary keys exist
	if not data.has("tables"):
		return false
	if typeof(data.tables) != TYPE_DICTIONARY:
		return false
	# check that each table in db has a counterpart in data
	for table_name in db.tables.keys():
		if not data.tables.has(table_name):
			return false
		
		var db_table = db.tables[table_name]
		var data_table = data.tables[table_name]
		if typeof(data_table) != TYPE_DICTIONARY:
			return false
			
		# check that the table has a schema
		if not data_table.has("schema"):
			return false
		if typeof(data_table.schema) != TYPE_DICTIONARY:
			return false
		# check schema matches
		if not len(data_table.schema) == len(db_table.schema):
			return false
		for element in db_table.schema:
			if not data_table.schema.has(element):
				return false
		# check that rows match schema
		if not data_table.has("rows"):
			return false
		if typeof(data_table.rows) != TYPE_ARRAY:
			return false
		for row in data_table.rows:
			for column_name in db_table.schema:
				if not row.has(column_name):
					return false
			for column_name in row.keys():
				if typeof(row[column_name]) != db_table.schema[column_name]:
					print("row type mismatched against schema with value %s" % row[column_name])
					return false
	return true
	
	
func select(table_name: String, conditionals: Array, order: SortParam) -> Dictionary:
	var result: Dictionary = {
		"success": false,
		"error_string": "",
		"rows": []
	}
	if not db.tables.has(table_name):
		result.error_string = "table %s does not exist" % table_name
		return result
	var table = db.tables[table_name]
	
	for i in conditionals.size():
		var filter: FilterParam = conditionals[i]
		if not is_filter_valid(filter, table_name):
			result.error_string = "invalid conditional"
			result.rows = []
			return result

		var to_search: Array
		var new_result_rows: Array = []
		if i == 0:
			to_search = table.rows
		elif filter.has("append_previous") and filter.append_previous == true:
			to_search = table
			new_result_rows = result.rows
		else: 
			to_search = result.rows

		match filter.operator_enum:
			OP_EQUAL:
				for row in to_search:
					var row_value = row[filter.column]
					for index in filter.sub_indexes:
						row_value = row_value[index]
					if row_value == filter.value:
						new_result_rows.append(row)
			OP_NOT_EQUAL:
				for row in to_search:
					var row_value = row[filter.column]
					for index in filter.sub_indexes:
						row_value = row_value[index]
					if row_value != filter.value:
						new_result_rows.append(row)
			OP_LESS:
				for row in to_search:
					var row_value = row[filter.column]
					for index in filter.sub_indexes:
						row_value = row_value[index]
					if row_value < filter.value:
						new_result_rows.append(row)
			OP_LESS_EQUAL:
				for row in to_search:
					var row_value = row[filter.column]
					for index in filter.sub_indexes:
						row_value = row_value[index]
					if row_value <= filter.value:
						new_result_rows.append(row)
			OP_GREATER:
				for row in to_search:
					var row_value = row[filter.column]
					for index in filter.sub_indexes:
						row_value = row_value[index]
					if row_value > filter.value:
						new_result_rows.append(row)
			OP_GREATER_EQUAL:
				for row in to_search:
					var row_value = row[filter.column]
					for index in filter.sub_indexes:
						row_value = row_value[index]
					if row_value >= filter.value:
						new_result_rows.append(row)
		result.rows = new_result_rows
	
	if table.schema.has(order.column):
		RowSorter.sorting_column.clear()
		RowSorter.sorting_column.append(order.column)
		if RowSorter.is_container(table.schema[order.column]):
			RowSorter.sorting_column.append_array(order.sub_indexes)
		if order.descending:
				result.rows.sort_custom(row_sorter, "sort_descending")
		else: 
			result.rows.sort_custom(row_sorter, "sort_ascending")
	result.success = true
	return result
	
func new_filter_param(column: String, operator_enum: int, value, sub_indexes: Array, append_previous: bool = false) -> FilterParam:
	var filter_param = FilterParam.new()
	filter_param.column = column
	filter_param.operator_enum = operator_enum
	filter_param.value = value
	filter_param.sub_indexes = sub_indexes
	filter_param.append_previous = append_previous
	return filter_param

func new_sort_param(column: String, descending: bool = false, sub_indexes: Array = []) -> SortParam:
	var sort_param = SortParam.new()
	sort_param.column = column
	sort_param.descending = descending
	sort_param.sub_indexes = sub_indexes
	return sort_param

func is_filter_valid(filter: FilterParam, table_name: String) -> bool:
	if not db.tables[table_name].schema.has(filter.column):
		return false
	
	var column_type: int = db.tables[table_name].schema[filter.column]
	var operator_valid = false

	if len(filter.sub_indexes) == 0 and typeof(filter.value) != column_type:
		return false

	if RowSorter.is_container(column_type):
		operator_valid = true # if column contains array or dictionary, bypass the check. It can be checked later when querying sub-index.
	else:
		match filter.operator:
			OP_EQUAL: 
				operator_valid = true
			OP_NOT_EQUAL: 
				operator_valid = true
			OP_LESS: 
				if RowSorter.is_comparable(column_type): 
					operator_valid = true
			OP_LESS_EQUAL: 
				if RowSorter.is_comparable(column_type): 
					operator_valid = true
			OP_GREATER: 
				if RowSorter.is_comparable(column_type): 
					operator_valid = true
			OP_GREATER_EQUAL: 
				if RowSorter.is_comparable(column_type): 
					operator_valid = true
	return operator_valid
