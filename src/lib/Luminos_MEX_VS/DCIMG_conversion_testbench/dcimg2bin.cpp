/* * * * * * * * * * * * * * * * * * * *\
 *                                     *
 *   2018 Vicente Parot                *
 *   Cohen Lab - Harvard University    *
 *                                     *
 *   Modified from Hamamatsu DCIMGAPI  *
 *  Example: access_recorded_image.cpp *
 * Convert_file optimized for IO 2024  *
 * by F. Phil Brooks III               *
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
#define sprintf_sDebugThread(...) sprintf_s(__VA_ARGS__)
#define MSGSIZE 512
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
    char msg[MSGSIZE];
    sprintf_sDebugThread(msg,MSGSIZE, "%s file name is %S", "dcimg_open", filename);
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
//This new version copies full frames at a time instead of line-by-line
//It is possible this could cause issues under some circumstances if the lines
//are stored in reverse order in the dcimg, but it appears to work under typical
//circumstances. Set the LINEBYLINE flag to 1 if you want the old behavior (3x slower)
#define LINEBYLINE 0
bool convert_file(const char *dcimg_fname, const char *fname_bin_temp) {
  bool return_value = true;
  char msg[MSGSIZE];

  // make destination path
  char dstpath[MAX_PATH * 8];
  strcpy_s(dstpath, MAX_PATH*8,fname_bin_temp);

  const size_t cSize = strlen(dcimg_fname) + 1;
  wchar_t *wc_dcimgfile = new wchar_t[cSize];
  size_t *chars_converted = 0;
  mbstowcs_s(chars_converted,wc_dcimgfile,cSize, dcimg_fname, cSize);

  HDCIMG hdcimg = dcimgcon_init_open(wc_dcimgfile);
  if (hdcimg == NULL) {
    sprintf_sDebugThread(msg, MSGSIZE,"could not open dcimg file\n%s", dcimg_fname);
    myErrMsgFcn(msg);
    return_value = false;
  }
  // printfDebugThread("reading %s\n",dcimg_fname);
  DCIMG_ERR err;

  // get number of frame
  int32 nFrame;
  err = dcimg_getparaml(hdcimg, DCIMG_IDPARAML_NUMBEROF_FRAME, &nFrame);
  if (failed(err)) {
    sprintf_sDebugThread(msg,MSGSIZE,
                       "could not get the number of frames in dcimg file\n%s",
                       dcimg_fname);
    myErrMsgFcn(msg);
    return_value = false;
  }

  char *p = (char *)get_extension(dstpath);
  sprintf_sDebugThread(p, 5,".bin");
  FILE *fp;
  fopen_s(&fp,dstpath, "wb");
  if (!fp) {
    sprintf_sDebugThread(msg, MSGSIZE,"could not open bin file\n%s", dstpath);
    myErrMsgFcn(msg);
    return_value = false;
  }
  printfDebugThread("writing %s\n", dstpath);

  //Iterate through frames
  for (int it = 0; return_value && it < nFrame; it++) {
    if (!((it + 1) % 1000)) { //print message every 1000 frames
      printfDebugThread("writing frame %d\n", it + 1);
    }

    // access to frame data
    DCIMG_FRAME frame;
    memset(&frame, 0, sizeof(frame)); //overwrite zeros
    frame.size = sizeof(frame);
    frame.iFrame = it;

    err = dcimg_lockframe(hdcimg, &frame); //Get pointer to image data in DCIMG file. We are okay just accessing the original data buffer, so we don't need dcimg_copyframe()
    if (failed(err)) {
      sprintf_sDebugThread(msg,MSGSIZE, "%s #%d frame", "dcimg_lockframe()",
                         frame.iFrame);
      myErrMsgFcn(msg);
      return_value = false;
    }

    int rowbytes_body; //bytes per image row
    switch (frame.type) {
    case DCIMG_PIXELTYPE_MONO8:
      rowbytes_body = frame.width;
      break;
    case DCIMG_PIXELTYPE_MONO16:
      rowbytes_body = frame.width * 2;
      break;
    default:
      sprintf_sDebugThread(msg, MSGSIZE,"unsupported pixel type: %d", frame.type);
      myErrMsgFcn(msg);
      return_value = false;
      break;
    }
#if LINEBYLINE

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
#else
      if (fwrite((char*)frame.buf, rowbytes_body*frame.height,1, fp) < 1) { //fwrite returns number of items written (should be 1)
        fclose(fp);
        printfDebugThread("bin file closed\n");
        // close DCIMG handle
        dcimg_close(hdcimg);
        printfDebugThread("dcimg file closed\n");
        return_value = false;
      }
#endif     

  }
  fclose(fp);
  printfDebugThread("bin file closed\n");

  // close DCIMG handle
  dcimg_close(hdcimg);
  printfDebugThread("dcimg file closed\n");
  return return_value;
}
#endif // HAMAMATSU_CONFIGURED