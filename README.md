# EasySpring
Small dynamic spring module.

## Installation
Just copy Spring.luau.

## Usage

Using Part(or instance with valid position types):
```lua
local Spring = require(script.Parent.Spring)

local Part = Instance.new("Part")
Part.Position = Vector3.new(0,0,0)
Part.Anchored = true
Part.Parent = workspace

task.wait(1)

local NewSpring = Spring.CreateSpring(
	Part,
	{ Damping = 0.5, Stiffness = 1, Speed = 3 }
)

NewSpring:Start(function(NewPosition, Velocity)
	
end)

NewSpring:SetTarget(Vector3.new(5,5,5))
```

Using any of the position types:
```lua
local Spring = require(script.Parent.Spring)

local Part = Instance.new("Part")
Part.Position = Vector3.new(0,0,0)
Part.Anchored = true
Part.Parent = workspace

task.wait(1)

local NewSpring = Spring.CreateSpring(
	0,
	{ Damping = 0.5, Stiffness = 1, Speed = 3 }
)

NewSpring:Start(function(NewPosition, Velocity)
	Part.Position = Vector3.new(
    Part.Position.X,
    NewPosition,
    Part.Position.Z
  )
end)

NewSpring:SetTarget(10)
```

You can also calculate it without creating a spring, using .CalculateSpring:
```lua
local Spring = require(path.to.Spring)
Spring.CalculateSpring(
  Origin: ValueTypes,
  Target: ValueTypes,
  dt: number,
  Params: SpringParams & {Velocity: ResultTypes, AsOffset: boolean?}
)
```
