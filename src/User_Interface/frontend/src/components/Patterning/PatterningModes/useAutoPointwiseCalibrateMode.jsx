import { useEffect, useState } from "react";
import { useSnackbar } from "notistack";
import { useDrawingControls } from "../DrawingControlsContext";
import { snap } from "../../../matlabComms/mainComms";
import { getImageFolderPath } from "../../../matlabComms/miscellaneousComms";
import { tellMatlabAboutImage } from "../../../matlabComms/patterningComms";
import { findPointCentroid } from "../../../matlabComms/scanningComms";
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

export const useAutoPointwiseCalibrateMode = ({
    calculateCalibration,
    projectCalibrationPattern,
    name = "calibrate",
    deviceType, // e.g. "DMD"
    deviceName = [],
} = {}) => {
    const NUM_POINTS_IN_CALIBRATION = useNumPointsInCalibration(
        deviceType,
        deviceName
    );
    const { mode, setMode, setImgSelected, imgHeight } = useDrawingControls();
    const [isCalibrateMode, setIsCalibrateMode] = useState(false);
    const { enqueueSnackbar, closeSnackbar } = useSnackbar();

    //When all points have been displayed, call this to perform calibration calculations
    const finishCalibration = async () => {
        const pts = [0, 0];
        setIsCalibrateMode(false);

        await projectCalibrationPattern(-1, deviceName) //project calibration point
            .then(() => sleep(300))
            .then(() => snap({ folder: "temp", showDate: false }))
            .then(() => sleep(700))
            .then(() => getImageFolderPath())
            .then((folderPath) => tellMatlabAboutImage(`${folderPath}/temp.png`, deviceType, deviceName));
 
        setMode("");
        const key = enqueueSnackbar("Calibrating...", {
            variant: "info",
            persist: true,
        });
        calculateCalibration(pts, imgHeight, deviceName).then((success) => { //arbitrary points just to avoid undefined
            closeSnackbar(key);
            enqueueSnackbar(
                success ? "Calibration successful" : "Calibration failed",
                { variant: success ? "success" : "error" }
            );
            setClickedPoints([]);
        });
    };
    function sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    const startCalibration = async () => {
        // 1. Project first calibration point
        // 2. Display dialog asking user to ensure that laser is on and shutter is open.
        // 3. Snap image, changing imgSelected to the latest image
        // 4. Send image to Matlab to calculate centroid.
        // 5. Project next point, repeat until all points projected and calculated.
        // 6. finish calibration
        const success = await projectCalibrationPattern(-1, deviceName); // project all points to start
        

        for (let i = 1; i <= NUM_POINTS_IN_CALIBRATION; i++) {
            await projectCalibrationPattern(i, deviceName) //project calibration point
                .then(() => sleep(300))
                .then(() => snap({ folder: "temp", showDate: false }))
                .then(() => sleep(700))
                .then(() => getImageFolderPath())
                .then((folderPath) => tellMatlabAboutImage(`${folderPath}/temp.png`, deviceType, deviceName))
                .then(() => findPointCentroid(i));
        }
        finishCalibration();
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
        setIsCalibrateMode(false);
    };


    //Graphics object that is returned (appears as "Calibrate" button)
    return {
        clear,
        clearCurrent: clear,
        icon: (
            <div className="text-sm font-medium" title="Calibrate with camera">
                Calibrate
            </div>
        ),
        handleButtonClick,
        name,
        isSelected: isCalibrateMode,
        helperText: "Ensure shutter is open and laser on",
    };
};
