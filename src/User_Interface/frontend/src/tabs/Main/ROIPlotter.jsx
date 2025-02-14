import React, { useEffect, useState } from "react";
import { linSpace, useInterval } from "../../components/Utils";
import {
  getCameraProperties,
  getROIBuffer,
  Check_for_ROI,
} from "../../matlabComms/mainComms";
import { usePrevious } from "../../components/Utils";
import { Plots } from "../../components/PlotsRealTime";

export const ROIPlotter = ({ ...props }) => {
  const secondsToPlot = 60;
  const [exposureTimes, setExposureTimes] = useState([]);
  const prevExposureTimes = usePrevious(exposureTimes);
  const [cameraInfo, setCameraInfo] = useState([]);
  const [x, setX] = useState([]);
  const [y, setY] = useState([]);
  const [camerasWithROI, setCamerasWithROI] = useState([]);

  // Fetch camera properties and initialize exposure times and x, y arrays
  useEffect(() => {
    const fetchCameraInfoAndInitialize = async () => {
      const info = await getCameraProperties(["exposuretime", "name"]);
      if (!info || info.length === 0) return;

      setCameraInfo(info);
      setExposureTimes(info.map((camera) => camera.exposuretime));

      // Initialize x and y arrays based on initial exposure times
      const initialFudgeFactors = info.map((camera) =>
        Math.max(camera.exposuretime, 1 / 63)
      );
      setX(
        initialFudgeFactors.map((fudgeFactor) =>
          linSpace(-secondsToPlot, 0, Math.round(secondsToPlot / fudgeFactor))
        )
      );
      setY(
        initialFudgeFactors.map((fudgeFactor) =>
          new Array(Math.round(secondsToPlot / fudgeFactor)).fill(NaN)
        )
      );
    };

    fetchCameraInfoAndInitialize();
  }, [secondsToPlot]);

  // Update x and y arrays when exposureTimes change
  useEffect(() => {
    if (
      prevExposureTimes &&
      !exposureTimes.every((time, i) => time === prevExposureTimes[i])
    ) {
      const updatedFudgeFactors = exposureTimes.map((time) =>
        Math.max(time, 1 / 63)
      );

      setX(
        updatedFudgeFactors.map((fudgeFactor) =>
          linSpace(-secondsToPlot, 0, Math.round(secondsToPlot / fudgeFactor))
        )
      );

      setY(
        updatedFudgeFactors.map((fudgeFactor) =>
          new Array(Math.round(secondsToPlot / fudgeFactor)).fill(NaN)
        )
      );
    }
  }, [exposureTimes, prevExposureTimes, secondsToPlot, cameraInfo.length]);

  // Fetch ROI data and update x and y arrays
  useInterval(async () => {
    const cameraInfo = await getCameraProperties(["exposuretime", "name"]);
    if (!cameraInfo || cameraInfo.length === 0) return false;

    const newExposureTimes = cameraInfo.map((camera) => camera.exposuretime);
    setExposureTimes(newExposureTimes);

    // Added a function that asks cpp Cam_Wrapper if ROI has been selected and return true/false.
    const activeCameras = await Promise.all(
      cameraInfo.map(async (camera) => {
        return (await Check_for_ROI(camera.name)) ? camera : null;
      })
    );

    // Filter out cameras with an ROI and store them
    const camerasWithROI = activeCameras;//.filter((camera) => camera !== null);
    setCamerasWithROI(camerasWithROI);

    // Calculate new x and y values
    const newX = await Promise.all(
      cameraInfo.map(async (camera, index) => {
        if (camerasWithROI.includes(camera)) {
          const fudgeFactor = Math.max(newExposureTimes[index], 1 / 63);
          return linSpace(
            -secondsToPlot,
            0,
            Math.round(secondsToPlot / fudgeFactor)
          );
        } else {
          return new Array(Math.round(secondsToPlot / (1 / 63))).fill(NaN);
        }
      })
    );

    const newY = await Promise.all(
      cameraInfo.map(async (camera, index) => {
        if (camerasWithROI.includes(camera)) {
          const fudgeFactor = Math.max(newExposureTimes[index], 1 / 63);
          const newData = await getROIBuffer(camera.name);
          if (newData) {
            const lastYData = y[index] || [];
            // Filter for duplicate values here. These show up inconsistently depending on the rig
            const filteredNewData = newData.filter((newPoint, idx) => 
              newData.indexOf(newPoint) === idx &&
              !(idx === 0 && newPoint === lastYData[lastYData.length - 1])
            );
            return [...lastYData, ...filteredNewData].slice(
              -Math.round(secondsToPlot / fudgeFactor)
            );
          } else {
            return new Array(Math.round(secondsToPlot / fudgeFactor)).fill(NaN);
          }
        } else {
          return new Array(Math.round(secondsToPlot / (1 / 63))).fill(NaN);
        }
      })
    );
    setX(newX); // Update x for each camera separately
    setY(newY); // Update y data for each camera

    return true;
  });

  const plotnames = cameraInfo.map((camera) => `${camera.name}`);

  // Plot using PlotsRealTime
  return (
    <div {...props}>
      <Plots
        data={x.map((xArray, index) => [xArray, y[index] || []])}
        names={plotnames}
        header="Camera ROI Means Plots"
        className="w-96"
      />
    </div>
  );
};
