
#if defined _chatnotice_included_
  #endinput
#endif
#define _chatnotice_included_

/**
 * Register a chat notice
 *
 * @param format  char[1024]; Notice message format
 * @param ...     format elements
 */
native void ChatNotice_Register(const char[] format, any ...);

/**
 * PrintToChat forwarder
 */
public void ChatNotice_PrintToChat(int client, const char[] format, any ...)
{
    char /*buffer[1024], */buffer2[1024];
    SetGlobalTransTarget(client);
    //Format(buffer, sizeof(buffer), "\x01%s", format);
    VFormat(buffer2, sizeof(buffer2), format, 3);
    PrintToChat(client, buffer2);
}