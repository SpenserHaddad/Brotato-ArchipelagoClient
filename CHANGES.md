# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1]

### Added

- Initial release of both the apworld and the client mod for Brotato. This is a minimal
  working implementation that should be usable as a full game, but there are likely bugs
  and balance issues, and not all planned features are included yet.
- This release of the randomizer implements:
    - Goal: Win a certain number of runs with different characters.
    - Options:
        - How many run wins are needed for victory.
        - The number of starting characters.
        - Whether to start with the default characters or a random selection.
        - Which waves count as checks when completed.
        - The number of normal and legendary loot crate drops which count as checks.
        - The number of upgrade items to include in the pool.
        - The number of shop slots to start with. The remaining slots will be added to
          the item pool.
    - Locations:
        - Complete waves with different characters.
        - Win runs with different characters.
        - Pick up regular and legendary loot crates during waves. 
            - Loot crates are replaced with special Archipelago consuamables until all
              relevant locations are found.
            - There are separate items for regular and legendary loot crates.
    - Items:
        - Common, Uncommon, Rare and Legendary non-weapon items.
        - XP drops. Values are: 5, 10, 25, 50, 100, and 150.
        - Gold drops. Values are: 10, 25, 50, 100, 200.
        - Shop slots.
        - Characters which are not unlocked by default.
        - "Run Won": A special item for tracking how many runs the player has won.
    - Logic for placing locations sanely.
- This release of the client mod implements:
    - An Archipelago WebSocket client.
    - Hooks into Brotato to add the received items listed above and detect when
      locations are checked.


