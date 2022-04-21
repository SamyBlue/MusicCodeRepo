--!strict

--[[
- Data structure of several (position, value) pairs which are ordered in ascending order of position 
- Can insert multiple values at the same position (important for playing multiple notes at the same time i.e. musical chords)
- Will be used to maintain order in which notes are played as well as store instrument sounds in ascending order of pitch
]]

local EQUALITY_THRESHOLD = 0.001

local OrderedPositionTable = {}
OrderedPositionTable.__index = OrderedPositionTable

export type SerializedOrderedPositionTable<ValuesType> = {
	_positions: {number},
	_values: {ValuesType}
}

export type OrderedPositionTable = typeof(setmetatable({} :: SerializedOrderedPositionTable<any>, OrderedPositionTable))

function OrderedPositionTable.new(): OrderedPositionTable
	local self = setmetatable({}, OrderedPositionTable)

	self._positions = {}
	self._values = {}

	self.START_INDEX = 1 -- Make sure you treat this as a readonly public property

	return self
end

-- Create new instance with supplied input data
-- Use in combination with OrderedPositionTable:serialize()
function OrderedPositionTable.deserialize(data: SerializedOrderedPositionTable<any>): OrderedPositionTable
	data["START_INDEX"] = 1
	return setmetatable(data, OrderedPositionTable)
end

function OrderedPositionTable:_getInsertIndex(position: number): number
	-- Binary Search to find correct index to insert at that maintains ascending order of self._positions
	local iStart, iEnd, iMid, iState = 1, #self._positions, 1, 0

	while iStart <= iEnd do
		-- Calculate middle index
		iMid = math.floor( (iStart + iEnd) / 2 )
		-- Compare
		if position < self._positions[iMid] then
			iEnd, iState = iMid - 1, 0
		else
			iStart, iState = iMid + 1, 1
		end
	end

	return iMid + iState
end

function OrderedPositionTable:_positionsAreEqual(position1: number, position2: number): boolean
	if type(position1) ~= 'number' or type(position2) ~= 'number' then
		return false
	end
	return math.abs(position2 - position1) < EQUALITY_THRESHOLD
end

function OrderedPositionTable:insert(position: number, value): number
	local insertIndex = self:_getInsertIndex(position)
	
	-- Insert at same positions
	table.insert(self._positions, insertIndex, position)
	table.insert(self._values, insertIndex, value)
	
	return insertIndex
end

function OrderedPositionTable:delete(position: number, value)
	local insertIndex = self:_getInsertIndex(position) :: number
	
	-- Check surrounding positions for equality
	local indexToCheck = insertIndex - 1
	while self:_positionsAreEqual(self._positions[indexToCheck], position) do
		if self._values[indexToCheck] == value then
			table.remove(self._positions, indexToCheck)
			table.remove(self._values, indexToCheck)
			return
		end
		indexToCheck = indexToCheck - 1
	end
	
	warn("OrderedPositionTable:delete failed as following (position, value) pair was not found:", position, value)
	return error("OrderedPositionTable:delete failed")
end

function OrderedPositionTable:getPosValue(index: number): (number?, any?)
	return self._positions[index], self._values[index]
end

function OrderedPositionTable:getLength(): number
	return #self._positions
end

function OrderedPositionTable:getLastPosValue(): (number?, any?)
	return self._positions[self:getLength()], self._values[self:getLength()]
end

function OrderedPositionTable:nextIndexPosValue(index: number): (number?, number?, any?) --returns next index, position, value triplet (behaves like the global next() function)
	index = index + 1
	local position, value = self._positions[index], self._values[index]
	if position then
		return index, position, value
	end
	return nil, nil, nil
end

function OrderedPositionTable:prevIndexPosValue(index: number): (number?, number?, any?) --returns previous index, pos, value triplet
	index = index - 1
	local position, value = self._positions[index], self._values[index]
	if position then
		return index, position, value
	end
	return nil, nil, nil
end

function OrderedPositionTable:pairsIterator(initialIndex: number?) --specifying initialIndex is optional. Usage e.g. for index, pos, value in object:pairsIterator() do
	local controlIndex = initialIndex or self.START_INDEX
	
	return self.nextIndexPosValue, self, controlIndex - 1 -- Lua requires control variable to be one behind if want to include initialIndex iteration
end

local function shallowCopy<T>(input: {T}): {T}
	local copy = {}
	for orig_key, orig_value in pairs(input) do
		copy[orig_key] = orig_value
	end
	return copy
end

-- Use the following method in combination with OrderedPositionTable.deserialize(data) to store data in datastores or send over remote events
-- Returns the data in a format suitable for storage in datastores or for sending over remote events
function OrderedPositionTable:serialize(): SerializedOrderedPositionTable<any>
	return {
		_positions = table.clone(self._positions),
		_values = table.clone(self._values)
	}
end

return OrderedPositionTable