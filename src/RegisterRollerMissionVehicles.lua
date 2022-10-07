RegisterRollerMissionVehicles = {
    filename = g_currentModDirectory .. "xml/missionVehicles.xml"
}

function RegisterRollerMissionVehicles:loadMapFinished(node, arguments, callAsyncCallback)
    g_missionManager:loadMissionVehicles(RegisterRollerMissionVehicles.filename)
end

BaseMission.loadMapFinished = Utils.appendedFunction(BaseMission.loadMapFinished, RegisterRollerMissionVehicles.loadMapFinished)

--addConsoleCommand("gsFieldGenerateMission", "Force generating a new mission for given field", "consoleGenerateFieldMission", g_missionManager)