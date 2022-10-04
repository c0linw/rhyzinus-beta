extends Node

class RowSorter:
	var sorting_column: String = ""
	
	func sort_ascending(a: Dictionary, b: Dictionary) -> bool:
		return a[sorting_column] < b[sorting_column]
		
	func sort_descending(a: Dictionary, b: Dictionary) -> bool:
		return a[sorting_column] > b[sorting_column]

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

# operator structure:
# {
# 	"column": "column_name_here",
# 	"operator": "=", # can be one of "=", "!=", ">", "<", ">=", "<="
# 	"value": 10, # the value to compare using operator
# 	"sub_indexes": [3], # optional key. If the column queried is a data container like an array or dictionary, it will index it using this value. Put multiple values in this array for nested indexing.
# 	"append_previous": true, # optional key. If true, appends this filter's result to the previous filter's result (OR statement). Default behaviour will filter against the previous result (AND statement).
# }


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
	var err = file.open(path, _File.READ)
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
	db.tables.songs.rows = result.tables.songs.rows
	db.tables.packs.rows = result.tables.packs.rows
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
		if typeof(data_table.schema) != TYPE_ARRAY:
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
				if typeof(row[column_name]) != typeof(db_table.schema[column_name]):
					return false
	return true
	
	
func select(table_name: String, conditionals: Array, order: String) -> Dictionary:
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
		var filter = conditionals[i]
		if not is_conditional_valid(filter, table_name):
			result.error_string = "invalid conditional"
			return result

		var to_search: Array
		var new_result_rows: Array = []
		if i == 0:
			to_search = table
		elif filter.has("append_previous") and filter.append_previous == true:
			to_search = table
			new_result_rows = result.rows
		else: 
			to_search = result.rows

		# do any sub-indexing of a column value if available:
		var use_sub_index: bool = filter.has("sub_indexes")

		match filter.operator:
			"=":
				for row in to_search:
					var row_value = row[filter.column]
					if use_sub_index:
						for index in filter.sub_indexes:
							row_value = row_value[index]
					if row_value == filter.value:
						new_result_rows.append(row)
			"!=":
				for row in to_search:
					var row_value = row[filter.column]
					if use_sub_index:
						for index in filter.sub_indexes:
							row_value = row_value[index]
					if row_value != filter.value:
						new_result_rows.append(row)
			">":
				for row in to_search:
					var row_value = row[filter.column]
					if use_sub_index:
						for index in filter.sub_indexes:
							row_value = row_value[index]
					if row_value > filter.value:
						new_result_rows.append(row)
			"<":
				for row in to_search:
					var row_value = row[filter.column]
					if use_sub_index:
						for index in filter.sub_indexes:
							row_value = row_value[index]
					if row_value < filter.value:
						new_result_rows.append(row)
			">=":
				for row in to_search:
					var row_value = row[filter.column]
					if use_sub_index:
						for index in filter.sub_indexes:
							row_value = row_value[index]
					if row_value >= filter.value:
						new_result_rows.append(row)
			"<=":
				for row in to_search:
					var row_value = row[filter.column]
					if use_sub_index:
						for index in filter.sub_indexes:
							row_value = row_value[index]
					if row_value <= filter.value:
						new_result_rows.append(row)
		result.rows = new_result_rows
	
	var sort_params = order.rsplit(" ", true, 1)
	if table.schema.has(sort_params[0]):
		row_sorter.sorting_column = sort_params[0]
		if sort_params[1] == "asc":
			result.rows.sort_custom(RowSorter, "sort_ascending")
		elif sort_params[1] == "desc": 
			result.rows.sort_custom(RowSorter, "sort_descending")
	# default behaviour: invalid order string silently leaves the result unsorted
	return result
	
func is_conditional_valid(conditional: Dictionary, table_name: String) -> bool:
	if not conditional.has("column"):
		return false
	if not db.tables[table_name].schema.has(conditional.column):
		return false
		
	if not conditional.has("value"):
		return false
	if not conditional.has("operator"):
		return false
	
	# TODO: typecheck the lesser/greater-type operators for numerical columns only? Requires types to be bound to schema columns
	var operator_valid = false
	match conditional.operator:
		"=": operator_valid = true
		"!=": operator_valid = true
		">": operator_valid = true
		"<": operator_valid = true
		">=": operator_valid = true
		"<=": operator_valid = true
	return operator_valid
