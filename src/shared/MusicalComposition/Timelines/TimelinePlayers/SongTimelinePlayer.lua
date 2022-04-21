local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OrderedPositionTable = require(ReplicatedStorage.MusicalComposition.OrderedPositionTable)
local InstrumentTimelinePlayer = require(ReplicatedStorage.MusicalComposition.Timelines.TimelinePlayers.InstrumentTimelinePlayer)
local SongTimeline = require(ReplicatedStorage.MusicalComposition.Timelines.SongTimeline)
--TODO: Support Speed
local clock = os.clock

local SongTimelinePlayer = {}
SongTimelinePlayer.__index = SongTimelinePlayer

function SongTimelinePlayer.new(songTimeline: SongTimeline, soundParent: Instance)
	if songTimeline._type ~= "SongTimeline" then
		error('SongTimelinePlayer.new failed as songTimeline input was not a valid SongTimeline')
	end
	
	local self = setmetatable({}, SongTimelinePlayer)

	self.isPlaying = false -- Make sure you treat this as a readonly public property

	self._songTimeline = songTimeline
	self._soundParent = soundParent
	self._steppedConnection = nil
	self._instrumentPlayers = OrderedPositionTable.new()
	self._bindableEvent = nil

	return self
end

function SongTimelinePlayer:getTimeLength()
	local lastTimePos, lastInstrTimeline = self._songTimeline:getLastPosValue()
	local lastInstrTimelineLength = lastInstrTimeline:getLastPosValue()
	if lastTimePos ~= nil then
		return lastTimePos + lastInstrTimelineLength
	end
	return 0
end

function SongTimelinePlayer:_stopAllInstruments()
	for index, timePos, instrumentPlayer in self._instrumentPlayers:pairsIterator() do
		instrumentPlayer:stop()
	end
	self._instrumentPlayers = OrderedPositionTable.new() -- Safest to reset right after stopping all instruments
end

function SongTimelinePlayer:_getNewInstrumentPlayers()
	self:_stopAllInstruments() -- Want to reset self._instrumentPlayers
	
	for index, timePos, instrumentTimeline in self._songTimeline:pairsIterator() do
		self._instrumentPlayers:insert(timePos, InstrumentTimelinePlayer.new(instrumentTimeline, self._soundParent))
	end 
	
	return self._instrumentPlayers
end

function SongTimelinePlayer:_playInstrumentPlayersTraversed(currentTime: number, fromIndex: number, fromTimePos: number) 
	-- Plays all InstrumentTimelinePlayers in the interval [fromTimePos, currentTime]
	-- Returns first index that has a time pos greater than currentTime & that time pos
	local players = self._instrumentPlayers

	-- Initialise
	local fromTimePos, currentPlayer = players:getPosValue(fromIndex)

	while (fromTimePos ~= nil) and (currentTime >= fromTimePos) do
		currentPlayer:play()

		fromIndex, fromTimePos, currentPlayer = players:nextIndexPosValue(fromIndex)
	end

	return fromIndex, fromTimePos
end

function SongTimelinePlayer:play()
	if self.isPlaying == true then
		warn('SongTimelinePlayer: Aborted play attempt as already playing!')
		return
	end
	
	self.isPlaying = true
	
	local players = self:_getNewInstrumentPlayers()
	local songTimeLength = self:getTimeLength() + 0.5 -- Add 0.5 to allow time to play final notes
	local nextIndexToPlay = players.START_INDEX
	local nextTimePosToPlayAt = -1
	local startingTime = clock()

	self._steppedConnection = RunService.Stepped:Connect(function ()
		local timePassed = clock() - startingTime
		
		if timePassed > songTimeLength then
			self:stop()
		end
		
		nextIndexToPlay, nextTimePosToPlayAt = self:_playInstrumentPlayersTraversed(timePassed, nextIndexToPlay, nextTimePosToPlayAt)
	end)
end

function SongTimelinePlayer:stop()
	self.isPlaying = false
	self:_stopAllInstruments()

	if self._steppedConnection ~= nil then
		self._steppedConnection:Disconnect()
		self._steppedConnection = nil
	end
	
	if self._bindableEvent ~= nil then
		self._bindableEvent:Fire()
	end
end

-- If want to do something like:
-- song:playYieldUntilStopped()
-- UI.PlayButton.Visible = true -- i.e. Wait until stopped playing to make play button visible again
function SongTimelinePlayer:playYieldUntilStopped()
	if self.isPlaying == true then
		warn('SongTimelinePlayer: Aborted playYieldUntilStopped attempt as already playing!')
		return
	end
	
	self._bindableEvent = Instance.new("BindableEvent")
	self:play()
	self._bindableEvent.Event:Wait()
	self._bindableEvent:Destroy()
end

return SongTimelinePlayer