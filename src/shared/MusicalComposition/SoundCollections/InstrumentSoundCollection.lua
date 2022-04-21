--[[
- Handles how all Sounds relevant to one instrument are stored (in some order which is typically ascending pitch order) and accessed
- Each Instance of this class is immutable making InstrumentSoundCollection.getCollectionFromName safe globally
]]

local MAX_SOUNDS_PER_COLLECTION = 61 -- 5 Full octaves + 1 extra key = 5*12 + 1 = 61

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OrderedPositionTable = require(ReplicatedStorage.MusicalComposition.OrderedPositionTable)
type OrderedPositionTable = OrderedPositionTable.OrderedPositionTable

local InstrumentSoundCollection = {}
InstrumentSoundCollection.__index = InstrumentSoundCollection

local _soundCollectionInstances = {}

--[[
- Ensure instrumentName is unique and hasn't been used yet
- soundInstances contains an array of all Sound Instances relevant to an instrument
- getPosOfSoundInOrderedTable determines the order that Sound Instances will be stored in 
  e.g. 
  function (sound) 
  	return sound:GetAttribute("PianoKeyNumber") 
  end 
  would store and allow access to Sounds in ascending piano key order
--]]
function InstrumentSoundCollection.new(instrumentName: string, soundInstances: {Sound}, getPosOfSoundInOrderedTable: (Sound) -> (number))
	local self = setmetatable({}, InstrumentSoundCollection)
	
	if instrumentName == nil then
		error('InstrumentSoundCollection.new: No instrumentName was specified')
	end
	if #soundInstances > MAX_SOUNDS_PER_COLLECTION then
		error('InstrumentSoundCollection.new: The following InstrumentSoundCollection has too many Sounds and failed to construct as a result: ' ..instrumentName)
	end
	if _soundCollectionInstances[instrumentName] ~= nil then -- Reuse cached instances of the same name
		warn('InstrumentSoundCollection.new: Returning cached instance as the following InstrumentSoundCollection already exists: ' ..instrumentName)
		return InstrumentSoundCollection.getCollectionFromName(instrumentName)
	end
	
	self.instrumentName = instrumentName -- Make sure you treat this as a readonly public property
	self.soundInstanceArray = soundInstances -- Make sure you treat this as a readonly public property
	self.orderingFunctionUsed = getPosOfSoundInOrderedTable -- Make sure you treat this as a readonly public property
	self.numSounds = #soundInstances -- Make sure you treat this as a readonly public property
	
	_soundCollectionInstances[instrumentName] = self
	
	-- Variables with an underscore prefix are private properties and should not be accessed outside this module
	self._orderedSounds = self:_buildOrderedSounds(soundInstances, getPosOfSoundInOrderedTable)

	return self
end

function InstrumentSoundCollection:_buildOrderedSounds(soundInstances: {Sound}, getPosOfSoundInOrderedTable: (Sound) -> (number))
	local orderedSounds = OrderedPositionTable.new()

	for soundInstanceIndex, sound in ipairs(soundInstances) do
		orderedSounds:insert(getPosOfSoundInOrderedTable(sound), soundInstanceIndex)
	end

	return orderedSounds
end

function InstrumentSoundCollection.getCollectionFromName(instrumentName: string)
	if _soundCollectionInstances[instrumentName] == nil then
		error('InstrumentSoundCollection.getCollectionFromName: The following InstrumentSoundCollection was not found: ' ..instrumentName)
	end
	return _soundCollectionInstances[instrumentName]
end

-- E.g. collection:getSoundInstance(1) would return the Sound Instance with lowest PianoKeyNumber if the collection was ordered by a 'PianoKeyNumber' number attribute
function InstrumentSoundCollection:getSoundInstance(instrumentSoundIndex: number): Sound
	local pos, soundInstanceIndex = self._orderedSounds:getPosValue(instrumentSoundIndex)
	return self.soundInstanceArray[soundInstanceIndex]
end

return InstrumentSoundCollection