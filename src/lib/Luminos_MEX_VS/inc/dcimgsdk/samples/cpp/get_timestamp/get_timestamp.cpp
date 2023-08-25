/**
 @file	get_timestamp
 @brief		sample code to get time stamp of all frames in specified session
 @details	This program accesses the time stamp of all frames in specified
 session and displays time stamp value.
 @remarks	dcimg_copymetadatablock
 */

#include "../misc/console_dcimg.h"
#include "../misc/common_dcimg.h"

/**
 @brief	get time stamp of all frames in specified session
 @details	This function displays time stamp value of all frames in
 specified session with argument.
 @param hdcimg:	DCIMG handle
 @param arg:	class to manage argument
 @return	result to get time stamp of frame. 0 is success.
 @sa	dcimg_getparaml, dcimg_setsessionindex, dcimg_copymetadatablock
 */
int do_dcimg_timestamp(HDCIMG hdcimg, const cmdline &arg) {
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

  // get number of frame
  int32 nFrame;
  err = dcimg_getparaml(hdcimg, DCIMG_IDPARAML_NUMBEROF_FRAME, &nFrame);
  if (failed(err)) {
    dcimgcon_show_dcimgerr(err,
                           "dcimg_getparaml(DCIMG_IDPARAML_NUMBEROF_FRAME)");
    return 3;
  }

  // prepare buffer to receive TIMESTAMP

  BOOL bElapse = TRUE;

  DCIMG_TIMESTAMP *timestamps = new DCIMG_TIMESTAMP[nFrame];
  if (timestamps == NULL) {
    printf("Error: fail to allocate %d TIMESTAMP.\n", nFrame);
    return 2;
  }

  int ret = 0;

  DCIMG_TIMESTAMPBLOCK block;
  memset(&block, 0, sizeof(block));
  block.hdr.size = sizeof(block);
  block.hdr.iKind = DCIMG_METADATAKIND_TIMESTAMPS;

  block.timestamps = timestamps;
  block.timestampmax = nFrame;
  block.timestampsize = sizeof(*timestamps);

  err = dcimg_copymetadatablock(hdcimg, &block.hdr);
  if (failed(err)) {
    dcimgcon_show_dcimgerr(err,
                           "dcimg_copymetadatablock(DCIMG_TIMESTAMPBLOCK)");
    ret = 3;
  } else if (block.timestampvalidsize < sizeof(*timestamps)) {
    printf("dcimg_copymetadatablock(DCIMG_TIMESTAMPBLOCK) returns unknown time "
           "stamp that size is %d bytes. This is smaller than expected.\n",
           block.timestampvalidsize);
    ret = 3;
  } else if (bElapse) {
    int32 iFrame;
    DCIMG_TIMESTAMP &ts = timestamps[0];
    double fStart = double(ts.sec) + double(ts.microsec) / 1000000;

    for (iFrame = 0; iFrame < block.timestampcount; iFrame++) {
      ts = timestamps[iFrame];
      double fNow = double(ts.sec) + double(ts.microsec) / 1000000;
      printf("%d\t%.6f\n", iFrame, fNow - fStart);
    }
  } else {
    int32 iFrame;
    for (iFrame = 0; iFrame < block.timestampcount; iFrame++) {
      DCIMG_TIMESTAMP &ts = timestamps[iFrame];
      printf("%d\t%d.%06d\n", iFrame, ts.sec, ts.microsec);
    }
  }

  delete timestamps;

  return ret;
}

int main(int argc, char *argv[]) {
  printf("PROGRAM START\n");

  int ret = 0;

  cmdline arg;
  // set argument type
  arg.set_argment_flag(ARGFLAG_NONE, ARGFLAG_ENABLE);

  // set string of target data kind
  arg.set_targetkind("time stamp data");

  // check command line argument
  ret = arg.set_arg(argc, argv);
  if (ret == 0) {
    // initialize and open
    HDCIMG hdcimg = dcimgcon_init_open(arg.m_path);
    if (hdcimg == NULL) {
      ret = 3;
    } else {
      // access time stamp
      ret = do_dcimg_timestamp(hdcimg, arg);
    }

    // close DCIMG handle
    dcimg_close(hdcimg);
  }

  printf("PROGRAM END\n");
  return ret;
}