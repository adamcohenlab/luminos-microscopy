import { useEffect, useState } from "react";
import { useSnackbar } from "notistack";
import { useDrawingControls } from "../DrawingControlsContext";
import { snap } from "../../../matlabComms/mainComms";
import { getImageFolderPath } from "../../../matlabComms/miscellaneousComms";
import { tellMatlabAboutImage } from "../../../matlabComms/patterningComms";
import { useMatlabVariable } from "../../../matlabComms/matlabHelpers";

// compute the number of points to use in the calibration by asking matlab for calpoints belonging to specific device
const useNumPointsInCalibration = (deviceType, deviceName) => {
  const [calibrationPoints, setCalibrationPoints] = useMatlabVariable(
    "calpoints",
    deviceType,
    deviceName
  );
  return calibrationPoints?.length;
};

export const useCalibrateMode = ({
  calculateCalibration,
  projectCalibrationPattern,
  name = "calibrate",
  deviceType, // e.g. "DMD"
  deviceName = [],
} = {}) => {
  const [clickedPoints, setClickedPoints] = useState([]);
  const NUM_POINTS_IN_CALIBRATION = useNumPointsInCalibration(
    deviceType,
    deviceName
  );
  const { mode, setMode, setImgSelected, imgHeight } = useDrawingControls();
  const [isCalibrateMode, setIsCalibrateMode] = useState(false);

  const { enqueueSnackbar, closeSnackbar } = useSnackbar();

  const handleClick = (x, y) => {
    //when new click on image comes in:
    //If we've clicked all of the calibration points, append final click and finish calibration
    if (clickedPoints.length === NUM_POINTS_IN_CALIBRATION - 1) {
      const allPoints = [...clickedPoints, [x, y]];
      setClickedPoints((prevPoints) => [...prevPoints, [x, y]]);
      finishCalibration(allPoints);
      //Otherwise, append click and project new point.
    } else {
      projectCalibrationPattern(clickedPoints.length + 2, deviceName); // add one more point to the calibration pattern
      setClickedPoints((prevPoints) => [...prevPoints, [x, y]]);
    }
  };

  //When all points have been clicked, call this to perform calibration calculations
  const finishCalibration = (pts) => {
    setIsCalibrateMode(false);

    // stop snapping images
    if (intervalId !== null) clearInterval(intervalId);

    setMode("");
    const key = enqueueSnackbar("Calibrating...", {
      variant: "info",
      persist: true,
    });
    calculateCalibration(pts, imgHeight, deviceName).then((success) => {
      closeSnackbar(key);
      enqueueSnackbar(
        success ? "Calibration successful" : "Calibration failed",
        { variant: success ? "success" : "error" }
      );
      setClickedPoints([]);
    });
  };

  const [intervalId, setIntervalId] = useState(null);

  const startCalibration = async () => {
    // 1. Project calibration pattern
    // 2. Keep snapping images until the user is done, while changing imgSelected to the latest image
    const success = await projectCalibrationPattern(1, deviceName); // project 1 point to start

    // continuously snap images until the user clicks stop
    const interval = setInterval(() => {
      snap({ folder: "temp", showDate: false });

      getImageFolderPath().then((folderPath) => {
        // add a random number to the end of the image name to force a re-render
        setImgSelected(`${folderPath}/temp.png?${Date.now()}`);
        tellMatlabAboutImage(`${folderPath}/temp.png`, deviceType, deviceName);
      });
    }, 2000); // 2 seconds

    setIntervalId(interval);
  };

  //Main function that executes upon clicking "Calibrate" button
  const handleButtonClick = (prevIsSelected, clearAllShapes) => {
    if (!prevIsSelected) {
      clearAllShapes();
      startCalibration();
    }
    setIsCalibrateMode(!prevIsSelected);
  };

  useEffect(() => {
    // if the mode changes from calibrate to something other than "zoom" or "", set isCalibrateMode to false
    if (isCalibrateMode && !["calibrate", "zoom", ""].includes(mode)) {
      clear();
    }

    // switch back to calibrate mode if mode is "".
    // For e.g. if user clicks on zoom button then leaves the zoom, we want them to stay on calibrate
    if (mode == "" && isCalibrateMode) setMode(name);
  }, [mode]);

  const clear = () => {
    setClickedPoints([]);
    setIsCalibrateMode(false);

    // stop snapping images
    if (intervalId !== null) clearInterval(intervalId);
  };

  //Graphics object that is returned (appears as "Calibrate" button)
  return {
    shapes: clickedPoints,
    setShapes: (pts) => {
      setClickedPoints(pts);
    },
    clear,
    clearCurrent: clear,
    handleClick,
    icon: (
      <div className="text-sm font-medium" title="Calibrate with camera">
        Calibrate
      </div>
    ),
    handleButtonClick,
    type: "points", // tells ROIShapes to render as points
    name,
    isSelected: isCalibrateMode,
    helperText: "Select the calibration points",
  };
};
