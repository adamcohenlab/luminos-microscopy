import React from "react";
import { SectionHeader } from "../../components/SectionHeader";
import { DrawROIs } from "../../components/Patterning/DrawROIs";
import { usePolygonMode } from "../../components/Patterning/PatterningModes/usePolygonMode";
import { useCircleMode } from "../../components/Patterning/PatterningModes/useCircleMode";
import { useCalibrateMode } from "../../components/Patterning/PatterningModes/useCalibrateMode";
import { useFreeformMode } from "../../components/Patterning/PatterningModes/useFreeformMode";
import { DrawingControlsProvider } from "../../components/Patterning/DrawingControlsContext";
import {
  applySLMMask,
  calculateSLMCalibrationTransform,
  projectSLMCalPattern,
} from "../../matlabComms/slmComms";
import { useDrawingControls } from "../../components/Patterning/DrawingControlsContext";
import { AdvancedSLMSettings } from "./AdvancedSLMSettings";
import { useWaitingButtonMode } from "../../components/Patterning/PatterningModes/useWaitingButtonMode";
import { computeMask } from "../../utils/computeMask";

export default function SLM({ slmDeviceName = [] }) {
  return <SLMDraw imgHeight={600} slmDeviceName={slmDeviceName} />;
}

const SLMDraw = ({ imgHeight, ...props }) => {
  return (
    <div>
      <SectionHeader>Draw SLM ROIs</SectionHeader>
      <DrawingControlsProvider imgHeight={imgHeight}>
        <SLMDrawPatterns {...props} />
      </DrawingControlsProvider>
      <AdvancedSLMSettings className="mt-8" />
    </div>
  );
};

const SLMDrawPatterns = ({ slmDeviceName, ...props }) => {
  const polygonMode = usePolygonMode();
  const circleMode = useCircleMode();
  const calibrateMode = useCalibrateMode({
    calculateCalibration: calculateSLMCalibrationTransform,
    projectCalibrationPattern: projectSLMCalPattern,
    deviceType: "SLM_Device",
    deviceName: slmDeviceName,
  });
  const freeformMode = useFreeformMode();

  const { imgHeight, imgWidth } = useDrawingControls();

  const computeAndApplyMask = async () => {
    // compute a binary mask from the polygons and circles
    // mask should be of size [height, width]
    const mask = computeMask({
      polygons: polygonMode.shapes,
      circles: circleMode.shapes,
      height: imgHeight,
      width: imgWidth,
    });
    const success = await applySLMMask(mask);
    return success;
  };

  const slmClickMode = useWaitingButtonMode({
    handleButtonClick: computeAndApplyMask,
    title: "Update SLM",
  });

  const allModes = [
    polygonMode,
    circleMode,
    freeformMode,
    slmClickMode,
    calibrateMode,
  ];

  return (
    <DrawROIs
      deviceType={"SLM_Device"}
      deviceName={slmDeviceName}
      allModes={allModes}
      {...props}
    />
  );
};
