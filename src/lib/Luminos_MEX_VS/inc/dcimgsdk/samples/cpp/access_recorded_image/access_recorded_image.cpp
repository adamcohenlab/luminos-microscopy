/**
 @file	access_recorded_image.cpp
 @brief		sample code to access the image in file
 @details	This program gets the specified image and makes the raw data
 file. The function used to access image is changed by the directive
 "USE_COPYFRAME".
 @remarks	dcimg_lockframe
 @remarks	dcimg_copyframe
 */

#include "../misc/console_dcimg.h"
#include "../misc/common_dcimg.h"

/**
 @def	USE_COPYFRAME
 *
 *0:	dcimg_lockframe is used to access image.\n
 *				This function gets the pointer of image, so it is
 necessary to copy the target ROI from this pointer.
 *
 *1:	dcimg_copyframe is used to access image.\n
 *				This function sets the pointer of buffer to get
 image. DCIMG copies the target ROI to this pointer.
 */
#define USE_COPYFRAME                                                          \
  0 // 0: call dcimg_lockframe to access image, 1: call dcimg_copyframe to
    // access image

/**
 @brief	get image information
 @param	hdcimg:		DCIMG handle
 @param width:		image width
 @param height:		image height
 @param rowbytes:	image rowbytes
 @param pixeltype:	DCIMG_PIXELTYPE value
 @return	result to get information
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
 @brief	write image data as raw data
 @param dstpath:		specified file path
 @param src:			pointer of top of image data
 @param rowbytes_skip:	row bytes of src data
 @param rowbytes_body:	row bytes of image data
 @param heght:			image height
 @return	result to make file
 */
int save_rawfile(const char *dstpath, const void *src, int rowbytes_skip,
                 int rowbytes_body, int height) {
  FILE *fp;
  int err = fopen_s(&fp, dstpath, "wb");
  if (err != 0) {
    printf("Fail to open destination file %s.\n", dstpath);
    return 2;
  }

  int y;
  for (y = 0; y < height; y++) {
    fwrite(src, rowbytes_body, 1, fp);
    src = (const char *)src + rowbytes_skip;
  }

  fclose(fp);
  return 0;
}

/**
 @brief	access frame data specified by argument and output image data
 @details		This function accesses specified frame data and output
 image data as raw data. The method used to access frame is changed by the
 directive "USE_COPYFRAME"
 @param hdcimg:	DCIMG handle
 @param arg:	class to manage argument
 @return	result to get image data. 0 is success.
 @sa	dcimg_paraml, dcimg_setsessionindex, dcimg_lockframe, dcimg_copyframe
 */
int do_dcimg_frame(HDCIMG hdcimg, const cmdline &arg) {
  DCIMG_ERR err;

  int32 iSession;
  if (arg.m_iSession == NOTSET_SESSIONINDEX) {
    iSession = 0; // first session
  } else {
    // get number of session
    int32 nSession;
    err = dcimg_getparaml(hdcimg, DCIMG_IDPARAML_NUMBEROF_SESSION, &nSession);
    if (failed(err)) {
      dcimgcon_show_dcimgerr(
          err, "dcimg_getparaml(DCIMG_IDPARAML_NUMBEROF_SESSION)");
      return 3;
    }

    if (arg.m_iSession >= nSession) {
      printf("Number of session in the specified file is %d.\n", nSession);
      printf("But session index specified in the argument was %d do it was out "
             "of range.\n",
             arg.m_iSession);
      return 2;
    }

    // chnage current session;
    err = dcimg_setsessionindex(hdcimg, arg.m_iSession);
    if (failed(err)) {
      dcimgcon_show_dcimgerr(err, "dcimg_setsessionindex()", "index=%d",
                             arg.m_iSession);
      return 3;
    }

    iSession = arg.m_iSession;
  }

  if (arg.m_iFrame == NOTSET_FRAMEINDEX) {
    printf("Error: no frame index is specified.\n");
    return 3;
  }

  // get number of frame
  int32 nFrame;
  err = dcimg_getparaml(hdcimg, DCIMG_IDPARAML_NUMBEROF_FRAME, &nFrame);
  if (failed(err)) {
    dcimgcon_show_dcimgerr(err,
                           "dcimg_getparaml(DCIMG_IDPARAML_NUMBEROF_FRAME)");
    return 3;
  }

  if (arg.m_iFrame >= nFrame) {
    printf("Number of frame in the specified session is %d.\n", nFrame);
    printf("But frame index specified in the argument was %d so it was out of "
           "range.\n",
           arg.m_iFrame);
    return 2;
  }

  // access to frame data
  DCIMG_FRAME frame;
  memset(&frame, 0, sizeof(frame));
  frame.size = sizeof(frame);
  frame.iFrame = arg.m_iFrame;

#if USE_COPYFRAME
  int32 width, height, rowbytes, pixeltype;
  if (!get_image_information(hdcimg, width, height, rowbytes, pixeltype))
    return 3;

  char *buf = new char[rowbytes * height];
  frame.buf = buf;
  frame.width = width;
  frame.height = height;
  frame.rowbytes = rowbytes;

  err = dcimg_copyframe(hdcimg, &frame);
  if (failed(err)) {
    delete buf;

    dcimgcon_show_dcimgerr(err, "dcimg_copyframe()", "#%d frame", frame.iFrame);
    return 3;
  }
#else
  err = dcimg_lockframe(hdcimg, &frame);
  if (failed(err)) {
    dcimgcon_show_dcimgerr(err, "dcimg_lockframe()", "#%d frame", frame.iFrame);
    return 3;
  }
#endif

  int ret = 0;

  int rowbytes_body;

  switch (frame.type) {
  case DCIMG_PIXELTYPE_MONO8:
    rowbytes_body = frame.width;
    break;
  case DCIMG_PIXELTYPE_MONO16:
    rowbytes_body = frame.width * 2;
    break;
  default:
    printf("unknown pixeltype(%d)\n", frame.type);
    ret = 2;
    break;
  }

  int rowbytes_skip = frame.rowbytes;

  if (ret == 0) {
    // make destination path
    char dstpath[MAX_PATH];
    strcpy_s(_secure_buf(dstpath), arg.m_path);

    char *p = get_extension(dstpath);
    sprintf_s(_secure_bufuseptr(dstpath, p), "%d-%d.raw", iSession,
              arg.m_iFrame);

    ret = save_rawfile(dstpath, frame.buf, rowbytes_skip, rowbytes_body,
                       frame.height);
  }

#if USE_COPYFRAME
  delete buf;
#endif

  return ret;
}

int main(int argc, char *argv[]) {
  printf("PROGRAM START\n");

  int ret = 0;

  cmdline arg;
  // set argument type
  arg.set_argment_flag(ARGFLAG_ENABLE, ARGFLAG_ENABLE | ARGFLAG_ABBR);

  // set string of target data kind
  arg.set_targetkind("raw data");

  // check command line argument
  ret = arg.set_arg(argc, argv);
  if (ret == 0) {
    // initialize and open
    HDCIMG hdcimg = dcimgcon_init_open(arg.m_path);
    if (hdcimg == NULL) {
      ret = 3;
    } else {
      // access image and make raw file
      ret = do_dcimg_frame(hdcimg, arg);

      // close DCIMG handle
      dcimg_close(hdcimg);
    }
  }

  printf("PROGRAM END\n");
  return ret;
}
