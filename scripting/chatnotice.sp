#include <sourcemod>

public Plugin myinfo =
{
    name = "Chat Notice",
    author = "hjjg200",
    description = "Periodic chat notices with native",
    version = "1.0",
    url = "http://www.sourcemod.net/"
};

/*
ArrayList g_notices = ArrayList of StringMap = lang=>msg
StringMap g_notice_indices = key=>g_notices index
int g_cursor
ArrayList g_order

plugin load
{
    set cvar ...default_lang_code "en"
    set cvar ...interval 5

    save config
}

native void register(key, lang, msg)
{
    if invalid lang
        LogError

    var msgmap
    if key exists
        set it as msgmap
    else
        set msgmap as new map
        push to array
        set notice index with key

        push index to order

    set msgmap[lang] as msg
}

Action timer
{
    if size == 0
        return

    if cursor == size
        cursor = 0
        shuffle order

    msgmap = notice[order]
    for each client
        get client lang
        if lang in map
            print
            continue

        if default lang in map
            print
            continue

        LogError
}
 */

ConVar g_Interval;

ArrayList g_Notices;
int g_Cursor;
ArrayList g_Order;

public void OnPluginStart()
{
    g_Interval = CreateConVar("sm_chatnotice_interval", "6",
        "How many minutes between each notice",
        0,
        true,
        1.0);

    AutoExecConfig(true, "chatnotice");

    CreateTimer(g_Interval.FloatValue * 1.0, Timer_Notice, _, TIMER_REPEAT);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    g_Order = CreateArray();
    g_Notices = CreateArray();

    CreateNative("ChatNotice_Register", Native_Register);
    return APLRes_Success;
}

public any Native_Register(Handle plugin, int numParams)
{
    ArrayList args = CreateArray();

    PushArrayCell(args, plugin);

    char format[1024];
    GetNativeString(1, format, sizeof(format));
    LogMessage("-------- original len: %d", GetNativeStringLength(1));
    PushArrayString(args, format);
    LogMessage("----------len: %d", SetArrayString(args, 1, format));

    for(int i = 2; i <= numParams; i++)
    {
        PushArrayCell(args, GetNativeCell(i));
    }

    // Push
    PushArrayCell(g_Order, PushArrayCell(g_Notices, args));
}

public Action Timer_Notice(Handle timer)
{
    int size = GetArraySize(g_Notices);
    if(size == 0)
    {
        return Plugin_Continue;
    }

    if(g_Cursor == size)
    {
        g_Cursor = 0;
        ShuffleOrder();
    }

    ArrayList args = GetArrayCell(g_Notices, GetArrayCell(g_Order, g_Cursor));
    g_Cursor++;

    int len = GetArraySize(args);
    Handle plugin = GetArrayCell(args, 0);
    Function fn = GetFunctionByName(plugin, "ChatNotice_PrintToChat");

    char format[1024];
    GetArrayString(args, 1, format, sizeof(format));

    PrintToChatAll("aaa %s", format);

    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsClientInGame(i)) continue;
        Call_StartFunction(plugin, fn);
        Call_PushCell(i);
        Call_PushString(" a2ef\x04%t");
        for(int j = 2; j < len; j++)
            Call_PushCell(GetArrayCell(args, j));

        Call_Finish();
    }

    return Plugin_Continue;
}

public void ShuffleOrder()
{
    SortADTArray(g_Order, Sort_Random, Sort_Integer);
}