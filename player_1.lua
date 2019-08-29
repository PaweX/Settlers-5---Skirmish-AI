createPlayer1 = function()

	local playerId = 1
	Logic.SetPlayerName(1, String.MainKey.."_Player1Name")
	-- Info about the AI player
	_paAI_info_Player1 = {}

	--	set up  player ai

	local aiDescription = {
	
		serfLimit				=	20,
		
		resourceFocus 			= ResourceType.WoodRaw,
		--------------------------------------------------
		resources = {
			gold				=	1000,
			clay				=	1000,
			iron				=	1000,
			sulfur				=	1000,
			stone				=	1000,
			wood				=	1000
		},
		--------------------------------------------------
		refresh = {
			gold				=	0,
			clay				=	0,
			iron				=	0,
			sulfur				=	0,
			stone				=	0,
			wood				=	0,
			updateTime			=	100
		},
		--------------------------------------------------
		extracting = true,
		--------------------------------------------------
		rebuild	=	{
				delay				=	0,
				randomTime			=	0
			},	

		
	}
	Message("Player 1: starting to load PawelAI!")
	---------- Pawel AI ----------
	PawelAI_SetupPlayerAi(playerId,aiDescription,_paAI_info_Player1)
	
	-- Start AI control
	StartJob("ControlPlayer1")
	
	------------------------------
	--SetupPlayerAi(playerId,aiDescription)
	
	Message("Player 1: PawelAI loaded!")
	
	AI.Player_SetResourceLimits(playerId, 9999, 9999, 9999, 9999, 9999, 9999)

end

-----------------------------------------------------------------------------------------------------------------------
--
--	JOB: "ControlPlayer1"
--
-----------------------------------------------------------------------------------------------------------------------	
	-------------------------------------------------------------------------------------------------------------------
	Condition_ControlPlayer1 = function()
	-------------------------------------------------------------------------------------------------------------------
		return Counter.Tick2("ControlPlayer1",10)
	end
		
	-------------------------------------------------------------------------------------------------------------------
	Action_ControlPlayer1 = function()
	-------------------------------------------------------------------------------------------------------------------
		return PawelAI_AITick(_paAI_info_Player1)		
	end
-----------------------------------------------------------------------------------------------------------------------