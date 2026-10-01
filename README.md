# zoo_indoorstorm

**The storm, heard from indoors.** A free RedM script by Zoo Scripts.

In RedM, a storm sounds just as loud inside most houses as it does outside. Thunder, rain and wind roar through walls and roofs. Step into a cabin, a shop or a camp shack during a thunderstorm and it sounds like you never left the street.

This script fixes that. Walk inside and the storm drops away, muffled the way it would be through real walls. Stand under a porch, an awning or a tent and it softens too. Step back out and it comes back.

Nothing you can see changes. The weather, the falling rain and the lightning stay exactly as they are. Only the sound changes, and only for the player who is inside.

---

## Features

- **Thunder, rain and wind turned down indoors.** The thunder is also muffled, as if heard through a wall.
- **A softer version under shelter**, such as porches, awnings and tents.
- **Cloth roofs work too.** Canvas awnings and tents that move in the wind are detected.
- **The weather is never touched.** No rain is removed, no sky is changed, and the weather sync script is never paused.
- **Smooth.** The sound fades in and out instead of cutting.
- **Per player.** Each player hears their own place; nothing is sent over the network.
- **Light.** Between storms the script only checks the weather every few seconds.
- **Standalone.** No framework needed; it works on VORP, RSG, TPZ or anything else.

---

## How it works

**The sound.** The game sorts its sounds into groups, and the storm has three of its own: thunder, rain and wind. The script ships two audio mixes, written in the game's own mix format: one for inside and one for shelter. When you step in, the matching mix turns those groups down. When you step out, it lets them go.

**The place.** During a storm, the script checks around the player twice a second, and only when they have moved.
- **Inside** means a roof overhead and walls on most sides.
- **Shelter** means a low roof right overhead, such as a porch, an awning or a tent.
- A high roof with open sides, like a bridge, still counts as outside.

The game's own interior rooms are not trusted for this, because some of them let the whole storm in.

---

## Installation

1. Put the `zoo_indoorstorm` folder in your server's `resources` folder.
2. Add this line to your `server.cfg`:
   ```
   ensure zoo_indoorstorm
   ```
3. Restart the server, or run `ensure zoo_indoorstorm` in the console.

The audio mix loads when a player joins, and again when the resource restarts.

---

## Try it

Type this in the chat:

```
/stormtest
```

You get a thunderstorm for yourself only. Wait a few seconds for it to build, then walk into a house or under an awning and listen. Type the command again to get your weather back.

It works with `weathersync` if your server runs it, and without it too. To remove the command, set `Config.TestCommand = false`.

---

## Settings

Open `config.lua`:

```lua
Config.Inside  = 100   -- inside a house: a roof overhead and walls around
Config.Shelter = 100   -- under a low roof: a tent, a porch, an awning
Config.TestCommand = true
```

- **`Config.Inside` and `Config.Shelter`** set how strongly the storm is turned down in each place, from 0 to 100.
  - **100** is the whole mix. The storm is still heard, just much quieter and muffled, as it would be indoors.
  - **0** leaves it as loud as outside.
  - Any number in between is a share of the mix.
- **`Config.TestCommand`** turns `/stormtest` on or off.

The detection settings are the named values at the top of `client.lua`: how often it checks, how high a roof can be, how many walls make a room, and so on. Each one has a comment that says what it does.

---

## License

Free to use and modify on your own server.

You may **not** re-upload it, sell it, or present it as your own. Link people to this repository instead.

See [LICENSE.md](LICENSE.md) for the full terms.

---

**Zoo Scripts**: [zoo-scripts.tebex.io](https://zoo-scripts.tebex.io)
