# GPD Duo

Display layouts and touchpad slider control for the [GPD Duo](https://www.gpd.hk/gpdduo) on Omarchy Quattro.

The Duo’s lower OLED is physically inverted, and the lid is a second 13.3" panel. This plugin offers the two layouts that keep the main panel powered, and a toggle for the brightness/volume strips on the lower touchpad. Touch and stylus mapping are **not** included yet.

The lid display only works while the main (lower) panel is enabled, so upper-only and tablet modes are not offered. Turning the main panel off leaves both screens unusable.

## Layouts

| Mode | What it does |
|------|----------------|
| Dual laptop | Both screens stacked; lower `eDP` rotated 180° |
| Lower only | Main display on, lid display off |

On a Duo whose main screen is still unrotated, the background service applies **Dual laptop** once at login. It does not write `monitors.lua` until you click **Save**.

The session lock screen inherits Hyprland’s layout, so it is already oriented correctly.

The **login** path is two different screens:

- After **logout**, SDDM’s greeter is a separate Hyprland compositor and does not read `monitors.lua`. **Fix login screen orientation** writes `/etc/sddm/gpd-duo-hyprland.lua` so the lower OLED is rotated 180° there.
- After **reboot**, autologin skips SDDM. The first password prompt is **Plymouth** (stock Omarchy). Rotating that splash per-display fights Hyprland’s pointer mapping, so the boot unlock screen stays default: lower inverted, lid upright.

Those greeter files are not owned by `omarchy-settings`.

## Install

```sh
omarchy plugin add https://github.com/dannyowelch/omarchy-gpd-duo.git --enable
```

The git repo is `~/Projects/omarchy-gpd-duo`. Omarchy loads plugins from a separate live copy:

```
~/.config/omarchy/plugins/io.github.dannyowelch.gpd-duo/
```

After editing the repo, install into that live path:

```sh
./install-local.sh
```

Saved files in the live plugin directory reload automatically. Force rediscovery with:

```sh
omarchy-shell shell rescanPlugins
omarchy plugin enable io.github.dannyowelch.gpd-duo --section right
```

## Usage

- Click the dual-display icon on the bar (right section by default)
- Click a layout to apply it live via Hyprland
- Toggle **Touchpad sliders** to enable or disable the brightness and volume strips
- **Save to monitors.lua** writes `~/.config/hypr/monitors.lua` (after a timestamped backup)
- **Fix login screen orientation** writes the SDDM greeter config for logout. Prompts for privileges. If a custom boot splash is still installed, restores stock Omarchy and rebuilds the UKI once.
- Right-click the bar icon also saves
- Super-summon: `omarchy-shell shell summon io.github.dannyowelch.gpd-duo '{}'`

CLI (same binary the panel runs):

```sh
~/.config/omarchy/plugins/io.github.dannyowelch.gpd-duo/gpd-duo-ctl status
~/.config/omarchy/plugins/io.github.dannyowelch.gpd-duo/gpd-duo-ctl apply dual
~/.config/omarchy/plugins/io.github.dannyowelch.gpd-duo/gpd-duo-ctl sliders off
~/.config/omarchy/plugins/io.github.dannyowelch.gpd-duo/gpd-duo-ctl sliders on
~/.config/omarchy/plugins/io.github.dannyowelch.gpd-duo/gpd-duo-ctl save
~/.config/omarchy/plugins/io.github.dannyowelch.gpd-duo/gpd-duo-ctl login-fix
```

The slider toggle writes `~/.local/state/omarchy/toggles/hypr/gpd-duo-sliders.lua` (Hyprland ignores that device’s keybinds) and a small `gpd-duo-sliderd` process maps the strips to **speaker** volume and display brightness. Omarchy’s global `XF86Audio*` binds would otherwise treat some of those HID usages as microphone controls.

## Hardware

Detected when DMI is `GPD` / `G1622*` (this machine is `G1622-01`), or when an `eDP` output and a Stargate Technology panel are both present.

| Role | Typical output | Notes |
|------|----------------|-------|
| Lower | `eDP-1` | Samsung OLED, needs transform 2 |
| Upper | `DP-3` | Stargate Technology lid OLED |
| Touchpad sliders | `sp3105ft:…-keyboard` | Brightness/volume strips; plugin sets `keybinds` |

## Remove

```sh
omarchy plugin remove io.github.dannyowelch.gpd-duo
```

Removal does not revert `monitors.lua`, the slider overlay, or the SDDM greeter config. Restore a `~/.config/hypr/monitors.lua.bak.*` backup if you want the previous layout. Delete `~/.local/state/omarchy/toggles/hypr/gpd-duo-sliders.lua` and reload Hyprland to drop the slider setting. Remove `/etc/sddm/gpd-duo-hyprland.lua` and `/etc/sddm.conf.d/20-gpd-duo.conf` to restore the stock logout greeter.

## License

MIT
