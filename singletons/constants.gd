class_name BrotatoApConstants

const CHARACTERS = [
	"Well Rounded",
	"Brawler",
	"Crazy",
	"Ranger",
	"Mage",
	"Chunky",
	"Old",
	"Lucky",
	"Mutant",
	"Generalist",
	"Loud",
	"Multitasker",
	"Wildling",
	"Pacifist",
	"Gladiator",
	"Saver",
	"Sick",
	"Farmer",
	"Ghost",
	"Speedy",
	"Entrepeneur",
	"Engineer",
	"Explorer",
	"Doctor",
	"Hunter",
	"Artificer",
	"Arms Dealer",
	"Streamer",
	"Cyborg",
	"Glutton",
	"Jack",
	"Lich",
	"Apprentice",
	"Cryptid",
	"Fisherman",
	"Golem",
	"King",
	"Renegade",
	"One Armed",
	"Bull",
	"Soldier",
	"Masochist",
	"Knight",
	"Demon",
]

const ITEM_DROP_NAME_TO_TIER = {
	"Common Item": Tier.COMMON,
	"Uncommon Item": Tier.UNCOMMON,
	"Rare Item": Tier.RARE,
	"Legendary Item": Tier.LEGENDARY
}

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
