
#if defined _chatnotice_included_
  #endinput
#endif
#define _chatnotice_included_
 
/**
 * Register a chat notice
 *
 * @param key     Unique key of the notice
 * @param lang    Language code(e.g. en, es, ko) of the added notice
 * @param msg     char[256]; Notice message
 */
native void ChatNotice_Register(const char[] key, const char[] lang, const char[] msg);