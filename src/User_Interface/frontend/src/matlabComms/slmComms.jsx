// matlab communications for the SLM
import { matlabDeviceMethod } from "./matlabHelpers";
import {
  applyMask,
  calculateCalibrationTransform,
  projectCalPattern,
} from "./patterningComms";

export const generateSLMHologram = async () => {
  // SLM_genholo
  const success = await matlabDeviceMethod({
    method: "SLM_genholo",
    devtype: "SLM_Device",
    args: [],
  });
  return success;
};

export const applySLMMask = async (mask, deviceName) => {
  let success = await applyMask(mask, "SLM_Device", deviceName, false);
  success = await generateSLMHologram();
  return success;
};

export const calculateSLMCalibrationTransform = async (
    pts,
    imgHeight,
    deviceName
)  => {
    return calculateCalibrationTransform(
        pts,
        imgHeight,
        "SLM_Device",
        deviceName || []
    );
};

export const projectSLMCalPattern = async (numPointsToShow, deviceName) => {
  return projectCalPattern(numPointsToShow, "SLM_Device", deviceName);
};
