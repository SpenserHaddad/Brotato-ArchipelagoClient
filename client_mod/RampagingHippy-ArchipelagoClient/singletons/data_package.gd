const LOG_NAME = "RampagingHippy-Archipelago/DataPackage"

class BrotatoLocationGroups:
	## Container for id-to-value for various types of locations we want to reference at runtime.
	var consumables: Dictionary
	var legendary_consumables: Dictionary
	var character_run_complete: Dictionary
	var character_wave_complete: Dictionary

	static func from_location_table(location_name_to_id: Dictionary) -> BrotatoLocationGroups:
		var location_groups = BrotatoLocationGroups.new()
		var consumable_location_pattern = RegEx.new()
		consumable_location_pattern.compile("^Loot Crate (\\d+)")
	
		var legendary_consumable_location_pattern = RegEx.new()
		legendary_consumable_location_pattern.compile("^Legendary Loot Crate (\\d+)")
	
		var char_run_complete_pattern = RegEx.new()
		char_run_complete_pattern.compile("^Run Won \\(([\\w ]+)\\)")
	
		var char_wave_complete_pattern = RegEx.new()
		char_wave_complete_pattern.compile("^Wave (\\d+) Completed \\(([\\w ]+)\\)$")
	
		for location_name in location_name_to_id:
			var location_id = location_name_to_id[location_name]
			
			var consumable_match = consumable_location_pattern.search(location_name)
			if consumable_match:
				# By the end this should be the highest crate drop we've seen
				var consumable_number = int(consumable_match.get_string(1))
				location_groups.consumables[location_id] = consumable_number
				continue
	
			var legendary_consumable_match = legendary_consumable_location_pattern.search(location_name)
			if legendary_consumable_match:
				# By the end this should be the highest crate drop we've seen
				var legendary_consumable_number = int(legendary_consumable_match.get_string(1))
				location_groups.legendary_consumables[location_id] = legendary_consumable_number
				continue
			
			var char_run_complete_match = char_run_complete_pattern.search(location_name)
			if char_run_complete_match:
				var character = char_run_complete_match.get_string(1)
				location_groups.character_run_complete[location_id] = character
				continue

			var char_wave_complete_match = char_wave_complete_pattern.search(location_name)
			if char_wave_complete_match:
				var wave_number = int(char_wave_complete_match.get_string(1))
				var wave_character = char_wave_complete_match.get_string(2)
				location_groups.character_wave_complete[location_id] = [wave_number, wave_character]
		return location_groups

class BrotatoDataPackage:
	## The Archipelago Data Package for Brotato in an easier-to-search form
	var item_name_to_id: Dictionary
	var item_id_to_name: Dictionary
	var location_name_to_id: Dictionary
	var location_id_to_name: Dictionary
	var location_groups: BrotatoLocationGroups

	func _init(
		item_name_to_id_: Dictionary,
		location_name_to_id_: Dictionary,
		item_id_to_name_: Dictionary,
		location_id_to_name_: Dictionary,
		location_groups_: BrotatoLocationGroups
	):
		item_name_to_id = item_name_to_id_
		item_id_to_name = item_id_to_name_
		location_name_to_id = location_name_to_id_
		location_id_to_name = location_id_to_name_
		location_groups = location_groups_
		
	static func from_data_package(data_package: Dictionary) -> BrotatoDataPackage:
		# Expects that you already extracted the game's data package from the message
		var item_name_to_id_ = data_package["item_name_to_id"]
		var item_id_to_name_ = Dictionary()
		for item_name in item_name_to_id_:
			var item_id = item_name_to_id_[item_name]
			item_id_to_name_[item_id] = item_name

		var location_name_to_id_ = data_package["location_name_to_id"]
		var location_id_to_name_ = Dictionary()
		for location_name in location_name_to_id_:
			var location_id = location_name_to_id_[location_name]
			location_id_to_name_[location_id] = location_name
		
		var location_groups_ = BrotatoLocationGroups.from_location_table(location_name_to_id_)

		return BrotatoDataPackage.new(
			item_name_to_id_,
			location_name_to_id_,
			item_id_to_name_,
			location_id_to_name_,
			location_groups_
		)
