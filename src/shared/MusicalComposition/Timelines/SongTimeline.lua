--[[
- Inherits from OrderedPositionTable so has all of the same methods + additional ones below
- Stores timings of multiple InstrumentTimelines within a single Song
- Can also change speed of song with SongTimeline:changeSpeed() which gets used by SongTimelinePlayer
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OrderedPositionTable = require(ReplicatedStorage.MusicalComposition.OrderedPositionTable)
local InstrumentTimeline = require(ReplicatedStorage.MusicalComposition.Timelines.InstrumentTimeline)

local SongTimeline = setmetatable({}, OrderedPositionTable) -- Inherits from OrderedPositionTable so has all of the same methods + additional ones below
SongTimeline.__index = SongTimeline

local MIN_SONG_SPEED = 0.25
local MAX_SONG_SPEED = 3 -- Don't set higher as roblox is capped at 60fps meaning music playing too fast will sound offbeat

function SongTimeline.new()
	local self = setmetatable(OrderedPositionTable.new(), SongTimeline)
	
	local musicKeys = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
	
	self.speedMultiplier = 1 -- Make sure you treat this as a readonly public property. Use SongTimeline:changeSpeed() to change.
	self.mainScaleKey = musicKeys[math.random(1, #musicKeys)] -- Random starting scale key to encourage users who don't change scale property to change key for different songs
	self.mainScaleType = "MAJOR" -- Default scale type
	self._type = "SongTimeline"
	
	return self
end

-- Create new instance with supplied input data
-- Use in combination with SongTimeline:serialize()
function SongTimeline.deserialize(data)
	data = OrderedPositionTable.deserialize(data)
	data._type = "SongTimeline"
	
	for i, serializedInstrumentTimeline in pairs(data._values) do
		data._values[i] = InstrumentTimeline.deserialize(serializedInstrumentTimeline)
	end
	
	return setmetatable(data, SongTimeline)
end

function SongTimeline:changeSpeed(newSpeed: number)
	if not (MIN_SONG_SPEED <= newSpeed and newSpeed <= MAX_SONG_SPEED) then
		newSpeed = math.clamp(newSpeed, MIN_SONG_SPEED, MAX_SONG_SPEED)
		warn('SongTimeline:changeSpeed: The speed ' ..tostring(newSpeed) ..' was clamped as it is less than MIN_SONG_SPEED or more than MAX_SONG_SPEED')
	end
	
	self.speedMultiplier = newSpeed
end

function SongTimeline:insert(timePos: number, instrumentTimeline: InstrumentTimeline): number
	if instrumentTimeline._type ~= "InstrumentTimeline" then
		error('SongTimeline:insert failed as instrumentTimeline input was not a valid InstrumentTimeline')
	end
	for _, _, internalInstrTimeline in self:pairsIterator() do
		if instrumentTimeline == internalInstrTimeline then -- Could change to warn() as this is sort of safe & allowed but erroring is safer
			error('SongTimeline:insert failed as your input instrumentTimeline was already found inside this SongTimeline')
		end
	end
	
	local insertIndex = OrderedPositionTable.insert(self, timePos, instrumentTimeline)

	return insertIndex
end

function SongTimeline:delete(timePos: number, instrumentTimeline: InstrumentTimeline)
	OrderedPositionTable.delete(self, timePos, instrumentTimeline)
end

-- Use the following method in combination with SongTimeline.deserialize(data) to store data in datastores or send over remote events
-- Returns the data in a format suitable for storage in datastores or for sending over remote events
function SongTimeline:serialize()
	local serializedOrderedPosTab = OrderedPositionTable.serialize(self)
	
	serializedOrderedPosTab["speedMultiplier"] = self.speedMultiplier
	serializedOrderedPosTab["mainScaleKey"] = self.mainScaleKey
	serializedOrderedPosTab["mainScaleType"] = self.mainScaleType
	
	serializedOrderedPosTab._values = {}
	for i, instrumentTimeline in pairs(self._values) do
		serializedOrderedPosTab._values[i] = instrumentTimeline:serialize()
	end

	return serializedOrderedPosTab
end

return SongTimeline