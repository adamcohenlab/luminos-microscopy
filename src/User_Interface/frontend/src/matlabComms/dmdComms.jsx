// matlab communicatinons for the dmd tab

import { ComputerDesktopIcon } from "@heroicons/react/20/solid";
import { matlabDeviceMethod, matlabAppMethod } from "./matlabHelpers";
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

export const writeWhiteToCurrentFov = async (deviceName = []) => {
  const success = await dmdMethod({
    method: "Write_White_Current_FOV",
    devname: deviceName || [],
    args: [],
  });
  return success;
};

export const writeDarkToDMD = async (deviceName = []) => {
  const success = await dmdMethod({
    method: "Write_Dark",
    devname: deviceName || [],
    args: [],
  });
  return success;
};

export const projectDMDCalPattern = async (
  deviceName = [],
  selectedPatternPoints = "4"
) => {
  const success = await dmdMethod({
    method: "Project_Cal_Pattern",
    devname: deviceName || [],
    args: [selectedPatternPoints],
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

export const calculateDMDCalibrationTransform = async (
  deviceName = [],
  transformType = [],
  pts = null
) => {
  return await dmdMethod({
    method: "calculateCalibrationTransform",
    devname: deviceName,
    args: [pts || [], transformType],
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

export const ExportShapesToMatlab = async (
  { polygons, circles },
  deviceName = []
) => {
  const success = await dmdMethod({
    method: "Export_Shapes_To_Matlab",
    devname: deviceName || [],
    args: [{ polygons, circles }],
  });
  return success;
};

export const loadDmdPatterns = async ({ deviceName }) => {
  let dmdPatterns;

  if (!!deviceName) {
    try {
      dmdPatterns = await matlabDeviceMethod({
        method: "loadDmdPatterns",
        devtype: "DMD",
        args: [],
        devname: deviceName,
      });
    } catch (error) {
      console.error("Error loading DMD patterns:", error);
      throw new Error("Failed to load DMD patterns");
    }
  } else {
    console.log("Device name is empty; no DMD patterns to load");
    dmdPatterns = [];
  }
  return dmdPatterns;
};

export const getDmdDimensions = async ({ deviceName }) => {
  let dmdDimensions;
  if (!!deviceName) {
    try {
      dmdDimensions = await matlabDeviceMethod({
        method: "getDmdDimensions",
        devtype: "DMD",
        args: [],
        devname: deviceName,
      });
    } catch (error) {
      console.error("Error getting DMD dimensions:", error);
      throw new Error("Failed to get DMD dimensions");
    }
  } else {
    console.log("Device name is empty; no DMD dimensions to get");
    dmdDimensions = [];
  }
  return dmdDimensions;
};

export const getImageHeight = async ({ deviceType, deviceName }) => {
  let dmdDeviceName;
  if (typeof deviceName === "string") {
    dmdDeviceName = deviceName;
  } else if (typeof deviceName === "object" && deviceName.dmdDeviceName) {
    dmdDeviceName = deviceName.dmdDeviceName;
  } else {
    //console.error("Invalid deviceName format:", deviceName);
    return 1024;
  }

  let imageHeightNatural;
  if (!!dmdDeviceName) {
    if (!deviceType) throw new Error("deviceType is required");
    const refImageDimensions = await matlabDeviceMethod({
      method: "ref_im_dims",
      devtype: deviceType,
      args: [],
      devname: dmdDeviceName,
    });
    imageHeightNatural = refImageDimensions[0];
  } else {
    //console.log("DMD name empty, returning default image height");
    imageHeightNatural = 1024;
  }
  return imageHeightNatural;
};

export const getImageTform = async ({ deviceType, deviceName }) => {
  let dmdDeviceName;
  if (typeof deviceName === "string") {
    dmdDeviceName = deviceName;
  } else if (typeof deviceName === "object" && deviceName.dmdDeviceName) {
    dmdDeviceName = deviceName.dmdDeviceName;
  } else {
    //console.error("Invalid deviceName format:", deviceName);
    return -1;
  }

  let refImgDet;
  if (!!dmdDeviceName) {
    if (!deviceType) throw new Error("deviceType is required");
    refImgDet = await matlabDeviceMethod({
      method: "ref_im_tform",
      devtype: deviceType,
      args: [],
      devname: dmdDeviceName,
    });
  } else {
    refImgDet = -1;
  }
  return refImgDet;
};

export const Generate_Hadamard = async (
  deviceName = [],
  pattern = [63, 14]
) => {
  const success = await matlabDeviceMethod({
    method: "Generate_Hadamard",
    devtype: "DMD",
    args: [pattern],
    devname: deviceName,
  });
  return success;
};

export const getDMDs = async () => {
  const tabs = await matlabAppMethod({
    method: "get",
    args: ["tabs"],
  });
  
  let dmdNames = [];
  for (const tab of tabs) {
    if (typeof tab === "string" && tab.includes("DMD")) {
      dmdNames.push(tab);
    } else if (typeof tab === "object" && tab.type === "DMD") {
      if (typeof tab.names === "string") {
        dmdNames.push(tab.names);
      } else if (Array.isArray(tab.names)) {
        dmdNames = [...dmdNames, ...tab.names];
      }
    }
  }

  return dmdNames.length === 1 ? dmdNames[0] : dmdNames;
};
