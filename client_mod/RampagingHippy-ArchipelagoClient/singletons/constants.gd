class_name BrotatoApConstants

const CHARACTER_NAME_TO_ID = {	
	"Well Rounded": "character_well_rounded",
	"Brawler": "character_brawler",
	"Crazy": "character_crazy",
	"Ranger": "character_ranger",
	"Mage": "character_mage",
	"Chunky": "character_chunky",
	"Old": "character_old",
	"Lucky": "character_lucky",
	"Mutant": "character_mutant",
	"Generalist": "character_generalist",
	"Loud": "character_loud",
	"Multitasker": "character_multitasker",
	"Wildling": "character_wildling",
	"Pacifist": "character_pacifist",
	"Gladiator": "character_gladiator",
	"Saver": "character_saver",
	"Sick": "character_sick",
	"Farmer": "character_farmer",
	"Ghost": "character_ghost",
	"Speedy": "character_speedy",
	"Entrepreneur": "character_entrepreneur",
	"Engineer": "character_engineer",
	"Explorer": "character_explorer",
	"Doctor": "character_doctor",
	"Hunter": "character_hunter",
	"Artificer": "character_artificer",
	"Arms Dealer": "character_arms_dealer",
	"Streamer": "character_streamer",
	"Cyborg": "character_cyborg",
	"Glutton": "character_glutton",
	"Jack": "character_jack",
	"Lich": "character_lich",
	"Apprentice": "character_apprentice",
	"Cryptid": "character_cryptid",
	"Fisherman": "character_fisherman",
	"Golem": "character_golem",
	"King": "character_king",
	"Renegade": "character_renegade",
	"One Armed": "character_one_arm", # This the one case where the ID and name differ
	"Bull": "character_bull",
	"Soldier": "character_soldier",
	"Masochist": "character_masochist",
	"Knight": "character_knight",
	"Demon": "character_demon",	
}

const CHARACTER_ID_TO_NAME = {}

const ITEM_DROP_NAME_TO_TIER = {
	"Common Item": Tier.COMMON,
	"Uncommon Item": Tier.UNCOMMON,
	"Rare Item": Tier.RARE,
	"Legendary Item": Tier.LEGENDARY
}

const UPGRADE_NAME_TO_TIER = {
	"Common Upgrade": Tier.COMMON,
	"Uncommon Upgrade": Tier.UNCOMMON,
	"Rare Upgrade": Tier.RARE,
	"Legendary Upgrade": Tier.LEGENDARY
}

const SHOP_SLOT_ITEM_NAME = "Progressive Shop Slot"

# The ItemService generates items using the current wave to choose the value. This value
# defines how many items are dropped for each wave, going up. For example, if 2 then
# the first two items will be generated with wave=1, the next two with wave=2, etc.
const NUM_ITEM_DROPS_PER_WAVE = 2

const GOLD_DROP_NAME_TO_VALUE = {
	"Gold (10)": 10,
	"Gold (25)": 25,
	"Gold (50)": 50,
	"Gold (100)": 100,
	"Gold (200)": 200,
}

const XP_ITEM_NAME_TO_VALUE = {
	"XP (5)": 5,
	"XP (10)": 10,
	"XP (25)": 25,
	"XP (50)": 50,
	"XP (100)": 100,
	"XP (150)": 150,
}

func _init():
	for char_name in CHARACTER_NAME_TO_ID:
		var char_id = CHARACTER_NAME_TO_ID[char_name]
		CHARACTER_ID_TO_NAME[char_id] = char_name
