tool
extends Node2D

export(String, FILE) var path:String
export var save:bool setget do_save

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func do_save(_new_value) -> void:
	print("Saving")
	var data = []
	for weapon_data in ItemService.weapons:
		var weapon_sets_data = []
		for set_data in weapon_data.sets:
			weapon_sets_data.append({
				"name": tr(set_data.name),
				"id": set_data.my_id
			})
		data.append({"name": weapon_data.weapon_id, "type": weapon_data.type, "sets": weapon_sets_data})
	var jd = JSON.print(data, "\t")
	var out_file = File.new()
	out_file.open(path, File.WRITE)
	out_file.store_string(jd)
	out_file.close()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
