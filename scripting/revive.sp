#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <chatnotice>

public Plugin myinfo =
{
    name = "Revive",
    author = "hjjg200",
    description = "[CSGO] Revive on spectatee",
    version = "1.0",
    url = "http://www.sourcemod.net/"
};

//https://forums.alliedmods.net/showthread.php?t=267337
#define SPECMODE_FIRSTPERSON 4
#define SPECMODE_3RDPERSON 5

#define CS_SLOT_PRIMARY 0 /**< Primary weapon slot. */
#define CS_SLOT_SECONDARY 1 /**< Secondary weapon slot. */
#define CS_SLOT_KNIFE 2 /**< Knife slot. */
#define CS_SLOT_GRENADE 3 /**< Grenade slot (will only return one grenade). */
#define CS_SLOT_C4 4 /**< C4 slot. */

ConVar g_CvarRevivePerRound;
ConVar g_CvarDummyBot;

//
new playerReviveCount[MAXPLAYERS + 1];

public void OnPluginStart()
{
    g_CvarRevivePerRound = CreateConVar("sm_revive_per_round", "2",
        "Sets the limit how many times a player can revive in a round",
        FCVAR_NOTIFY, true, 0.0, false, 0.0);

    g_CvarDummyBot = CreateConVar("sm_revive_dummy", "1",
        "Add a dummy bot for each team so that players can use it as a revive point");

    if(g_CvarDummyBot.IntValue == 1)
    {
        // Adding bots trigger mp_autoteambalance to be adjusted
        HookConVarChange(FindConVar("mp_autoteambalance"), _mpAutoBalanceHandler);
    }

    // Register command
    RegConsoleCmd("sm_rv", Command_Revive);

    HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
    HookEvent("player_death", OnPlayerDeath);

    AutoExecConfig(true, "revive");

    LoadTranslations("revive.phrases");
    ChatNotice_Register("\x05%t", "revive.command", "!rv");
    ChatNotice_Register("\x05%t", "revive.bindTip", "bind v \"say !rv\"")
}

public void OnConfigsExecuted()
{
    if(g_CvarDummyBot.IntValue == 1)
    {
        CreateTimer(1.0, Timer_AddDummyBot);
    }
}

public Action Timer_AddDummyBot(Handle timer)
{
    SetConVarString(FindConVar("bot_quota_mode"), "normal");
    SetConVarInt(FindConVar("bot_quota"), 0);
    SetConVarInt(FindConVar("bot_join_after_player"), 0);
    ServerCommand("bot_add_t");
    ServerCommand("bot_add_ct");
}

public void _mpAutoBalanceHandler(Handle cvar, const char[] oldValue, const char[] newValue)
{
    SetConVarInt(cvar, 0);
}

public void OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        playerReviveCount[i] = 0;
    }
    if(g_CvarDummyBot.IntValue == 1)
    {
        // Make it stationary
        SetConVarInt(FindConVar("bot_stop"), 1);
    }
}

public void OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
    // TODO: show remaining revive count
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    PrintHintText(client, "%t: %d\n%t", "revive.remainingLives", 
        g_CvarRevivePerRound.IntValue - playerReviveCount[client],
        "revive.command", "!rv");
}

/*
https://forums.alliedmods.net/showthread.php?t=316048

int specmode, target;
for(int i = 1; i <= MaxClients; i++) {
    if (!IsClientInGame(i) || !IsClientObserver(i))
        continue;
                
    specmode = GetEntProp(i, Prop_Send, "m_iObserverMode");
    if (specmode != 4 && specmode != 5)
        continue;
            
    target = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");    
    if (target == client) {
        //
    }
}
*/

public Action Command_Revive(int client, int argc)
{
    if (client <= 0)
        return Plugin_Handled;

    if (!IsClientInGame(client) || !IsClientObserver(client))
        return Plugin_Handled;

    int specmode = GetEntProp(client, Prop_Send, "m_iObserverMode");
    if (specmode != SPECMODE_3RDPERSON && specmode != SPECMODE_FIRSTPERSON)
        return Plugin_Handled;

    int target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
    if (IsPlayerAlive(target))
    {
        // Check same team
        int team0, team1;
        team0 = GetClientTeam(client);
        team1 = GetClientTeam(target);
        if (team0 != team1)
        {
            // TODO: say you can only revive from a teammate
            PrintCenterText(client, " \x05%t", "revive.teammatesOnly");
            return Plugin_Handled;
        }

        // Check limit and deduct
        if (playerReviveCount[client] >= g_CvarRevivePerRound.IntValue)
        {
            // TODO: show reached limit
            PrintCenterText(client, " \x05%t", "revive.livesAllConsumed");
            return Plugin_Handled;
        }
        playerReviveCount[client]++;

        // Respawn and teleport
        float origin[3], angles[3], vec[3];
        GetClientAbsOrigin(target, origin);
        GetClientAbsAngles(target, angles);
        GetEntPropVector(target, Prop_Data, "m_vecVelocity", vec);

        CS_RespawnPlayer(client);
        TeleportEntity(client, origin, angles, vec);

        // Copy HP
        SetEntityHealth(client, GetClientHealth(target));

        // Remove every equipment
        // https://forums.alliedmods.net/archive/index.php/t-200167.html
        int weapon = -1;
        for (int i = 0; i < 5; i++)
        {
            weapon = GetPlayerWeaponSlot(client, i);
            if (weapon != -1)
                RemovePlayerItem(client, weapon);
            
            // If spectatee has knife
            if (i == CS_SLOT_KNIFE && GetPlayerWeaponSlot(target, i) != -1)
                GivePlayerItem(client, "weapon_knife");
        }
    }

    return Plugin_Handled;
}