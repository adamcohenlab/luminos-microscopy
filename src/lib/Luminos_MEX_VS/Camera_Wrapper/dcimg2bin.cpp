/* * * * * * * * * * * * * * * * * * * *\
 *                                     *
 *   2018 Vicente Parot                *
 *   Cohen Lab - Harvard University    *
 *                                     *
 *   Modified from Hamamatsu DCIMGAPI  *
 *   Example                           *
\* * * * * * * * * * * * * * * * * * * */
// Convert dcimg files to bin using Hamamatsu proprietary library calls
#include "pch.h"
#include "Cam_Wrapper.h"
#ifdef HAMAMATSU_CONFIGURED

// #define _CRT_SECURE_NO_WARNINGS

#include "dcimg2bin.h"
// debug printing outside of threads
// #define printfDebugThread(...) printf(__VA_ARGS__)
// #define sprintfDebugThread(...) sprintf(__VA_ARGS__)

// safe to use inside threads
#define printfDebugThread(...)                                                 \
  {}
#define sprintfDebugThread(...) sprintf(__VA_ARGS__)

// Print error message from dcimg conversion
void dcimgcon_show_dcimgerr(DCIMG_ERR errid, const char *apiname) {
  printfDebugThread("FAILED: (DCIMG_ERR)0x%08x @ %s", errid, apiname);
  printfDebugThread("\n");
}

// Initialize and open dcimg file.
HDCIMG dcimgcon_init_open(const wchar_t *filename) {
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
  openparam.path = (LPCWSTR)filename;
  err = dcimg_open(&openparam);
  if (failed(err)) {
    char msg[512];
    sprintfDebugThread(msg, "%s file name is %S", "dcimg_open", filename);
    dcimgcon_show_dcimgerr(err, msg);
    return NULL;
  }
  return openparam.hdcimg;
}

// Get filename extension string.
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

// Convert file from dcimg to bin format
bool convert_file(const char *dcimg_fname, const char *fname_bin_temp) {
  bool return_value = true;
  char msg[512];

  // make destination path
  char dstpath[MAX_PATH * 8];
  strcpy(dstpath, fname_bin_temp);

  const size_t cSize = strlen(dcimg_fname) + 1;
  wchar_t *wc_dcimgfile = new wchar_t[cSize];
  mbstowcs(wc_dcimgfile, dcimg_fname, cSize);

  HDCIMG hdcimg = dcimgcon_init_open(wc_dcimgfile);
  if (hdcimg == NULL) {
    sprintfDebugThread(msg, "could not open dcimg file\n%s", dcimg_fname);
    myErrMsgFcn(msg);
    return_value = false;
  }
  // printfDebugThread("reading %s\n",dcimg_fname);
  DCIMG_ERR err;

  // get number of frame
  int32 nFrame;
  err = dcimg_getparaml(hdcimg, DCIMG_IDPARAML_NUMBEROF_FRAME, &nFrame);
  if (failed(err)) {
    sprintfDebugThread(msg,
                       "could not get the number of frames in dcimg file\n%s",
                       dcimg_fname);
    myErrMsgFcn(msg);
    return_value = false;
  }

  char *p = (char *)get_extension(dstpath);
  sprintfDebugThread(p, ".bin");

  FILE *fp = fopen(dstpath, "wb");
  if (!fp) {
    sprintfDebugThread(msg, "could not open bin file\n%s", dstpath);
    myErrMsgFcn(msg);
    return_value = false;
  }
  printfDebugThread("writing %s\n", dstpath);

  for (int it = 0; return_value && it < nFrame; it++) {
    if (!((it + 1) % 1000)) {
      printfDebugThread("writing frame %d\n", it + 1);
    }

    // access to frame data
    DCIMG_FRAME frame;
    memset(&frame, 0, sizeof(frame));
    frame.size = sizeof(frame);
    frame.iFrame = it;

    err = dcimg_lockframe(hdcimg, &frame);
    if (failed(err)) {
      sprintfDebugThread(msg, "%s #%d frame", "dcimg_lockframe()",
                         frame.iFrame);
      myErrMsgFcn(msg);
      return_value = false;
    }
    int rowbytes_body;
    switch (frame.type) {
    case DCIMG_PIXELTYPE_MONO8:
      rowbytes_body = frame.width;
      break;
    case DCIMG_PIXELTYPE_MONO16:
      rowbytes_body = frame.width * 2;
      break;
    default:
      sprintfDebugThread(msg, "unsupported pixel type: %d", frame.type);
      myErrMsgFcn(msg);
      return_value = false;
      break;
    }
    int rowbytes_skip = frame.rowbytes;

    const char *src = (const char *)frame.buf;

    int y;
    for (y = 0; return_value && y < frame.height; y++) {
      if (fwrite(src, rowbytes_body, 1, fp) < 1) {
        fclose(fp);
        printfDebugThread("bin file closed\n");
        // close DCIMG handle
        dcimg_close(hdcimg);
        printfDebugThread("dcimg file closed\n");
        return_value = false;
      }
      src = (const char *)src + rowbytes_skip;
    }
  }
  fclose(fp);
  printfDebugThread("bin file closed\n");

  // close DCIMG handle
  dcimg_close(hdcimg);
  printfDebugThread("dcimg file closed\n");
  return return_value;
}

#endif // HAMAMATSU_CONFIGURED