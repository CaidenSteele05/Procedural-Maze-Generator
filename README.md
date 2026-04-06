# Procedural-Maze-Generator
Roblox procedural maze generator that builds tile-based 3D mazes with configurable size, height, and recursive expansion.

This project is a Roblox maze generation system that builds a 3D maze from tile connections and automatically generates the walls and floor parts needed to represent the final layout. The maze expands outward from a starting tile by recursively creating neighboring tiles and opening or closing paths in the four cardinal directions.
The generator supports configurable map settings such as maze size limit, tile size, and wall height, and it can rebuild the maze dynamically through a remote event. Once the tile connectivity is finalized, the system converts the stored grid data into physical parts in the workspace to form a playable 3D maze.
This project demonstrates procedural generation, grid-based map construction, recursive expansion logic, configurable world generation, and automated geometry creation in Roblox.
