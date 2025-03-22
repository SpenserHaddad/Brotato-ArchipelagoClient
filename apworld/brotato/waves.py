from worlds.brotato.constants import NUM_WAVES

from .options import WavesPerCheck


def get_waves_with_checks(waves_per_check: WavesPerCheck) -> list[int]:
    # Ignore 0 value, but choosing a different start gives the wrong wave results
    return list(range(0, NUM_WAVES + 1, waves_per_check.value))[1:]
