import React, { useEffect, useState } from "react";
import { linSpace, useInterval } from "../../components/Utils";
import { getCameraProperties, getROIBuffer } from "../../matlabComms/mainComms";
import { usePrevious } from "../../components/Utils";
import { Plots } from "../../components/Plots";
import { subsamplingRate } from "../Waveforms/WaveformPlots";

export const ROIPlotter = ({ ...props }) => {
  const secondsToPlotGoal = 30;
  const secondsToPlot =  secondsToPlotGoal / subsamplingRate; // need to account for subsampling DI
  const [exposureTime, setExposureTime] = useState(0.015); // will update below
  const numDataPoints = Math.round(secondsToPlot / exposureTime);

  const prevExposureTime = usePrevious(exposureTime);

  let x;
  if (numDataPoints < 1e5) x = linSpace(0, secondsToPlot, numDataPoints);
  else x = linSpace(0, exposureTime * 1e5 , Math.round(1e5));
  const [y, setY] = useState([]);
  // Stretch the x values by a factor of 10
  x = x.map(value => value * subsamplingRate);

  useEffect(() => {
    if (prevExposureTime !== exposureTime) {
      setY([]);
    }
  }, [exposureTime]);

  // Get ROI data periodically using the updated useInterval function
  useInterval(async () => {
    // Fetch camera properties
    const cameraInfo = await getCameraProperties(["exposuretime", "name"]);

    // If cameraInfo does not exist, return false to stop the interval
    if (!cameraInfo || cameraInfo.length === 0) {
      return false; // return false to stop the polling
    }
    // Update exposure time state
    setExposureTime(cameraInfo[0].exposuretime);

    // Fetch ROI buffer data
    const newData = await getROIBuffer(cameraInfo[0].name);
    // If newData does not exist, return false to stop the interval
    if (!newData) {
      return false;
    }
    // Update Y state with newData, keeping the array length limited to numDataPoints
    setY((oldData) => {
      let newY = [...oldData, ...newData];
      newY = newY.slice(-numDataPoints);
      return newY; // note, this is a return value inside setY, not the function
    });

    // Return a non-false value if everything is successful
    return true;
  });

  return (
    <div {...props}>
      <Plots
        data={[x, y]}
        names={["Mean ROI Counts per pixel per frame"]}
        header="Region of Interest Plots"
        className="w-96"
      />
    </div>
  );
};
