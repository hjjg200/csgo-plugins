#include <sourcemod>

public Plugin myinfo =
{
    name = "Alt Hostname",
    author = "hjjg200",
    description = "Alternating hostname",
    version = "1.0",
    url = "http://www.sourcemod.net/"
};

ConVar g_CvarHostname;
ConVar g_CvarInterval;
ConVar g_CvarAlt1;
ConVar g_CvarAlt2;
CreateStack g_Hostnames;

public void OnPluginStart()
{
    g_CvarHostname = FindConVar("hostname");

    g_CvarInterval = CreateConVar("sm_althostname_interval", "5",
        "Minutes between changes",
        FCVAR_NOTIFY, true, 1.0, false, 0.0);
    g_CvarAlt1 = CreateConVar("sm_althostname_1", "", "First alternative hostname");
    g_CvarAlt2 = CreateConVar("sm_althostname_2", "", "Second alternative hostname");

    AutoExecConfig(true, "althostname");

    g_Hostnames = CreateStack(256);
    PushIfNotEmpty(g_CvarAlt1);
    PushIfNotEmpty(g_CvarAlt2);
    PushIfNotEmpty(g_CvarHostname);

    ScheduleTimer();
}

public Action Timer_Alternate(Handle timer)
{
    char name[256];
    PopStackString(g_Hostnames, name, sizeof(name));
    PushStackString(g_Hostnames, name);

    SetConVarString(g_CvarHostname, name);
    ScheduleTimer();
}

ScheduleTimer()
{
    CreateTimer(60.0 * GetConVarFloat(g_CvarInterval), Timer_Alternate);
}

PushIfNotEmpty(ConVar alt)
{
    char name[256];

    GetConVarString(alt, name, sizeof(name));
    if(strlen(name) == 0)
        return;

    PushStackString(g_Hostnames, name);
}