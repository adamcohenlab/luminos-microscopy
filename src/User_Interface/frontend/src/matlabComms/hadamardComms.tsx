// matlab communications for the hadamard tab

import { makeArrayIfNotAlready } from "../components/Utils";
import {
  MatlabSpecificDeviceMethodOptions,
  getProperties,
  getPropertiesForMultipleDevices,
  matlabAppMethod,
  matlabDeviceMethod,
  setProperty,
} from "./matlabHelpers";

export const Generate_Hadamard = async (folder) => {
  const success = await matlabAppMethod({
    method: "Generate_Hadamard",
    args: [
      {
        folder: folder,
      },
    ],
  });
  return success;
};

export const Acquire_Hadamard_ZStack_Triggered = async (thickness, numSlices, folderName) => {
  await matlabAppMethod({
    method: 'Acquire_Hadamard_ZStack_Triggered',
    args: [parseFloat(thickness), parseInt(numSlices), folderName],
  });
  return true;
};

