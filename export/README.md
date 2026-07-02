# Export Notes

## PC

Use PC builds as the first development target. Install Godot export templates, then create macOS, Windows, and Linux presets from the editor.

## Android

Install Android Studio, SDK, NDK, Java, and Godot Android export templates. Add touch controls before treating Android as playable.

## iOS

Requires Xcode and an Apple Developer account for device testing or publishing. Keep platform SDK code outside gameplay scripts.

## Web and Mini-Game Platforms

Godot can export to web. Many mini-game platforms need an adapter or wrapper around a web build, plus platform SDK calls for login, sharing, ads, and payments. Keep these integrations in platform-specific scripts instead of mixing them into player, enemy, or weapon code.
