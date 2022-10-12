# rhyzinus-beta
Beta for Rhyzinus, a 3D touchscreen rhythm game

## To run this project:
You will need a build of Godot with the Shinobu module. Download this release: https://github.com/c0linw/godot/releases/tag/3.5.1-shinobu 

If you export this project, you will also need to set the included build template executables (android_debug_VERSION.exe and android_release_VERSION.exe)

## Unable to load audio files via Shinobu on the exported game?
If you intend to include an audio file as part of the exported game, make sure that its import method is set to "Keep". Otherwise, it will only be loaded when running via editor but not when running the exported game.

## Connecting something to an effect breaks audio playback?
Make sure the audio effect is connected to the engine's output using the effect's connect_to_endpoint() function. 
