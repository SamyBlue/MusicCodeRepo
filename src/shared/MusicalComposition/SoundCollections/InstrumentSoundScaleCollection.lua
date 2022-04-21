--[[
- Inherits from InstrumentSoundCollection so has all of the same methods
- This is used to restrict instrument sounds to specific musical scales (for non-percussion instruments)
- Works well in combination with 
- InstrumentTimeline:changeSoundCollection
]] 

local SOUNDS_PER_SCALE_COLLECTION = 29 -- 4 Scale octaves + 1 extra key = 4*7 + 1 = 29 keys per scale

local MUSICAL_SCALE_DATA = {
	["MAJOR"] = {1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1},
	["MINOR"] = {1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0},
	["MAJOR BLUES"] = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
	["MINOR BLUES"] = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
	["CHROMATIC"] = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
}

local MUSICAL_KEY_ENUMS = {
	["C"] = 1,
	["C#"] = 2,
	["D"] = 3,
	["D#"] = 4,
	["E"] = 5,
	["F"] = 6,
	["F#"] = 7,
	["G"] = 8,
	["G#"] = 9,
	["A"] = 10,
	["A#"] = 11,
	["B"] = 12,
}

-- Check that truth tables within MUSICAL_SCALE_DATA are all length 12
for _, scaleTable in pairs(MUSICAL_SCALE_DATA) do
	if #scaleTable ~= 12 then
		error('InstrumentSoundScaleCollection Critical Error: Musical Scale Data contains a musical scale array that is not of length 12')
	end
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InstrumentSoundCollection = require(ReplicatedStorage.MusicalComposition.SoundCollections.InstrumentSoundCollection)

local InstrumentSoundScaleCollection = setmetatable({}, InstrumentSoundCollection)
InstrumentSoundScaleCollection.__index = InstrumentSoundScaleCollection

function InstrumentSoundScaleCollection.new(instrumentSoundCollection, scaleKey: string, scaleType: string)
	scaleKey = string.upper(scaleKey)
	scaleType = string.upper(scaleType)
	
	if (not MUSICAL_KEY_ENUMS[scaleKey]) or (not MUSICAL_SCALE_DATA[scaleType]) then
		error('InstrumentSoundScaleCollection.new: Invalid scaleKey or invalid scaleType')
	end
	if instrumentSoundCollection.numSounds ~= 61 then
		error('InstrumentSoundScaleCollection.new: instrumentSoundCollection input must have exactly 61 sounds')
	end
	
	local instrumentName = instrumentSoundCollection.instrumentName .. "_" .. scaleKey .. "_" .. scaleType
	local soundInstances = InstrumentSoundScaleCollection._getSoundsInMusicalScale(instrumentSoundCollection, scaleKey, scaleType)
	local orderingFunction = instrumentSoundCollection.orderingFunctionUsed
	
	if #soundInstances ~= SOUNDS_PER_SCALE_COLLECTION then
		error('InstrumentSoundScaleCollection.new: The following InstrumentSoundScaleCollection failed to have exactly 29 Sounds: ' ..instrumentName)
	end
		
	local self = setmetatable(InstrumentSoundCollection.new(instrumentName, soundInstances, orderingFunction), InstrumentSoundScaleCollection)
	
	self.usedInstrumentName = InstrumentSoundCollection.instrumentName
	self.scaleKey = scaleKey
	self.scaleType = scaleType

	return self
end

function InstrumentSoundScaleCollection._getSoundsInMusicalScale(instrumentSoundCollection, scaleKey: string, scaleType: string)
	local filteredSoundInstances = {}
	local keyNumber = MUSICAL_KEY_ENUMS[scaleKey] - 1
	local scaleArray = MUSICAL_SCALE_DATA[scaleType]
	
	for i = 1 + keyNumber, 61 - 12 + keyNumber do
		if #filteredSoundInstances >= SOUNDS_PER_SCALE_COLLECTION then
			break
		end
		
		local currKey = (i - 1 - keyNumber) % 12 + 1
		if scaleArray[currKey] == 1 then -- See if in scale
			local soundInstance = instrumentSoundCollection:getSoundInstance(i)
			table.insert(filteredSoundInstances, soundInstance)
		end
	end
	
	return filteredSoundInstances
end

return InstrumentSoundScaleCollection
