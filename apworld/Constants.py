from enum import Enum

BASE_ID = 0x7A70_0000


NUM_WAVES = 20
MAX_DIFFICULTY = 5


class ItemRarity(Enum):
    COMMON = "Common"
    UNCOMMON = "Uncommon"
    RARE = "Rare"
    LEGENDARY = "Legendary"


CHARACTERS = {
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
    "Entrepreneur",
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
}

DEFAULT_CHARACTERS = {"Well Rounded", "Brawler", "Crazy", "Ranger", "Mage"}
UNLOCKABLE_CHARACTERS = CHARACTERS - DEFAULT_CHARACTERS

MAX_REQUIRED_RUN_WINS = 50

NUM_CHARACTERS = len(CHARACTERS)
NUM_DEFAULT_CHARACTERS = len(DEFAULT_CHARACTERS)
NUM_UNLOCKABLE_CHARACTERS = NUM_CHARACTERS - NUM_DEFAULT_CHARACTERS

MAX_NORMAL_CRATE_DROPS = 50
MAX_LEGENDARY_CRATE_DROPS = 50

MAX_COMMON_UPGRADES = 50
MAX_UNCOMMON_UPGRADES = 50
MAX_RARE_UPGRADES = 50
MAX_LEGENDARY_UPGRADES = 50

MAX_SHOP_SLOTS = 4  # Brotato default, can't easily increase beyond this.
MAX_SHOP_LOCATIONS_PER_TIER = {
    ItemRarity.COMMON: 20,
    ItemRarity.UNCOMMON: 10,
    ItemRarity.RARE: 10,
    ItemRarity.LEGENDARY: 10,
}

# Location name string templates
CRATE_DROP_LOCATION_TEMPLATE = "Loot Crate {num}"
LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE = "Legendary Loot Crate {num}"
WAVE_COMPLETE_LOCATION_TEMPLATE = "Wave {wave} Completed ({char})"
RUN_COMPLETE_LOCATION_TEMPLATE = "Run Won ({char})"
SHOP_ITEM_LOCATION_TEMPLATE = "{tier} Shop Item {num}"
