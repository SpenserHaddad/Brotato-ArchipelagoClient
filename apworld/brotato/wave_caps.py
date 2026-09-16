from .constants import NUM_WAVES
from .options import NumWaveCaps


def get_wave_cap_info(num_wave_caps: NumWaveCaps) -> tuple[int, dict[int, range]]:
    # The first cap is implicitly part of sphere 0, so it doesn't need an item to access
    num_items = num_wave_caps - 1

    # We could just hard-code these, but it makes us slightly more flexible if we add more
    # values down the road.
    wave_access: dict[int, range] = {}
    wave_start = 1
    step_size = NUM_WAVES // num_wave_caps
    for cap in range(num_wave_caps):
        wave_access[cap] = range(wave_start, wave_start + step_size)
        wave_start += step_size

    return num_items, wave_access
