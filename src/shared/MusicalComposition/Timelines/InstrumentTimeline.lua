--[[
- Inherits from OrderedPositionTable so has all of the same methods + additional ones below
- Stores timings of Sounds (for a chosen InstrumentSoundCollection) to be played
- Usually a short motif on that instrument https://en.wikipedia.org/wiki/Motif_(music)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OrderedPositionTable = require(ReplicatedStorage.MusicalComposition.OrderedPositionTable)
local InstrumentSoundCollection = require(ReplicatedStorage.MusicalComposition.SoundCollections.InstrumentSoundCollection)

local InstrumentTimeline = setmetatable({}, OrderedPositionTable) -- Inherits from OrderedPositionTable so has all of the same methods + additional ones below
InstrumentTimeline.__index = InstrumentTimeline

-- E.g. local newSection = InstrumentTimeline.new(InstrumentSoundCollection.getCollectionFromName("Piano"))
function InstrumentTimeline.new(instrumentSoundCollection: InstrumentSoundCollection)
	local self = setmetatable(OrderedPositionTable.new(), InstrumentTimeline)
	
	self._soundCollection = instrumentSoundCollection
	self._type = "InstrumentTimeline"
	self.instrumentName = self._soundCollection.instrumentName -- Make sure you treat this as a readonly public property
	
	return self
end

-- Create new instance with supplied input data
-- Use in combination with InstrumentTimeline:serialize()
function InstrumentTimeline.deserialize(data) --TODO: Fix deserialization as InstrumentSoundScaleCollection or InstrumentSoundCollection might not exist (yet)
	data = OrderedPositionTable.deserialize(data)
	data._soundCollection = InstrumentSoundCollection.getCollectionFromName(data.instrumentName)
	data._type = "InstrumentTimeline"
	return setmetatable(data, InstrumentTimeline)
end

-- Insert notes / sounds into this InstrumentTimeline
-- instrumentSoundIndex 1 corresponds to lowest key sound, instrumentSoundIndex 2 corresponds to the key sound that comes next, etc. ...
function InstrumentTimeline:insert(timePos: number, instrumentSoundIndex: number): number
	if not (1 <= instrumentSoundIndex and instrumentSoundIndex <= self._soundCollection.numSounds) then
		warn("InstrumentTimeline:insert failed as following instrumentSoundIndex is out of range:", instrumentSoundIndex)
		return error("InstrumentTimeline:insert failed")
	end
	
	local insertIndex = OrderedPositionTable.insert(self, timePos, instrumentSoundIndex)
	
	return insertIndex
end

function InstrumentTimeline:delete(timePos: number, instrumentSoundIndex: number)
	OrderedPositionTable.delete(self, timePos, instrumentSoundIndex)
end

function InstrumentTimeline:getSoundInstance(instrumentSoundIndex: number): Sound
	return self._soundCollection:getSoundInstance(instrumentSoundIndex)
end

-- Ideal for transposing musical scales whilst keeping melody and rhythm the same
function InstrumentTimeline:changeSoundCollection(newInstrumentSoundCollection)
	if self._soundCollection.numSounds ~= newInstrumentSoundCollection.numSounds then
		error('InstrumentTimeline:changeSoundCollection failed as newInstrumentSoundCollection should have the same number of sounds as the current sound collection (for data consistency)')
	end
	self._soundCollection = newInstrumentSoundCollection
	self.instrumentName = newInstrumentSoundCollection.instrumentName
end

-- Use the following method in combination with InstrumentTimeline.deserialize(data) to store data in datastores or send over remote events
-- Returns the data in a format suitable for storage in datastores or for sending over remote events
function InstrumentTimeline:serialize()
	local serializedOrderedPosTab = OrderedPositionTable.serialize(self)
	serializedOrderedPosTab["instrumentName"] = self.instrumentName
	
	return serializedOrderedPosTab
end

return InstrumentTimeline