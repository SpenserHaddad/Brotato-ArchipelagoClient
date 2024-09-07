# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0]

### Added

- (Internal) Added new utility for saving a Godot scene to an image. This helps a lot
  with creating scenes which use Brotato's shader and font.

### Changed

- The arrows in the Archipelago upgrade icon is now colored to match its tier.
- The Archipelago gift item icon now has a colored letter to match its tier.
- Resized all gift item icons to match the default loot box image.

### Fixed
- The run won icon on the player select screen is now an appropriate size.
- Removed logs that would cause the game to hang when connecting to a multiworld.
- Fix game freezing for a few seconds when connecting to a slot after winning a run.
- Fix shop lock buttons staying disabled after disconnecting from a multiworld.
- Fix number of starting shop lock buttons not matching options.
  - This unfortunately cannot be fixed for existing games, only for ones generated with
    this fix.
- Fix upgrades and items received being duplicated across slots if connecting to
  multiple servers/players in the same game instance.

## [0.3.0] - 2024-08-15

### Added
- The "Lock" buttons in the shop can now be added as items in the randomizer.
  - Two new options control if the buttons are randomized, and how many.
  - If enabled, the buttons will disabled until the corresponding item is received.
  - The lock buttons are progressive, so you will always receive the button for the
    first shop slot, then the second, etc.

### Changed
- Resized the Archipelago logos used in various parts of the mod to make them closer in
  size to similar images.
- Added a black border to the logo used in-game to make it stand out better.

## [0.2.1] - 2024-08-05

### Fixed

- Fixed the number of items and locations mismatching with certain option combinations.

## [0.2.0] - 2024-07-18

### Added
- New option: "Include Characters", to include/exclude certain characters from the world
  if players don't want to play as them.
  - Characters not included in the option will not have an item to unlock them, and
    their run and wave complete checks will be excluded from the world.
  - Currently, the option is defined in the YAML only, NOT on the options page. This is
    an Archipelago core limitation.

### Changed
- World generation will now remove Brotato items and upgrades from the Archipelago item
  pool if there are not enough locations.
  - This typically occurs if too few characters are included with the new "Include
    Characters" option.
- Legendary loot crate drops are now marked as `EXCLUDED`, to account for how
 infrequently they drop.  
 - This may be reverted in a future update.

## [0.1.0] - 2024-07-07

### Added
- Loot crate drops are now organized into "groups", which are not dropped by the game
  until a certain number of wins are obtained.
  - The number of normal and legendary loot crate groups can be configured by two new
    options added for them.
  - Loot crates are evenly distributed among the groups, with a bias towards earlier
    groups if there's excess.
  - Each group requires a certain number of wins before the game will drop them, which is
    calculated by dividing the number of groups by the number of required victories for
    goal completion. The first group is always unlocked at the start of the game.
    - For example, if the world requires 20 wins and has 10 common crate drop groups, the
      first group will be unlocked from the start, the second after two wins, the third
      after four wins, etc.
    - If the options specify more groups than the required number of wins, the number of
      groups is clamped to the number of wins.
- The weights of Brotato item tiers (Common/Uncommon/Rare/Legendary) can now be
  configured via new options:
  - `Default` uses a weights that tries to match Brotato's item tier drop chances.
  - `Chaos` uses random weights for the tiers.
  - `Custom` uses user-specified weights.
- Added new options to let the user set item rarity weights (see `Custom` option above).
- Add new panel to the character select screen to show info on the multiworld progress if connected:
  - Number of runs completed and how many are needed for your goal.
  - The number of loot crate checks found, available, and total.
  - How many wins are needed to unlock the next set of loot crates.
  - The number of shop slots available.
- Add an AP icon to each character on the character select screen that you've won a run with.
- Add new HUD elements to show the number of progress towards loot crate checks.

### Changed
- (Internal) Broke the large class `BrotatoApSession` into multiple smaller "progress"
objects for better organization and readability.
- (Internal) Removed old game state tracker and replaced with simpler class to just
  check when runs and waves start and finish.
- (Internal) AP client now handles `RoomUpdate` commands.
- (Internal) Rename `BrotatoApSession` to `BrotatoApClient`.
- (Internal) Rename `ApPlayerSession` to `GodotApClient`.
- Options descriptions now use reStructuredText formatting to make them look nicer.
- Updated names of all options to be shorter and have a more consistent style.
- Reworded some option descriptions to reflect changes to the randomizer and make the
  options clearer.
- `(Legendary) Loot Crates per Check` has been renamed to `(Legendary) Crate Pickup
  Step`.
- `Number of normal crate drop locations` has been renamed to `Loot Crate Locations`.
- `Number of legendary crate drop locations` has been renamed to `Legendary Loot Crate
  Locations`.
- Default value for `(Legendary) Crate Pickup Step` is now 1 instead of 0.
  - 0 was a nonsensical value for this option.
- Archipelago password text is now hidden by default, with a button to toggle.
- Archipelago connect menu now shows correct server and player entered.
  - This is still reset when the game exits, however (for now).

### Fixed
- XP and gold given to player is now properly tracked between connections to the
  multiworld.
- Brotato items other than common items are now included in the Archipelago item pool.
- Archipelago connect button on the main menu can now be navigated to with controller
  and keyboard.
- Archipelago connect menu can now be navigated with controller and keyboard.
- Completing wave 20 while going into endless mode now counts as a win.
- Update minimum Archipelago version to 0.5.0 for .apworld and the mod.

### Removed
- Removed the unused option `Shop items`.
- Removed the related shop item locations, they were never used.

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

[unreleased]: https://github.com/SpenserHaddad/Brotato-ArchipelagoClient/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/SpenserHaddad/Brotato-ArchipelagoClient/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/SpenserHaddad/Brotato-ArchipelagoClient/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/SpenserHaddad/Brotato-ArchipelagoClient/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/SpenserHaddad/Brotato-ArchipelagoClient/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/SpenserHaddad/Brotato-ArchipelagoClient/compare/v0.0.6...v0.1.0
[0.0.6]: https://github.com/SpenserHaddad/Brotato-ArchipelagoClient/compare/v0.0.5...v0.0.6
[0.0.5]: https://github.com/SpenserHaddad/Brotato-ArchipelagoClient/compare/v0.0.4...v0.0.5
[0.0.4]: https://github.com/SpenserHaddad/Brotato-ArchipelagoClient/compare/v0.0.3...v0.0.4
[0.0.3]: https://github.com/SpenserHaddad/Brotato-ArchipelagoClient/compare/v0.0.2...v0.0.3
[0.0.2]: https://github.com/SpenserHaddad/Brotato-ArchipelagoClient/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/SpenserHaddad/Brotato-ArchipelagoClient/releases/tag/v0.0.1