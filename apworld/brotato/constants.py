from enum import Enum
from typing import Dict

BASE_ID = 0x7A70_0000


NUM_WAVES = 20
MAX_DIFFICULTY = 5


class ItemRarity(Enum):
    COMMON = "Common"
    UNCOMMON = "Uncommon"
    RARE = "Rare"
    LEGENDARY = "Legendary"


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

# Percentage (Brotato) items of different rarities should be made when creating AP items to fill the common loot crate
# drop locations. The different item rarity is never explicitly defined in Brotato's source code, but we can make a
# reasonable guess by looking at the max chance of getting items of each rarity/tier from the shop, which is publically
# documented here: https://brotato.wiki.spellsandguns.com/Shop#Rarity_of_Shop_Items_and_Luck. For below, we sum the Max
# Chance percent for each rarity for all rarities, then divide each individual rarity Max Chance by the sum. We when
# tweak the numbers slightly to get nice "clean" numbers for readability. The variation is negligible (ex. legendaries
# would be 4% nominally but are 5% below). It's not perfect, but it "feels" correct and works better in lieu of actual
# rarities.
ITEM_RARITY_WEIGHTS: Dict[ItemRarity, float] = {
    ItemRarity.COMMON: 0.5,
    ItemRarity.UNCOMMON: 0.3,
    ItemRarity.RARE: 0.15,
    ItemRarity.LEGENDARY: 0.05,
}

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

# Region name string templates
CRATE_DROP_GROUP_REGION_TEMPLATE = "Loot Crate Group {num}"
LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE = "Legendary Loot Crate Group {num}"
