RollerMissionGenerator = {}

function RollerMissionGenerator:generateMissions(dt)
    self.missionTypes = Utils.shuffle(self.missionTypes)
    --[[ 
    -- alternative version to generate roller missions for sure by not depending on the order of mission types.
    local numActionsLeft = MissionManager.MAX_TRIES_PER_GENERATION
	local numMissionsLeft = MissionManager.MAX_MISSIONS_PER_GENERATION
	local indices = {}

	for i = 1, #g_fieldManager.fields do
		table.insert(indices, i)
	end

	Utils.shuffle(indices)

	for _, index in ipairs(indices) do
        local field = g_fieldManager.fields[index]

        if field.fieldMissionAllowed and not RollerMissionGenerator.hasFieldRollerMission(field.fieldId) then
            local fieldSpraySet, sprayFactor, fieldPlowFactor, limeFactor, weedFactor, maxWeedState, stubbleFactor, rollerFactor = self:getFieldData(field)
            local canRun, fieldState, growthState, weedState, args = RollerMission.canRunOnField(field, sprayFactor, fieldSpraySet, fieldPlowFactor, limeFactor, maxWeedState, stubbleFactor, rollerFactor)

            if canRun then
                local mission = RollerMission.new(true, g_client ~= nil)
                mission.type = g_missionManager:getMissionType("roll")

                if mission:init(field, sprayFactor, fieldSpraySet, fieldPlowFactor, fieldState, growthState, limeFactor, weedFactor, weedState, stubbleFactor, rollerFactor, args) then
                    self:assignGenerationTime(mission)
                    mission:register()
                    table.insert(self.missions, mission)
                    g_messageCenter:publish(MessageType.MISSION_GENERATED)

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
    ]]
end

function RollerMissionGenerator.hasFieldRollerMission(fieldId)
    for _, mission in pairs(g_missionManager.missions) do
        if mission.field.fieldId == fieldId then
            return true
        end
    end
    return false
end

function RollerMissionGenerator:startMission(startedMission, farmId, spawnVehicles)
    local fieldId = startedMission.field.fieldId
    for _, mission in pairs(self.missions) do
        if mission.field.fieldId == fieldId and mission ~= startedMission then
            mission:delete()
        end
    end
end

MissionManager.generateMissions = Utils.prependedFunction(MissionManager.generateMissions, RollerMissionGenerator.generateMissions)
MissionManager.startMission = Utils.appendedFunction(MissionManager.startMission, RollerMissionGenerator.startMission)