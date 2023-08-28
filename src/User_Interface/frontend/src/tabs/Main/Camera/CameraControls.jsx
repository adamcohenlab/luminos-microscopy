import React, { useEffect } from "react";
import { useSnackbar } from "notistack";
import {
  capitalize,
  getValueIfExists,
  prettyName,
  retrieveByName,
} from "../../../components/Utils";
import {
  setCameraExposureTime,
  setCameraProperty,
  setCameraROI,
  snap,
  startCamAcquisition,
} from "../../../matlabComms/mainComms";
import { TextField, MenuField, Button } from "./CameraUtils";
import { buildWaveforms } from "../../../matlabComms/waveformComms";

const CameraControls = ({
  cameraName,
  controls,
  setControls,
  experimentName,
  ...props
}) => {
  const { enqueueSnackbar, closeSnackbar } = useSnackbar();

  const setValue = (id, value) => {
    setControls((prevControls) =>
      prevControls.map((control) =>
        control.id == id ? { ...control, value } : control
      )
    );
  };

  const sendToMatlab = (prop, value) => {
    // send to matlab
    if (prop.object === "camera") {
      if (prop.name == "exposuretime") {
        // separate way of handling exposure time changes
        setCameraExposureTime(Number(value), cameraName);
      } else {
        const val = prop.type === "number" ? Number(value) : value;
        setCameraProperty(prop.name, val, cameraName);
      }
    } else if (prop.object === "ROI") {
      const getROIVal = (name) => {
        const x = retrieveByName(name, controls);
        return x == undefined ? x : Number(x.value);
      };

      let top = getROIVal("top");
      let left = getROIVal("left");
      let width = getROIVal("width");
      let height = getROIVal("height");
      let type = controls.find(
        (control) => control.object === "ROI" && control.type === "menu"
      ).value;

      // use value instead of controls because controls is not updated yet
      if (prop.name === "ROI Mode") type = value;
      else if (prop.name === "top") top = Number(value);
      else if (prop.name === "left") left = Number(value);
      else if (prop.name === "width") width = Number(value);
      else if (prop.name === "height") height = Number(value);

      setCameraROI({ left, width, top, height }, type, cameraName);
    }
  };

  // watch for changes to ROI Mode
  const roiMode = getValueIfExists(retrieveByName("ROI Mode", controls));
  useEffect(() => {
    setControls((prevControls) =>
      // hide top and left controls if ROI mode is not arbitrary
      prevControls.map((control) => {
        if (control.name !== "top" && control.name !== "left") return control;
        else return { ...control, show: roiMode == "arbitrary" };
      })
    );
  }, [roiMode]);

  const frameTriggerSource = getValueIfExists(
    retrieveByName("frametrigger_source", controls)
  );

  // watch for changes to frame trigger source
  useEffect(() => {
    setControls((prevControls) =>
      // hide daqtrig_period_ms if frame trigger source is not daq
      prevControls.map((control) => {
        if (control.name !== "daqtrig_period_ms") return control;
        else return { ...control, show: frameTriggerSource === "DAQ" };
      })
    );
  }, [frameTriggerSource]);

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

  const onClickStartAcquisition = () => {
    buildWaveforms().then((successWfm) => {
      if (!successWfm) return;
      const key = enqueueSnackbar("Acquiring data...", {
        variant: "info",
        persist: true,
      });

      startCamAcquisition(experimentName).then((success) => {
        closeSnackbar(key);
        if (!success) {
          enqueueSnackbar("Acquisition failed", {
            variant: "error",
          });
        } else {
          enqueueSnackbar("Acquisition complete", {
            variant: "success",
          });
        }
      });
    });
  };

  const onClicks = {
    snap: onClickSnap,
    start: onClickStartAcquisition,
  };

  const filteredControls = controls.filter(
    (control) =>
      // if show exists in control, and it's set to false, filter it out
      control.show == undefined || control.show
  );
  const textControls = filteredControls.filter(
    (control) => control.type === "text" || control.type === "number"
  );
  const menuControls = filteredControls.filter(
    (control) => control.type === "menu"
  );
  const buttonControls = filteredControls.filter(
    (control) => control.type === "button"
  );

  return (
    <div {...props}>
      <div className="px-2 bg-gray-800 bg-opacity-75 rounded-md w-96">
        <div className="grid grid-cols-1 divide-y divide-gray-700">
          <div className="font-semibold text-gray-100 p-2">
            {prettyName(cameraName)}
          </div>
          <div className="py-2 grid grid-cols-2 gap-2 gap-y-1">
            {textControls.map((control) => (
              <TextField
                key={control.name}
                defaultValue={control.defaultVal}
                value={control.value}
                setValue={(value) => setValue(control.id, value)}
                onBlur={(e) => sendToMatlab(control, e.target.value)}
                optionalButton={control.button}
              >
                {capitalize(control.displayName || control.name)}
              </TextField>
            ))}
          </div>
          <div className="py-2 flex flex-col gap-y-1">
            {menuControls.map((control) => (
              <MenuField
                options={control.options}
                defaultValue={control.defaultVal}
                selected={control.value}
                setSelected={(value) => {
                  setValue(control.id, value);
                  sendToMatlab(control, value);
                }}
                key={control.id}
              >
                {capitalize(control.displayName || control.name)}
              </MenuField>
            ))}
          </div>
          {/* grid with 2 columns */}
          <div className="pt-4 pb-3 grid grid-cols-2 gap-2 gap-y-1">
            {buttonControls.map((control) => (
              <Button
                key={control.id}
                onClick={() => onClicks[control.name.toLowerCase()]()}
                disabled={control.disabled}
                className="my-0"
                primary={control.name == "start"}
              >
                {capitalize(control.displayName || control.name)}
              </Button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default CameraControls;
