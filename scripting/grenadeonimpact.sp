#include <sourcemod>
#include <sdkhooks>

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
    SetTrieValue(g_ProjectileKeys, "flashbang_projectile", true);
    SetTrieValue(g_ProjectileKeys, "smokegrenade_projectile", true);
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if(!IsValidEntity(entity)) return;

    bool ok;
    if(!GetTrieValue(g_ProjectileKeys, classname, ok)) return;

    SDKHook(entity, SDKHook_StartTouch, OnStartTouch);
}

public void OnStartTouch(int entity)
{
    SDKUnhook(entity, SDKHook_StartTouch, OnStartTouch);

    // Not using EntToRef might cause problem
    // https://forums.alliedmods.net/archive/index.php/t-235247.html
    int ref = EntIndexToEntRef(entity);
    PrintToChatAll("ok");

    // Wait 0.2 seconds for maps like smoke grenade fight
    CreateTimer(0.2, Timer_Detonate, ref);
}

// https://forums.alliedmods.net/showthread.php?p=1989016
// https://forums.alliedmods.net/showthread.php?p=1985693#post1985693
public Action Timer_Detonate(Handle timer, int ref)
{
    int entity = EntRefToEntIndex(ref);

    if(entity == INVALID_ENT_REFERENCE) return Plugin_Stop;

    SetEntProp(entity, Prop_Data, "m_nNextThinkTick", 1);
    SetEntProp(entity, Prop_Data, "m_takedamage", 2 );
    SetEntProp(entity, Prop_Data, "m_iHealth", 1 );
    SDKHooks_TakeDamage(entity, 0, 0, 1.0);

    return Plugin_Stop;
}