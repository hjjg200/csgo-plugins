#include <sourcemod>

public Plugin myinfo =
{
    name = "Noblock",
    author = "hjjg200",
    description = "[CSGO] No block",
    version = "1.0",
    url = "http://www.sourcemod.net/"
};

// https://developer.valvesoftware.com/wiki/Collision_groups
#define COLLISION_GROUP_DEBRIS_TRIGGER 2
#define COLLISION_GROUP_INTERACTIVE_DEBRIS 3
#define COLLISION_GROUP_PLAYER 5
#define COLLISION_GROUP_PUSHAWAY 17

int g_CollisionGroup;

public void OnPluginStart()
{
    g_CollisionGroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");

    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int userid = GetEventInt(event, "userid");
    int client = GetClientOfUserId(userid);

    SetEntData(client, g_CollisionGroup, COLLISION_GROUP_INTERACTIVE_DEBRIS, 4, true);
}