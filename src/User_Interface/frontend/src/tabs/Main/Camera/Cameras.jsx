import React from "react";
import { SectionHeader } from "../../../components/SectionHeader";
import CameraControls from "./CameraControls";
import { useGlobalAppVariables } from "../../../components/GlobalAppVariablesContext";
import { useCameras } from "./hooks/useCameras";

export const Cameras = () => {
  const { experimentName } = useGlobalAppVariables();

  // used camera properties are in useCameras.jsx
  const { cameras, setCameras } = useCameras();

  return (
    <div>
      <SectionHeader>Camera Controls</SectionHeader>
      <div className="max-w-lg flex flex-col gap-4">
        {cameras.map((camera, idx) => (
          <CameraControls
            key={idx}
            cameraName={camera.name}
            controls={camera.props}
            experimentName={experimentName}
            setControls={(setNewCam) => {
              setCameras((oldCameras) =>
                oldCameras.map((oldCam, oldCamIdx) =>
                  oldCamIdx === idx
                    ? { name: oldCam.name, props: setNewCam(oldCam.props) }
                    : oldCam
                )
              );
            }}
          />
        ))}
      </div>
    </div>
  );
};
