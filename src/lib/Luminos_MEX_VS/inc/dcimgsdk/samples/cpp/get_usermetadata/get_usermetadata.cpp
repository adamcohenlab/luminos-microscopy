/**
 @file	get_usermetadata.cpp
 @brief		sample code to get user mate data
 @details	This program accesses the user meta data. The target data is
 changed by the directive "USERMETA_DATATYPE".
 @remarks	dcimg_copymetadata
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
 @brief	get text meta data specified by argument
 @details	This function outputs file written text meta data specified
 location with argument
 @param hdcimg:		DCIMG handle
 @param arg:		class to manage argument
 @return	result to get meta text. 0 is success.
 @sa	dcimg_getparaml, dcimg_setsessionindex, dcimg_copymetadata
 */
int do_dcimg_metatext(HDCIMG hdcimg, const cmdline &arg) {
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
  DCIMG_USERDATATEXT meta;
  memset(&meta, 0, sizeof(meta));
  meta.hdr.size = sizeof(meta);
  meta.hdr.iKind = DCIMG_METADATAKIND_USERDATATEXT;

  int32 databytes;

  if (arg.m_iSession == NOTSET_SESSIONINDEX &&
      arg.m_iFrame == NOTSET_FRAMEINDEX) {
    // file meta data
    err = dcimg_getparaml(hdcimg, DCIMG_IDPARAML_SIZEOF_USERDATATEXT_FILE,
                          &databytes);
    if (failed(err)) {
      dcimgcon_show_dcimgerr(
          err, "dcimg_getparaml(DCIMG_IDPARAML_SIZEOF_USERDATATEXT_FILE)");
      return 3;
    }
    if (databytes == 0) {
      printf("SIZEOF_USERDATATEXT_FILE is %d. This means no text file meta "
             "data.\n",
             databytes);
      return 3;
    }

    // setup for file text meta data.
    meta.hdr.option = DCIMG_USERDATAKIND_FILE;
    sprintf_s(_secure_bufuseptr(dstpath, pDstPathLast), ".txt");
  } else if (arg.m_iSession != NOTSET_SESSIONINDEX &&
             arg.m_iFrame == NOTSET_FRAMEINDEX) {
    // session meta data
    err = dcimg_getparaml(hdcimg, DCIMG_IDPARAML_SIZEOF_USERDATATEXT_SESSION,
                          &databytes);
    if (failed(err)) {
      dcimgcon_show_dcimgerr(
          err, "dcimg_getparaml(DCIMG_IDPARAML_SIZEOF_USERDATATEXT_SESSION)");
      return 3;
    }
    if (databytes == 0) {
      printf("SIZEOF_USERDATATEXT_SESSION is %d. This means no text session "
             "meta data.\n",
             databytes);
      return 3;
    }

    // setup for session text meta data
    meta.hdr.option = DCIMG_USERDATAKIND_SESSION;
    sprintf_s(_secure_bufuseptr(dstpath, pDstPathLast), "%d.txt", iSession);
  } else {
    // frame meta data
    err = dcimg_getparaml(hdcimg, DCIMG_IDPARAML_MAXSIZE_USERDATATEXT,
                          &databytes);
    if (failed(err)) {
      dcimgcon_show_dcimgerr(
          err, "dcimg_getparaml(DCIMG_IDPARAML_MAXSIZE_USERDATATEXT)");
      return 3;
    }
    if (databytes == 0) {
      printf("MAXSIZE_USERDATATEXT is %d. This means no text frame meta data "
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

    if (arg.m_iFrame >= nFrame) {
      printf("Number of frame in the specified session is %d.\n", nFrame);
      printf("But frame index specified in the argument was %d so it was out "
             "of range.\n",
             arg.m_iFrame);
      return 2;
    }

    // setup for frame text meta data
    meta.hdr.option = DCIMG_USERDATAKIND_FRAME;
    meta.hdr.iFrame = arg.m_iFrame;
    sprintf_s(_secure_bufuseptr(dstpath, pDstPathLast), "%d-%d.txt", iSession,
              arg.m_iFrame);
  }

  // access to user text meta data
  meta.text = new char[databytes];
  if (meta.text == NULL) {
    printf("Error: fail to allocate %d bytes.\n", databytes);
    return 3;
  }

  int ret = 0;

  meta.text_len = databytes;
  err = dcimg_copymetadata(hdcimg, &meta.hdr);
  if (failed(err)) {
    dcimgcon_show_dcimgerr(err, "dcimg_copymetadata()",
                           "iKind=0x%08x, option=0x%08x", meta.hdr.iKind,
                           meta.hdr.option);
    return 3;
  } else {
    if (meta.text_len == 0) {
      if (meta.hdr.option == DCIMG_USERDATAKIND_FRAME) {
        printf("DCIMG_USERDATATEXT.text_len is %d. This means no text meta "
               "data for specified frame.\n",
               meta.text_len);
      } else {
        printf("unreach error\n");
      }

      ret = 3;
    } else {
      ret = save_metadata(dstpath, meta.text, meta.text_len);
      printf("Code page is %d. Data size is %d bytes.\n", meta.codepage,
             meta.text_len);
    }
  }

  delete meta.text;

  return ret;
}

/**
 @brief	get binary meta data specified by argument
 @details	This function outputs file written binary meta data specified
 location with argument
 @param hdcimg:		DCIMG handle
 @param arg:		class to manage argument
 @return	result to get binary text. 0 is success.
 @sa	dcimg_getparaml, dcimg_setsessionindex, dcimg_copymetadata
 */
int do_dcimg_metabinary(HDCIMG hdcimg, const cmdline &arg) {
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
  DCIMG_USERDATABIN meta;
  memset(&meta, 0, sizeof(meta));
  meta.hdr.size = sizeof(meta);
  meta.hdr.iKind = DCIMG_METADATAKIND_USERDATABIN;

  int32 databytes;

  if (arg.m_iSession == NOTSET_SESSIONINDEX &&
      arg.m_iFrame == NOTSET_FRAMEINDEX) {
    // file meta data
    err = dcimg_getparaml(hdcimg, DCIMG_IDPARAML_SIZEOF_USERDATABIN_FILE,
                          &databytes);
    if (failed(err)) {
      dcimgcon_show_dcimgerr(
          err, "dcimg_getparaml(DCIMG_IDPARAML_SIZEOF_USERDATABIN_FILE)");
      return 3;
    }
    if (databytes == 0) {
      printf("SIZEOF_USERDATABIN_FILE is %d. This means no binary file meta "
             "data.\n",
             databytes);
      return 3;
    }

    // setup for file binary meta data.
    meta.hdr.option = DCIMG_USERDATAKIND_FILE;
    sprintf_s(_secure_bufuseptr(dstpath, pDstPathLast), ".bin");
  } else if (arg.m_iSession != NOTSET_SESSIONINDEX &&
             arg.m_iFrame == NOTSET_FRAMEINDEX) {
    // session meta data
    err = dcimg_getparaml(hdcimg, DCIMG_IDPARAML_SIZEOF_USERDATABIN_SESSION,
                          &databytes);
    if (failed(err)) {
      dcimgcon_show_dcimgerr(
          err, "dcimg_getparaml(DCIMG_IDPARAML_SIZEOF_USERDATABIN_SESSION)");
      return 3;
    }
    if (databytes == 0) {
      printf("SIZEOF_USERDATABIN_SESSION is %d. This means no binary session "
             "meta data.\n",
             databytes);
      return 3;
    }

    // setup for session binary meta data
    meta.hdr.option = DCIMG_USERDATAKIND_SESSION;
    sprintf_s(_secure_bufuseptr(dstpath, pDstPathLast), "%d.bin", iSession);
  } else {
    // frame meta data
    err =
        dcimg_getparaml(hdcimg, DCIMG_IDPARAML_MAXSIZE_USERDATABIN, &databytes);
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

    if (arg.m_iFrame >= nFrame) {
      printf("Number of frame in the specified session is %d.\n", nFrame);
      printf("But frame index specified in the argument was %d so it was out "
             "of range.\n",
             arg.m_iFrame);
      return 2;
    }

    // setup for frame binary meta data
    meta.hdr.option = DCIMG_USERDATAKIND_FRAME;
    meta.hdr.iFrame = arg.m_iFrame;
    sprintf_s(_secure_bufuseptr(dstpath, pDstPathLast), "%d-%d.bin", iSession,
              arg.m_iFrame);
  }

  // access to user binary meta data
  meta.bin = new char[databytes];
  if (meta.bin == NULL) {
    printf("Error: fail to allocate %d bytes.\n", databytes);
    return 3;
  }

  int ret = 0;

  meta.bin_len = databytes;
  err = dcimg_copymetadata(hdcimg, &meta.hdr);
  if (failed(err)) {
    dcimgcon_show_dcimgerr(err, "dcimg_copymetadata()",
                           "iKind=0x%08x, option=0x%08x", meta.hdr.iKind,
                           meta.hdr.option);
    return 3;
  } else {
    if (meta.bin_len == 0) {
      if (meta.hdr.option == DCIMG_USERDATAKIND_FRAME) {
        printf("DCIMG_USERDATATEXT.text_len is %d. This means no text meta "
               "data for specified frame.\n",
               meta.bin_len);
      } else {
        printf("unreach error\n");
      }

      ret = 3;
    } else {
      ret = save_metadata(dstpath, meta.bin, meta.bin_len);
      printf("Data size is %d bytes.\n", meta.bin_len);
    }
  }

  delete meta.bin;

  return ret;
}

int main(int argc, char *argv[]) {
  printf("PROGRAM START\n");

  int ret = 0;

  cmdline arg;
  // set argument type
  arg.set_argment_flag(ARGFLAG_ENABLE | ARGFLAG_ABBR,
                       ARGFLAG_ENABLE | ARGFLAG_ABBR);

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
      // access user meta data
#if USERMETA_DATATYPE == 0
      // text data
      ret = do_dcimg_metatext(hdcimg, arg);
#elif USERMETA_DATATYPE == 1
      // binary data
      ret = do_dcimg_metabinary(hdcimg, arg);
#else
      printf("directive error!\n");
      ret = 2;
#endif
      // close HDCIMG handle
      dcimg_close(hdcimg);
    }
  }

  printf("PROGRAME END\n");
  return ret;
}
