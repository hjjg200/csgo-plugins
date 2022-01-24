
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
native void ChatNotice_Register(const char[] format, any... ...);

/**
 * Load requested phrases
 *
 * @param file phrases file
 */
native void ChatNotice_LoadTranslations(const char[] file);