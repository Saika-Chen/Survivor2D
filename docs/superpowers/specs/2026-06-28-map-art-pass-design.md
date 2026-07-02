# Map Art Pass Design

## Scope
Improve the large arena's visual identity with a dark sacrificial wasteland style. The map should read less like a grid and more like a finished 2D battlefield while staying procedural and lightweight.

## Static Map Art
`arena.gd` draws layered terrain: dark rock base, subtle large tile variation, cracks, blood stains, bone shards, rune circles, altar plates, and stronger edge fog/walls. These are deterministic procedural details, so no runtime asset downloads are required.

## Dynamic Map Decor
A lightweight `map_decor.gd` adds slow moving fog wisps, soul flames, and pulsing rune glows. The node redraws only a small set of decorative elements and avoids spawning many particles.

## Performance
Static terrain remains in `Arena._draw()` and does not call `queue_redraw()` every frame. Animated decor uses a small fixed list of elements and a low-cost draw pass.
