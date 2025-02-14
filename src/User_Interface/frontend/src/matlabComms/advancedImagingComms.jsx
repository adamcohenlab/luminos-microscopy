import { matlabAppMethod } from "./matlabHelpers";


// Methods for repeat acquisition: Normal, Hadamard, HiLo, Snap

export const startMultipleAcquisition = async (folder, repetitions) => {
  const success = await matlabAppMethod({
    method: "multiple_acquisition_js",
    args: [
    {
    folder, repetitions,
    },
    ],
  });
  return success;
};

export const startMultipleHadamard = async (folder, repetitions, deviceName, cameraName) => {
  const success = await matlabAppMethod({
    method: "multiple_hadamard_js",
    args: [
      {
        folder,
        repetitions,
      },
      (deviceName && { devname: deviceName }),
      (cameraName && { camname: cameraName }),
    ],
  });
  return success;
};

export const startMultipleHiLo = async (folder, repetitions, deviceName, cameraName) => {
  const success = await matlabAppMethod({
    method: "multiple_hilo_js",
    args: [
      {
        folder,
        repetitions,
      },
      (deviceName && { devname: deviceName }),
      (cameraName && { camname: cameraName }),
    ],
  });
  return success;
};

export const startMultipleSnap = async (folder, repetitions, cameraName) => {
  const success = await matlabAppMethod({
    method: "multiple_snap_js",
    args: [
      {
        folder,
        repetitions,
      },
      (cameraName && { camname: cameraName }),
    ],
  });
  return success;
};

export const startMultipleWaveform = async (folder, repetitions) => {
  const success = await matlabAppMethod({
    method: "multiple_waveform_js",
    args: [
    {
    folder, repetitions,
    },
    ],
  });
  return success;
};
  

// Methods for repeat acquisition with parameter scan: Normal, Hadamard, HiLo, Snap
export const startMultipleAcquisitionScan = async (folder, repetitions, scanParameters = []) => {
  const success = await matlabAppMethod({
    method: "multiple_acquisition_scan_js",
    args: [
      {
        folder,
        repetitions,
        scanParameters, 
      },
    ],
  });
  return success;
};

export const startMultipleHadamardScan = async (folder, repetitions, deviceName, scanParameters = [], cameraName) => {
  const success = await matlabAppMethod({
    method: "multiple_hadamard_scan_js",
    args: [
      {
        folder,
        repetitions,
        scanParameters,
      },
      (deviceName && { devname: deviceName }),
      (cameraName && { camname: cameraName }),
    ],
  });
  return success;
};

export const startMultipleHiLoScan = async (folder, repetitions, deviceName, scanParameters = [], cameraName) => {
  const success = await matlabAppMethod({
    method: "multiple_hilo_scan_js",
    args: [
      {
        folder,
        repetitions,
        scanParameters,
      },
      (deviceName && { devname: deviceName }),
      (cameraName && { camname: cameraName }),
    ],
  });
  return success;
};

export const startMultipleSnapScan = async (folder, repetitions, scanParameters = [], cameraName) => {
  const success = await matlabAppMethod({
    method: "multiple_snap_scan_js",
    args: [
      {
        folder,
        repetitions,
        scanParameters,
      },
      (cameraName && { camname: cameraName }),
    ],
  });
  return success;
};
    
export const startMultipleWaveformScan = async (folder, repetitions, scanParameters = []) => {
  const success = await matlabAppMethod({
    method: "multiple_waveform_scan_js",
    args: [
      {
        folder,
        repetitions,
        scanParameters, 
      },
    ],
  });
  return success;
};