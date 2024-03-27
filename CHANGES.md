# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.6] - 2024-03-27

### Added
- Added AP logo image to the connection menu to show the state of the connection.
- Connection menu now shows an error message when a connection error occurs.
- (Internal) Mod now properly detects if the player quits a game early or restarts it.
  - This is a needed change to ensure they are given gold and XP items at the right time
    (see `Changed` section below).
- (Internal) Total gold and XP given to the player is now tracked using two data storage entries
  per Brotato player in the multiworld.
  - Another needed change to support giving players gold and XP items only once. Using
    data storage lets us track the value outside the game.

### Fixed
- Connection to server should properly handle connection errors now.
- Connection to server now times out if it can't reach the server.

### Changed
- Gold and XP items are now given to players once in their current run or the next run
  after they receive the item, not in every run.
  - This should keep players from getting too strong too fast and trivializing their
    playthrough.
- Connecting to multiworld no longer needs to reconnect to the server if already connected.
  - This makes the process more closely follow the [Archipelago Connection
    Handshake](https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#archipelago-connection-handshake).
- (Internal) - Split out WebSocket connection from multiworld connection, since both were
  getting to be too complex for a single class.

## [0.0.5] - 2024-01-25

### Fixed
- Fix bug in rules generation where all locations were viewed accessible from the start.
- Fix bug where character accessed rule checked if Demon was unlocked instead of the
  relevant character.
- Fix progression items being placed in legendary loot crate drop locations.
  there.
  - Note: Unlike the intended change in 0.0.4, the location type is back to `DEFAULT`,
    and the apworld uses a manual `item_rule` for now that prevents `progression` and
    `progression_skip_balancing` items from being placed at these locations.. This may
    be changed in the future, however currently marking the locations as `EXCLUDED`
    causes issues in world generation.


## [0.0.4] - 2024-01-10

### Fixed
- Fix consumables not spawning when playing vanilla with the mod installed.
- Fix character select menu not loading when playing vanilla with the mod installed.

### Changed
- Change "Legendary Loot Crate <x>" location progress type from `DEFAULT` to `EXCLUDED`.
  These are too difficult to get for them to hold progression items.

## [0.0.3] - 2024-01-06

### Fixed
- The client mod can now connect to servers hosted both with and without SSL (aka using
  `wss://` and `ws://`).
  - The mod will attempt to connect using `wss://` first, then fall back to `ws://` if
    the first connection fails.
- Fix an issue where the client mod dropped incoming messages above a certain size (~64
  KB).
- Fix the game freezing for several seconds if large amounts of items were received all
  at once. For example, if the game was released.
- Random character generation should now work properly on all supported versions of
  Python (3.8 through 3.11).

### Changed
- Add several checks to the client mod to check if the game is connected to a
  MultiServer before doing any Archipelago-specific actions.
  - This prevents any issues when playing the game with the mod installed, but not
    connected to a server. i.e. playing in "vanilla" mode.
- Several internal changes were made to follow updated Archipelago development
  guidelines and to make the code better organized overall.

## [0.0.2] - 2023-10-27

### Fixed
- Fix generating games failing when using Python 3.11 and the random starting character
  option.
- Fix player name being passed as the password field when connecting to the server.

### Changed
- Use `self.random` when generating games instead of `self.multiworld.random`, to match
  new Archipelago API changes.

## [0.0.1] - 2023-10-15

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

[unreleased]: https://github.com/SpenserHaddad/Brotato-ArchipelagoClient/compare/v0.0.6...HEAD
[0.0.6]: https://github.com/SpenserHaddad/Brotato-ArchipelagoClient/compare/v0.0.5...v0.0.6
[0.0.5]: https://github.com/SpenserHaddad/Brotato-ArchipelagoClient/compare/v0.0.4...v0.0.5
[0.0.4]: https://github.com/SpenserHaddad/Brotato-ArchipelagoClient/compare/v0.0.3...v0.0.4
[0.0.3]: https://github.com/SpenserHaddad/Brotato-ArchipelagoClient/compare/v0.0.2...v0.0.3
[0.0.2]: https://github.com/SpenserHaddad/Brotato-ArchipelagoClient/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/SpenserHaddad/Brotato-ArchipelagoClient/releases/tag/v0.0.1