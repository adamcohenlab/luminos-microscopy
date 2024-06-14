// matlab communications for the galvos tab

import { matlabAppMethod, matlabDeviceMethod } from "./matlabHelpers";
import {
  calculateCalibrationTransform,
  getStretchFactor,
  projectCalPattern,
} from "./patterningComms";
import { buildWaveforms } from "./waveformComms";

const galvoMethod = async (x) => {
  const success = await matlabDeviceMethod({
    devtype: "Scanning_Device",
    ...x,
  });
  return success;
};

export const startSinglePlaneGalvoAcquisition = async ({
  numFrames,
  folder,
}) => {
  const success = await matlabAppMethod({
    method: "Acquire_Scanning_Frames",
    args: [numFrames, folder],
  });
  return success;
};

export const startZStackGalvoAcquisition = async ({
  totalThickness,
  numPlanes,
  averagingFactor,
  folder,
}) => {
  const success = await matlabAppMethod({
    method: "Acquire_Scanning_ZStack",
    args: [totalThickness, numPlanes, averagingFactor, folder],
  });
  return success;
};

export const startWithWaveformsGalvoAcquisition = async ({ folder }) => {
  // first build the waveforms, then run the acquisition
  let success = await buildWaveforms();

  if (!success) return success;

  success = await matlabAppMethod({
    method: "Waveform_Scanning_Sync_Acquisition",
    args: [folder],
  });
  return success;
};

export const turnGalvoOn = async () => {
  const success = await galvoMethod({
    method: "startup_js",
    args: [],
  });
  return success;
};

// seems to not work due to memory issues
// export const turnGalvoOff = async () => {
//   const success = await matlabFunction({
//     type: "dev_method",
//     method: "deleteJs",
//     devtype: "Scanning_Device",
//     args: [],
//   });
//   return success;
// };

export const framerateToMicronsPerPoint = async (framerate) => {
  const micronsPerPoint = await galvoMethod({
    method: "framerate_to_microns_per_point",
    args: [Number(framerate)],
  });
  return micronsPerPoint;
};

export const micronsPerPointToFramerate = async (micronsPerPoint) => {
  const framerate = await galvoMethod({
    type: "dev_method",
    method: "microns_per_point_to_framerate",
    args: [micronsPerPoint],
  });
  return framerate;
};

export const getFramerate = async () => {
  const framerate = await galvoMethod({
    type: "dev_method",
    method: "get_framerate",
    args: [],
  });
  return framerate;
};

//Request current resolution (points_per_volt) from Matlab object.
export const getResolution = async () => {
  const mpp = await galvoMethod({
    type: "dev_method",
    method: "get_resolution",
    args: [],
  });
  return mpp;
};

export const updateFramerate = async (framerate) => {
  const success = await galvoMethod({
    type: "dev_method",
    method: "set_framerate",
    args: [framerate],
  });
  return success;
};

export const snapScanning = async ({ experimentName }) => {
  const success = await matlabAppMethod({
    method: "Scanning_Snap",
    args: [experimentName],
  });
  return success;
};

export const scalePointsScanning = async (points, imgHeight) => {
  // scale points to confocal device coords

  // points is dict with many points or an array of points
  const stretchFactor = await getStretchFactor({
    imgHeight,
    deviceType: "Scanning_Device",
  });

  if (points.length) {
    // points is an array of points
    return points.map((point) => Math.round(point * stretchFactor));
  }

  const newPoints = {};
  Object.keys(points).forEach((key) => {
    newPoints[key] = Math.round(points[key] * stretchFactor);
  });
  return newPoints;
};

export const generateRaster = async ({ xmin, xmax, ymin, ymax, imgHeight }) => {
  // convert to img coords
  const scaledPoints = await scalePointsScanning(
    { xmin, xmax, ymin, ymax },
    imgHeight
  );

  const success = await galvoMethod({
    method: "Gen_Raster_JS",
    args: [scaledPoints],
  });
  return success;
};

export const generateSpiral = async ({
  centerx,
  centery,
  radius,
  imgHeight,
}) => {
  const scaledPoints = await scalePointsScanning(
    {
      centerx,
      centery,
      radius,
    },
    imgHeight
  );

  const success = await galvoMethod({
    method: "Gen_Spiral_JS",
    args: [scaledPoints],
  });
  return success;
};

export const generateDonut = async ({
  centerx,
  centery,
  innerRadius,
  outerRadius,
  imgHeight,
}) => {
  // function success = Gen_Donut_JS(obj, donut)
  // % donut = {centerx, centery, innerRadius, outerRadius}

  const scaledPoints = await scalePointsScanning(
    {
      centerx,
      centery,
      innerRadius,
      outerRadius,
    },
    imgHeight
  );

  const success = await galvoMethod({
    method: "Gen_Donut_JS",
    args: [scaledPoints],
  });
  return success;
};

export const generateFreeform = async ({ xPoints, yPoints, imgHeight }) => {
  // function success = Gen_Freeform_JS(obj, xPoints, yPoints)

  const scaledXPoints = await scalePointsScanning(xPoints, imgHeight);
  const scaledYPoints = await scalePointsScanning(yPoints, imgHeight);

  const success = await galvoMethod({
    method: "Gen_Freeform_JS",
    args: [scaledXPoints, scaledYPoints],
  });
  return success;
};

export const generatePoints = async ({ xPoints, yPoints, imgHeight }) => {
  const scaledXPoints = await scalePointsScanning(xPoints, imgHeight);
  const scaledYPoints = await scalePointsScanning(yPoints, imgHeight);

  const success = await galvoMethod({
    method: "genPoints",
    args: [scaledXPoints, scaledYPoints, "dwell_time", 0.1],
  });
  return success;
};

export const projectGalvoCalPattern = async (
  numPointsToShow,
  deviceName = []
) => {
  return projectCalPattern(
    numPointsToShow,
    "Scanning_Device",
    deviceName || []
  );
};

export const findPointCentroid = async (ptIndex) => {
  const success = await galvoMethod({
    method: "findCalSpotLocation",
    args: [ptIndex],
  });
  return success;
};

export const calculateGalvoCalibrationTransform = async (
  pts,
  imgHeight,
  deviceName
) => {
  return calculateCalibrationTransform(
    pts,
    imgHeight,
    "Scanning_Device",
    deviceName || []
  );
};
