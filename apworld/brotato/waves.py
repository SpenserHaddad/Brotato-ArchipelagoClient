from math import ceil

from .constants import NUM_WAVES, ItemRarity
from .items import ItemName
from .options import WavesPerCheck


def get_waves_with_checks(waves_per_check: WavesPerCheck) -> list[int]:
    """Determine which waves will have checks based on the waves_per_check option.

    waves_per_check is a shorthand for saying "every <n> waves completed with a character should be a check", and this
    converts that value into the actual wave numbers for easier use internally.
    """
    # Ignore 0 value, but choosing a different start gives the wrong wave results
    return list(range(0, NUM_WAVES + 1, waves_per_check.value))[1:]


def get_wave_for_each_item(item_counts: dict[ItemName, int]) -> dict[int, list[int]]:
    """Create the wave each item should be generated with.

    In each item rarity tier, increment the wave by one for each item, looping over at 20 (the max number of waves in a
    run), then sort the result so we have an even distribution of waves in increasing order.

    Brotato generates items from a pool determined by the rarity (or tier) of the item and the wave the item was found
    or bought. We want to emulate this behavior with the items we create here, so items aren't just all from the weakest
    or strongest pool when given to the player. This determines the effective wave to use for each item when it's
    received. When the client receives the next item for a certain rarity, it will lookup the next entry in the list for
    the rarity and use that as the wave when generating the values.

    We attempt to equally distribute the items over the 20 waves in a normal run, with a bias towards higher numbers,
    for fun.
    """
    x =  10
    item_names_to_rarity: dict[ItemName, ItemRarity] = {
        ItemName.COMMON_ITEM: ItemRarity.COMMON,
        ItemName.UNCOMMON_ITEM: ItemRarity.UNCOMMON,
        ItemName.RARE_ITEM: ItemRarity.RARE,
        ItemName.LEGENDARY_ITEM: ItemRarity.LEGENDARY,
    }

    def generate_waves_per_item(num_items: int) -> list[int]:
        """Evenly distribute the items over 20 waves, then sort so items received are generated with steadily
        increasing waves (aka they got steadily stronger).
        """
        values: list[int] = []
        if num_items > 0:
            # Simple linspace implementation, except we start distributing from the top so there's always at least one
            # wave 20 item.
            step: float = (NUM_WAVES) / num_items
            wave_value: float = 20
            while len(values) < num_items:
                values.append(ceil(wave_value))
                wave_value -= step
                wave_value = max(wave_value, 1)
        return sorted(values)

    # Use a default of 0 in case no items of a tier were created for whatever reason.
    return {
        rarity.value: generate_waves_per_item(item_counts.get(name, 0)) for name, rarity in item_names_to_rarity.items()
    }
