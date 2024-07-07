from enum import Enum
from typing import Tuple

BASE_ID = 0x7A70_0000


NUM_WAVES = 20
MAX_DIFFICULTY = 5


class ItemRarity(Enum):
    # These values match the constants in Brotato, which the client mod uses. Change at your own risk.
    COMMON = 0
    UNCOMMON = 1
    RARE = 2
    LEGENDARY = 3


CHARACTERS = (
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
)

DEFAULT_CHARACTERS = ("Well Rounded", "Brawler", "Crazy", "Ranger", "Mage")
UNLOCKABLE_CHARACTERS = tuple(set(CHARACTERS) - set(DEFAULT_CHARACTERS))

MAX_REQUIRED_RUN_WINS = 50

NUM_CHARACTERS = len(CHARACTERS)
NUM_DEFAULT_CHARACTERS = len(DEFAULT_CHARACTERS)
NUM_UNLOCKABLE_CHARACTERS = NUM_CHARACTERS - NUM_DEFAULT_CHARACTERS

MAX_NORMAL_CRATE_DROPS = 50
MAX_LEGENDARY_CRATE_DROPS = 50
# Since groups are unlocked by winning runs, the maximum number of groups there is the number of characters.
# So these are just aliases of NUM_CHARACTERS to make them more explicit.
MAX_NORMAL_CRATE_DROP_GROUPS = NUM_CHARACTERS
MAX_LEGENDARY_CRATE_DROP_GROUPS = NUM_CHARACTERS

# Weights to use when generating Brotato items using the "default item weights" option. These weights are intended to
# match the rarity of each tier in the vanilla game. The distribution is not explicitly defined in the game, but we can
# make a reasonable guess by looking at the max chances of getting items of each rarity/tier from the shop or loot
# crates, which are publcially listed here: https://brotato.wiki.spellsandguns.com/Shop#Rarity_of_Shop_Items_and_Luck.
# We use the values from the "Max Chance" column in the table in the linked sections as weights. It's not perfect, but
# it "feels" right and seems close enough.s
DEFAULT_ITEM_WEIGHTS: Tuple[int, int, int, int] = (100, 60, 25, 8)


MAX_COMMON_UPGRADES = 50
MAX_UNCOMMON_UPGRADES = 50
MAX_RARE_UPGRADES = 50
MAX_LEGENDARY_UPGRADES = 50

MAX_SHOP_SLOTS = 4  # Brotato default, can't easily increase beyond this.

# Location name string templates
CRATE_DROP_LOCATION_TEMPLATE = "Loot Crate {num}"
LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE = "Legendary Loot Crate {num}"
WAVE_COMPLETE_LOCATION_TEMPLATE = "Wave {wave} Completed ({char})"
RUN_COMPLETE_LOCATION_TEMPLATE = "Run Won ({char})"
SHOP_ITEM_LOCATION_TEMPLATE = "{tier} Shop Item {num}"

# Region name string templates
CRATE_DROP_GROUP_REGION_TEMPLATE = "Loot Crate Group {num}"
LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE = "Legendary Loot Crate Group {num}"
