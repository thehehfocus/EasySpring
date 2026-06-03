const Module = {}

--== Config ==--
const Iterations = 1
const DefaultSpring = {
	Damping = 0.8,
	Force = 4,
	Speed = 1,
	Mass = 1,
	Velocity = 0 :: Types,
}

--== Services ==--
const RunService = game:GetService("RunService")

--== Types ==--
type Types = number|Vector3|Vector2

export type SpringParams = typeof(DefaultSpring)

const SpringClass = {}
SpringClass.__index = SpringClass

export type Spring<T = Types> = {
	Value: T,
	Target: T,

	Properties: {
		Velocity: T,
		Mass: number,
		Damping: number,
		Force: number,
		Speed: number,
	},
	BoundInstance: (Instance & { Position: Types })?,

	Start: (self: Spring<T>, Callback: (Spring: Spring, dt: number) -> ()?) -> RBXScriptConnection,
	Update: (self: Spring<T>, dt: number) -> T,
	Shove: (self: Spring<T>, Velocity: T) -> (),
	SetTarget: (self: Spring<T>, Target: T) -> (),
}

--== Main ==--
function Module.CreateSpring(InitialValue: Types|(Instance&{Position: Types}), Params: SpringParams?) : Spring
	Params = Params or {}

	local Spring = setmetatable({
		Value = InitialValue,
		Target = nil,

		Properties = {
			Velocity = 0,
			Mass = Params.Mass or DefaultSpring.Mass,
			Damping = Params.Damping or DefaultSpring.Damping,
			Force = Params.Force or DefaultSpring.Force,
			Speed = Params.Speed or DefaultSpring.Speed,
		}
	}, SpringClass)

	local Type = typeof(InitialValue)
	local Success = pcall(function()
		if Type == "Instance" then
			Spring.BoundInstance = InitialValue
			Spring.Value = InitialValue.Position
			Spring.Properties.Velocity = Spring.Value * 0
		else
			Spring.Properties.Velocity = InitialValue * 0
		end
	end)
	if not Success then
		error("Unsupported value type for spring: " .. Type)
	end

	return Spring
end

function Module.CalculateSpring(
	Origin: Types, 
	Target: Types, 
	dt: number,
	Params: SpringParams & { Velocity: Types }
) : (Types, Types)
	Params = Params or {}

	local Speed = Params.Speed or DefaultSpring.Speed
	local Force = Params.Force or DefaultSpring.Force
	local Damping = Params.Damping or DefaultSpring.Damping
	local Mass = Params.Mass or DefaultSpring.Mass
	local Velocity = Params.Velocity or Origin * 0

	local Delta = Target - Origin
	local DtSpeed = dt * Speed

	local Force = (Delta * Force) / Mass
	local DampingForce = (Velocity * -Damping)
	local Acceleration = (Force + DampingForce)

	Velocity = Velocity + Acceleration * DtSpeed
	local ResultValue = Origin + Velocity * DtSpeed

	return ResultValue, Velocity
end

function SpringClass.Start(self: Spring, Callback: (Spring: Spring, dt: number) -> ()?)
	local Connection = RunService.Heartbeat:Connect(function(dt)
		self:Update(dt)
		if Callback then Callback(self, dt) end
	end)

	return Connection
end

function SpringClass.Update(self: Spring, dt: number)
	if self.BoundInstance then
		self.Value = self.BoundInstance.Position
	end

	local ScaledDt = dt / Iterations

	local ResultValue, Velocity
	for i=1, Iterations do
		ResultValue, Velocity = Module.CalculateSpring(
			self.Value, 
			self.Target, 
			ScaledDt,
			self.Properties
		)

		if self.BoundInstance then
			self.BoundInstance.Position = ResultValue
		else
			self.Value = ResultValue
		end
		self.Properties.Velocity = Velocity
	end

	return ResultValue
end

function SpringClass.Shove(self: Spring, Force: Types)
	if math.isinf(Force) or math.isnan(Force) then
		return
	end

	self.Properties.Velocity += Force
end

function SpringClass.SetTarget(self: Spring, Target: Types)
	self.Target = Target
end

return Module
