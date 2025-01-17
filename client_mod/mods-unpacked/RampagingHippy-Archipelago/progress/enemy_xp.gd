## Track if enemies can give XP to the player.
##
## This really just checks if we're connected to a multiworld and, if so, the value of
## the `enable_enemy_xp` slot data entry. This corresponds directly to the value of the
## "Enable Enemy XP" option in the apworld. If we're connected and the flag is False,
## then enemy XP rewards are intercepted and disabled.
##
## This is referenced by our override of RunData.add_xp to check if XP should be awarded
## or not. We put the logic for checking the slot here for consistency with the rest of
## the mod. The progress handlers are the only place slot data is checked currently,
## which seems like a good convention to maintain.
extends "res://mods-unpacked/RampagingHippy-Archipelago/progress/_base.gd"
class_name ApEnemyXpProgress

const LOG_NAME = "RampagingHippy-Archipelago/progress/enemy_xp"

# Enable enemy XP (vanilla behavior) until we're connected to a multiworld.
var enable_enemy_xp = true

func _init(ap_client, game_state).(ap_client, game_state):
	pass

func on_connected_to_multiworld():
	# Reset received XP. As the multiworld sends us all our received items we'll
	# recalculate the received XP.
	enable_enemy_xp = _ap_client.slot_data["enable_enemy_xp"]
	ModLoaderLog.info("enable_enemy_xp set to %s" % enable_enemy_xp, LOG_NAME)

func on_disconnected_from_multiworld():
	# Disconnected, set the flag to true
	enable_enemy_xp = true