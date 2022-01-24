
#if defined _chatnotice_included_
  #endinput
#endif
#define _chatnotice_included_
 
/**
 * Register a chat notice
 *
 * @param format  char[256]; Notice message format
 * @param ...     format elements
 */
native void ChatNotice_Register(const char[] format, ...);