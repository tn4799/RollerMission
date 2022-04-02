RollerMission = {
    REWARD_PER_HA = 650
}

local RollerMission_mt = Class(RollerMission, AbstractFieldMission)

InitObjectClass(RollerMission, "RollerMission")

function RollerMission_mt.new(isServer, isClient, customMt)
	local self = AbstractFieldMission.new(isServer, isClient, customMt or PlowMission_mt)
	self.workAreaTypes = {
		[WorkAreaType.ROLLER] = true
	}
	self.rewardPerHa = RollerMission.REWARD_PER_HA
	self.reimbursementPerHa = 0
	local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = self.mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
	self.completionModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, self.mission.terrainRootNode)
	self.completionFilter = DensityMapFilter.new(self.completionModifier)
	local rollerValue = self.mission.fieldGroundSystem:getFieldGroundValue(FieldGroundType.ROLLED_SEEDBED)

	self.completionFilter:setValueCompareParams(DensityValueCompareType.EQUAL, rollerValue)

	return self
end

function RollerMission:finish(...)
    RollerMission:superClass().finish(self, ...)

    self.field.fruitType = FruitType.UNKNOWN
end

function RollerMission:completeField()
	for i = 1, table.getn(self.field.maxFieldStatusPartitions) do
		g_fieldManager:setFieldPartitionStatus(self.field, self.field.maxFieldStatusPartitions, i, nil, FieldManager.FIELDSTATE_GROWING, 0, self.sprayFactor, self.fieldSpraySet, self.fieldPlowFactor)
	end
end

function RollerMission.canRunOnField(field, sprayFactor, fieldSpraySet, fieldPlowFactor, limeFactor, maxWeedState, stubbleFactor, rollerFactor)
    local fruitType = field.fruitType
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)
	local x, z = FieldUtil.getMeasurementPositionOfField(field)

    if rollerFactor > 0 or fruitDesc == nil then
        return false
    end

    local area, _ = FieldUtil.getFruitArea(x - 1, z - 1, x + 1, z - 1, x - 1, z + 1, {}, {}, fruitType, fruitDesc.minPreparingGrowthState, fruitDesc.maxPreparingGrowthState, 0, 0, 0, false)

    if area > 0 then
        return true, FieldManager.FIELDSTATE_GROWING
    end

    return false
end

function RollerMission:getData()
	return {
		location = string.format(g_i18n:getText("fieldJob_number"), self.field.fieldId),
		jobType = g_i18n:getText("FieldJob_jobType_rolling"),
		action = g_i18n:getText("FieldJob_desc_action_rolling"),
		description = string.format(g_i18n:getText("FieldJob_desc_rolling"), self.field.fieldId)
	}
end



function RollerMission:validate(event)
    return event == FieldManager.FIELDEVENT_SOWN or event == FieldManager.FIELDEVENT_GROWING
end

g_missionManager:registerMissionType(RollerMission, "roll")