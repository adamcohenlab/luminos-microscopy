import { useEffect, useState } from "react";
import { useSnackbar } from "notistack";
import { useDrawingControls } from "../DrawingControlsContext";
import { snap } from "../../../matlabComms/mainComms";
import { getImageFolderPath } from "../../../matlabComms/miscellaneousComms";
import { tellMatlabAboutImage } from "../../../matlabComms/patterningComms";
import { useMatlabVariable } from "../../../matlabComms/matlabHelpers";
import {
  writeWhiteToDMD,
  writeDarkToDMD,
  projectDMDManualCalPattern,
  calculateDMDPointsCalibrationTransform,
} from "../../../matlabComms/dmdComms";
import { CustomGrayBox } from "../../CustomGrayBox";
import { PrettyTextInput } from "../../PrettyTextInput";
import { ViewfinderCircleIcon } from "@heroicons/react/20/solid";

// Compute the number of points to use in the calibration by asking MATLAB for calpoints belonging to a specific device
const useNumPointsInCalibration = (deviceType, deviceName) => {
  const [calibrationPoints, setCalibrationPoints] = useMatlabVariable(
    "calpoints",
    deviceType,
    deviceName
  );
  return calibrationPoints?.length;
};

export const useAutoPatternCalibrateMode = ({
  calculateCalibration,
  projectCalibrationPattern,
  name = "calibrate",
  deviceType, 
  deviceName = [],
} = {}) => {
  const [clickedPoints, setClickedPoints] = useState([]);
  const [isCalibrateMode, setIsCalibrateMode] = useState(false);
  const [calibrationPatternDisplayed, setCalibrationPatternDisplayed] = useState(false);
  const [selectedTransform, setSelectedTransform] = useState("Affine transform");
  const [selectedPatternPoints, setSelectedPatternPoints] = useState("4x6 April"); 
  const [isCalibrating, setIsCalibrating] = useState(false); // New state to track calibration progress
  
  const NUM_POINTS_IN_CALIBRATION = useNumPointsInCalibration(deviceType, deviceName);
  const { mode, setMode, setImgSelected, imgHeight } = useDrawingControls();
  const { enqueueSnackbar, closeSnackbar } = useSnackbar();
  const [isManual, setIsManual] = useState(false);
  const [intervalId, setIntervalId] = useState(null);

  const finishCalibration = async () => {
    await calculateCalibration(deviceName, selectedTransform).then((success) => {
      enqueueSnackbar(
        success ? "Calibration successful." : "Calibration failed.",
        { variant: success ? "success" : "error" }
      );
      setIsCalibrateMode(false);
      setMode("");
      setClickedPoints([]);
    });
    setIsCalibrating(false); // Re-enable controls after calibration finishes
  };

  const startCalibration = async () => {
    setIsCalibrating(true); // Disable controls during calibration
    setCalibrationPatternDisplayed(false); // Turn off the display pattern checkbox
    const key = enqueueSnackbar("Calibration in progress.", {
      variant: "info",
      persist: true,
    });
    
    const success = await writeWhiteToDMD(deviceName)
      .then(() => snap({ folder: "temp", showDate: false }))
      .then(() => getImageFolderPath())
      .then((folderPath) =>
        tellMatlabAboutImage(`${folderPath}/temp.png`, deviceType, deviceName)
      )
      .then(() => projectCalibrationPattern(deviceName, selectedPatternPoints.charAt(0)))
      .then(() => snap({ folder: "temp", showDate: false }))
      .then(() => getImageFolderPath())
      .then((folderPath) =>
        tellMatlabAboutImage(`${folderPath}/temp.png`, deviceType, deviceName)
      );

    finishCalibration();
    closeSnackbar(key);
    writeDarkToDMD(deviceName);
  };

  const handleToggleDisplayCalPattern = () => {
    if (!isCalibrating) {
      setCalibrationPatternDisplayed((prev) => {
        const newState = !prev;
        if (newState) {
          projectCalibrationPattern(deviceName, selectedPatternPoints.charAt(0));
        } else {
          writeDarkToDMD(deviceName);
        }
        return newState;
      });
    }
  };

  const handleTransformSelect = (e) => {
    if (!isCalibrating) {
      setSelectedTransform(e.target.value);
    }
  };

  const handlePatternPointsSelect = (e) => {
    if (!isCalibrating) {
      const value = e.target.value;
      setSelectedPatternPoints(value);
      if (value === "Manual") {
        setSelectedTransform("Manual calibration (affine)");
      }
    }
  };

  const handleButtonClick = (prevIsSelected, clearAllShapes) => {
    if (!prevIsSelected) {
      clearAllShapes();
    }
    setIsCalibrateMode(!prevIsSelected);
  };

  const clear = () => {
    setClickedPoints([]);
    setIsCalibrateMode(false);
    if (intervalId !== null) clearInterval(intervalId);
  };

  // Effect to update the displayed calibration pattern if `selectedPatternPoints` changes
  // while the display pattern checkbox is checked
  useEffect(() => {
    if (calibrationPatternDisplayed && !isCalibrating) {
      projectCalibrationPattern(deviceName, selectedPatternPoints.charAt(0));
    }
  }, [selectedPatternPoints, calibrationPatternDisplayed, isCalibrating]);

  return {
    shapes: clickedPoints,
    clear,
    clearCurrent: clear,
    handleButtonClick,
    type: "points",
    name,
    isSelected: isCalibrateMode,
    helperText: "Ensure shutter is open and laser on",
    icon: (
      <div className="text-sm font-medium" title="Calibrate with camera">
        Calibrate
      </div>
    ),
    
    // Conditionally render calibration control panel
    sideComponent: isCalibrateMode && (
      <CustomGrayBox style={{ width: '288px' }} className="p-5 rounded-none">
        <h3 className="text-lg font-semibold mb-4">Calibration Setup</h3>

        {/* Calibration Pattern Section */}
        <div className="mb-4">
          <label className="block text-sm font-bold mb-1">Select Calibration Pattern</label>
          <div className="flex items-center">
            <input
              type="checkbox"
              checked={calibrationPatternDisplayed}
              onChange={handleToggleDisplayCalPattern}
              className="ml-4"
              disabled={isCalibrating} // Disable when calibrating
            />
            {/* Dropdown for selecting April Tag layout */}
            <select
              value={selectedPatternPoints}
              onChange={handlePatternPointsSelect}
              style={{ width: '200px'}}
              className="bg-black bg-opacity-0 outline-none border border-gray-600 border-opacity-0 hover:border-opacity-100 focus:ring-0 focus:border-0 text-xs ml-2"
              disabled={isCalibrating} // Disable when calibrating
            >
              {["1x1 April", "2x3 April", "3x4 April", "4x6 April", "5x7 April", "6x8 April", "7x9 April", "8x11 April", "Manual"].map((num) => (
                <option key={num} value={num} className="bg-gray-800">
                  {num}
                </option>
              ))}
            </select>
          </div>
        </div>

        <div className="my-4 bg-gray-700" style={{ height: '1px' }}></div>
        
        {/* Dropdown for selecting transform */}
        <div className="flex flex-col mb-4">
          <label className="block text-sm font-bold mb-1">Select Target Transform</label>
          <select
            value={selectedTransform}
            onChange={handleTransformSelect}
            style={{ width: '245px' }}
            className="bg-black bg-opacity-0 outline-none border border-gray-600 border-opacity-0 hover:border-opacity-100 focus:ring-0 focus:border-0 text-xs"
            disabled={isCalibrating || selectedPatternPoints === "Manual"} // Disable when calibrating or "Manual" pattern is selected
          >
            {selectedPatternPoints === "Manual" ? (
              <option value="Manual calibration (affine)" className="bg-gray-800 text-white">
                Manual calibration (affine)
              </option>
            ) : (
              <>
                <option value="Affine transform" className="bg-gray-800 text-white">
                  Affine transform
                </option>
                <option value="Projective transform" className="bg-gray-800 text-white">
                  Projective transform
                </option>
                <option value="2nd Degree Polynomial transform" className="bg-gray-800 text-white">
                  2nd Degree Polynomial transform
                </option>
                <option value="4th Degree Polynomial transform" className="bg-gray-800 text-white">
                  4th Degree Polynomial transform
                </option>
              </>
            )}
          </select>
        </div>

        <div className="text-gray-400 text-xs ml-2 mt-4">
            Calibration is fully agnostic with respect to ROI and Binning. 2nd Degree Polynomial needs at least fully visible 2 tags, 4th Degree needs 5.
        </div>

        <div className="my-4 bg-gray-700" style={{ height: '1px' }}></div>

        {/* Start Calibration Button */}
        <div className="flex justify-center mt-4">
          <button
            className="bg-gray-800 hover:bg-gray-700 py-2 px-3 rounded-md flex items-center"
            onClick={startCalibration}
            disabled={isCalibrating} // Prevent multiple clicks while calibrating
          >
            <ViewfinderCircleIcon className="h-4 w-4 text-gray-100 mr-2" />
            Start Calibration
          </button>
        </div>
      </CustomGrayBox>
    ),
  };
};
