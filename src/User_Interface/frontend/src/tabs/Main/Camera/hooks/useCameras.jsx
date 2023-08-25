import { useEffect, useRef, useState } from "react";
import {
  getAutoNumFrames,
  getCameraProperties,
} from "../../../../matlabComms/mainComms";
import { addIds, setIfEmpty } from "../../../../components/Utils";
import { useGlobalAppVariables } from "../../../../components/GlobalAppVariablesContext";

export const useCameras = () => {
  const [cameras, setCameras] = useState([]);

  const { waveformControls } = useGlobalAppVariables();
  const { getGlobalPropValue } = waveformControls;
  const initialFetch = useRef(false); // This ref will track the initial data fetch

  const updateCameraProperty = (cameraIndex, propName, dict) => {
    // dict is a dictionary of properties to update
    setCameras((oldCameras) =>
      oldCameras.map((oldCam, idx) =>
        idx === cameraIndex
          ? {
              ...oldCam,
              props: oldCam.props.map((prop) =>
                prop.name === propName ? { ...prop, ...dict } : prop
              ),
            }
          : oldCam
      )
    );
  };

  const getCameraProperty = (cameraIndex, propName) => {
    const camera = cameras[cameraIndex];
    if (camera) {
      const prop = camera.props.find((prop) => prop.name === propName);
      return prop.value;
    }
    return null;
  };

  const updateCameraPropertyValue = (cameraIndex, propName, value) =>
    updateCameraProperty(cameraIndex, propName, { value: value });

  // add autoN button to frames_requested
  const updateCameras = () => {
    cameras.forEach((camera, idx) => addAutoNButton(camera, idx));
  };

  const addAutoNButton = (camera, cameraIndex) => {
    updateCameraProperty(cameraIndex, "frames_requested", {
      button: (
        <button
          onClick={() => {
            const totalTime = getGlobalPropValue("length"); // TODO: Not updating when length changes
            getAutoNumFrames(totalTime, camera.name).then((n) => {
              updateCameraPropertyValue(cameraIndex, "frames_requested", n);
            });
          }}
          className="bg-gray-500/50 rounded-full py-1 px-2 hover:bg-gray-400/50"
        >
          Auto
        </button>
      ),
    });
  };

  // update camera properties after we get the data from matlab and when length changes
  useEffect(updateCameras, [getGlobalPropValue("length")]);

  // Run this block only after the initial data fetch
  useEffect(() => {
    if (initialFetch.current) {
      // Run only after the initial fetch
      updateCameras();
      initialFetch.current = false; // Reset the flag so this block won't run again
    }
  }, [cameras]);

  // get data from matlab at the beginning
  useEffect(() => {
    // fetch data from matlab
    const fetchData = async () => {
      const cameraInfo = await getCameraProperties([
        "name",
        "exposuretime",
        "ROI",
        "frames_requested",
        "frametrigger_source",
        "daqtrig_period_ms",
      ]);
      setCameras(
        cameraInfo.map((camera, idx) => ({
          name: camera.name,
          props: createCameraProps(camera, idx),
        }))
      );
      initialFetch.current = true; // Mark the initial data as fetched
    };

    fetchData();
  }, []);

  const createCameraProps = (camera, idx) => {
    return addIds([
      {
        name: "exposuretime",
        displayName: "Exposure (s)",
        value: camera.exposuretime,
        type: "number",
        object: "camera",
      },
      {
        name: "frames_requested",
        displayName: "Frames",
        value: setIfEmpty(camera.frames_requested, 1),
        type: "number",
        object: "camera",
      },
      {
        name: "ROI Mode",
        value: camera.ROI.length === 4 ? "arbitrary" : "centered",
        options: ["centered", "arbitrary"],
        type: "menu",
        object: "ROI",
      },
      //add dropdown for frame trigger source
      {
        name: "frametrigger_source",
        displayName: "Frame Trigger",
        value: camera.frametrigger_source,
        options: ["Off", "DAQ", "External"],
        type: "menu",
        object: "camera",
      },
      // add start acquisition button and save snap button
      {
        name: "start",
        displayName: "Start Acquisition",
        type: "button",
        object: "camera",
      },
      {
        name: "Snap",
        type: "button",
        object: "camera",
      },
      {
        displayName: "ROI Width",
        name: "width",
        value: camera.ROI[1],
        type: "number",
        object: "ROI",
      },
      {
        displayName: "ROI Height",
        name: "height",
        value: camera.ROI[3],
        type: "number",
        object: "ROI",
      },
      {
        displayName: "ROI Top",
        name: "top",
        value: camera.ROI[2],
        type: "number",
        object: "ROI",
        show: camera.ROI.length === 4, // only show if arbitrary ROI
      },
      {
        displayName: "ROI Left",
        name: "left",
        value: camera.ROI[0],
        type: "number",
        object: "ROI",
        show: camera.ROI.length === 4,
      },
      {
        name: "daqtrig_period_ms",
        displayName: "Frame Period (ms)",
        value: camera.daqtrig_period_ms,
        type: "number",
        object: "camera",
        show: camera.frametrigger_source === "DAQ", // only show if frame trigger source is DAQ
      },
    ]);
  };

  return { cameras, updateCameraPropertyValue, setCameras };
};
