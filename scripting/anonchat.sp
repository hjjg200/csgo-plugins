#include <sourcemod>
#include <chatnotice>

public Plugin myinfo =
{
    name = "Anonymous Chat",
    author = "hjjg200",
    description = "Anonymous chat plugin",
    version = "1.0",
    url = "http://www.sourcemod.net/"
};


/*
Array[EPOCH_SIZE] = 1 - EPOCH_SIZE shuffled
Array[BATCH_SIZE] = 1 - BATCH_SIZE shuffled
Array[MaxClients] = ClientID -> Muted steam IDs map
Array steam IDs = auto_increment -> steam ID
Array[MaxClients] steam ID index = clientID -> steadm IDs index
Array[EPOCH_SIZE] = ChatNo -> steam ID map key

chat {
    prevent default event

    if batch ended {
        shuffle batch array
        batch cursor to 0
    }
    if epoch ended {
        epoch cursor to 0
    }

    get chatNo
    get steam_id

    for clients {
        if mutelist[each][steam_id] is set {
            continue
        }
        print chat #chatNo: ...
        if client == each {
            different color for #chatNo
        }
        if client is admin {
            include nickname
        }
    }
}

mute {
    var muted

    get muted client id from array
    if -1 {
        user is not found
        return
    }

    get steam id of muted

    mutelist[client][muted steam id] = true

    print have muted user #chatNo
}

unmute_all {
    clear mutelist[client]

    print unmuted %d users
}

on_user_join {
    unmute_all
    add steam ID
    steamID index[auto incr] = index
}

on map start {
    clear steam IDs
    epoch cursor to 0
    bath cursor to 0
    shuffle epoch
    shuffle batch
}
 */

#define EPOCH_SIZE 1000
#define BATCH_SIZE 10

#define STEAM_ID_LENGTH 32

int g_epoch[EPOCH_SIZE];
int g_batch[BATCH_SIZE];
int g_epoch_cursor = 0;
int g_batch_cursor = 0;

ArrayList g_steamIDs;

bool g_clientMuteAll[MAXPLAYERS+1];
StringMap g_clientMutedSteamIDMaps[MAXPLAYERS+1];
int g_clientSteamIDIndices[MAXPLAYERS+1];

int g_chatSteamIDIndices[EPOCH_SIZE];

public void OnPluginStart()
{
    for(int i = 0; i < EPOCH_SIZE; i++)
    {
        g_epoch[i] = i;
    }
    for(int i = 0; i < BATCH_SIZE; i++)
    {
        g_batch[i] = i;
    }

    g_steamIDs = new ArrayList(STEAM_ID_LENGTH);

    for(int i = 1; i <= MaxClients; i++)
    {
        g_clientMuteAll[i] = false;
        g_clientMutedSteamIDMaps[i] = CreateTrie();
    }

    LoadTranslations("anonchat.phrases");

    ChatNotice_Register("\x05%t", "anonchat.command.mute", "!mu", "anonchat.chatno");
    ChatNotice_Register("\x05%t", "anonchat.command.muteall", "!muall");
    ChatNotice_Register("\x05%t", "anonchat.command.unmuteall", "!unmuall");

    RegConsoleCmd("sm_mu", Command_Mute);
    RegConsoleCmd("sm_muall", Command_MuteAll);
    RegConsoleCmd("sm_unmuall", Command_UnmuteAll);
}

public Action Command_Mute(int client, int argc)
{
    if(client < 1) return Plugin_Handled;

    if(argc != 1)
    {
        PrintToChat(client, "!mu <chat no> to mute");
        return Plugin_Handled;
    }

    char arg[16];
    int from = 0;

    GetCmdArg(1, arg, sizeof(arg));
    if(arg[0] == '#') from++;

    // Check chat no
    int chatNo = -1;
    StringToIntEx(arg[from], chatNo);
    if(chatNo < 0 || chatNo >= EPOCH_SIZE)
    {
        PrintToChat(client, "Invalid chat no");
        return Plugin_Handled;
    }

    int idx = g_chatSteamIDIndices[chatNo];
    char steamID[STEAM_ID_LENGTH];

    if(idx < 0 || idx >= GetArraySize(g_steamIDs))
    {
        PrintToChat(client, "User not found");
        return Plugin_Handled;
    }

    GetArrayString(g_steamIDs, idx, steamID, STEAM_ID_LENGTH);

    

    return Plugin_Handled;
}

public Action Command_MuteAll(int client, int argc)
{
    if(client < 1) return Plugin_Handled;

    return Plugin_Handled;
}

public Action Command_UnmuteAll(int client, int argc)
{
    if(client < 1) return Plugin_Handled;
    
    return Plugin_Handled;
}

public void ReduceSteamIDs()
{
    ClearArray(g_steamIDs);
    for(int i = 1; i <= MaxClients; i++)
    {
        if(false == IsClientAuthorized(i))
            continue;

        RegisterSteamID(i);
    }
}

public void RegisterSteamID(client)
{
    char steamID[STEAM_ID_LENGTH];
    GetClientAuthId(client, AuthId_Steam3, steamID, STEAM_ID_LENGTH);
    g_clientSteamIDIndices[client] = PushArrayString(g_steamIDs, steamID);
}

public void OnMapStart()
{
    // Clean steamd IDs up
    ReduceSteamIDs();
    ClearChatEpoch();

    // Reset epoch and batch
    g_epoch_cursor = 0;
    g_batch_cursor = 0;
    ShuffleEpoch();
    ShuffleBatch();
}

public void ShuffleEpoch()
{
    SortIntegers(g_epoch, EPOCH_SIZE, Sort_Random);
}

public void ShuffleBatch()
{
    SortIntegers(g_batch, BATCH_SIZE, Sort_Random);
}

public void ClearChatEpoch()
{
    for(int i = 0; i < EPOCH_SIZE; i++)
    {
        g_chatSteamIDIndices[i] = -1;
    }
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
    if(g_batch_cursor == BATCH_SIZE)
    {
        ShuffleBatch();
        g_batch_cursor = 0;
        g_epoch_cursor += BATCH_SIZE;
    }
    // if cursor exceeds boundary
    int add = g_batch[g_batch_cursor];
    if(g_epoch_cursor + add >= EPOCH_SIZE /*|| g_epoch_cursor == EPOCH_SIZE*/)
    {
        g_epoch_cursor = 0;
    }

    // Get chatNo
    int chatNo = g_epoch[g_epoch_cursor + add];
    //g_epoch_cursor++;
    g_batch_cursor++;

    char steamID[STEAM_ID_LENGTH];
    GetClientAuthId(client, AuthId_Steam3, steamID, STEAM_ID_LENGTH);

    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsClientInGame(i))
            continue;

        if(i == client)
        {
            PrintToChat(i, " \x03#%d: \x01%s", chatNo, sArgs);
            continue;
        }

        StringMap muted = g_clientMutedSteamIDMaps[i];
        bool ok;
        if(GetTrieValue(muted, steamID, ok) || g_clientMuteAll[i] == true)
            continue;

        if(CheckCommandAccess(i, "sm_admin", ADMFLAG_GENERIC))
        {
            PrintToChat(i, " \x04#%d %N: \x01%s", chatNo, client, sArgs);
        }
        else
        {
            PrintToChat(i, " \x04#%d: \x01%s", chatNo, sArgs);
        }
    }
    return Plugin_Handled;
/*
default (white): \x01
teamcolour (will be purple if message from server): \x03
red: \x07
lightred: \x0F
darkred: \x02
bluegrey: \x0A
blue: \x0B
darkblue: \x0C
purple: \x03
orchid: \x0E
yellow: \x09
gold: \x10
lightgreen: \x05
green: \x04
lime: \x06
grey: \x08
grey2: \x0D
 */
}

/*
1: success
0: already muted
-1: user not found
 */
public int Mute(int client, int chatNo)
{
    int targetIdx = g_chatSteamIDIndices[chatNo];
    if(targetIdx == -1)
        return -1;

    char targetID[STEAM_ID_LENGTH];
    GetArrayString(g_steamIDs, targetIdx, targetID, STEAM_ID_LENGTH);

    if(SetTrieValue(g_clientMutedSteamIDMaps[client], targetID, true, false))
        return 1;
    return 0;
}

public int UnmuteAll(int client)
{
    StringMap muted = g_clientMutedSteamIDMaps[client];
    int size = GetTrieSize(muted);

    ClearTrie(muted);
    return size;
}

public void OnClientPostAdminCheck(int client)
{
    UnmuteAll(client);
    RegisterSteamID(client);
}