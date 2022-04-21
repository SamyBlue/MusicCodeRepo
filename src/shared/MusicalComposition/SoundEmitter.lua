--[[
Takes a Sound as input and then:

- Plays Sound without resetting TimePosition on each Play() (so can overlap the audio of another play() if it is already playing)

]]


local SoundEmitter = {}

function SoundEmitter.playEmit(sound: Sound, parent: Instance)
	local StartTimePos, EndTimePos = sound:GetAttribute("StartTimePos"), sound:GetAttribute("EndTimePos")
	
	if StartTimePos and EndTimePos then
		
		local clone = sound:Clone()
		clone.Parent = parent
		clone.TimePosition = StartTimePos
		
		clone:Play()
		
		task.delay(EndTimePos - StartTimePos, function ()
			clone:Stop()
			clone:Destroy()
		end)
		
	else
		
		warn('SoundEmitter: The following Sound has no StartTimePos or EndTimePos Attribute and was not played: ', sound:GetFullName())
		
	end
end

return SoundEmitter