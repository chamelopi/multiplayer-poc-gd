# Multiplayer PoC

Just trying out Godot 4.1 multiplayer functionality (scene replication)

## Sources

- https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html
- https://godotengine.org/article/multiplayer-in-godot-4-0-scene-replication/
- https://gist.github.com/Meshiest/1274c6e2e68960a409698cf75326d4f6

## TODOs

- Figure out why we can't synchronize the velocity / any other custom property with the MultiplayerSynchronizer
- Handle disconnect of client correctly on server side
- Add selection + movement functionality (?) for each player
