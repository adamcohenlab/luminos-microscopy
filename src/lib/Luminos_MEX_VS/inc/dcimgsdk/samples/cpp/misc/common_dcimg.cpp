// console/misc/common.cpp
//

#include "console_dcimg.h"
#include "common_dcimg.h"

#include <stdarg.h>

#ifndef ASSERT
#define ASSERT(c)
#endif

// ----------------------------------------------------------------

/**
 @brief	show error status
 @param errid:		DCIMG error ID
 @param apiname:	function name returned error
 @param fmt:		additional text format
 */
void dcimgcon_show_dcimgerr(DCIMG_ERR errid, const char *apiname,
                            const char *fmt, ...) {
  printf("FAILED: (DCIMG_ERR)0x%08x @ %s", errid, apiname);

  if (fmt != NULL) {
    printf(" : ");

    va_list arg;
    va_start(arg, fmt);
    vprintf(fmt, arg);
    va_end(arg);
  }

  printf("\n");
}

// ----------------------------------------------------------------
// initialize DCIMG-API and DCIMG handle.

/**
 @brief open file and get DCIMG handle
 @param filename:	DCIMG file name
 @return DCIMG handle
 */
HDCIMG dcimgcon_init_open(const char *filename) {
  DCIMG_ERR err;

  // initialize DCIMG-API
  DCIMG_INIT initparam;
  memset(&initparam, 0, sizeof(initparam));
  initparam.size = sizeof(initparam);

  err = dcimg_init(&initparam);
  if (failed(err)) {
    dcimgcon_show_dcimgerr(err, "dcimg_init()");
    return NULL;
  }

  // open DCIMG file
  DCIMG_OPEN openparam;
  memset(&openparam, 0, sizeof(openparam));
  openparam.size = sizeof(openparam);
  openparam.path = filename;

  err = dcimg_open(&openparam);
  if (failed(err)) {
    dcimgcon_show_dcimgerr(err, "dcimg_open", "file name is %s", filename);
    return NULL;
  }

  return openparam.hdcimg;
}

//-------

/**
 @brief get end of file path except for extension
 @param p:	file path
 @retun		pointer is end of file path except for extension
 */
char *get_extension(char *p) {
  size_t len = strlen(p);

  char *src = p + (len - 1);
  while (src - p > 0) {
    if (*src == '.')
      return src;

    if (*src == '\\')
      break;

    src--;
  }

  return p + len;
}

// ----------------------------------------------------------------
// cmdline class

cmdline::cmdline() {
  memset(m_executefile, 0, sizeof(m_executefile));

  m_iFrame = NOTSET_FRAMEINDEX;
  m_iSession = NOTSET_SESSIONINDEX;
  m_path = NULL;

  m_argflag_frame = ARGFLAG_NONE;
  m_argflag_session = ARGFLAG_NONE;

  memset(m_targetkind, 0, sizeof(m_targetkind));
}

/**
 @brief set argument flag
 @param frameflag:		frame argument flag
 @param sessionflag:	session argument flag
 */
void cmdline::set_argment_flag(int frameflag, int sessionflag) {
  m_argflag_frame = frameflag;
  m_argflag_session = sessionflag;
}

/**
 @brief set target kind string
 @param targetkind:		target kind string
 */
void cmdline::set_targetkind(const char *targetkind) {
  strcpy_s(_secure_buf(m_targetkind), targetkind);
}

/**
 @brief	set argument of command line and interpret
 @param argc:	number of argument
 @param argv:	array of argument
 @return result of interpret argument. 0 is success.
 */
int cmdline::set_arg(int argc, char *argv[]) {
  char *p = strrchr(argv[0], '\\');
  if (p != NULL) {
    strcpy_s(_secure_buf(m_executefile), p + 1);

    p = strstr(m_executefile, ".exe");
    if (p != NULL)
      *p = 0;
    else
      memset(m_executefile, 0, sizeof(m_executefile));
  }

  int i;
  for (i = 1; i < argc; i++) {
    int ret;
    ret = interpret_option(argv[i]);
    if (ret > 0) // argument is incorrect.
      return ret;

    if (ret < 0)
      break; // end of option argument
  }

  if (i < argc) {
    m_path = argv[i];
    return 0;
  }

  printf("Error: source DCIMG file is not specified\n");
  return 3;
}

/**
 @brief	get number from argument string
 @param arg:	argument string
 @param a:		receive number
 @return boolean
 */
inline int get_number(const char *&arg, int &a) {
  // skip front blank characters
  while (isspace(*arg))
    arg++;

  if (!isdigit(*arg))
    return false; // first character is not digit.

  a = *arg++ - '0';
  while (isdigit(*arg)) {
    a *= 10;
    a += *arg++ - '0';
  }

  // skip back blank characters
  while (isspace(*arg))
    arg++;

  return true;
}

/**
 @brief	show information about argument
 @details	argument is session index only.
 @param executefile:	execute file name
 @param targetkind:		target data kind
 @return 2
 */
int usage_Session(const char *executefile, const char *targetkind) {
  if (executefile == NULL)
    printf("usage: @<session-index> <source DCIMG File>\n");
  else
    printf("usage: %s @<session-index> <source DCIMG File>\n", executefile);

  printf("This tool will extract %s in a session from source DCIMG file\n",
         targetkind);
  printf("session index is 0 based.\n");

  return 2;
}

/**
 @brief	show information about argument
 @details	argument are frame index and session index. enable to abbreviate
 session index
 @param executefile:	execute file name
 @param targetkind:		target data kind
 @return 2
 */
int usage_Frame_aSession(const char *executefile, const char *targetkind) {
  if (executefile == NULL)
    printf("usage: <frame-index>[@<session-index>] <source DCIMG File>\n");
  else
    printf("usage: %s <frame-index>[@<session-index>] <source DCIMG File>\n",
           executefile);

  printf("This tool will extract %s from source DCIMG file\n", targetkind);
  printf("session index and frame index are 0 based.\n");

  return 2;
}

/**
 @brief	show information about argument
 @details	argument are frame index and session index. enable to abbreviate
 both
 @param executefile:	execute file name
 @param targetkind:		target data kind
 @return 2
 */
int usage_aFrame_aSession(const char *executefile, const char *targetkind) {
  if (executefile == NULL)
    printf("usage: [<frame-index>][@<session-index>] <source DCIMG File>\n");
  else
    printf("usage: %s [<frame-index>][@<session-index>] <source DCIMG File>\n",
           executefile);

  printf("This tool will extract %s from source DCIMG file\n", targetkind);
  printf("session index and frame index are 0 based.\n");

  return 2;
}

/**
 @brief	show usage by argument flag
 @param argflag_frame:		frame argument flag
 @param argflag_session:	session argument flag
 @param executefile:		execute file name
 @param targetkind:			target data kind
 @return 2
 */
int usage(int argflag_frame, int argflag_session, const char *executefile,
          const char *targetkind) {
  if ((argflag_frame & ARGFLAG_ENABLE) && (argflag_session & ARGFLAG_ENABLE)) {
    if ((argflag_frame & ARGFLAG_ABBR) && (argflag_session & ARGFLAG_ABBR))
      return usage_aFrame_aSession(executefile, targetkind);
    else if (argflag_session & ARGFLAG_ABBR)
      return usage_Frame_aSession(executefile, targetkind);

    printf("unknown argument format!\n");
  } else if (argflag_session & ARGFLAG_ENABLE) {
    if (argflag_session & ARGFLAG_ABBR)
      printf("unknown argument format!\n");
    else
      return usage_Session(executefile, targetkind);
  } else {
    printf("unknown argument format!\n");
  }

  return 2;
}

/**
 @brief	interpret argument string
 @param arg:	argument string
 @return	result of interpret. 0 is success.
 */
int cmdline::interpret_option(const char *arg) {
  if (*arg == '@') {
    // atmark is prefix for session
    int a;
    if (!get_number(++arg, a)) {
      printf("@ is prefix for specifying session and following word has to be "
             "number.\n");
      return -1;
    }

    if (m_argflag_session & ARGFLAG_ENABLE) {
      if (m_iSession != NOTSET_SESSIONINDEX) {
        printf("this tool can use for one session.\n");
        return 3;
      }

      m_iSession = a;
      return 0; // success
    } else {
      printf("this tool doesn't support session index.\n");
      return 3;
    }
  }

  // check help option
  if (_stricmp(arg, "-h") == 0 || _stricmp(arg, "-help") == 0) {
    // show uage
    return usage(m_argflag_frame, m_argflag_session, m_executefile,
                 m_targetkind);
  }

  // check frame number
  {
    int a;
    if (!get_number(arg, a)) {
      if (m_argflag_frame & ARGFLAG_ENABLE) {
        if (m_iFrame == NOTSET_FRAMEINDEX &&
            (m_argflag_frame & ARGFLAG_ABBR) == 0) {
          printf("this tool needs frame index in argument.\n");
          return 3;
        }
      }

      if (m_argflag_session & ARGFLAG_ENABLE) {
        if (m_iSession == NOTSET_SESSIONINDEX &&
            (m_argflag_session & ARGFLAG_ABBR) == 0) {
          printf("this tool needs session index in argument.\n");
          return 3;
        }
      }

      return -1; // no more option argument
    }

    if (m_argflag_frame & ARGFLAG_ENABLE) {
      if (m_iFrame != NOTSET_FRAMEINDEX) {
        printf("this tool can specify one frame.\n");
        return 3;
      }

      m_iFrame = a; // specified index
      return 0;     // success
    } else {
      printf("this tool doesn't support frame index.\n");
      return 3;
    }
  }
}
