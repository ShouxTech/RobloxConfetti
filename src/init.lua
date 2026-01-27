--!strict
local TweenService = game:GetService('TweenService');
local Players = game:GetService('Players');

type Particle = {
	Instance: Frame,
	Velocity: Vector2,
	RotSpeed: number,
};

local localPlayer = Players.LocalPlayer;
local playerGui = localPlayer.PlayerGui;

local activeParticles: { Particle } = {};

local CONFETTI_GUI_NAME = 'Confetti';
local CONFETTI_SHAPES = {'Square', 'Circle', 'Rectangle'};
local GRAVITY = 1;
local DEFAULT_EMIT_AMOUNT = 250;
local BASE_COLORS = {
	Color3.fromRGB(255, 75, 75),
	Color3.fromRGB(75, 255, 75),
	Color3.fromRGB(75, 75, 255),
	Color3.fromRGB(255, 255, 75),
	Color3.fromRGB(255, 75, 255),
	Color3.fromRGB(75, 255, 255)
};

local function swapRemove(tbl: { any }, index: number)
	if index <= 0 then return; end;

	local lastIndex = #tbl;
	if index > lastIndex then return; end;

	tbl[index] = tbl[lastIndex];
	tbl[lastIndex] = nil;
end;

local function createConfettiPiece()
	local shapeType = CONFETTI_SHAPES[math.random(#CONFETTI_SHAPES)];

	local piece = Instance.new('Frame');
	piece.Name = 'ConfettiPiece';
	if shapeType == 'Square' then
		local size = math.random(24, 36);
		piece.Size = UDim2.new(0, size, 0, size);
	elseif shapeType == 'Rectangle' then
		piece.Size = UDim2.fromOffset(math.random(28, 38), math.random(18, 28));
	end;
	piece.Position = UDim2.fromScale(math.random(0, 100) / 100, math.random(-25, 125) / 100);
	piece.BackgroundTransparency = 1;
	piece.BorderSizePixel = 0;
	piece.AnchorPoint = Vector2.new(0.5, 0.5);

	local baseColor = BASE_COLORS[math.random(#BASE_COLORS)];
	local brightnessFactor = math.random(95, 105) / 100;
	piece.BackgroundColor3 = Color3.new(
		math.clamp(baseColor.R * brightnessFactor, 0, 1),
		math.clamp(baseColor.G * brightnessFactor, 0, 1),
		math.clamp(baseColor.B * brightnessFactor, 0, 1)
	);

	local uiGradient = Instance.new('UIGradient');
	uiGradient.Rotation = math.random(0, 360);
	uiGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(math.random(75, 100) / 100, math.random(75, 100) / 100, math.random(75, 100) / 100)),
		ColorSequenceKeypoint.new(1, Color3.new(math.random(75, 100) / 100, math.random(75, 100) / 100, math.random(75, 100) / 100))
	};
	uiGradient.Parent = piece;

	local uiCorner = Instance.new('UICorner');
	if shapeType == 'Circle' then
		uiCorner.CornerRadius = UDim.new(1, 0);
	end;
	uiCorner.Parent = piece;

	TweenService:Create(piece, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {BackgroundTransparency = 0}):Play();

	return piece;
end;

local function updateStep(dt: number)
	for i = #activeParticles, 1, -1 do
		local particle = activeParticles[i];

		particle.Velocity = Vector2.new(particle.Velocity.X, particle.Velocity.Y + (GRAVITY * dt));

		local currentPos = particle.Instance.Position;
		local newX = currentPos.X.Scale + (particle.Velocity.X * dt);
		local newY = currentPos.Y.Scale + (particle.Velocity.Y * dt);

		particle.Instance.Position = UDim2.new(newX, 0, newY, 0);

		particle.Instance.Rotation = particle.Instance.Rotation + (particle.RotSpeed * dt);

		if newY > 1.2 then
			swapRemove(activeParticles, i);
			particle.Instance:Destroy();
		end;
	end;
end;

local Confetti = {};

function Confetti:emit(amount: number?)
	amount = if typeof(amount) == 'number' then amount else DEFAULT_EMIT_AMOUNT;

	local screenGui = playerGui:FindFirstChild(CONFETTI_GUI_NAME);
	if not screenGui then
		screenGui = Instance.new('ScreenGui');
		screenGui.Name = CONFETTI_GUI_NAME;
		screenGui.IgnoreGuiInset = true;
		screenGui.ResetOnSpawn = false;
		screenGui.Parent = playerGui;
	end;
	
	local doSimulation = #activeParticles == 0;

	for _ = 1, amount do
		local piece = createConfettiPiece();
		piece.Parent = screenGui;

		table.insert(activeParticles, {
			Instance = piece,
			Velocity = Vector2.new(math.random(-300, 300) / 400, math.random(-350, -200) / 400),
			RotSpeed = math.random(-300, 300),
		});
	end;
	
	if doSimulation then
		task.spawn(function()
			while #activeParticles > 0 do
				updateStep(task.wait());
			end;
			screenGui:Destroy();
		end);
	end;
end;

return Confetti;