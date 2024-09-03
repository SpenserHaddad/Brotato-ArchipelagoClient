tool
extends Viewport

export(String, FILE) var path:String
export var save:bool setget do_save


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func do_save(_new_value) -> void:
	var target_path := path.strip_edges()
	var folder := target_path.get_base_dir()
	var file_name := target_path.get_file()
	var extension := target_path.get_extension()
	if file_name == "":
		push_error("Output folder does not exist")
		return
		
	if extension != "png":
		target_path += "png" if target_path.ends_with(".") else ".png"
	
	var image := get_texture().get_data()
	image.flip_y()
	image.convert(Image.FORMAT_RGBA8)
	var error := image.save_png(target_path)
	if error != OK:
		push_error("Failed to save output image")
		return
	print("Image saved to ", target_path)
