import { useRef, useEffect, useState } from "react";
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
} from "../../../matlabComms/dmdComms";
import { CustomGrayBox } from "../../CustomGrayBox";
import { PrettyTextInput } from "../../PrettyTextInput";
import { ViewfinderCircleIcon } from "@heroicons/react/20/solid";

const useNumPointsInCalibration = (deviceType, deviceName) => {
  const [calibrationPoints] = useMatlabVariable(
    "calpoints",
    deviceType,
    deviceName
  );
  return calibrationPoints?.length;
};

export const useAdvancedCalibrateMode = ({
  calculateCalibration,
  projectCalibrationPattern,
  name = "calibrate",
  deviceType,
  deviceName = [],
} = {}) => {
  const [clickedPoints, setClickedPoints] = useState([]);
  const [isCalibrateMode, setIsCalibrateMode] = useState(false);
  const [calibrationPatternDisplayed, setCalibrationPatternDisplayed] =
    useState(false);
  const [selectedTransform, setSelectedTransform] =
    useState("Affine transform");
  const [selectedPatternPoints, setSelectedPatternPoints] =
    useState("4x6 April");
  const [isCalibrating, setIsCalibrating] = useState(false);
  const [isManual, setIsManual] = useState(false);
  const [intervalId, setIntervalId] = useState(null);

  const NUM_POINTS_IN_CALIBRATION = useNumPointsInCalibration(
    deviceType,
    deviceName
  );

  const { mode, setMode, setImgSelected, imgHeight } = useDrawingControls();
  const { enqueueSnackbar, closeSnackbar } = useSnackbar();
  const key1Ref = useRef(null);

  const closeCalibrationSnackbar = () => {
    if (key1Ref.current) {
      closeSnackbar(key1Ref.current);
      key1Ref.current = null;
    }
  };

  const finishCalibration = async (pts) => {
    closeCalibrationSnackbar();
    if (isManual) {
      setIsCalibrateMode(false);
      if (intervalId !== null) clearInterval(intervalId);
      setMode("");
      const key = enqueueSnackbar("Calibrating...", {
        variant: "info",
        persist: true,
      });
      pts = pts.map((pt) => pt.map((coord) => coord / imgHeight));
      calculateCalibration(deviceName, selectedTransform, pts).then(
        (success) => {
          closeSnackbar(key);
          enqueueSnackbar(
            success ? "Calibration successful" : "Calibration failed",
            { variant: success ? "success" : "error" }
          );
          setClickedPoints([]);
          setIsCalibrating(false);
        }
      );
    } else {
      await calculateCalibration(deviceName, selectedTransform).then(
        (success) => {
          closeCalibrationSnackbar();
          enqueueSnackbar(
            success ? "Calibration successful." : "Calibration failed.",
            { variant: success ? "success" : "error" }
          );
          setIsCalibrateMode(false);
          setMode("");
          setClickedPoints([]);
        }
      );
      setIsCalibrating(false);
    }
  };

  const startCalibration = async () => {
    setIsCalibrating(true);
    setCalibrationPatternDisplayed(false);
    closeCalibrationSnackbar();
    key1Ref.current = enqueueSnackbar(
      isManual
        ? "Manual Calibration in progress."
        : "Automatic calibration in progress.",
      {
        variant: "info",
        persist: true,
      }
    );

    if (isManual) {
      const success = await projectDMDManualCalPattern(1, deviceName);
      if (success) {
        const interval = setInterval(() => {
          snap({ folder: "temp", showDate: false });
          getImageFolderPath().then((folderPath) => {
            setImgSelected(`${folderPath}/temp.png?${Date.now()}`);
            tellMatlabAboutImage(
              `${folderPath}/temp.png`,
              deviceType,
              deviceName
            );
          });
        }, 2000);
        setIntervalId(interval);
      }
    } else {
      await writeWhiteToDMD(deviceName)
        .then(() => snap({ folder: "temp", showDate: false }))
        .then(() => getImageFolderPath())
        .then((folderPath) =>
          tellMatlabAboutImage(`${folderPath}/temp.png`, deviceType, deviceName)
        )
        .then(() =>
          projectCalibrationPattern(deviceName, selectedPatternPoints.charAt(0))
        )
        .then(() => snap({ folder: "temp", showDate: false }))
        .then(() => getImageFolderPath())
        .then((folderPath) =>
          tellMatlabAboutImage(`${folderPath}/temp.png`, deviceType, deviceName)
        );
      finishCalibration([]);
      writeDarkToDMD(deviceName);
    }
  };

  const handleClick = (x, y) => {
    if (isManual) {
      if (clickedPoints.length === NUM_POINTS_IN_CALIBRATION - 1) {
        const allPoints = [...clickedPoints, [x, y]];
        setClickedPoints(allPoints);
        finishCalibration(allPoints);
      } else {
        projectDMDManualCalPattern(clickedPoints.length + 2, deviceName);
        setClickedPoints([...clickedPoints, [x, y]]);
      }
    }
  };

  const handleToggleDisplayCalPattern = () => {
    if (!isCalibrating) {
      setCalibrationPatternDisplayed((prev) => {
        const newState = !prev;
        if (newState) {
          projectCalibrationPattern(
            deviceName,
            selectedPatternPoints.charAt(0)
          );
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
        setIsManual(true);
      } else {
        setSelectedTransform("Affine transform");
        setIsManual(false);
      }
    }
  };

  const handleButtonClick = (prevIsSelected, clearAllShapes) => {
    if (isCalibrating) return;

    if (!prevIsSelected) {
      clearAllShapes();
    } else {
      setCalibrationPatternDisplayed(false);
    }
    setIsCalibrateMode(!prevIsSelected);
    writeDarkToDMD(deviceName);
  };

  const clear = () => {
    setClickedPoints([]);
    setIsCalibrateMode(false);
    if (intervalId !== null) clearInterval(intervalId);
  };

  useEffect(() => {
    if (calibrationPatternDisplayed && !isCalibrating && !isManual) {
      projectCalibrationPattern(deviceName, selectedPatternPoints.charAt(0));
    }
  }, [selectedPatternPoints, calibrationPatternDisplayed, isCalibrating]);

  useEffect(() => {
    if (isCalibrateMode && ![name, "zoom", ""].includes(mode)) {
      clear();
    }
    if (mode === "" && isCalibrateMode) setMode(name);
  }, [mode]);

  return {
    shapes: clickedPoints,
    setShapes: (pts) => setClickedPoints(pts),
    clear,
    clearCurrent: clear,
    handleClick: isManual ? handleClick : undefined,
    handleButtonClick,
    type: isManual ? "points" : null,
    name,
    isSelected: isCalibrateMode,
    helperText: isManual
      ? "Click on the center of the calibration points as they appear on the screen."
      : "Ensure sample is in focus and well illuminated before starting calibration.",
    icon: (
      <div className="text-sm font-medium" title="Calibrate with camera">
        Calibrate
      </div>
    ),
    sideComponent: isCalibrateMode && (
      <CustomGrayBox style={{ width: "288px" }} className="p-5 rounded-none">
        <h3 className="text-lg font-semibold mb-4">Calibration Setup</h3>
        <div className="mb-4">
          <label className="block text-sm font-bold mb-1">
            Select Calibration Pattern
          </label>
          <div className="flex items-center">
            <input
              type="checkbox"
              checked={calibrationPatternDisplayed}
              onChange={handleToggleDisplayCalPattern}
              className="ml-4"
              disabled={isCalibrating} // Disable when calibrating
            />
            <select
              value={selectedPatternPoints}
              onChange={handlePatternPointsSelect}
              style={{ width: "200px" }}
              className="bg-black bg-opacity-0 outline-none border border-gray-600 border-opacity-0 hover:border-opacity-100 focus:ring-0 focus:border-0 text-xs ml-2"
              disabled={isCalibrating} // Disable when calibrating
            >
              {[
                "1x1 April",
                "2x3 April",
                "3x4 April",
                "4x6 April",
                "5x7 April",
                "6x8 April",
                "7x9 April",
                "8x11 April",
                "Manual",
              ].map((num) => (
                <option key={num} value={num} className="bg-gray-800">
                  {num}
                </option>
              ))}
            </select>
          </div>
        </div>

        <div className="my-4 bg-gray-700" style={{ height: "1px" }}></div>

        <div className="flex flex-col mb-4">
          <label className="block text-sm font-bold mb-1">
            Select Target Transform
          </label>
          <select
            value={selectedTransform}
            onChange={handleTransformSelect}
            style={{ width: "245px" }}
            className="bg-black bg-opacity-0 outline-none border border-gray-600 border-opacity-0 hover:border-opacity-100 focus:ring-0 focus:border-0 text-xs"
            disabled={isCalibrating} // Disable when calibrating
          >
            {isManual ? (
              <option
                value="Manual calibration (affine)"
                className="bg-gray-800 text-white"
              >
                Manual calibration (affine)
              </option>
            ) : (
              <>
                <option
                  value="Affine transform"
                  className="bg-gray-800 text-white"
                >
                  Affine transform
                </option>
                <option
                  value="Projective transform"
                  className="bg-gray-800 text-white"
                >
                  Projective transform
                </option>
                <option
                  value="2nd Degree Polynomial transform"
                  className="bg-gray-800 text-white"
                >
                  2nd Degree Polynomial transform
                </option>
                <option
                  value="4th Degree Polynomial transform"
                  className="bg-gray-800 text-white"
                >
                  4th Degree Polynomial transform
                </option>
              </>
            )}
          </select>
        </div>

        <div className="text-gray-400 text-xs ml-2 mt-4">
          Calibration is fully agnostic with respect to ROI and Binning. 2nd
          Degree Polynomial needs at least 3 fully visible tags, 4th Degree
          needs 5.
        </div>

        <div className="my-4 bg-gray-700" style={{ height: "1px" }}></div>

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
