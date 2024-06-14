// matlab communications for the main tab

import { makeArrayIfNotAlready } from "../components/Utils";
import {
  MatlabSpecificDeviceMethodOptions,
  getProperties,
  getPropertiesForMultipleDevices,
  matlabAppMethod,
  matlabDeviceMethod,
  setProperty,
} from "./matlabHelpers";

const cameraMethod = async (x: MatlabSpecificDeviceMethodOptions) => {
  return matlabDeviceMethod({
    devtype: "Camera",
    ...x,
  });
};

export const getAutoNumFrames = async (totalTime, deviceName) => {
  const info = await cameraMethod({
    method: "AutoN",
    args: [totalTime],
    ...(deviceName && { devname: deviceName }),
  });
  return info;
};

export const getRoiFromStream = async (deviceName: string | []) => {
  const roi = await cameraMethod({
    method: "getRoiFromStream",
    args: [],
    devname: deviceName,
  });
  return roi;
};

export const getCameraProperties = async (properties, deviceName) => {
  const info = await getPropertiesForMultipleDevices(
    "Camera",
    properties,
    deviceName
  );
  return info;
};

export const setShutter = async (value, deviceName) => {
  const success = await setProperty(
    "Shutter_Device",
    "State",
    value,
    deviceName
  );
  return success;
};

export const getShutterProperties = async (properties, deviceName) => {
  const info = await getPropertiesForMultipleDevices(
    "Shutter_Device",
    properties,
    deviceName
  );
  return info;
};

export const setModulator = async (value, deviceName) => {
  const success = await setProperty(
    "Modulator_Device",
    "level",
    Number(value),
    deviceName
  );
  return success;
};

export const getModulatorProperties = async (properties, deviceName) => {
  const info = await getPropertiesForMultipleDevices(
    "Modulator_Device",
    properties,
    deviceName
  );
  return info;
};

export const getNotes = async () => {
  const notes = await matlabAppMethod({
    method: "get_notes_js",
    args: [],
  });
  return notes;
};

export const saveNotesToFile = async (notes) => {
  const success = await matlabAppMethod({
    method: "save_notes_js",
    args: [notes],
  });
  return success;
};

export const getROIBuffer = async (deviceName) => {
  const data = await cameraMethod({
    method: "Get_ROI_Buffer",
    args: [],
    ...(deviceName && { devname: deviceName }),
  });
  if (data) {
    return makeArrayIfNotAlready(data);
  }
  return null;
};

// snap
export const snap = async ({
  folder = "",
  showDate = true,
  deviceName = [],
}) => {
  const success = await matlabAppMethod({
    method: "save_cam_snap_js",
    args: [
      // pass arguments matlab style (yuck)
      "folder",
      folder,
      "show_date",
      showDate,
      "devname",
      deviceName,
    ],
  });
  return success;
};

export const startCamAcquisition = async (folder) => {
  const success = await matlabAppMethod({
    method: "cam_acquisition_js",
    args: [
      {
        folder: folder,
      },
    ],
  });
  return success;
};

export const relaunchCamera = async (deviceName: string | [] = []) => {
  const success = await cameraMethod({
    method: "Relaunch",
    devname: deviceName,
    args: [],
  });
  return success;
};

// filter wheel
export const getFilterWheelProperties = async (propertyNames) => {
  return getPropertiesForMultipleDevices("Filter_Wheel", propertyNames);
};

export const setFilter = async (value, filterWheelName) => {
  return setProperty("Filter_Wheel", "active_filter", value, filterWheelName);
};

// stage. For z-stage, position.x is coarse, position.y is fine step size. 
export const applyStagePosition = async (position) => {
  const success = await matlabDeviceMethod({
    method: "Move_To_Position",
    devtype: "Linear_Controller",
    args: [position.map((x) => Number(x))],
  });
  return success;
};

// Move z-stage relative to current position
export const applyStagePositionRel = async (delta) => {
  const success = await matlabDeviceMethod({
    method: "moveToRel",
    devtype: "Linear_Controller",
    args: delta,
  });
  return success;
};

export const getStagePosition = async () => {
  const properties = await getProperties("Linear_Controller", ["pos"]);
  return properties.pos; // {x, y, z}
};

export const checkStageFlag = async () => {
  try {
    const properties = await getProperties("Linear_Controller", ["zStageFlag"]);
    if (properties && properties.hasOwnProperty('zStageFlag')) {
      return true;
    } else {
      return false;
    }
  } catch (error) {
    console.error("Error fetching properties:", error);
    return false;  // Return false in case of an error
  }
};

//Spinning Disk Unit get current speed (polls unit)
export const getSDSpeed = async () => {
  const speed = await matlabDeviceMethod({
    method: "GetSpeed",
    devtype: "Spinning_Disk",
    args: [],
  });
  return speed;
};

//Spinning Disk Unit set speed
export const setSDSpeed = async (speed) => {
  const success = await matlabDeviceMethod({
    method: "SetSpeed",
    devtype: "Spinning_Disk",
    args: [Number(speed)],
  });
  return success;
};

//Spinning Disk Unit auto-adjust speed based on camera exposure time.
export const autoSDSpeed = async (exposure) => {
  const success = await matlabDeviceMethod({
    method: "AutoSpeed",
    devtype: "Spinning_Disk",
    args: [Number(exposure)],
  });
  return success;
};

//Start Spinning Disk Unit
export const Start_SD = async () => {
  const success = await matlabDeviceMethod({
    method: "Start",
    devtype: "Spinning_Disk",
    args: [],
  });
  return success;
};

//Stop Spinning Disk Unit
export const Stop_SD = async () => {
  const success = await matlabDeviceMethod({
    method: "Stop",
    devtype: "Spinning_Disk",
    args: [],
  });
  return success;
};

export const toggleSD = async (on) => {
  let method;
  if (on) {
    method = "Start";
  } else {
    method = "Stop";
  }
  const success = await matlabDeviceMethod({
    method: method,
    devtype: "Spinning_Disk",
    args: [],
  });
  return success;
};

export const SD_Limits = async () => {
  const limits = await matlabDeviceMethod({
    method: "GetSpeedLimits",
    devtype: "Spinning_Disk",
    args: [],
  });
  return limits;
};
