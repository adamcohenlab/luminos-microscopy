/**
 @file	get_fileinformation.cpp
 @brief		sample code to get file information
 @details	This program gets file information
 @remarks	dcimg_init
 @remarks	dcimg_open
 @remarks	dcimg_getparaml
 @remarks	dcimg_setsessionindex
 */

#include "../misc/console_dcimg.h"
#include "../misc/common_dcimg.h"

/**
 @brief show format version of opened file
 @param hdcimg:		DCIMG handle
 */
void show_fileformat_version(HDCIMG hdcimg) {
  DCIMG_ERR err;

  int32 paraml = 0;
  err = dcimg_getparaml(hdcimg, DCIMG_IDPARAML_FILEFORMAT_VERSION, &paraml);
  if (failed(err)) {
    dcimgcon_show_dcimgerr(
        err, "dcimg_getparaml(DCIMG_IDPARAML_FILEFORMAT_VERSION)");
    return;
  }

  int32 major = (paraml & 0xFF000000) >> 24;
  int32 minor = (paraml & 0x00FF0000) << 16;
  int32 rev = (paraml & 0x0000FFFF);

  printf("File Format:\t%d.%d.%d\n", major, minor, rev);
}

/**
 @brief get number of total frame in opened file.
 @param hdcimg:			DCIMG handle
 @param totalframecount	number of total frame
 @return	result to get number of total frame
 */
BOOL get_totalframecount(HDCIMG hdcimg, int32 &totalframecount) {
  DCIMG_ERR err;

  int32 paraml = 0;

  // get total frame count
  err = dcimg_getparaml(hdcimg, DCIMG_IDPARAML_NUMBEROF_TOTALFRAME, &paraml);
  if (failed(err)) {
    dcimgcon_show_dcimgerr(
        err, "dcimg_getparaml(DCIMG_IDPARAML_NUMBEROF_TOTALFRAME)");
    return FALSE;
  }

  totalframecount = paraml;

  return TRUE;
}

/**
 @brief get number of session in opened file.
 @param hdcimg:			DCIMG handle
 @param sessioncount	number of session
 @return	result to get number of session
 */
BOOL get_sessioncount(HDCIMG hdcimg, int32 &sessioncount) {
  DCIMG_ERR err;

  int32 paraml = 0;

  // get session count
  err = dcimg_getparaml(hdcimg, DCIMG_IDPARAML_NUMBEROF_SESSION, &paraml);
  if (failed(err)) {
    dcimgcon_show_dcimgerr(err,
                           "dcimg_getparaml(DCIMG_IDPARAML_NUMBEROF_SESSION)");
    return FALSE;
  }

  sessioncount = paraml;

  return TRUE;
}

/**
 @brief get image information of current session.
 @param hdcimg:		DCIMG handle
 @param width		image width
 @param height		image height
 @param rowbytes	image row bytes
 @param pixeltype	image pixle type
 @return	result to get image information
 */
BOOL get_image_information(HDCIMG hdcimg, int32 &width, int32 &height,
                           int32 &rowbytes, int32 &pixeltype) {
  DCIMG_ERR err;

  int32 nWidth;
  // get width
  err = dcimg_getparaml(hdcimg, DCIMG_IDPARAML_IMAGE_WIDTH, &nWidth);
  if (failed(err)) {
    dcimgcon_show_dcimgerr(err, "dcimg_getparaml(DCIMG_IDPARAML_IMAGE_WIDTH)");
    return FALSE;
  }

  int32 nHeight;
  // get height
  err = dcimg_getparaml(hdcimg, DCIMG_IDPARAML_IMAGE_HEIGHT, &nHeight);
  if (failed(err)) {
    dcimgcon_show_dcimgerr(err, "dcimg_getparaml(DCIMG_IDPARAML_IMAGE_HEIGHT)");
    return FALSE;
  }

  int32 nRowbytes;
  // get row bytes
  err = dcimg_getparaml(hdcimg, DCIMG_IDPARAML_IMAGE_ROWBYTES, &nRowbytes);
  if (failed(err)) {
    dcimgcon_show_dcimgerr(err,
                           "dcimg_getparaml(DCIMG_IDPARAML_IMAGE_ROWBYTES)");
    return FALSE;
  }

  int32 nPixeltype;
  // get pixel type
  err = dcimg_getparaml(hdcimg, DCIMG_IDPARAML_IMAGE_PIXELTYPE, &nPixeltype);
  if (failed(err)) {
    dcimgcon_show_dcimgerr(err,
                           "dcimg_getparaml(DCIMG_IDPARAML_IMAGE_PIXELTYPE)");
    return FALSE;
  }

  width = nWidth;
  height = nHeight;
  rowbytes = nRowbytes;
  pixeltype = nPixeltype;

  return TRUE;
}

/**
 @brief show designated session information.
 @param hdcimg:			DCIMG handle
 @param sessionindex	session index
 @return	result to show session information
 */
BOOL show_session_information(HDCIMG hdcimg, int32 sessionindex) {
  DCIMG_ERR err;

  // change current session
  err = dcimg_setsessionindex(hdcimg, sessionindex);
  if (failed(err)) {
    dcimgcon_show_dcimgerr(err, "dcimg_setsessionindex()", "index=%d",
                           sessionindex);
    return FALSE;
  }

  int32 nFrame;
  // get number of frame in current session
  err = dcimg_getparaml(hdcimg, DCIMG_IDPARAML_NUMBEROF_FRAME, &nFrame);
  if (failed(err)) {
    dcimgcon_show_dcimgerr(err,
                           "dcimg_getparaml(DCIMG_IDPARAML_NUMBEROF_FRAME)");
    return FALSE;
  }

  int32 nView;
  // get number of view in current session
  err = dcimg_getparaml(hdcimg, DCIMG_IDPARAML_NUMBEROF_VIEW, &nView);
  if (failed(err)) {
    dcimgcon_show_dcimgerr(err,
                           "dcimg_getparaml(DCIMG_IDPARAML_NUMBEROF_VIEW)");
    return FALSE;
  }

  int32 nWidth, nHeight, nRowbyte, nPixelType;
  // get image information
  if (!get_image_information(hdcimg, nWidth, nHeight, nRowbyte, nPixelType)) {
    return FALSE;
  }

  if (nView > 1)
    printf("#%d session: %d frames(x%d views): ", sessionindex, nFrame, nView);
  else
    printf("#%d session: %d frames: ", sessionindex, nFrame);

  printf("%d x %d ", nWidth, nHeight);

  switch (nPixelType) {
  case DCIMG_PIXELTYPE_MONO8:
    printf("(MONO8) ");
    break;
  case DCIMG_PIXELTYPE_MONO16:
    printf("(MONO16) ");
    break;
  default:
    printf("(Unknown Pixel Type=%d) ", nPixelType);
    break;
  }

  printf("rowbytes = %d\n", nRowbyte);

  return TRUE;
}

int main(int argc, char *const argv[]) {
  printf("PROGRAM START\n");

  int ret = 0;

  // check command line argument
  if (argc < 2) {
    printf("Error: an argument is necessary to run this program.\n");
    printf("usage: get_fileinformation <source DCIMG File>\n");
    ret = 3;
  } else if (_stricmp(argv[1], "-h") == 0 || _stricmp(argv[1], "-help") == 0) {
    printf("usage: get_fileinformation <source DCIMG File>\n");
    printf("This tool will show some information of the target DCIMG file.\n");
    ret = 2;
  }

  if (ret == 0) {
    const char *filename = argv[1];

    // initialize and open
    HDCIMG hdcimg = dcimgcon_init_open(filename);
    if (hdcimg == NULL) {
      ret = 3;
    } else {
      int32 nTotalFrame, nSession;

      // get number of total frame and session.
      if (get_totalframecount(hdcimg, nTotalFrame) &&
          get_sessioncount(hdcimg, nSession)) {
        printf("Information of DCIMG file %s.\n", filename);
        // show file format version
        show_fileformat_version(hdcimg);

        printf("Number of total frames: %d\n", nTotalFrame);
        printf("Number of session: %d\n", nSession);

        // show each session information
        int32 iSession;
        for (iSession = 0; iSession < nSession; iSession++) {
          if (!show_session_information(hdcimg, iSession)) {
            ret = 3;
            break;
          }
        }
      } else {
        ret = 3;
      }

      // close handle
      dcimg_close(hdcimg);
    }
  }

  printf("PROGRAM END\n");
  return ret;
}