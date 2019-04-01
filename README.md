# Super Simple 3D Engine v1.2

groverburger's Super Simple 3D Engine (SS3D) is my take on simplifying LÖVE 11's new 3D capabilities into a ready-to-use library for simple 3D games.

### Features:
- Built in first person camera controls
- Engine encapsulated into a single file
- Readable and commented code
- 2D rendering / HUD support
- Rotatable and translatable models
- UV mapping
- Backface culling (enabled on a per-model basis)
- Wireframe rendering (enabled on a per-model basis)
- Simple directional ambient lighting

### To Dos
- Phong lighting
- Obj file format import
- Simple collision handling
- Detailed wiki

### Installation
Drag the engine.lua file into your project directory to install. SS3D does require CPML, which can be found [here](https://github.com/excessive/cpml). I've included the latest version of CPML which I have confirmed works without problems in this repository.

### Basic Usage
Import a reference to the engine before love.load.
```lua
Engine = require "engine"
```
In love.load create a new Scene object to start using 3D.
The two arguments refer to the output width and height in pixels of the Scene's camera.
It's also recommended to set the mouse's relative mode to true, especially for first-person cameras.
```lua
love.mouse.setRelativeMode(true)
Scene = Engine.newScene(love.graphics.getWidth(), love.graphics.getHeight())
```
