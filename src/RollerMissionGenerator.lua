RollerMissionGenerator = {}

function RollerMissionGenerator:generateMissions(dt)
    local numActionsLeft = MissionManager.MAX_TRIES_PER_GENERATION
	local numMissionsLeft = MissionManager.MAX_MISSIONS_PER_GENERATION
	local indices = {}

	for i = 1, #g_fieldManager.fields do
		table.insert(indices, i)
	end

	Utils.shuffle(indices)

	for _, index in ipairs(indices) do
        local field = g_fieldManager.fields[index]

        if field.fieldMissionAllowed then
            local fieldSpraySet, sprayFactor, fieldPlowFactor, limeFactor, weedFactor, maxWeedState, stubbleFactor, rollerFactor = self:getFieldData(field)
            local canRun, fieldState, growthState, weedState, args = RollerMission.canRunOnField(field, sprayFactor, fieldSpraySet, fieldPlowFactor, limeFactor, maxWeedState, stubbleFactor, rollerFactor)

            if canRun then
                local mission = RollerMission.new(true, g_client ~= nil)
                mission.type = "roll"

                if mission:init(field, sprayFactor, fieldSpraySet, fieldPlowFactor, fieldState, growthState, limeFactor, weedFactor, weedState, stubbleFactor, rollerFactor, args) then
                    self:assignGenerationTime(mission)
                    mission:register()
                    table.insert(self.missions, mission)

                    numMissionsLeft = numMissionsLeft - 1

                    if numMissionsLeft <= 0 then 
                        break
                    end
                else
                    mission:delete()
                end
            end
        end

        numActionsLeft = numActionsLeft - 1

        if numActionsLeft <= 0 then
            break
        end
    end
end

MissionManager.generateMissions = Utils.prependedFunction(MissionManager.generateMissions, RollerMissionGenerator.generateMissions)

function RollerMissionGenerator:startMission(startedMission, farmId, spawnVehicles)
    local fieldId = startedMission.field.fieldId
    for _, mission in pairs(self.missions) do
        if mission.field.fieldId == fieldId then
            mission:delete()
        end
    end
end

MissionManager.startMission = Utils.appendedFunction(MissionManager.startMission, RollerMissionGenerator.startMission)