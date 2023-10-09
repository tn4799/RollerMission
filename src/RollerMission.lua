RollerMission = {
    REWARD_PER_HA = 700
}

local RollerMission_mt = Class(RollerMission, AbstractFieldMission)

InitObjectClass(RollerMission, "RollerMission")

function RollerMission.new(isServer, isClient, customMt)
	local self = AbstractFieldMission.new(isServer, isClient, customMt or RollerMission_mt)

	self.workAreaTypes = {
		[WorkAreaType.ROLLER] = true
	}
	self.rewardPerHa = RollerMission.REWARD_PER_HA
	self.reimbursementPerHa = 0
	local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = self.mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.ROLLER_LEVEL)
	self.completionModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, self.mission.terrainRootNode)
	self.completionFilter = DensityMapFilter.new(self.completionModifier)
	self.completionFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
	self.groundTypeModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, self.mission.terrainRootNode)
	self.rollerLinesType = g_currentMission.fieldGroundSystem:getFieldGroundValue(FieldGroundType.ROLLER_LINES)

	return self
end

function RollerMission:resetField()
	for i = 1, table.getn(self.field.maxFieldStatusPartitions) do
		g_fieldManager:setFieldPartitionStatus(self.field, self.field.maxFieldStatusPartitions, i, self.field.fruitType, self.fieldState, 1, self.sprayFactor * self.sprayLevelMaxValue, self.fieldSpraySet, self.fieldPlowFactor * self.plowLevelMaxValue, self.weedState, self.limeFactor * self.limeLevelMaxValue)
	end
end

function RollerMission:completeField()
	--set field completly to rolled
	for i = 1, getNumOfChildren(self.field.fieldDimensions) do
        local dimWidth = getChildAt(self.field.fieldDimensions, i - 1)
        local dimStart = getChildAt(dimWidth, 0)
        local dimHeight = getChildAt(dimWidth, 1)

        local startX, _, startZ = getWorldTranslation(dimStart)
        local widthX, _, widthZ = getWorldTranslation(dimWidth)
        local heightX, _, heightZ = getWorldTranslation(dimHeight)

		self.completionModifier:setParallelogramWorldCoords(startX, startZ, widthX, widthZ, heightX, heightZ, DensityCoordType.POINT_POINT_POINT)
		self.completionModifier:executeSet(0)
	end

	for i = 1, table.getn(self.field.maxFieldStatusPartitions) do
		g_fieldManager:setFieldPartitionStatus(self.field, self.field.maxFieldStatusPartitions, i, self.field.fruitType, self.fieldState, 1, self.sprayFactor * self.sprayLevelMaxValue, self.fieldSpraySet, self.fieldPlowFactor * self.plowLevelMaxValue, self.weedState, self.limeFactor * self.limeLevelMaxValue)
	end
end

function RollerMission.canRunOnField(field, sprayFactor, fieldSpraySet, fieldPlowFactor, limeFactor, maxWeedState, stubbleFactor, rollerFactor)
    local fruitType = field.fruitType
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)

    if rollerFactor == 0 or fruitDesc == nil then
        return false
    end

	local currentGrowthState = FieldUtil.getMaxGrowthState(field, fruitType)
	if fruitDesc.needsRolling and FieldUtil.getRollerFactor(field) > 0 and currentGrowthState == 1 then
        return true, FieldManager.FIELDSTATE_GROWING, currentGrowthState
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

function RollerMission:partitionCompletion(x, z, widthX, widthZ, heightX, heightZ)
	self.completionModifier:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ, DensityCoordType.POINT_VECTOR_VECTOR)

	local _, area, totalArea = self.completionModifier:executeGet(self.completionFilter)

	return area, totalArea
end

function RollerMission:validate(event)
	return event == FieldManager.FIELDEVENT_SOWN
end

g_missionManager:registerMissionType(RollerMission, "roll")