import { getMatlabAppProperty, matlabDeviceMethod } from "./matlabHelpers";

export const tellMatlabAboutImage = async (
  imgName,
  deviceType,
  deviceName = []
) => {
  const datafolder = await getMatlabAppProperty("datafolder");

  // strip off the folders from the image name
  const fileName = imgName.split("/").pop();

  const success = await matlabDeviceMethod({
    method: "Load_Ref_Im_JS",
    args: [`${datafolder}/Snaps/${fileName}`],
    devtype: deviceType,
    devname: deviceName || [],
  });
  return success;
};

export const projectCalPattern = async (
  numPointsToShow,
  deviceType,
  deviceName = []
) => {
  const success = await matlabDeviceMethod({
    method: "Project_Cal_Pattern",
    devtype: deviceType,
    args: [numPointsToShow],
    ...(deviceName && { devname: deviceName }),
  });
  return success;
};

// export const projectCalPatternDMD = async (deviceType, deviceName = []) => {
//   console.log("projectCalPatternDMD");
//   const success = await matlabDeviceMethod({
//     method: "Project_Cal_Pattern_QR",
//     devtype: deviceType,
//     args: deviceName && { devname: deviceName },
//   });
//   return success;
// };

export const applyMask = async (
  mask,
  deviceType,
  deviceName,
  writeWhenComplete = true
) => {
  // run setPatterningROI on Patterning_Device
  const success = await matlabDeviceMethod({
    method: "setPatterningROI",
    devtype: deviceType,
    args: [mask, "write_when_complete", writeWhenComplete],
    ...(deviceName && { devname: deviceName }),
  });
  return success;
};

export const getStretchFactor = async ({
  imgHeight,
  deviceType,
  deviceName,
}) => {
  // first get the dimensions of the reference image
  const refImageDimensions = await matlabDeviceMethod({
    method: "ref_im_dims",
    devtype: deviceType,
    args: [],
    ...(deviceName && { devname: deviceName }),
  });
  // scale the points to the reference image dimensions
  const stretchFactor = refImageDimensions[1] / imgHeight;
  return stretchFactor;
};

export const calculateCalibrationTransform = async (
  pts,
  imgHeight,
  deviceType,
  deviceName = []
) => {
  // pts: [[x1, y1], [x2, y2], ...]

  const stretchFactor = await getStretchFactor({
    imgHeight,
    deviceType,
    deviceName,
  });

  const scaledPts = pts.map((pt) => [
    pt[0] * stretchFactor,
    pt[1] * stretchFactor,
  ]);

  // function calculateCalibrationTransform(obj, pts)
  const success = await matlabDeviceMethod({
    method: "calculateCalibrationTransform",
    devtype: deviceType,
    args: [scaledPts],
    ...(deviceName && { devname: deviceName }),
  });
  return success;
};
