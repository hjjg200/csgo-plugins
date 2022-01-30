#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

public Plugin myinfo =
{
    name = "Grenade on Impact",
    author = "hjjg200",
    description = "[CSGO] Detonate grenades on impact",
    version = "1.0",
    url = "http://www.sourcemod.net/"
};

/*

on entity spawn {
    hook sdk spawn
    hook sdk shouldcollide
}

sdk spawn hook {
    unhook spawn
}

sdk shouldcollide {
    unhook shouldcollide

    timer for detonate
}

 */

StringMap g_ProjectileKeys;

public void OnPluginStart()
{
    g_ProjectileKeys = CreateTrie();
    SetTrieValue(g_ProjectileKeys, "hegrenade_projectile", true);
    SetTrieValue(g_ProjectileKeys, "smokegrenade_projectile", true);
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if(!IsValidEntity(entity)) return;

    bool ok;
    if(!GetTrieValue(g_ProjectileKeys, classname, ok)) return;

    SDKHook(entity, SDKHook_TouchPost, OnTouchPost);
}

public void OnTouchPost(int entity)
{
    SDKUnhook(entity, SDKHook_TouchPost, OnTouchPost);

    // Making stationary let smoke detonate mid-air
    // tested working 2022 Jan
    SetEntityMoveType(entity, MOVETYPE_NONE);
    float v[3] = {0.0, 0.0, 0.0};
    TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, v);

    // https://forums.alliedmods.net/showthread.php?p=1989016
    // https://forums.alliedmods.net/showthread.php?p=1985693#post1985693
    SetEntProp(entity, Prop_Data, "m_nNextThinkTick", 1);
    SetEntProp(entity, Prop_Data, "m_takedamage", 2);
    SetEntProp(entity, Prop_Data, "m_iHealth", 1);
    SDKHooks_TakeDamage(entity, 0, 0, 1.0);
}
