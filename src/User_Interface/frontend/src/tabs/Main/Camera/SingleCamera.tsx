import React, { useEffect } from "react";
import { useSnackbar } from "notistack";
import {
  getAutoNumFrames,
  getRoiFromStream,
  snap,
  getCameraProperties,
} from "../../../matlabComms/mainComms";
import Camera from "./CameraUtils";
import { buildWaveforms } from "../../../matlabComms/waveformComms";
import { useMatlabVariable } from "../../../matlabComms/matlabHelpers";
import { useGlobalAppVariables } from "../../../components/GlobalAppVariablesContext";
import { ArrowPathIcon } from "@heroicons/react/20/solid";
import { CameraIcon } from "@heroicons/react/20/solid";

interface ROI {
  left: number;
  top: number;
  width: number;
  height: number;
  type: string;
}

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

  const { waveformControls } = useGlobalAppVariables();
  const { getGlobalPropValue } = waveformControls;

  const onClickAutoN = () => {
    const totalTime = getGlobalPropValue("length");
    getAutoNumFrames(totalTime, cameraName).then((n) => {
      setNumFrames(n);
    });
  };

  return (
    <Camera.Wrapper title={cameraName}>
      <Camera.Section>
        <Camera.SubTitle title="General" />
        <Camera.TextFieldsWrapper>
          <Camera.NumberField
            value={exposureTime}
            setValue={(x) => setExposureTime(Number(x))}
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
          <Camera.Button onClick={onClickSnap} className="h-8 w-24">
            <CameraIcon className="h-4 w-4 inline-block mr-2" /> Snap
          </Camera.Button>
        </Camera.TextFieldsWrapper>
      </Camera.Section>
      <CameraROI cameraName={cameraName} />
      <CameraFrameTriggering cameraName={cameraName} />
    </Camera.Wrapper>
  );
};

const CameraFrameTriggering = ({
  cameraName,
  className = "",
}: {
  cameraName: string;
  className?: string;
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

  return (
    <Camera.Section className={className}>
      <Camera.SubTitle title="Frame Triggering (Advanced)" />
      <Camera.MenuField
        options={["Off", "DAQ", "External"]}
        selected={frameTrigger || undefined}
        setSelected={(x) => setFrameTrigger(x)}
        title="Frame Trigger"
      />
      {frameTrigger === "DAQ" && (
        <Camera.NumberField
          value={daqtrigPeriod}
          setValue={(x) => setDaqtrigPeriod(x)}
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

  const onClickLoadROI = async () => {
    const newBin = await getCameraProperties(["bin"], cameraName);
    setBinning(newBin[0].bin);
    const newRoi = (await getRoiFromStream(cameraName)) as ROI;
    setRoi(newRoi);
  };

  return (
    <Camera.Section>
      <Camera.SubTitle title="ROI" />

      <Camera.MenuField
        options={["arbitrary", "centered"]}
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
        Keyboard shortcuts: Z for zoom in, X for zoom out, C for color, Numpad
        +/- for binning, Arrows to shift ROI
      </Camera.Description>
    </Camera.Section>
  );
};

export default SingleCamera;
