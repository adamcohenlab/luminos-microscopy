/* **************************************************************** *

        dcimgapi.h:	April 4, 2017

 * **************************************************************** */

#ifndef _INCLUDE_DCIMGAPI_H_

// ****************************************************************
//  common declaration with dcamapi.h

/* **************************************************************** *

        macros

 * **************************************************************** */

#ifdef __cplusplus

/* C++ */

#define BEGIN_DCIMG_DECLARE(kind, tag) kind tag
#define END_DCIMG_DECLARE(tag) ;

#else

/* C */

#define BEGIN_DCIMG_DECLARE(kind, tag) typedef kind
#define END_DCIMG_DECLARE(tag) tag;

#endif // __cplusplus

/* define - DCIMGAPI */

#ifndef DCIMGAPI
#ifdef WIN32
#define DCIMGAPI PASCAL /* DCAM-API based on PASCAL calling */
#else
#define DCIMGAPI
#endif
#endif /* DCIMGAPI */

#ifndef _INCLUDE_DCAMAPI_H_

/* define - int32 & _ui32 */

#if defined(WIN32) || defined(_INC_WINDOWS)
typedef long int32;
typedef unsigned long _ui32;
#else
typedef int int32;
typedef unsigned int _ui32;
#endif

#endif

/* **************************************************************** *

        constant declaration

 * **************************************************************** */

/*** --- errors --- ***/

BEGIN_DCIMG_DECLARE(enum, DCIMG_ERR){
    /* status error */

    /* wait error */

    /* initialization error */
    DCIMG_ERR_NOMEMORY =
        0x80000203, /*		not enough memory		*/

    /* calling error */
    DCIMG_ERR_INVALIDHANDLE =
        0x80000807,                      /*		invalid dcimg value	*/
    DCIMG_ERR_INVALIDPARAM = 0x80000808, /*		invalid parameter, e.g.
                                            parameter is NULL	*/
    DCIMG_ERR_INVALIDVALUE =
        0x80000821,                     /*		invalid parameter value	*/
    DCIMG_ERR_INVALIDVIEW = 0x8000082a, /* invalid view index	*/
    DCIMG_ERR_INVALIDFRAMEINDEX =
        0x80000833, /*		the frame index is invalid	*/
    DCIMG_ERR_INVALIDSESSIONINDEX =
        0x80000834,                       /*		the session index is invalid	*/
    DCIMG_ERR_FILENOTOPENED = 0x80000835, /*		file is not opened at
                                             dcimg_open() or dcimg_create() */
    DCIMG_ERR_UNKNOWNFILEFORMAT =
        0x80000836, /*		opened file format is not supported */
    DCIMG_ERR_NOTSUPPORT =
        0x80000f03, /*		the function or property are not supportted
                       under current condition */

    /* camera or bus trouble */

    DCIMG_ERR_FAILEDREADDATA = 0x84001004, DCIMG_ERR_UNKNOWNSIGN = 0x84001801,
    DCIMG_ERR_OLDERFILEVERSION = 0x84001802,
    DCIMG_ERR_NEWERFILEVERSION = 0x84001803, DCIMG_ERR_NOIMAGE = 0x84001804,
    DCIMG_ERR_UNKNOWNIMAGEPROC = 0x84001805,
    DCIMG_ERR_NOTSUPPORTIMAGEPROC = 0x84001806, DCIMG_ERR_NODATA = 0x84001807,
    DCIMG_ERR_IMAGE_UNKNOWNSIGNATURE =
        0x84003001, /*	sigunature of image header is unknown or corrupted
                     */
    DCIMG_ERR_IMAGE_NEWRUNTIMEREQUIRED =
        0x84003002, /* version of image header is newer than version that used
                       DCAM supports	*/
    DCIMG_ERR_IMAGE_ERRORSTATUSEXIST =
        0x84003003, /*	image header stands error status	*/
    DCIMG_ERR_IMAGE_HEADERCORRUPTED =
        0x84004004, /*	image header value is strange	*/
    DCIMG_ERR_IMAGE_BROKENCONTENT =
        0x84004005, /*	image content is corrupted	*/

    /* calling error for DCAM-API 2.1.3 */
    DCIMG_ERR_UNKNOWNCOMMAND =
        0x80000801, /*		unknown command id		*/
    DCIMG_ERR_UNKNOWNPARAMID =
        0x80000803, /*		unkown parameter id		*/

    /* internal error */
    DCIMG_ERR_SUCCESS =
        1, /*		no error, general success code		*/

    /* internal error */
    DCIMG_ERR_UNREACH = 0x80000f01, /*		internal error
                                     */

    _end_of_dcimgerr,

    DCIMG_ERR_OLDERERFILEVERSION = DCIMG_ERR_OLDERFILEVERSION,
    DCIMG_ERR_NEWERERFILEVERSION =
        DCIMG_ERR_NEWERFILEVERSION} END_DCIMG_DECLARE(DCIMG_ERR)

    /*** --- Code Page --- ***/

    BEGIN_DCIMG_DECLARE(enum, DCIMG_CODEPAGE){
        DCIMG_CODEPAGE__SHIFT_JIS = 932, // Shift JIS

        DCIMG_CODEPAGE__UTF16_LE = 1200, // UTF-16 (Little Endian)
        DCIMG_CODEPAGE__UTF16_BE = 1201, // UTF-16 (Big Endian)

        DCIMG_CODEPAGE__UTF7 = 65000, // UTF-7 translation
        DCIMG_CODEPAGE__UTF8 = 65001, // UTF-8 translation

        DCIMG_CODEPAGE__NONE = 0x80000000} END_DCIMG_DECLARE(DCIMG_CODEPAGE)

    /*** --- IDs --- ***/

    BEGIN_DCIMG_DECLARE(enum, DCIMG_FRAME_OPTION){
        DCIMG_FRAME_OPTION__VIEW_CURRENT = 0x00000000,
        DCIMG_FRAME_OPTION__VIEW_1 = 0x00100000,
        DCIMG_FRAME_OPTION__VIEW_2 = 0x00200000,
        DCIMG_FRAME_OPTION__VIEW_3 = 0x00300000,
        DCIMG_FRAME_OPTION__VIEW_4 = 0x00400000,

        DCIMG_FRAME_OPTION__PROC_NONE = 0x00000000,
        DCIMG_FRAME_OPTION__PROC_HIGHCONTRAST = 0x00000010,

        DCIMG_FRAME_OPTION__VIEW__STEP = 0x00100000,
        DCIMG_FRAME_OPTION__VIEW__MASK = 0x00F00000,
        DCIMG_FRAME_OPTION__PROC__MASK = 0x0000FFF0,

        end_of_dcimg_frame_option} END_DCIMG_DECLARE(DCIMG_FRAME_OPTION)

        BEGIN_DCIMG_DECLARE(enum, DCIMGDATA_OPTION){
            DCIMGDATA_OPTION__VIEW_CURRENT = DCIMG_FRAME_OPTION__VIEW_CURRENT,
            DCIMGDATA_OPTION__VIEW_1 = DCIMG_FRAME_OPTION__VIEW_1,
            DCIMGDATA_OPTION__VIEW_2 = DCIMG_FRAME_OPTION__VIEW_2,
            DCIMGDATA_OPTION__VIEW_3 = DCIMG_FRAME_OPTION__VIEW_3,
            DCIMGDATA_OPTION__VIEW_4 = DCIMG_FRAME_OPTION__VIEW_4,

            DCIMGDATA_OPTION__VIEW__STEP = DCIMG_FRAME_OPTION__VIEW__STEP,
            DCIMGDATA_OPTION__VIEW__MASK =
                DCIMG_FRAME_OPTION__VIEW__MASK} END_DCIMG_DECLARE(DCIMGDATA_OPTION)

            BEGIN_DCIMG_DECLARE(enum, DCIMGDATA_KIND){
                DCIMGDATA_KIND__UNKNOWN = 0x00000000,
                DCIMGDATA_KIND__REGION = 0x00000010,
                DCIMGDATA_KIND__SENSORPARAM = 0x00000020,
            } END_DCIMG_DECLARE(DCIMGDATA_KIND)

                BEGIN_DCIMG_DECLARE(enum, DCIMGDATA_REGIONTYPE){
                    DCIMGDATA_REGIONTYPE__RECT16ARRAY = 0x00000002,

                    DCIMGDATA_REGIONTYPE__NONE =
                        0x00000000} END_DCIMG_DECLARE(DCIMGDATA_REGIONTYPE)

                    BEGIN_DCIMG_DECLARE(enum, DCIMG_PIXELTYPE){
                        DCIMG_PIXELTYPE_NONE = 0x00000000,

                        DCIMG_PIXELTYPE_MONO8 = 0x00000001,
                        DCIMG_PIXELTYPE_MONO16 = 0x00000002,

                        end_of_dcimg_pixeltype} END_DCIMG_DECLARE(DCIMG_PIXELTYPE)

                        BEGIN_DCIMG_DECLARE(enum, DCIMG_METADATAKIND){
                            DCIMG_METADATAKIND_USERDATATEXT = 0x00000001,
                            DCIMG_METADATAKIND_USERDATABIN = 0x00000002,
                            DCIMG_METADATAKIND_TIMESTAMPS = 0x00010000,
                            DCIMG_METADATAKIND_FRAMESTAMPS = 0x00020000,

                            end_of_dcimg_metadatakind} END_DCIMG_DECLARE(DCIMG_METADATAKIND)

                            BEGIN_DCIMG_DECLARE(
                                enum,
                                DCIMG_METADATAOPTION) // DCIMG_METADATAHDR::option
    {DCIMG_METADATAOPTION__LOCATION_FRAME = 0x00000000,
     DCIMG_METADATAOPTION__LOCATION_FILE = 0x01000000,
     DCIMG_METADATAOPTION__LOCATION_SESSION = 0x02000000,
     DCIMG_METADATAOPTION__LOCATION__MASK = 0xFF000000,

     end_of_dcimg_metadataoption} END_DCIMG_DECLARE(DCIMG_METADATAOPTION)

        BEGIN_DCIMG_DECLARE(
            enum, DCIMG_USERDATAKIND) // DCIMG_METADATAHDR::option, obsolete
    {DCIMG_USERDATAKIND_FRAME = DCIMG_METADATAOPTION__LOCATION_FRAME,
     DCIMG_USERDATAKIND_FILE = DCIMG_METADATAOPTION__LOCATION_FILE,
     DCIMG_USERDATAKIND_SESSION = DCIMG_METADATAOPTION__LOCATION_SESSION,

     DCIMG_USERDATAKIND_LOCATION_MASK = DCIMG_METADATAOPTION__LOCATION__MASK,

     end_of_dcimg_userdatakind} END_DCIMG_DECLARE(DCIMG_USERDATAKIND)

        BEGIN_DCIMG_DECLARE(enum, DCIMG_CAPABILITY_IMAGEPROC){
            DCIMG_CAPABILITY_IMAGEPROC__HIGHCONTRAST =
                DCIMG_FRAME_OPTION__PROC_HIGHCONTRAST,

            DCIMG_CAPABILITY_IMAGEPROC__NONE =
                0x00000000} END_DCIMG_DECLARE(DCIMG_CAPABILITY_IMAGEPROC)

    /* **************************************************************** *

            structures (ver 4.x)

     * **************************************************************** */

    BEGIN_DCIMG_DECLARE(struct, DCIMG_TIMESTAMP) {
  _ui32 sec;      // [out]
  int32 microsec; // [out]
}
END_DCIMG_DECLARE(DCIMG_TIMESTAMP)

BEGIN_DCIMG_DECLARE(struct, DCIMG_FRAME) {
  // copyframe() and lockframe() use this structure. Some members have different
  // direction. [i:o] means, the member is input at copyframe() and output at
  // lockframe(). [i:i] and [o:o] means always input and output at both
  // function. "input" means application has to set the value before calling.
  // "output" means function filles a value at returning.
  int32 size;                // [i:i] size of this structure.
  int32 iKind;               // reserved. set to 0.
  int32 option;              // reserved. set to 0.
  int32 iFrame;              // [i:i] frame index
  void *buf;                 // [i:o] pointer for top-left image
  int32 rowbytes;            // [i:o] byte size for next line.
  DCIMG_PIXELTYPE type;      // reserved. set to 0.
  int32 width;               // [i:o] horizontal pixel count
  int32 height;              // [i:o] vertical line count
  int32 left;                // [i:o] horizontal start pixel
  int32 top;                 // [i:o] vertical start line
  DCIMG_TIMESTAMP timestamp; // [o:o] timestamp
  int32 framestamp;          // [o:o] framestamp
  int32 camerastamp;         // [o:o] camerastamp
  // add parameter from 16.9
  double conversionfactor_coeff;  // [o:o] conversion factor coefficient.
                                  // if it is disable, value is 0.
  double conversionfactor_offset; // [o:o] conversion factor offset. if coeff is
                                  // 0, it is disable.
}
END_DCIMG_DECLARE(DCIMG_FRAME)

BEGIN_DCIMG_DECLARE(struct, DCIMG_METADATAHDR) {
  int32 size;   // [in] size of this structure.
  int32 iKind;  // [in] DCIMG_METADATAKIND
  int32 option; // [in] 0 reserved
  int32 iFrame; // [in] start frame index
}
END_DCIMG_DECLARE(DCIMG_METADATAHDR)

BEGIN_DCIMG_DECLARE(struct, DCIMG_USERDATATEXT) {
  DCIMG_METADATAHDR
  hdr; // [in]	size member should be size of this structure
       // [in]	iKind should be DCIMG_METADATAKIND_USERDATATEXT
       // [in] option should be one of DCIMG_METADATAOPTION__LOCATION

  char *text;     // [io]
  int32 text_len; // [in]
  int32 codepage; // [in] character encoding value. See DCIMG_CODEPAGE.
}
END_DCIMG_DECLARE(DCIMG_USERDATATEXT)

BEGIN_DCIMG_DECLARE(struct, DCIMG_USERDATABIN) {
  DCIMG_METADATAHDR
  hdr; // [in]	size member should be size of this structure
       // [in]	iKind should be DCIMG_METADATAKIND_USERDATABIN
       // [in] option should be one of DCIMG_METADATAOPTION__LOCATION

  void *bin;      // [io]
  int32 bin_len;  // [in]
  int32 reserved; // [in] 0 reserved
}
END_DCIMG_DECLARE(DCIMG_USERDATABIN)

BEGIN_DCIMG_DECLARE(struct, DCIMG_USERDATATEXTBLOCK) {
  DCIMG_METADATAHDR hdr;

  void *userdatatext;           // [in] pointer for userdatatext block
  int32 userdatatextsize;       // [in] size of one userdatatext
  int32 *userdatatextvalidsize; // [in] return the written data text size of ...
  int32 userdatatextmax;        // [in] maximum number of userdatatext which can
                                // receive. userdatatext pointer should have
                                // userdatatextsize * userdatatextmax
  int32 userdatatextcount;      // [o] return how many userdatatext are filled
  int32 userdatatext_kind;      // [in] choose userdatatext kind from
                           // DCIMG_METADATAOPTION__LOCATION (File, Session,
                           // Frame)
  int32
      *userdatatextcodepage; // [in] return encode type of written userdatatext
}
END_DCIMG_DECLARE(DCIMG_USERDATATEXTBLOCK)

BEGIN_DCIMG_DECLARE(struct, DCIMG_USERDATABINBLOCK) {
  DCIMG_METADATAHDR hdr;

  void *userdatabin;           // [in] pointer for userdatabin block
  int32 userdatabinsize;       // [in] size of one userdatabin
  int32 *userdatabinvalidsize; // [in] return the written data bin size of ...
  int32 userdatabinmax; // [in] maximum number of userdatabin which can receive.
                        // userbindata pointer should have userdatabinsize *
                        // userdatamaxbin
  int32 userdatabincount; // [o] return how many userdatabin are filled
  int32
      userdatabin_kind; // [in] choose userdatabin kind from
                        // DCIMG_METADATAOPTION__LOCATION (File, Session, Frame)
}
END_DCIMG_DECLARE(DCIMG_USERDATABINBLOCK)

BEGIN_DCIMG_DECLARE(struct, DCIMG_TIMESTAMPBLOCK) {
  DCIMG_METADATAHDR hdr;

  DCIMG_TIMESTAMP *timestamps; // [i] pointer for TIMESTAMP block
  int32 timestampmax;          // [i] maximum number of timestamp to receive.
  int32 timestampkind; // [o] reserved value to return timestamp kind(Hardware,
                       // Driver, DCAM etc..)
  int32 timestampsize; // [i] sizeof(DCIMG_TIMESTAMP)	//additional 20120224
  int32 timestampvalidsize; // [o] return the written data size of
                            // DCIMG_TIMESTRAMP.
  int32 timestampcount;     // [o] return how many timestamps are filled
  int32 reserved;
}
END_DCIMG_DECLARE(DCIMG_TIMESTAMPBLOCK)

BEGIN_DCIMG_DECLARE(struct, DCIMG_FRAMESTAMPBLOCK) {
  DCIMG_METADATAHDR hdr;

  int32 *framestamps;    // [i] pointer for framestamp block
  int32 framestampmax;   // [i] maximum number of framestamp to receive.
  int32 framestampcount; // [o] return how many framestamps are filled
  int32 reserved;
}
END_DCIMG_DECLARE(DCIMG_FRAMESTAMPBLOCK)

BEGIN_DCIMG_DECLARE(struct, DCIMGDATA_REGIONRECT) {
  short left;
  short top;
  short right;
  short bottom;
}
END_DCIMG_DECLARE(DCIMGDATA_REGIONRECT)

// ****************************************************************
//  declaration for DCIMG API

BEGIN_DCIMG_DECLARE(enum, DCIMG_IDPARAML){
    DCIMG_IDPARAML_NUMBEROF_TOTALFRAME, // number of total frame in the file

    DCIMG_IDPARAML_NUMBEROF_SESSION, // number of session in the file.
    DCIMG_IDPARAML_NUMBEROF_FRAME,   // number of frame in current session.

    DCIMG_IDPARAML_SIZEOF_USERDATABIN_SESSION =
        4, // byte size of current session binary USER META DATA.
    DCIMG_IDPARAML_SIZEOF_USERDATABIN_FILE, // byte size of file binary USER
                                            // META DATA.

    DCIMG_IDPARAML_SIZEOF_USERDATATEXT_SESSION =
        7, // byte size of current session text USER META DATA.
    DCIMG_IDPARAML_SIZEOF_USERDATATEXT_FILE, // byte size of file text USER META
                                             // DATA.

    DCIMG_IDPARAML_IMAGE_WIDTH,     // image width in current session.
    DCIMG_IDPARAML_IMAGE_HEIGHT,    // image height in current session.
    DCIMG_IDPARAML_IMAGE_ROWBYTES,  // image rowbytes in current session.
    DCIMG_IDPARAML_IMAGE_PIXELTYPE, // image pixeltype in current session.

    DCIMG_IDPARAML_MAXSIZE_USERDATABIN =
        13, // maximum byte size of frame binary USER META DATA in current
            // session.
    DCIMG_IDPARAML_MAXSIZE_USERDATABIN_SESSION, // maximum byte size of session
                                                // binary USER META DATA in the
                                                // file.

    DCIMG_IDPARAML_MAXSIZE_USERDATATEXT =
        16, // maximum byte size of frame text USER META DATA in current
            // session.
    DCIMG_IDPARAML_MAXSIZE_USERDATATEXT_SESSION, // maximum byte size of session
                                                 // tex USER META DATA in the
                                                 // file.

    DCIMG_IDPARAML_CURRENT_SESSION = 19, // current session index
    DCIMG_IDPARAML_NUMBEROF_VIEW,        // number of view in current session.

    DCIMG_IDPARAML_FILEFORMAT_VERSION, // file format version

    DCIMG_IDPARAML_CAPABILITY_IMAGEPROC, // capability of image processing

    end_of_dcimg_idparaml

} END_DCIMG_DECLARE(DCIMG_IDPARAML)

    /* **************************************************************** */

    typedef struct tag_DCIMG *HDCIMG; // handle for file

BEGIN_DCIMG_DECLARE(struct, DCIMG_GUID) {
  _ui32 Data1;
  unsigned short Data2;
  unsigned short Data3;
  unsigned char Data4[8];
}
END_DCIMG_DECLARE(DCIMG_GUID)

#define DCIMG_DEFAULT_ARG = 0
#define DCIMG_DEFAULT_PTR = NULL

// initialize parameter
BEGIN_DCIMG_DECLARE(struct, DCIMG_INIT) {
  int32 size;             // [in]
  int32 reserved;         //
  const DCIMG_GUID *guid; // [in ptr]
}
END_DCIMG_DECLARE(DCIMG_INIT)

#ifdef _WIN32

// open parameter
BEGIN_DCIMG_DECLARE(struct, DCIMG_OPENW) {
  int32 size; // [in] size of this structure
  int32 reserved;
  HDCIMG hdcimg; // [out]
  LPCWSTR path;  // [in] DCIMG file path
}
END_DCIMG_DECLARE(DCIMG_OPENW)

BEGIN_DCIMG_DECLARE(struct, DCIMG_OPENA) {
  int32 size; // [in] size of this structure
  int32 reserved;
  HDCIMG hdcimg; // [out]
  LPCSTR path;   // [in] DCIMG file path
}
END_DCIMG_DECLARE(DCIMG_OPENA)

#if defined(UNICODE) || defined(_UNICODE)

#define DCIMG_OPEN DCIMG_OPENW
#define dcimg_open dcimg_openW

#else

#define DCIMG_OPEN DCIMG_OPENA
#define dcimg_open dcimg_openA

#endif // UNICODE & _UNICODE

#else

// open parameter
BEGIN_DCIMG_DECLARE(struct, DCIMG_OPEN) {
  int32 size; // [in] size of this structure
  int32 reserved;
  HDCIMG hdcimg;    // [out]
  const char *path; // [in] DCIMG file path
}
END_DCIMG_DECLARE(DCIMG_OPEN)

#endif

// setdata parameter
BEGIN_DCIMG_DECLARE(struct, DCIMGDATA_HDR) {
  int32 size;  // [in] size of this structure
  int32 iKind; // [in] DCIMGDATA_KIND__*

  int32 option;   // [in] 0 reserved
  int32 reserved; // [in] 0 reserved
}
END_DCIMG_DECLARE(DCIMGDATA_HDR)

BEGIN_DCIMG_DECLARE(struct, DCIMGDATA_REGION) {
  DCIMGDATA_HDR hdr; // [in] iKind = DCIMGDATA_KIND__REGION

  int32 option;   // [in] 0 reserved
  int32 type;     // [out] DCIMGDATA_REGIONTYPE__*
  void *data;     // [out] top of data
  int32 datasize; // [out] size of data
  int32 reserved; // [out] 0 reserved
}
END_DCIMG_DECLARE(DCIMGDATA_REGION)

BEGIN_DCIMG_DECLARE(struct, DCIMGDATA_SENSORPARAM) {
  DCIMGDATA_HDR hdr; // [in] iKind = DCIMGDATA_KIND__SENSORPARAM

  int32 option;      // [in] 0 reserved
  int32 binning;     // [out] binning of sensor
  int32 sensorhpos;  // [out] horizontal offset of sensor
  int32 sensorhsize; // [out] horizontal size of sensor
  int32 sensorvpos;  // [out] vertical offset of sensor
  int32 sensorvsize; // [out] vertical size of sensor
}
END_DCIMG_DECLARE(DCIMGDATA_SENSORPARAM);

// ****************************************************************
//  helper for C++

#ifdef __cplusplus

/* C++ */

extern "C" {

#endif // __cplusplus

/* **************************************************************** */

DCIMG_ERR DCIMGAPI dcimg_init(DCIMG_INIT *param);
#ifdef _WIN32
DCIMG_ERR DCIMGAPI dcimg_openW(DCIMG_OPENW *param);
DCIMG_ERR DCIMGAPI dcimg_openA(DCIMG_OPENA *param);
#else
DCIMG_ERR DCIMGAPI dcimg_open(DCIMG_OPEN *param);
#endif

DCIMG_ERR DCIMGAPI dcimg_close(HDCIMG hdcimg);

DCIMG_ERR DCIMGAPI dcimg_getdata(HDCIMG hdcimg, DCIMGDATA_HDR *hdr);

DCIMG_ERR DCIMGAPI dcimg_lockframe(HDCIMG hdcimg, DCIMG_FRAME *aFrame);
DCIMG_ERR DCIMGAPI dcimg_copyframe(HDCIMG hdcimg, DCIMG_FRAME *aFrame);
DCIMG_ERR DCIMGAPI dcimg_copymetadata(HDCIMG hdcimg, DCIMG_METADATAHDR *hdr);
DCIMG_ERR DCIMGAPI dcimg_copymetadatablock(HDCIMG hdcimg,
                                           DCIMG_METADATAHDR *hdr);

DCIMG_ERR DCIMGAPI
dcimg_setsessionindex(HDCIMG hdcimg, int32 index); // session index is 0 based.
DCIMG_ERR DCIMGAPI
dcimg_getsessionindex(HDCIMG hdcimg, int32 *index); // session index is 0 based.

DCIMG_ERR DCIMGAPI dcimg_getparaml(HDCIMG hdcimg, DCIMG_IDPARAML index,
                                   int32 *paraml);

/* **************************************************************** */

/* **************************************************************** */

#ifdef __cplusplus

/* end of extern "C" */
};

/*** C++ utility ***/

inline int failed(DCIMG_ERR err) { return int(err) < 0; }

#else

/* C */

/* backward compatibility */

#endif

/* **************************************************************** */

#define _INCLUDE_DCIMGAPI_H_
#endif // _INCLUDE_DCIMGAPI_H_
