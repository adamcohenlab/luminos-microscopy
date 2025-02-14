import React, { useEffect } from "react";
import { useSnackbar } from "notistack";
import {
  getAutoNumFrames,
  getAutoNumFramesExternal,
  getRoiFromStream,
  snap,
  getCameraProperties,
  rotateCamFOV,
  rotateCamFOVcounter,
  flipCamFOV,
} from "../../../matlabComms/mainComms";
import Camera from "./CameraUtils";
import { useMatlabVariable } from "../../../matlabComms/matlabHelpers";
import { useGlobalAppVariables } from "../../../components/GlobalAppVariablesContext";
import { ArrowPathIcon, ArrowsRightLeftIcon, ArrowUturnRightIcon, ArrowUturnLeftIcon  } from "@heroicons/react/20/solid";
import { CameraIcon } from "@heroicons/react/20/solid";

interface ROI {
  left: number;
  top: number;
  width: number;
  height: number;
  type: string;
}

// Track current values for exposureTime, frameTrigger, and daqtrigPeriod
let currentExposureTime;
let currentFrameTrigger;
let currentDaqtrigPeriod;

// Track active warning snackbar key
let activeWarningKey = null;

// Warning check function moved outside of components
const checkAndDisplayWarning = (enqueueSnackbar, closeSnackbar, cameraName) => {
  const warningMessage =
    "Kinetix camera: DAQ triggering period is too low for this exposure time. Set trigger period at least 0.02ms slower than exposure time to avoid dropping frames.";

  if (
    currentFrameTrigger === "DAQ" &&
    currentExposureTime != null &&
    (cameraName.includes("Kinetix") || cameraName.includes("Teledyne")) &&
    (currentExposureTime * 1000 + 0.02 > currentDaqtrigPeriod)
  ) {
    // Don't spam warnings
    if (!activeWarningKey) {
      activeWarningKey = enqueueSnackbar(warningMessage, { variant: "warning" });
    }
  } else {
    if (activeWarningKey) {
      closeSnackbar(activeWarningKey);
      activeWarningKey = null;
    }
  }
};

const SingleCamera = ({ cameraName, ...props }) => {
  const { enqueueSnackbar, closeSnackbar } = useSnackbar();
  const { experimentName } = useGlobalAppVariables();

  const useMatlabCameraVariable = <T,>(name: string) =>
    useMatlabVariable<T>(name, "Camera", cameraName);

  const [exposureTime, setExposureTime] =
    useMatlabCameraVariable<number>("exposuretime");

  const [numFrames, setNumFrames] =
    useMatlabCameraVariable<number>("frames_requested");

  const onClickSnap = () => {
    const key = enqueueSnackbar("Saving snap to file...", {
      variant: "info",
      persist: true,
    });
    snap({ folder: experimentName, deviceName: cameraName }).then((success) => {
      closeSnackbar(key);
      if (!success) return;
      enqueueSnackbar("Saved snap to file", { variant: "success" });
    });
  };

  const onClickRotate = () => {
    rotateCamFOV( cameraName );
  };

  const onClickRotateCounter = () => {
    rotateCamFOVcounter(cameraName );
  };

  const onClickFlip = () => {
    flipCamFOV( cameraName );
  };

  const { waveformControls } = useGlobalAppVariables();
  const { getGlobalPropValue } = waveformControls;

  const onClickAutoN = () => {
    const totalTime = getGlobalPropValue("length");
    if (currentFrameTrigger === "External") {
      getAutoNumFramesExternal(cameraName).then((n) => {
        setNumFrames(n);
      });
    } else {
      getAutoNumFrames(totalTime, cameraName).then((n) => {
        setNumFrames(n);
      });
    }
  };
  
  // Initialize currentExposureTime with the initial MATLAB value of exposureTime
  useEffect(() => {
    currentExposureTime = exposureTime;
    checkAndDisplayWarning(enqueueSnackbar, closeSnackbar, cameraName);
  }, [exposureTime]);

  return (
    <Camera.Wrapper title={cameraName}>
      <Camera.Section>
        <Camera.SubTitle title="General" />
        <Camera.TextFieldsWrapper>
  <Camera.NumberField
    value={exposureTime}
    setValue={(x) => {
      const newExposureTime = Number(x);
      // Reject update if newExposureTime is 0 or less
      if (newExposureTime > 0) {
        currentExposureTime = newExposureTime;
        setExposureTime(currentExposureTime);
        checkAndDisplayWarning(enqueueSnackbar, closeSnackbar, cameraName); // Call warning check on update
      } else {
        enqueueSnackbar("Exposure time must be a number greater than 0.", { variant: "error" });
      }
    }}
    title="Exposure (s)"
  />
  <Camera.NumberField
    value={numFrames}
    setValue={(x) => setNumFrames(Number(x))}
    title="Frames"
    optionalButton={
      <Camera.Button onClick={onClickAutoN} className="m-0">
        Auto
      </Camera.Button>
    }
  />
<div className="flex space-x-2">
  <Camera.Button onClick={onClickSnap} className="h-10 flex-grow flex items-center justify-center px-3">
    <CameraIcon className="h-5 w-5 mr-1" />
    <span>Snap</span>
  </Camera.Button>
  <Camera.Button onClick={onClickRotate} className="h-10 flex-grow flex items-center justify-center px-3">
    <ArrowUturnRightIcon className="h-5 w-5 mr-1" />
    <span>Rotate FOV</span>
  </Camera.Button>
  <Camera.Button onClick={onClickRotateCounter} className="h-10 flex-grow flex items-center justify-center px-3">
    <ArrowUturnLeftIcon className="h-5 w-5 mr-1" />
    <span>Rotate FOV</span>
  </Camera.Button>
  <Camera.Button onClick={onClickFlip} className="h-10 flex-grow flex items-center justify-center px-4">
    <ArrowsRightLeftIcon className="h-5 w-5 mr-1" />
    <span>Flip FOV</span>
  </Camera.Button>
</div>

</Camera.TextFieldsWrapper>


      </Camera.Section>
      <CameraROI cameraName={cameraName} />
      <CameraFrameTriggering
        cameraName={cameraName}
        enqueueSnackbar={enqueueSnackbar}
        closeSnackbar={closeSnackbar}
      />
    </Camera.Wrapper>
  );
};

const CameraFrameTriggering = ({
  cameraName,
  className = "",
  enqueueSnackbar,
  closeSnackbar,
}) => {
  const [frameTrigger, setFrameTrigger] = useMatlabVariable<string>(
    "frametrigger_source",
    "Camera",
    cameraName
  );

  const [daqtrigPeriod, setDaqtrigPeriod] = useMatlabVariable<number>(
    "daqtrig_period_ms",
    "Camera",
    cameraName
  );

  const displayOptions = [
    "Single Start Trigger",
    "Trigger each Frame",
    "Manual Setup in Waveforms (advanced)",
  ];

  const actualOptions = ["Off", "DAQ", "External"];

  // Initialize currentFrameTrigger and currentDaqtrigPeriod with initial MATLAB values
  useEffect(() => {
    currentFrameTrigger = frameTrigger;
    currentDaqtrigPeriod = daqtrigPeriod;
    checkAndDisplayWarning(enqueueSnackbar, closeSnackbar, cameraName);
  }, [frameTrigger, daqtrigPeriod]);

  // Update trigger selection
  const handleTriggerSelection = (selectedOption: string) => {
    currentFrameTrigger = actualOptions[displayOptions.indexOf(selectedOption)];
    setFrameTrigger(currentFrameTrigger);
  };

  // Update DAQ trigger period
  const handleDaqTriggerPeriodChange = (value: number) => {
    currentDaqtrigPeriod = value;
    setDaqtrigPeriod(currentDaqtrigPeriod);
    checkAndDisplayWarning(enqueueSnackbar, closeSnackbar, cameraName);
  };

  return (
    <Camera.Section className={className}>
      <Camera.SubTitle title="Frame Triggering Selection" />
      <Camera.MenuField
        options={displayOptions}
        selected={displayOptions[actualOptions.indexOf(frameTrigger)] || undefined}
        setSelected={handleTriggerSelection}
        title="Frame Trigger"
      />
      {frameTrigger === "DAQ" && (
        <Camera.NumberField
          value={daqtrigPeriod}
          setValue={handleDaqTriggerPeriodChange}
          title="DAQ Trigger Period (ms)"
        />
      )}
    </Camera.Section>
  );
};

const CameraROI = ({
  cameraName,
  ...props
}: {
  cameraName: string;
  props?: any;
}) => {
  const [roi, setRoi] = useMatlabVariable<ROI>("roiJS", "Camera", cameraName);
  const [binning, setBinning] = useMatlabVariable<number>(
    "bin",
    "Camera",
    cameraName
  );

  // Fetch ROI when "centered with offset" is initialized
  useEffect(() => {
    const initializeCenteredWithOffset = async () => {
      if (roi?.type === "centered with offset") {
        const newRoi = (await getRoiFromStream(cameraName)) as ROI;
        if (newRoi) {
          const centerX = Math.round(newRoi.left + newRoi.width / 2);
          const centerY = Math.round(newRoi.top + newRoi.height / 2);
          setRoi({ ...newRoi, left: centerX, top: centerY, width: newRoi.width, height: newRoi.height });
        }
      }
    };

    initializeCenteredWithOffset();
  }, [roi?.type, cameraName]);

  const onClickLoadROI = async () => {
    const newBin = await getCameraProperties(["bin"], cameraName);
    setBinning(newBin[0].bin);

    const newRoi = (await getRoiFromStream(cameraName)) as ROI;
    if (newRoi.type === "centered with offset") {
      // Update 'Center horizontal' and 'Center vertical' with the midpoint values
      const centerX = Math.round(newRoi.left + newRoi.width / 2);
      const centerY = Math.round(newRoi.top + newRoi.height / 2);
      setRoi({ ...newRoi, left: centerX, top: centerY, width: newRoi.width, height: newRoi.height });
    } else {
      setRoi(newRoi);
    }
  };

  return (
    <Camera.Section>
      <Camera.SubTitle title="ROI" />

      <Camera.MenuField
        options={["arbitrary", "centered", "centered with offset"]}
        selected={roi?.type}
        setSelected={(x) => setRoi({ ...roi, type: x })}
        title="Type"
      />
      <Camera.TextFieldsWrapper>
        {roi?.type === "arbitrary" && (
          <>
            <Camera.NumberField
              value={roi?.left}
              setValue={(x) => setRoi({ ...roi, left: x })}
              title="Left"
            />
            <Camera.NumberField
              value={roi?.top}
              setValue={(x) => setRoi({ ...roi, top: x })}
              title="Top"
            />
          </>
        )}
        {roi?.type === "centered with offset" && (
          <>
            <Camera.NumberField
              value={roi?.left ? Math.round(roi.left) : Math.round(roi.width / 2)}
              setValue={(x) => setRoi({ ...roi, left: x })}
              title="Center horizontal"
            />
            <Camera.NumberField
              value={roi?.top ? Math.round(roi.top) : Math.round(roi.height / 2)}
              setValue={(x) => setRoi({ ...roi, top: x })}
              title="Center vertical"
            />
          </>
        )}
        <Camera.NumberField
          value={roi?.width}
          setValue={(x) => setRoi({ ...roi, width: x })}
          title="Width"
        />
        <Camera.NumberField
          value={roi?.height}
          setValue={(x) => setRoi({ ...roi, height: x })}
          title="Height"
        />
      </Camera.TextFieldsWrapper>
      <Camera.Button onClick={onClickLoadROI}>
        <ArrowPathIcon className="h-4 w-4 inline-block mr-2" />
        Load ROI from stream
      </Camera.Button>
      <Camera.MenuField
        options={["1", "2", "4"]}
        selected={(binning || 1).toString()}
        setSelected={(x) => setBinning(Number(x))}
        title="Binning"
      />
      <Camera.Description>
        Keyboard shortcuts: Z for zoom in, 
        X for zoom out, C for color, Numpad
        +/- for binning, Arrows to shift ROI, R to restart frozen stream, S to toggle scaling auto or fixed, H to toggle Histogram equalization
      </Camera.Description>
    </Camera.Section>
  );
};

export default SingleCamera;
