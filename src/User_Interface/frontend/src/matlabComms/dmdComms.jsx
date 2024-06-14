// matlab communicatinons for the dmd tab

import { matlabDeviceMethod } from "./matlabHelpers";
import { applyMask, calculateCalibrationTransform } from "./patterningComms";

const dmdMethod = async (x) => {
  const success = await matlabDeviceMethod({
    devtype: "DMD",
    ...x,
  });
  return success;
};

export const applyDMDMask = async (mask, deviceName) => {
  return applyMask(mask, "DMD", deviceName, true);
};

export const writeWhiteToDMD = async (deviceName = []) => {
  const success = await dmdMethod({
    method: "Write_White",
    devname: deviceName || [],
    args: [],
  });
  return success;
};

export const projectDMDCalPattern = async (deviceName = []) => {
  const success = await dmdMethod({
    method: "Project_Cal_Pattern",
    devname: deviceName || [],
    args: [],
  });
  return success;
};

export const projectDMDManualCalPattern = async (
  numPointsToShow,
  deviceName = []
) => {
  const success = await dmdMethod({
    method: "Project_Manual_Cal_Pattern",
    devname: deviceName || [],
    args: [numPointsToShow],
  });
  return success;
};

export const calculateDMDCalibrationTransform = async (deviceName = []) => {
  // Assuming dmdMethod can handle the function call and inputs correctly
  return await dmdMethod({
    method: "calculateCalibrationTransform",
    devname: deviceName || [],
    args: [[], "AprilTag"],
  });
};

export const calculateDMDPointsCalibrationTransform = async (
  pts,
  imgHeight,
  deviceName
) => {
  return calculateCalibrationTransform(pts, imgHeight, "DMD", deviceName || []);
};

export const writeStackToDMD = async (stack, deviceName = []) => {
  const success = await dmdMethod({
    method: "Write_Stack_JS",
    devname: deviceName || [],
    args: [stack],
  });
  return success;
};
