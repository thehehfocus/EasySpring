local Module = {}

type ResultTypes = number|Vector3|Vector2
type ValueTypes = ResultTypes | (Instance & {Position: ResultTypes})

local DefaultSpring = {
	Damping = 0.7,
	Stiffness = 1,
	Speed = 1,
}
export type SpringParams = typeof(DefaultSpring)

local SpringClass = {}
SpringClass.__index = SpringClass

export type Spring = setmetatable<{
	CurrentValue: ValueTypes,
	CurrentPos: ResultTypes,
	TargetValue: ResultTypes,
	Velocity: ResultTypes,
} & SpringParams, typeof(SpringClass)>

type CalculationParams = SpringParams & {
	Velocity: ResultTypes,
	AsOffset: boolean?,
}

local RunService = game:GetService("RunService")

function Module.CreateSpring(InitialValue: ValueTypes, Params: SpringParams) : Spring
	local Spring = setmetatable({
		CurrentValue = InitialValue,
		CurrentPos = InitialValue,
		TargetValue = InitialValue,
		Velocity = 0,
		
		Damping = DefaultSpring.Damping,
		Stiffness = DefaultSpring.Stiffness,
		Speed = DefaultSpring.Speed,
	}, SpringClass)
	
	local Type = typeof(InitialValue)
	if Type == "Instance" then
		Type = typeof(InitialValue.Position)
	end
	
	local Success = pcall(function()
		Spring.Velocity = InitialValue * 0
	end)
	if not Success then
		error("Unsupported value type for spring: " .. Type)
	end
	
	Spring.PositionType = Type
	
	if Params then
		for key, value in Params do
			Spring[key] = value
		end
	end
	
	return Spring
end

function Module.CalculateSpring(
	Origin: ValueTypes, 
	Target: ValueTypes, 
	dt: number,
	Params: CalculationParams
) : (ResultTypes, ResultTypes)
	if typeof(Origin) == "Instance" then
		Origin = Origin.Position
	end
	if typeof(Target) == "Instance" then
		Target = Target.Position
	end
	
	local Speed = Params.Speed or DefaultSpring.Speed
	local Stiffness = Params.Stiffness or DefaultSpring.Stiffness
	local Damping = Params.Damping or DefaultSpring.Damping
	local Velocity = Params.Velocity or 0
	
	local Delta = Target - Origin
	local DtSpeed = dt * Speed
	
	local Force = (Stiffness * Delta)
	local DampingForce = (Velocity * -Damping)
	local Acceleration = Force + DampingForce
	
	Velocity = Velocity + Acceleration * DtSpeed
	local ResultValue = Origin + Velocity * DtSpeed
	
	if Params.AsOffset then
		return ResultValue - Origin, Velocity
	else
		return ResultValue, Velocity
	end
end

function SpringClass.Start(self: Spring, Callback: (NewPos: ResultTypes, Velocity: ResultTypes) -> ()?)
	local Connection = RunService.Heartbeat:Connect(function(dt)
		self:Update(dt)
		if Callback then Callback(self.CurrentPos, self.Velocity) end
	end)
	
	return Connection
end

function SpringClass.Update(self: Spring, dt: number)
	local ResultValue, Velocity = Module.CalculateSpring(
		self.CurrentValue, 
		self.TargetValue, 
		dt,
		self
	)
	
	if typeof(self.CurrentValue) == "Instance" then
		self.CurrentValue.Position = ResultValue
	else
		self.CurrentValue = ResultValue
	end
	self.CurrentPos = ResultValue
	self.Velocity = Velocity
	
	return ResultValue
end

function SpringClass.SetTarget(self: Spring, Target: ValueTypes)
	self.TargetValue = Target
end

return Module
