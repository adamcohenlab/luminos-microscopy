// console/misc/common.h
//

void dcimgcon_show_dcimgerr(DCIMG_ERR errid, const char *apiname,
                            const char *fmt = 0, ...);

HDCIMG dcimgcon_init_open(const char *filename);

//---

char *get_extension(char *p);

//-------

#define NOTSET_FRAMEINDEX -2
#define NOTSET_SESSIONINDEX -3

enum {
  ARGFLAG_ENABLE = 0x00000001, // enable argument
  ARGFLAG_ABBR = 0x00000010,   // possible to abbreviate

  ARGFLAG_NONE = 0x00000000
};

class cmdline {
public:
  cmdline();

public:
  void set_argment_flag(int frameflag, int sessionflag);
  void set_targetkind(const char *targetkind);

  int set_arg(int argc, char *argv[]);

protected:
  int interpret_option(const char *arg);

public:
  char m_executefile[256];

  int m_iSession;
  int m_iFrame;
  char *m_path;

protected:
  int m_argflag_frame;
  int m_argflag_session;

  char m_targetkind[256];
};
