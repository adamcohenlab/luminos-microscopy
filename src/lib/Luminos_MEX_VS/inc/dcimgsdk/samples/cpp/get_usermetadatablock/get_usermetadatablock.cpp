/**
 @file	get_usermetadatablock
 @brief		sample code to get user meta data block
 @details	This program accesses the user meta data of FRAME by block. The
 target data is changed by the directive "USERMETA_DATATYPE".
 @remarks	dcimg_copymetadatablock
 */

#include "../misc/console_dcimg.h"
#include "../misc/common_dcimg.h"

/**
 @def	USERMETA_DATATYPE
 *
 *0:	data type is text data
 *1:	data type is binary data
 */
#define USERMETA_DATATYPE 0

/**
 @brief write data to specified file
 @param dstpath:	specified file path
 @param src:		pointer of data
 @param srcbytes:	data size
 @return	result to write data. 0 is success
 */
int save_metadata(const char *dstpath, const void *src, int srcbytes) {
  FILE *fp;
  int err = fopen_s(&fp, dstpath, "w");
  if (err != 0) {
    printf("Fail to open destination file %s.\n", dstpath);
    return 2;
  }

  fwrite(src, srcbytes, 1, fp);

  fclose(fp);

  return 0;
}

/**
 @brief	get text meta data of all frames in specified session
 @details	This function outputs files written text meta data of frame in
 specified session with argument
 @param hdcimg:	DCIMG handle
 @param arg:	class to manage argument
 @return	result to get meta text of frame. 0 is success.
 @sa	dcimg_getparaml, dcimg_setsessionindex, dcimg_copymetadatablock
 */
int do_dcimg_metadatablock_text(HDCIMG hdcimg, const cmdline &arg) {
  DCIMG_ERR err;

  int32 iSession;
  if (arg.m_iSession == NOTSET_SESSIONINDEX)
    iSession = 0; // firest session
  else {
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

  // make destination path
  char dstpath[MAX_PATH];
  strcpy_s(_secure_buf(dstpath), arg.m_path);

  char *pDstPathLast = get_extension(dstpath);

  // parameter for getting text meta data
  DCIMG_USERDATATEXTBLOCK meta;
  memset(&meta, 0, sizeof(meta));
  meta.hdr.size = sizeof(meta);
  meta.hdr.iKind = DCIMG_METADATAKIND_USERDATATEXT;

  // frame text meta data
  int32 databytes;
  err =
      dcimg_getparaml(hdcimg, DCIMG_IDPARAML_MAXSIZE_USERDATATEXT, &databytes);
  if (failed(err)) {
    dcimgcon_show_dcimgerr(
        err, "dcimg_getparaml(DCIMG_IDPARAML_MAXSIZE_USERDATATEXT)");
    return 3;
  }
  if (databytes == 0) {
    printf("MAXSIZE_USERDATATEXT is %d. This means no text frame meta data for "
           "specified session.\n",
           databytes);
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

  int ret = 0;

  char *userdatatext = new char[databytes * nFrame];
  meta.userdatatextvalidsize = new int32[nFrame];

  if (userdatatext == NULL || meta.userdatatextvalidsize == NULL) {
    printf("Error: fail to allocate memory.\n");
    ret = 2;
  } else {
    memset(userdatatext, 0, databytes * nFrame);
    memset(meta.userdatatextvalidsize, 0,
           sizeof(*meta.userdatatextvalidsize) * nFrame);

    meta.userdatatext = userdatatext;
    meta.userdatatextsize = databytes;
    meta.userdatatextmax = nFrame;

    meta.userdatatext_kind = DCIMG_USERDATAKIND_FRAME;

    err = dcimg_copymetadatablock(hdcimg, &meta.hdr);
    if (failed(err)) {
      dcimgcon_show_dcimgerr(
          err, "dcimg_copymetadatablock(DCIMG_METADATAKIND_USERDATATEXT)");
      ret = 3;
    } else {
      int32 iFrame;
      for (iFrame = 0; iFrame < meta.userdatatextcount; iFrame++) {
        // store each user text meta data
        if (meta.userdatatextvalidsize[iFrame] == 0) {
          printf("Frame%d @ Sesison%d doesn't have text meta data.\n", iFrame,
                 iSession);
        } else {
          // setup for frame text meta data
          sprintf_s(_secure_bufuseptr(dstpath, pDstPathLast), "%d-%d.txt",
                    iSession, iFrame);

          char *src = userdatatext + databytes * iFrame;
          save_metadata(dstpath, src, meta.userdatatextvalidsize[iFrame]);
        }
      }
    }
  }

  if (userdatatext != NULL)
    delete userdatatext;
  if (meta.userdatatextvalidsize != NULL)
    delete meta.userdatatextvalidsize;

  return ret;
}

/**
 @brief	get binary meta data of all frames in specified session
 @details	This function outputs files written binary meta data of frame in
 specified session with argument
 @param hdcimg:	DCIMG handle
 @param arg:	class to manage argument
 @return	result to get meta binary of frame. 0 is success.
 @sa	dcimg_getparaml, dcimg_setsessionindex, dcimg_copymetadatablock
 */
int do_dcimg_metadatablock_binary(HDCIMG hdcimg, const cmdline &arg) {
  DCIMG_ERR err;

  int32 iSession;
  if (arg.m_iSession == NOTSET_SESSIONINDEX)
    iSession = 0; // firest session
  else {
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

  // make destination path
  char dstpath[MAX_PATH];
  strcpy_s(_secure_buf(dstpath), arg.m_path);

  char *pDstPathLast = get_extension(dstpath);

  // parameter for getting binary meta data
  DCIMG_USERDATABINBLOCK meta;
  memset(&meta, 0, sizeof(meta));
  meta.hdr.size = sizeof(meta);
  meta.hdr.iKind = DCIMG_METADATAKIND_USERDATABIN;

  // frame binary meta data
  int32 databytes;
  err = dcimg_getparaml(hdcimg, DCIMG_IDPARAML_MAXSIZE_USERDATABIN, &databytes);
  if (failed(err)) {
    dcimgcon_show_dcimgerr(
        err, "dcimg_getparaml(DCIMG_IDPARAML_MAXSIZE_USERDATABIN)");
    return 3;
  }
  if (databytes == 0) {
    printf("MAXSIZE_USERDATABIN is %d. This means no binary frame meta data "
           "for specified session.\n",
           databytes);
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

  int ret = 0;

  char *userdatabin = new char[databytes * nFrame];
  meta.userdatabinvalidsize = new int32[nFrame];

  if (userdatabin == NULL || meta.userdatabinvalidsize == NULL) {
    printf("Error: fail to allocate memory.\n");
    ret = 2;
  } else {
    memset(userdatabin, 0, databytes * nFrame);
    memset(meta.userdatabinvalidsize, 0,
           sizeof(*meta.userdatabinvalidsize) * nFrame);

    meta.userdatabin = userdatabin;
    meta.userdatabinsize = databytes;
    meta.userdatabinmax = nFrame;

    meta.userdatabin_kind = DCIMG_USERDATAKIND_FRAME;

    err = dcimg_copymetadatablock(hdcimg, &meta.hdr);
    if (failed(err)) {
      dcimgcon_show_dcimgerr(
          err, "dcimg_copymetadatablock(DCIMG_METADATAKIND_USERDATABIN)");
      ret = 3;
    } else {
      int32 iFrame;
      for (iFrame = 0; iFrame < meta.userdatabincount; iFrame++) {
        // store each user binary meta data
        if (meta.userdatabinvalidsize[iFrame] == 0) {
          printf("Frame%d @ Sesison%d doesn't have binary meta data.\n", iFrame,
                 iSession);
        } else {
          // setup for frame text meta data
          sprintf_s(_secure_bufuseptr(dstpath, pDstPathLast), "%d-%d.bin",
                    iSession, iFrame);

          char *src = userdatabin + databytes * iFrame;
          save_metadata(dstpath, src, meta.userdatabinvalidsize[iFrame]);
        }
      }
    }
  }

  if (userdatabin != NULL)
    delete userdatabin;
  if (meta.userdatabinvalidsize)
    delete meta.userdatabinvalidsize;

  return ret;
}

int main(int argc, char *argv[]) {
  printf("PROGRAM START\n");

  int ret = 0;

  cmdline arg;
  // set argument type
  arg.set_argment_flag(ARGFLAG_NONE, ARGFLAG_ENABLE | ARGFLAG_ABBR);

  // set string of target data kind
  arg.set_targetkind("user meta data");

  // check command line argument
  ret = arg.set_arg(argc, argv);
  if (ret == 0) {
    // initialize and open
    HDCIMG hdcimg = dcimgcon_init_open(arg.m_path);
    if (hdcimg == NULL) {
      ret = 3;
    } else {
      // access user meta data of FRAME
#if USERMETA_DATATYPE == 0
      // text data
      ret = do_dcimg_metadatablock_text(hdcimg, arg);
#elif USERMETA_DATATYPE == 1
      ret = do_dcimg_metadatablock_binary(hdcimg, arg);
#else
      printf("directive error!\n");
      ret = 2;
#endif
    }

    // close DCIMG handle
    dcimg_close(hdcimg);
  }

  printf("PROGRAM END\n");
  return ret;
}
