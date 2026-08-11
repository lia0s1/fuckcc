#define _DARWIN_C_SOURCE
#include <dlfcn.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
static char g_tz[128] = "America/Los_Angeles";
static char g_lang[64] = "en_US.UTF-8";
static char g_host[256] = "MacBook-Pro.local";
static pthread_once_t g_once = PTHREAD_ONCE_INIT;
static char *(*real_getenv)(const char *) = NULL;
static void ensure_real_getenv(void) {
  if (!real_getenv)
    real_getenv = (char *(*)(const char *))dlsym(RTLD_NEXT, "getenv");
}
static void init_mask(void) {
  ensure_real_getenv();
  const char *e;
  if (real_getenv) {
    e = real_getenv("FUCKCC_TZ");
    if (!e || !e[0]) e = real_getenv("TZ");
    if (e && e[0]) {
      strncpy(g_tz, e, sizeof(g_tz) - 1);
      g_tz[sizeof(g_tz) - 1] = '\0';
    }
    e = real_getenv("FUCKCC_LANG");
    if (!e || !e[0]) e = real_getenv("LANG");
    if (e && e[0]) {
      strncpy(g_lang, e, sizeof(g_lang) - 1);
      g_lang[sizeof(g_lang) - 1] = '\0';
    }
    e = real_getenv("FUCKCC_HOSTNAME");
    if (e && e[0]) {
      strncpy(g_host, e, sizeof(g_host) - 1);
      g_host[sizeof(g_host) - 1] = '\0';
    }
  }
}
static void ready(void) { pthread_once(&g_once, init_mask); }
static int is_locale_key(const char *name) {
  if (!name) return 0;
  if (strcmp(name, "LANG") == 0 || strcmp(name, "LANGUAGE") == 0 ||
      strcmp(name, "LC_ALL") == 0 || strcmp(name, "LC_CTYPE") == 0 ||
      strcmp(name, "LC_TIME") == 0 || strcmp(name, "LC_MESSAGES") == 0 ||
      strcmp(name, "LC_NUMERIC") == 0 || strcmp(name, "LC_COLLATE") == 0 ||
      strcmp(name, "LC_MONETARY") == 0 || strcmp(name, "LC_PAPER") == 0 ||
      strcmp(name, "LC_NAME") == 0 || strcmp(name, "LC_ADDRESS") == 0 ||
      strcmp(name, "LC_TELEPHONE") == 0 || strcmp(name, "LC_MEASUREMENT") == 0 ||
      strcmp(name, "LC_IDENTIFICATION") == 0)
    return 1;
  return 0;
}
char *getenv(const char *name) {
  ensure_real_getenv();
  if (!name) return real_getenv ? real_getenv(name) : NULL;
  ready();
  if (strcmp(name, "TZ") == 0 || strcmp(name, "FUCKCC_TZ") == 0)
    return g_tz;
  if (is_locale_key(name))
    return g_lang;
  if (strcmp(name, "FUCKCC_LANG") == 0)
    return g_lang;
  if (strcmp(name, "FUCKCC_ACTIVE") == 0)
    return "1";
  if (strcmp(name, "HOSTNAME") == 0 || strcmp(name, "HOST") == 0)
    return g_host;
  if (strcmp(name, "FUCKCC_HOSTNAME") == 0)
    return g_host;
  return real_getenv ? real_getenv(name) : NULL;
}
struct tm *localtime_r(const time_t *timer, struct tm *result) {
  static struct tm *(*real_localtime_r)(const time_t *, struct tm *) = NULL;
  if (!real_localtime_r)
    real_localtime_r =
        (struct tm *(*)(const time_t *, struct tm *))dlsym(RTLD_NEXT, "localtime_r");
  ready();
  setenv("TZ", g_tz, 1);
  tzset();
  if (real_localtime_r) return real_localtime_r(timer, result);
  return NULL;
}
struct tm *localtime(const time_t *timer) {
  static struct tm result;
  return localtime_r(timer, &result);
}
int gethostname(char *name, size_t namelen) {
  static int (*real_gethostname)(char *, size_t) = NULL;
  if (!real_gethostname)
    real_gethostname = (int (*)(char *, size_t))dlsym(RTLD_NEXT, "gethostname");
  ready();
  if (!name || namelen == 0) return -1;
  size_t n = strlen(g_host);
  if (n + 1 > namelen) {
    memcpy(name, g_host, namelen - 1);
    name[namelen - 1] = '\0';
    return 0; 
  }
  memcpy(name, g_host, n + 1);
  (void)real_gethostname; 
  return 0;
}
