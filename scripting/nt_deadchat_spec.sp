#include <sourcemod>

char message[192];
bool targets[32+1];
bool IsTeamChat;

public Plugin myinfo = {
	name = "NT Dead Chat Spec",
	author = "bauxite, based on Root_ All Chat",
	description = "Allows dead players to text chat with living teammates, spectators can always chat with everyone",
	version = "0.3.0",
};

public void OnPluginStart()
{
	HookUserMessage(GetUserMessageId("SayText"), SayTextHook, false);
	HookEvent("player_say", Event_PlayerSay, EventHookMode_Post);
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{	
	IsTeamChat = StrEqual(command, "say_team", false);
	
	for (int target = 1; target <= MaxClients; target++)
	{
		targets[target] = true;
	}
	
	return Plugin_Continue;
}

public Action SayTextHook(UserMsg msg_id, BfRead bf, const int[] players, int playersNum, bool reliable, bool init)
{
	BfReadString(bf, message, sizeof(message));

	for (int i; i < playersNum; i++)
	{
		targets[players[i]] = false;
	}
	
	return Plugin_Continue;
}

public void Event_PlayerSay(Event event, const char[] name, bool dontBroadcast)
{
	int clients[32+1];
	int numClients;
	int client;
	int i;

	client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client <= 0 || client > MaxClients)
	{
		return;
	}
	
	if (IsTeamChat)
	{
		for (i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == GetClientTeam(client) && targets[i])
			{
				clients[numClients++] = i;
			}
			
			targets[i] = false;
		}
	}
	else
	{
		if (GetClientTeam(client) == 1)
		{
			for (i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && targets[i])
				{
					clients[numClients++] = i;
				}
				
				targets[i] = false;
			}
		}
	}
	
	if(numClients == 0)
	{
		return;
	}
	
	Handle SayText = StartMessage("SayText", clients, numClients, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);

	if (SayText != INVALID_HANDLE)
	{
		BfWriteByte(SayText, client);

		BfWriteString(SayText, message);

		BfWriteByte(SayText, -1);

		EndMessage();
	}
}
