-- AI for Settlers 5 by Pawel C. v0.1



-- PlayerID, 0 for check all unit types, from Pos X, Y, in radius, on how many units it must enter
-- Logic.GetPlayerEntitiesInArea(gvMission.PlayerID, Entities.PB_Tower2, gvMission.TowerSpotN[i].X, gvMission.TowerSpotN[i].Y, 400, 1)


---------------------------------------------------------
--++++++++++++++++++ INDEX OF ISSUES ++++++++++++++++++--
---------------------------------------------------------
-- 0 = !! not used !!
-- 1 = no trees
-- 2 = no clay deposit
-- 3 = no clay at all! (2 included)
-- 4 = no stone deposit
-- 5 = no stone at all! (4 included)
-- 6 = no iron deposit
-- 7 = no iron at all! (6 included)
-- 8 = no sulfur deposit
-- 9 = no sulfur at all! (8 included)
-- 10 = no money

-- 100 = villager under attack -- ???????????? maybe other list
---------------------------------------------------------

---------------------------------------------------------
------------------------ GLOBALS ------------------------
---------------------------------------------------------
-- shared info between Pawel's AI players, for communication purposes
_paAI_shared = {}

_paAI_shared.reservedDepos	 = {} --reserved deposits, player can reserve a pit so other players won't try to build there - it solves some AI issues - it's a list of players and deposits


_paAI_minesList 	= {
						-- Village center is considered to be a mine because of technical purposes
						Entities.PB_VillageCenter1,
						Entities.PB_VillageCenter2,
						Entities.PB_VillageCenter3,
						
						Entities.PB_ClayMine1,
						Entities.PB_ClayMine2,
						Entities.PB_ClayMine3,
						Entities.PB_StoneMine1,
						Entities.PB_StoneMine2,
						Entities.PB_StoneMine3,
						Entities.PB_IronMine1,
						Entities.PB_IronMine2,
						Entities.PB_IronMine3,
						Entities.PB_SulfurMine1,
						Entities.PB_SulfurMine2,
						Entities.PB_SulfurMine3
													}

---------------------------------------------------------
------------------------ AI INIT ------------------------
---------------------------------------------------------
function PawelAI_SetupPlayerAi(_playerId,_description,_AI_info)

	Message("Player setup started!")
	
	--Init info about the AI player
	_AI_info.playerID				= _playerId
	_AI_info.headquartersID			= 0
	_AI_info.mainBasePosition		= { X=-1 , Y=-1 }
	
	-- initial buildings - these which player had on start of map
	--_AI_info.initialBuildings				= {}
	-- building that AI is supposed to build or rebuild if a building is destroyed - it's supposed to mirror ConstructionQueue
	_AI_info.buildingsList					= {} -- list of buildings built by the AI
	_AI_info.constrPlansList				= {} -- list of buildings that are planned to be built
	_AI_info.considerToBuildList			= {} -- list of buildings that can be build but are not the highest priority
	_AI_info.minesList						= {} -- list of initial player's mines. todo: shouldn't it be for all player's mines???
	_AI_info.issueList						= {} -- list of problems with which the AI player needs to deal

	_AI_info.economyTask			= 0 -- current task of economy
	_AI_info.militaryTask			= 0 -- current task of military
	_AI_info.VillageAdvancement		= 0 -- advancement of the village, higher number means more advanced village
	
	
	
	
	-- Get position of the Headquarters, it will become the position of the main base
	local NumberOfHQ1, HeadquartersID= Logic.GetPlayerEntities(_AI_info.playerID,Entities.PB_Headquarters1,1)	
	if NumberOfHQ1 >= 1 then
		_AI_info.headquartersID = HeadquartersID
		Tools.GetEntityPosition(_AI_info.headquartersID, _AI_info.mainBasePosition)
	end
	
	local NumberOfHQ2, HeadquartersID= Logic.GetPlayerEntities(_AI_info.playerID,Entities.PB_Headquarters2,1)	
	if NumberOfHQ2 >= 1 then
		_AI_info.headquartersID = HeadquartersID
		Tools.GetEntityPosition(_AI_info.headquartersID, _AI_info.mainBasePosition)
	end
	
	local NumberOfHQ3, HeadquartersID= Logic.GetPlayerEntities(_AI_info.playerID,Entities.PB_Headquarters3,1)	
	if NumberOfHQ3 >= 1 then
		_AI_info.headquartersID = HeadquartersID
		Tools.GetEntityPosition(_AI_info.headquartersID, _AI_info.mainBasePosition)
	end
	
	
	-- Setup AI
	SetupPlayerAi(_playerId,_description)
	
	-- AI player can extract resources
	AI.Village_EnableExtracting(_playerId, 1)
	AI.Village_SetResourceFocus(_playerId, ResourceType.Wood) -- AI collects all materials or just stones, no idea how to make it working
	
	-- Check initial buildings and build what is needed
	--PlanInitialBuildings(_AI_info)				XXXXXXXXXX!!!!!!XXXXXXXX	TURNNNNN OOOOOOOOOOOONNNNNNNN BACKKK AGAINNNNN!!!!!!!!!!

	
	-- debug
	Message("Player ".._AI_info.playerID.." setup done!")
	--Message("Player ".._AI_info.playerID.." info:")
	--Message("Headquarters ID: ".._AI_info.headquartersID)
	--Message("Camp pos X: ".._AI_info.mainBasePosition.X)
	--Message("Camp pos Y: ".._AI_info.mainBasePosition.Y)
	--GUI.CreateMinimapPulse(_AI_info.mainBasePosition.X, _AI_info.mainBasePosition.Y, 1)
	--Message("Player setup done!")
	
	
	return _AI_info
	
end


---------------------------------------------------------
---------------------- AI THINKING ----------------------
---------------------------------------------------------

------------------------ AI TICK ------------------------
function PawelAI_AITick(_AI_info)
	--------------------------
	---- Economy checking ----
	EconomyTick(_AI_info)

	--------------------------
	---- Military checking ----
	--local LastMessageTime, EntityID = Logic.FeedbackGetLastMessageGameTimeMS( PlayerID, Feedback.MessageAttack )

	Message("tick done for player ".._AI_info.playerID)
	
	--Camera.ScrollSetLookAt(GetPosition(id).X, GetPosition(id).Y)
	return false		
end
---------------------------------------------------------

function EconomyTick(_AI_info)
	--------------------------
	---- Economy checking ----
	---- TASKS ----
	EconomyTask(_AI_info) 

	---- OTHER ----
	-- Units --
	--SendIdleSerfsToWork(_AI_info)
	
	-- Buildings --

end

function EconomyTask(_AI_info)
	-- accepts both number as well as string
	--_task = _task and tonumber(_task) or _task     -- returns a number if the _task is a number or string. 

	-- Tasks - _AI_info.economyTask
	case =
	 {
		[0] = function ( ) -- initial task - build first buildings
			-- check if we have anything to be build
			if BuildFromPlans(_AI_info) then
				-- check if we have no issues, otherwise we can't move to task 2
				-- todo: check issues - do we have all necessary mines?

				-- task 0 completed, change to task 1
				_AI_info.economyTask = 1
				_AI_info.VillageAdvancement = 1 -- we move up

				-- plan to build second part of buildings now e.g. uni
				PlanUniversity(_AI_info)
			end
		end,

		[1] = function ( )	-- build second part of buildings, e.g. uni
			if BuildFromPlans(_AI_info) then
				-- check if we have no issues...
				-- todo: check issues ?

				-- task 1 completed, change to task 2
				_AI_info.economyTask = 2
				--GUIAction_ReserachTechnology(Technologies.GT_Construction)
				AI.Village_StartResearch(_AI_info.playerID,Technologies.GT_Construction,20,TECHNOLOGY,UpgradeCategories.University) -- prob value is 20, but I don't know what it does
			end
		end,
  
		[2] = function ( )                              
			--AI.Village_StartResearch(_AI_info.playerID,Technologies.GT_Construction,20,TECHNOLOGY,UpgradeCategories.University)
		end,

		[3] = function ( )                            
			--print("your choice is char + ")         
		end,
  
		default_ec_task = function ( )
			--print("your choice din't match any of those specified cases")   
		end,

		Message("Player ".._AI_info.playerID..": task ".._AI_info.economyTask)
	 }
  
	-- execution section
	if case[_AI_info.economyTask] then
	   case[_AI_info.economyTask]()
	else
	   case["default_ec_task"]()
	end

end


function MilitaryTask(_task)
	-- accepts both number as well as string
	choice = _task and tonumber(_task) or choice     -- returns a number if the _task is a number or string. 
  
	-- Define your cases
	case =
	 {
		[0] = function ( )
			--print("your choice is Number 0 ")
		end,  

		[1] = function ( )							-- case 1 : 
			--print("your choice is Number 1 ")		-- code block
		end,										-- break statement
  
		[2] = function ( )                              
			--print("your choice is string add ")
		end,
  
		[3] = function ( )                            
			--print("your choice is char + ")         
		end,
  
		default_mi_task = function ( )
			--print("your choice din't match any of those specified cases")   
		end,
	 }
  
	-- execution section
	if case[choice] then
	   case[choice]()
	else
	   case["default_mi_task"]()
	end
  
end

--function SendIdleSerfsToWork(_AI_info)
--	local IdleSerfAmount = Logic.GetNumberOfIdleSerfs(_AI_info.playerID)
--	if IdleSerfAmount == 0 then
--		Message("Wszyscy zajeci")
--		return
--	end
--	
--	local CurrentSerfID = Logic.GetNextIdleSerf(_AI_info.playerID)
--	Logic.MoveSettler(CurrentSerfID, 10380, 14225)
--	
--	Message("Do roboty!")
--end

-- example: _AI_info.constrPlansList = {-2,{_mine,Entities.PB_Farm1,Entities.PB_Residence1},_position,_depositID})
-- example: AI.Village_GetConstructionsInQueue(_AI_info.playerID)

function BuildFromPlans(_AI_info) -- returns true when there are no buildings that can be build

	-- check list from the end - it's less CPU expensive to remove elements this way
	if table.getn(_AI_info.constrPlansList) == 0 then -- if no elements then return true
		Message("Player ".._AI_info.playerID.." has nothing to build currently")
		return true -- nothing to build
	else
		local lastIndex = table.getn(_AI_info.constrPlansList)
		
		-- just check last entry, we don't want to build whole list at one go
		if _AI_info.constrPlansList[lastIndex][1] < 0 then
			if _AI_info.constrPlansList[lastIndex][1] == -2 then
				-- try to reserve the space for mine
				if ReserveSpaceForMine(_AI_info.playerID,_AI_info.constrPlansList[lastIndex][4]) then -- take position
					Message("Player ".._AI_info.playerID.." has reserved space for mine. Pos: ".._AI_info.constrPlansList[lastIndex][3].X.." and ".._AI_info.constrPlansList[lastIndex][3].Y)
				else
					Message("Player ".._AI_info.playerID.." can't build a mine as space is reserved")
					-- remove this last entry from building plans list
					table.remove(_AI_info.constrPlansList)
					return false
				end

				-- start construction for all buildings in the group
				for i=1,table.getn(_AI_info.constrPlansList[lastIndex][2]),1
				do
					StartConstruction(_AI_info,_AI_info.constrPlansList[lastIndex][2][i],_AI_info.constrPlansList[lastIndex][3])
				end
			else
				-- start construction for all buildings in the group, other buildings than the first one have pos -1, -1
				StartConstruction(_AI_info,_AI_info.constrPlansList[lastIndex][2][1],_AI_info.constrPlansList[lastIndex][3])

				for i=2,table.getn(_AI_info.constrPlansList[lastIndex][2]),1
				do
					StartConstruction(_AI_info,_AI_info.constrPlansList[lastIndex][2][i],invalidPosition)
				end
			end

			-- set flag: construction in progress
			_AI_info.constrPlansList[lastIndex][1] = 0
			
		--elseif _AI_info.constrPlansList[lastIndex][1] == 0 then
		else
			-- check if the last building from the list has been built
			--if Logic.IsConstructionComplete()
			if AI.Village_ConstructionQueueIsEmpty(_AI_info.playerID) == 1 then -- in fact building is not completed but started
				-- construction completed, so remove the entry from the list
				-- todo: P: we should wait until the building is finished, but I don't know how to get the building ID 
				table.remove(_AI_info.constrPlansList)
				Message("Player ".._AI_info.playerID.." has finished building")
			end
		end
	end

	return false
end

function ReserveSpaceForMine(_playerID,_depositID)
	-- first check the deposit
	if CheckIsDepositVacant(_depositID) == false then
		return false
	end

	-- reserve the deposit
	GUI.CreateMinimapPulse(GetPosition(_depositID).X, GetPosition(_depositID).Y, _playerID)
	table.insert(_paAI_shared.reservedDepos,{_playerID,_depositID})
	return true
end

---------- planning to build ----------

function PlanInitialBuildings(_AI_info) -- mines and vc

	-- IMPORTANT NOTICE!! -- the order of buildings here is from the bottom to the top!
	
	-- safety checking - FeedAiWithConstructionPlanFile shouldn't be used in player's lua script
	if AI.Village_ConstructionQueueIsEmpty(_AI_info.playerID) == 0 then
		Message("PAWEL's AI ERROR: AI player ".._AI_info.playerID.." doesn't have ConstructionQueue empty at the start of the map. Probably you used FeedAiWithConstructionPlanFile function. Don't use it!")
	end
	
	-- start checking what can we build

	
	---- check 

	-------------------------
	---- check if we have stone mines
	local minesKind = {Entities.PB_StoneMine1, Entities.PB_StoneMine2, Entities.PB_StoneMine3}
	local deposit = Entities.XD_StonePit1
	CheckInitialMines(_AI_info, minesKind, deposit, _AI_info.mainBasePosition)
	-------------------------
	---- check if we have clay mines
	local minesKind = {Entities.PB_ClayMine1, Entities.PB_ClayMine2, Entities.PB_ClayMine3}
	local deposit = Entities.XD_ClayPit1
	CheckInitialMines(_AI_info, minesKind, deposit, _AI_info.mainBasePosition)
	-------------------------
	---- check if we have a village center - must be last! Village centers are treated as mines here
	local minesKind = {Entities.PB_VillageCenter1, Entities.PB_VillageCenter2, Entities.PB_VillageCenter3}
	local deposit = Entities.XD_VillageCenter
	CheckInitialMines(_AI_info, minesKind, deposit, _AI_info.mainBasePosition)
	
	--local NumberOfVC1 = {Logic.GetPlayerEntities(_AI_info.playerID,Entities.PB_VillageCenter1,1)}	
	--local NumberOfVC2 = {Logic.GetPlayerEntities(_AI_info.playerID,Entities.PB_VillageCenter2,1)}				
	--local NumberOfVC3 = {Logic.GetPlayerEntities(_AI_info.playerID,Entities.PB_VillageCenter3,1)}				
	--if 	NumberOfVC1[1]>=1 or  NumberOfVC2[1]>=1 or NumberOfVC3[1]>=1 then
	--	Message("Mamy VC "..NumberOfVC1[2])
	--	--table.insert(_AI_info.initialBuildings, PB_VillageCenter1)
	--else
	--	Message("Nie ma VC")
	--	--if AI.Village_ConstructionQueueIsEmpty(_AI_info.playerID) == 1 then
	--	--if has_value(_AI_info.buildingsList, PB_VillageCenter1) == 0 then
	--	
	--	AddToConstrPlan(_AI_info,Entities.PB_VillageCenter1,_AI_info.mainBasePosition)
	--	--Message("Zero VC i lista pusta")
	--	--end
	--end
	-------------------------
	
	Message("Mines checked")
	
end

function PlanUniversity(_AI_info)
	-- check if we have don't have one
	
	if DoesPlayerHave(_AI_info, Entities.PB_University1) == false and DoesPlayerHave(_AI_info, Entities.PB_University2) == false then
		PlanToBuildWithFarmAndHouseIfNeeded(_AI_info,Entities.PB_University1,_AI_info.mainBasePosition,6)
	end
end

---------- ----------

function CheckInitialMines(_AI_info,_mineKind,_deposit,_position)

	local numberOfMines = 0
	local minesTable = {}
	minesTable[1] = {Logic.GetPlayerEntities(_AI_info.playerID,_mineKind[1],4)}	
	minesTable[2] = {Logic.GetPlayerEntities(_AI_info.playerID,_mineKind[2],4)}				
	minesTable[3] = {Logic.GetPlayerEntities(_AI_info.playerID,_mineKind[3],4)}	
	
	-- register our mines
	for i=1,3,1
	do
		for j=2,table.getn(minesTable[i]),1
		do
			numberOfMines = numberOfMines + 1
			table.insert(_AI_info.minesList, minesTable[i][j])	
			Message("Mine "..minesTable[i][j].." registered")
		end
	end
	
	if numberOfMines > 2 then -- we have many mines of this type, so we don't need to build more
		Message("Many mines: "..numberOfMines)
		return
		
	elseif numberOfMines == 0 then -- try to build some mines
		if TryToBuildMines(_AI_info,_mineKind,_deposit,_position) == 0 then
			-- todo: chceck if we have other materials in area (these ones not for mines)
			--AddIssueToList(_AI_info,2) -- todo add specific issue
			Message("Player ".._AI_info.playerID.." has issue with finding space for mine ".._mineKind[1])
			return
		else
			return -- do we do anything else?
		end
	else
		if _deposit ~= Entities.XD_VillageCenter then -- only if it's not a village center
			-- check if we can build some extra mines
			TryToBuildMines(_AI_info,_mineKind,_deposit,_position)
		end
	end
	
	Message(numberOfMines)
	
end

function TryToBuildMines(_AI_info,_mineKind,_deposit,_position)
	
	-- find near deposits
	-- as the village center is treated as mine, make sure it the ai won't built more than one at the map start
	local isVC = _deposit == Entities.XD_VillageCenter -- is it a village center
	
	local depositsTable = { Logic.GetEntitiesInArea(_deposit, _position.X, _position.Y, 15000, 6) }
	if depositsTable[1] == 0 then
		-- no deposits
		Message("No deposits in area")--: ".._deposit)
		return false
	else
		-- build a mine
		if depositsTable[1] >= 2 then 
			local buildCount = 0
			local maxToBuild = 2 -- max mines that can be build this time
			if isVC == true then maxToBuild = 1 end
				
			Message("Found mines: "..depositsTable[1])
			
			for i=2,table.getn(depositsTable),1
			do
				local position = GetPosition(depositsTable[i])
				if CheckIsAreaSafe(_AI_info,position,6000) then
					if CheckIsDepositVacant(depositsTable[i]) then
						if buildCount < maxToBuild then
							PlanToBuildMine(_AI_info,_mineKind[1],position,depositsTable[i],isVC)
							buildCount = buildCount + 1
						else
							Message(position.X)
							Message(position.Y)
							-- add to consideration
							table.insert(_AI_info.considerToBuildList, depositsTable[i]) -- add position as well
						end
					end
				else
					--todo: add this position to the unsafe areas list
				end
			end
			
			if buildCount == 0 then
				return false
			end
		else
			local position = GetPosition(depositsTable[2])
			if CheckIsAreaSafe(_AI_info,position,6000) then
				if CheckIsDepositVacant(depositsTable[2]) then
					-- we have just one
					PlanToBuildMine(_AI_info,_mineKind[1],position,depositsTable[2],isVC)
				else
					return false
				end
			else
				--todo: add this position to the unsafe areas list
				return false
			end
		end
	end
	
	return true
end


function CheckFarmVacanciesNear(_AI_info,_position,_requiredSpaces)
	-- check farms in area
	local spaces = 0
	local farmsTable = {}
	farmsTable[1] = {Logic.GetPlayerEntitiesInArea(_AI_info.playerID, Entities.PB_Farm1, _position.X, _position.Y, 7000, 4)}
	farmsTable[2] = {Logic.GetPlayerEntitiesInArea(_AI_info.playerID, Entities.PB_Farm2, _position.X, _position.Y, 7000, 4)}
	farmsTable[3] = {Logic.GetPlayerEntitiesInArea(_AI_info.playerID, Entities.PB_Farm3, _position.X, _position.Y, 7000, 4)}
	for i=1, 3, 1
	do
		for j=2, farmsTable[i][1], 1
		do
			-- check if we have free spaces
			spaces = spaces + Logic.GetMaxNumberOfEaters(farmsTable[i][j]) - Logic.GetAttachedEaterToBuilding(farmsTable[i][j])
			if spaces >= _requiredSpaces then
				Message("Free farm spaces: "..spaces.." required: ".._requiredSpaces)
				return true
			end
		end
	end

	return false
end

function CheckHouseVacanciesNear(_AI_info,_position,_requiredSpaces)
	-- check houses in area
	local spaces = 0
	local housesTable = {}
	housesTable[1] = {Logic.GetPlayerEntitiesInArea(_AI_info.playerID, Entities.PB_Residence1, _position.X, _position.Y, 7000, 4)}
	housesTable[2] = {Logic.GetPlayerEntitiesInArea(_AI_info.playerID, Entities.PB_Residence2, _position.X, _position.Y, 7000, 4)}
	housesTable[3] = {Logic.GetPlayerEntitiesInArea(_AI_info.playerID, Entities.PB_Residence3, _position.X, _position.Y, 7000, 4)}
	for i=1, 3, 1
	do
		for j=2, housesTable[i][1], 1
		do
			-- check if we have free spaces
			spaces = spaces + Logic.GetMaxNumberOfResidents(housesTable[i][j]) - Logic.GetAttachedResidentsToBuilding(housesTable[i][j])
			if spaces >= _requiredSpaces then
				Message("Free house spaces: "..spaces.." required: ".._requiredSpaces)
				return true
			end
		end
	end

	return false
end
	
function PlanToBuildAlone(_AI_info,_building,_position)
	table.insert(_AI_info.constrPlansList, {-1,{_building},_position})
end

function PlanToBuildWithFarmAndHouse(_AI_info,_building,_position)
	table.insert(_AI_info.constrPlansList, {-1,{_building,Entities.PB_Farm1,Entities.PB_Residence1},_position})
end

function PlanToBuildWithFarmAndHouseIfNeeded(_AI_info,_building,_position,_requiredSpaces) -- builds farm or house when there is no empty one in the area
	local hasHouse = CheckHouseVacanciesNear(_AI_info,_position,_requiredSpaces)
	local hasFarm = CheckFarmVacanciesNear(_AI_info,_position,_requiredSpaces)

	if hasHouse and hasFarm then
		table.insert(_AI_info.constrPlansList, {-1,{_building},_position})
	elseif hasHouse then
		table.insert(_AI_info.constrPlansList, {-1,{_building,Entities.PB_Farm1},_position})
	elseif hasFarm then
		table.insert(_AI_info.constrPlansList, {-1,{_building,Entities.PB_Residence1},_position})
	else
		table.insert(_AI_info.constrPlansList, {-1,{_building,Entities.PB_Farm1,Entities.PB_Residence1},_position})
	end
end

function PlanToBuildMine(_AI_info,_mine,_position,_depositID,_isVC)
	-- build mine with a house and farm
	-- mine has to be first in order
	if _isVC then -- don't build farm and house if it's a village center
		table.insert(_AI_info.constrPlansList, {-2,{_mine},_position,_depositID}) -- -1 means task progress: -2: means task waiting (for mines), -1 means: task waiting, 0 means: in progress
	else
		table.insert(_AI_info.constrPlansList, {-2,{_mine,Entities.PB_Farm1,Entities.PB_Residence1},_position,_depositID}) -- -1 means task progress: -2: means task waiting (for mines), -1 means: task waiting, 0 means: in progress
	end
	-- add defense
	-- todo: add tower ?? here?
end

function DoesPlayerHave(_AI_info,_entityType) -- check if the player has already this type of entity e.g. a building
	return Logic.GetPlayerEntities(_AI_info.playerID,_entityType,1) > 0
end

function CheckIsDepositVacant(_depositID) -- for mines
	-- check first if somebody else haven't already registered this deposit
	for i=1,table.getn(_paAI_shared.reservedDepos),1
	do
		--Message(_paAI_shared.reservedDepos[i][2].." compared ".._depositID)

		-- check if somebody have already registered this deposit
		if _paAI_shared.reservedDepos[i][2] == _depositID then
			-- somebody registered this deposit
			--Message("Player ".._playerID.." can't build mine as that depo is already registered")
			--todo: check if it's an enemy, then add this deposit to the targets
			return false
		end	
	end
	
	-- check if the area is not occupied with an other player's mine
	local position = GetPosition(_depositID)
	for j=1,table.getn(_paAI_minesList),1
	do
		local foundMine = Logic.GetEntitiesInArea(_paAI_minesList[j], position.X, position.Y, 10, 1)
		
		if foundMine > 0 then
			Message("Deposit ".._depositID.." is occupied")
			Camera.ScrollSetLookAt(position.X, position.Y)
			return false
		end
	end
	
	return true
end

function CheckIsAreaSafe(_AI_info,_position,_radius)

	--GUI.CreateMinimapPulse(_position.X, _position.Y, 2) -- just for test
	return true
end

-- other

-- mines don't use this function, they call table directly
function AddToConstrPlan(_AI_info,_buildingsGroup,_position,_isMine) -- like StartConstruction function, but it this one lets the AI tick to build later - better solution
	-- now push to the table
	--if _isMine then
	--	table.insert(_AI_info.constrPlansList, {-2,_buildingsGroup,_position}) -- -1 means task progress: -2: means task waiting (for mines), -1 means: task waiting, 0 means: in progress, means: completed
	--else
		table.insert(_AI_info.constrPlansList, {-1,_buildingsGroup,_position}) -- -1 means task progress: -2: means task waiting (for mines), -1 means: task waiting, 0 means: in progress, means: completed
	--end
	--Message("Player ".._AI_info.playerID..": constrPlansList: "..table.getn(_AI_info.constrPlansList))
	--GUI.CreateMinimapPulse(_position.X, _position.Y, _AI_info.playerID)
end

function StartConstruction(_AI_info,_entity,_position) -- don't use it directly
	AI.Village_StartConstruction(_AI_info.playerID,_entity,_position.X,_position.Y,0)
	--Message(table.getn(_AI_info.buildingsList))
	-- now push to the table
	table.insert(_AI_info.buildingsList, _entity)
	--Message(table.getn(_AI_info.buildingsList))
end

function AddIssueToList(_AI_info,_issueNum)

	table.insert(_AI_info.issueList, _issueNum)
	Message("Player ".._AI_info.playerID.." has added issue number: ".._issueNum)
	
end

function RemoveIssueFromList(_AI_info,_issueNum)
	--table.insert(_AI_info.issueList, _issueNum)
	
	--Message("Player ".._AI_info.playerID.." has added issue number: ".._issueNum)
end


-- tools
