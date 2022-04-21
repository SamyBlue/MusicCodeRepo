local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundEmitter = require(ReplicatedStorage.MusicalComposition.SoundEmitter)
local InstrumentTimeline = require(ReplicatedStorage.MusicalComposition.Timelines.InstrumentTimeline)
--TODO: Support Speed
local clock = os.clock

local InstrumentTimelinePlayer = {}
InstrumentTimelinePlayer.__index = InstrumentTimelinePlayer

function InstrumentTimelinePlayer.new(instrumentTimeline: InstrumentTimeline, soundParent: Instance)
	if instrumentTimeline._type ~= "InstrumentTimeline" then
		error('InstrumentTimelinePlayer.new failed as instrumentTimeline input was not a valid InstrumentTimeline')
	end
	
	local self = setmetatable({}, InstrumentTimelinePlayer)
	
	self.isPlaying = false -- Make sure you treat this as a readonly public property
	
	self._instrumentTimeline = instrumentTimeline
	self._soundParent = soundParent
	self._steppedConnection = nil
	
	return self
end

function InstrumentTimelinePlayer:_playSoundsTraversed(currentTime: number, fromIndex: number, fromTimePos: number)
	-- Plays all Sounds in the interval [fromTimePos, currentTime]
	-- Returns first index that has a time pos greater than currentTime & that time pos
	local timeline = self._instrumentTimeline
	local soundParent = self._soundParent
	
	-- Initialise
	local fromTimePos, currentSoundIndex = timeline:getPosValue(fromIndex)
	
	while (fromTimePos ~= nil) and (currentTime >= fromTimePos) do
		SoundEmitter.playEmit(timeline:getSoundInstance(currentSoundIndex), soundParent)
		
		fromIndex, fromTimePos, currentSoundIndex = timeline:nextIndexPosValue(fromIndex)
	end
	
	return fromIndex, fromTimePos
end

function InstrumentTimelinePlayer:play()
	if self.isPlaying == true then
		warn('InstrumentTimelinePlayer: Aborted play attempt as already playing!')
		return
	end
	
	self.isPlaying = true
	
	local nextIndexToPlay = self._instrumentTimeline.START_INDEX
	local nextTimePosToPlayAt = -1
	local startingTime = clock()
	
	self._steppedConnection = RunService.Stepped:Connect(function ()
		local timePassed = clock() - startingTime
		nextIndexToPlay, nextTimePosToPlayAt = self:_playSoundsTraversed(timePassed, nextIndexToPlay, nextTimePosToPlayAt)
		
		if nextTimePosToPlayAt == nil then
			self:stop()
		end
	end)
end

function InstrumentTimelinePlayer:stop()
	self.isPlaying = false
	
	if self._steppedConnection ~= nil then
		self._steppedConnection:Disconnect()
		self._steppedConnection = nil
	end
end

return InstrumentTimelinePlayer