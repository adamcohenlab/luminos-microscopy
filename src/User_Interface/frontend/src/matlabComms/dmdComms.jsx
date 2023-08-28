// matlab communicatinons for the dmd tab

import { matlabDeviceMethod } from "./matlabHelpers";
import {
  applyMask,
  calculateCalibrationTransform,
  projectCalPattern,
} from "./patterningComms";

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

export const projectDMDCalPattern = async (
  numPointsToShow,
  deviceName = []
) => {
  return projectCalPattern(numPointsToShow, "DMD", deviceName || []);
};

export const calculateDMDCalibrationTransform = async (
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
