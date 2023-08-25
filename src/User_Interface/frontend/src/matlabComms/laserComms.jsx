// matlab communications for the lasers

import {
  getPropertiesForMultipleDevices,
  matlabDeviceMethod,
  setProperty,
} from "./matlabHelpers";

const matlabLaserModeToHumanReadable = {
  CWP: "Constant Power (CWP)",
  CWC: "Constant Current (CWC)",
  DIG: "External Digital Modulation (DIG)",
  DIGITAL: "External Digital Modulation (DIGITAL)",
  ANALOG: "External Analog Modulation (ANAL)",
  MIXED: "Combined Digital and Analog Modulation (MIXED)",
};

// reverse the above object
const humanReadableToMatlabLaserMode = Object.fromEntries(
  Object.entries(matlabLaserModeToHumanReadable).map(([a, b]) => [b, a])
);

const laserMethod = async (x) => {
  return matlabDeviceMethod({
    devtype: "Laser_Device",
    ...x,
  });
};

export const getLasersInfo = async () => {
  // get the latest laser properties from matlab
  const laserProperties = await getPropertiesForMultipleDevices(
    "Laser_Device",
    ["Mode", "maxPower", "SetPower", "name"]
  );

  const lasersInfo = [];
  for (let i = 0; i < laserProperties.length; i++) {
    const laser = laserProperties[i];
    const isLaserOn = await laserMethod({
      method: "Get_state",
      args: [],
      devname: laser.name,
    });

    const availableModes = await laserMethod({
      method: "Get_available_modes",
      args: [],
      devname: laser.name,
    });

    lasersInfo.push({
      id: i,
      mode: matlabLaserModeToHumanReadable[laser.Mode] || laser.Mode,
      maxPower: 1000 * laser.maxPower, // convert to mW
      power: 1000 * laser.SetPower, // convert to mW
      name: laser.name,
      modeOptions: availableModes.map((mode) => {
        // return human readable mode if it's in the object, otherwise return the mode
        return matlabLaserModeToHumanReadable[mode] || mode;
      }),
      on: isLaserOn,
    });
  }

  return lasersInfo;
};

export const toggleLaser = async (on, laserName) => {
  let method;
  if (on) {
    method = "Start_JS";
  } else {
    method = "Stop_JS";
  }

  const success = await laserMethod({
    method: method,
    args: [],
    devname: laserName,
  });
  return success;
};

export const applyLaserPower = async (power, laserName) => {
  return setProperty(
    "Laser_Device",
    "SetPower",
    power / 1000, // convert to W
    laserName
  );
};

export const applyLaserMode = async (mode, laserName) => {
  // convert to matlab mode
  const matlabMode = humanReadableToMatlabLaserMode[mode] || mode;
  return setProperty("Laser_Device", "Mode", matlabMode, laserName);
};
