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
MAX_SHOP_LOCATIONS_PER_TIER = {
    ItemRarity.COMMON: 20,
    ItemRarity.UNCOMMON: 10,
    ItemRarity.RARE: 10,
    ItemRarity.LEGENDARY: 10,
}
