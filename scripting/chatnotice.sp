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

ConVar g_DefaultLangCode;
ConVar g_Interval;

ArrayList g_Notices;
StringMap g_NoticeIndices;
int g_Cursor;
ArrayList g_Order;

public void OnPluginStart()
{
    g_Notices = CreateArray();
    g_NoticeIndices = CreateTrie();
    g_Order = CreateArray();

    g_DefaultLangCode = CreateConVar("sm_chatnotice_default_lang_code", "en",
        "Default language code for chat notices");
    g_Interval = CreateConVar("sm_chatnotice_interval", "6",
        "How many minutes between each notice",
        0,
        true,
        1.0);

    AutoExecConfig(true, "chatnotice");

    CreateTimer(g_Interval.FloatValue * 60.0, Timer_Notice);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("ChatNotice_Register", Native_Register);
    return APLRes_Success;
}

public any Native_Register(Handle plugin, int numParams)
{
    /*
    key lang msg
     */

    char key[64], lang[8], msg[256];

    GetNativeString(1, key, sizeof(key));
    GetNativeString(2, lang, sizeof(lang));
    GetNativeString(3, msg, sizeof(msg));

    if(-1 == GetLanguageByCode(lang))
    {
        LogError("No language found for %s while registering %s", lang, key);
        return;
    }

    int idx;
    StringMap msgmap;
    if(GetTrieValue(g_NoticeIndices, key, idx))
    {
        msgmap = GetArrayCell(g_Notices, idx);
    }
    else
    {
        msgmap = CreateTrie();
        idx = PushArrayCell(g_Notices, msgmap);
        SetTrieValue(g_NoticeIndices, key, idx, false);
        PushArrayCell(g_Order, idx);
    }

    SetTrieString(msgmap, lang, msg, true);
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

    StringMap msgmap = GetArrayCell(g_Notices, GetArrayCell(g_Order, g_Cursor));
    g_Cursor++;

    char lang[8];
    char def[8];
    char buffer[256];

    g_DefaultLangCode.GetString(def, 8);
    for(int i = 1; i <= MaxClients; i++)
    {
        GetLanguageInfo(GetClientLanguage(i), lang, 8);
        if(GetTrieString(msgmap, lang, buffer, sizeof(buffer)))
        {
            PrintToChat(i, buffer);
            continue;
        }

        if(GetTrieString(msgmap, def, buffer, sizeof(buffer)))
        {
            PrintToChat(i, buffer);
            continue;
        }
    }

    return Plugin_Continue;
}

public void ShuffleOrder()
{
    SortADTArray(g_Order, Sort_Random, Sort_Integer);
}