-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

-- comm message handling

local Me = DiceMaster4 

-------------------------------------------------------------------------------
-- Routing table for DCM4 addon messages.
--
local MessageHandlers = {
 
	INSP    = "Inspect_OnInspectMessage";
	TRAIT   = "Inspect_OnTraitMessage";
	INV		= "Inspect_OnItemSlotMessage";
	STATUS  = "Inspect_OnStatusMessage";
	SKILLS   = "Inspect_OnSkillsMessage";
	APPROVE = "Inspect_OnTraitApprove";
	EXP     = "Inspect_OnExperience";
	SETHP   = "Inspect_OnSetHPMessage";
	SETMANA = "Inspect_OnSetManaMessage";
	
	EVENT   = "Triggered_OnEvent";
	
	R       = "Dice_OnRollMessage";
	ROLL    = "Dice_OnRollMessage";
	
	ITEM    = "LootToast_OnToast";
	ITEMLOOT = "LootToast_OnGroupLoot";
	ITEMROLL = "LootToast_OnGroupLootRoll";
	ITEMMSG = "LootToast_OnGroupLootMessage";
	ITEMML 	= "LootToast_OnMasterLootMessage";
	ITEMREQ = "ShopEditor_RequestItem";
	ITEMBUY = "ShopEditor_BuyItem";
	ITEMGET = "ShopEditor_ReceiveItem";
	ITEMUSE = "Inspect_OnItemUseRequest";
	ITEMAPP = "Inspect_OnItemUseApproved";
	
	TRDREM 	= "ItemTrade_RemoveTradeitem";
	TRDACC 	= "ItemTrade_TradeAccepted";
	TRDITEM = "ItemTrade_RecieveTradeItem";
	
	TYPE    = "PostTracker_OnTyping";
	
	TARGET  = "RollTracker_OnTargetMessage";
	NOTES   = "RollTracker_OnNoteMessage";
	NOTREQ  = "RollTracker_OnStatusRequest";
	MAPNODES  = "RollTracker_OnMapNodesMessage";
	MAPREQ  = "RollTracker_OnMapNodesRequest";
	
	BANNER  = "RollBanner_OnBanner";
	
	BUFF    = "BuffFrame_OnBuffMessage";
	REMOVE  = "BuffFrame_OnRemoveBuffMessage";
	
	SOUND   = "SoundPicker_OnSoundMessage";
	EFFECT  = "OnFullscreenEffectMessage";
	SECRET  = "SecretEditor_OnSecretActivated";
	SCEFFECT  = "ScreenEffectEditor_PlayEffect";
	
	MORALE  = "MoraleBar_OnStatusMessage";
	MORREQ  = "MoraleBar_OnStatusRequest";
	
	DMSAY   = "UnitFrame_OnDMSAY";
	UFFBUFF   = "UnitFrame_OnBuffMessage";
	UFREMOVE  = "UnitFrame_OnRemoveBuffMessage";
	UFREQ     = "UnitFrame_OnStatusRequest";
    UFSTAT    = "UnitFrame_OnStatusMessage";
    UFANIM    = "UnitFrame_OnAnimationMessage";
}

-------------------------------------------------------------------------------
-- Comm Handler for when an DCM4 message is received.
--
function Me:OnCommMessage( prefix, packed_message, dist, sender )
	local success, msgtype, data = Me:Deserialize( packed_message )
	
	if not success then return end
	
	-- DEBUG: Vemos exactamente qué nombre llega por el canal de comunicación
	print("|cff00ffff[COMM DEBUG]|r Recibido de: '" .. tostring(sender) .. "' | Type: " .. tostring(msgtype))

	-- En Forever, el nombre del remitente puede venir con apellido o con formato especial.
	-- Primero, limpiamos el reino si existe (formato "Nombre-Reino").
	local cleanSender = sender
	if cleanSender:find("-") then
		cleanSender = cleanSender:match("(.+)%-")
	end
	
	-- Ahora, comprobamos si el 'cleanSender' coincide con el nombre completo del jugador.
	-- Si el addon usa UnitFullName, el formato es "Nombre Apellido" (con espacio).
	local playerFullName = (UnitFullName("player"))
	if not cleanSender or cleanSender == "" then
		cleanSender = sender
	end

	-- Si el nombre limpio es solo el nombre de pila, pero nuestro cliente sabe que somos "Nombre Apellido",
	-- forzamos que el sender sea el nombre completo. (Solo si el mensaje parece ser para nosotros o de nosotros).
	if cleanSender == UnitName("player") and playerFullName ~= cleanSender then
		cleanSender = playerFullName
	end
	
	if dist == "RAID" and IsInGroup( LE_PARTY_CATEGORY_INSTANCE ) and IsInGroup( LE_PARTY_CATEGORY_HOME ) then
		dist = "PARTY";
	end
	
	local handler = MessageHandlers[msgtype]
	if Me[handler] then
		Me[handler]( data, dist, cleanSender )
	end
end

---------------------------------------------------------------------------
-- Received a talking head request.
--  na = name							string
--	md = model							number
-- 	ms = message						string
--  so = sound							number

function Me.UnitFrame_OnDMSAY( data, dist, sender )	
	-- Ignore our own data.
	if sender == (UnitFullName( "player" )) then return end
 
	-- sanitize message
	if not data.na and not data.md and not data.ms then
	   
		return
	end
	
	if ( UnitIsGroupLeader( sender ) or UnitIsGroupAssistant( sender ) ) and not DiceMasterTalkingHeadFrame then
		Me.PrintMessage("|cFFE6E68E"..(data.na or "Unknown").." says: "..data.ms, "RAID")
	end
end

---------------------------------------------------------------------------
-- Received a trigger event.
--	ev = event type

function Me.Triggered_OnEvent( data, dist, sender )
	-- sanitize message
	if not data.sv or not Me.db.global.allowEffects then
	   
		return
	end
	
	-- Only the party leader can send us these.
	if not UnitIsGroupLeader(sender, 1) then 
		return 
	end
	
	if data.ev then
		-- TODO
	end
end

---------------------------------------------------------------------------
-- Received a fullscreen effect request.
--	sv = spellVisualKitID				number
--	po = position ( x, y, z )			table
--  so = sound							number

function Me.ResetFullscreenEffect()
	local model = DiceMasterFullscreenEffectFrame.Model
	model:ClearModel()
	model:SetDisplayInfo( 6908 )
	model:SetPosition( 0, 0, -0.5 )
	model:SetPortraitZoom( 0 );
	model:SetCamDistanceScale( 5 );
end

function Me.OnFullscreenEffectMessage( data, dist, sender )
	-- sanitize message
	if not data.sv or not Me.db.global.allowEffects then
	   
		return
	end
	
	if ( UnitInRaid( sender) or UnitInParty( sender ) or Me.IsLeader( false ) ) then
		Me.ResetFullscreenEffect()
		DiceMasterFullscreenEffectFrame.Model:ApplySpellVisualKit( data.sv, true );
		if ( data.so ) then
			PlaySound( data.so )
		end
	end
end

-------------------------------------------------------------------------------
function Me.Comm_Init() 
	Me:RegisterComm( "DCM4", "OnCommMessage" ) 
end

-- Función segura para enviar mensajes en Forever
function Me.SafeSendComm(msgtype, data, target, priority)
	local dist = "PARTY"
	if IsInRaid() then
		dist = "RAID"
	elseif not IsInGroup() then
		-- Si no estamos en grupo, no enviamos nada (o lo enviamos por WHISPER si hay target)
		if target then
			dist = "WHISPER"
		else
			return -- No hay a quién enviar
		end
	end
	
	local msg = Me:Serialize(msgtype, data)
	local channel = dist
	if dist == "WHISPER" then
		C_ChatInfo.SendAddonMessage("DCM4", msg, channel, target)
	else
		C_ChatInfo.SendAddonMessage("DCM4", msg, channel)
	end
end