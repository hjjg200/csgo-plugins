#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <chatnotice>

public Plugin myinfo =
{
    name = "Revive",
    author = "hjjg200",
    description = "Revive on spectatee",
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

ConVar g_cvRevivePerRound;

//
new playerReviveCount[MAXPLAYERS + 1];

public void OnPluginStart()
{
    g_cvRevivePerRound = CreateConVar("sm_revive_per_round",
            "0",
            "Sets the limit how many times a player can revive in a round",
            FCVAR_NOTIFY,
            true,
            0.0,
            false,
            0.0);
    //g_cvRevivePerRound.IntValue
    LogMessage("--------------------test5");

    // Register command
    RegConsoleCmd("sm_rv", Command_Revive);

    //
    HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
    HookEvent("player_death", OnPlayerDeath);

    AutoExecConfig(true, "revive");

    LoadTranslations("revive.phrases");

    LogMessage("--------------------test0");
    //ChatNotice_Register(" abcd\x04%d %d", 3, 4);
    ChatNotice_Register("\x04%t", "Instruct command", "\x05!rv\x04");
}

public void OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        playerReviveCount[i] = 0;
    }
}

public void OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
    // TODO: show remaining revive count
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    PrintHintText(client, "남은 부활: \x04%d\n\x04!rv\x01로 부활 가능", 
        g_cvRevivePerRound.IntValue - playerReviveCount[client]);
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
    if (IsClientInGame(target))
    {
        // Check same team
        int team0, team1;
        team0 = GetClientTeam(client);
        team1 = GetClientTeam(target);
        if (team0 != team1)
        {
            // TODO: say you can only revive from a teammate
            PrintHintText(client, "\x04같은 팀원\x01에게서만 부할 가능");
            return Plugin_Handled;
        }

        // Check limit and deduct
        if (playerReviveCount[client] >= g_cvRevivePerRound.IntValue)
        {
            // TODO: show reached limit
            PrintHintText(client, "이번 라운드 부활 불가능");
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