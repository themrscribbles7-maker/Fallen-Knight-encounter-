# Fallen Knight Encounter

Initial Godot battle presentation for the custom boss encounter.

The scene is configured for a 1280x720 viewport and automatically reconstructs the two idle animations from numbered PNG files anywhere under `res://`:

- `Parralexs Idle 1`, `Parralexs Idle 2`, ... → looping `idle` animation on the left
- `Knight Idle 1`, `Knight Idle 2`, ... → looping `idle` animation on the right

Frames are sorted by their trailing number and played at 17 FPS. The source PNGs remain individual assets; they are only assembled into runtime `SpriteFrames`, not duplicated or treated as separate gameplay objects.

## Run

1. Open the repository folder in Godot 4.
2. Import the project.
3. Run `Main.tscn` (or press F6/F5).

If an animation does not appear, check that the filename begins with the expected prefix and ends with a number before `.png`. The loader searches recursively, so assets may remain in their existing folders.

Next implementation step: add the custom Parralexs UI and Battle Manager without changing the asset-loading approach.
