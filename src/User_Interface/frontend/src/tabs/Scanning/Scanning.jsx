import React, { useEffect } from "react";
import { DrawROIs } from "../../components/Patterning/DrawROIs";
import { useCircleMode } from "../../components/Patterning/PatterningModes/useCircleMode";
import { useCalibrateMode } from "../../components/Patterning/PatterningModes/useCalibrateMode";
import { useFreeformMode } from "../../components/Patterning/PatterningModes/useFreeformMode";
import {
  DrawingControlsProvider,
  useDrawingControls,
} from "../../components/Patterning/DrawingControlsContext";
import { ScanningSettings } from "./ScanningSettings";
import { useRectangleMode } from "../../components/Patterning/PatterningModes/useRectangleMode";
import { useDonutMode } from "../../components/Patterning/PatterningModes/useDonutMode";
import {
  calculateGalvoCalibrationTransform,
  generateDonut,
  generateFreeform,
  generatePoints,
  generateRaster,
  generateSpiral,
  projectGalvoCalPattern,
} from "../../matlabComms/scanningComms";
import { VerticalStack } from "../../components/VerticalStack";
import { SectionHeader } from "../../components/SectionHeader";
import { isEmpty } from "lodash";
import { usePointsMode } from "../../components/Patterning/PatterningModes/usePointsMode";

export default function Scanning({ deviceName = [] }) {
  return (
    <VerticalStack>
      <ScanningSettings />
      <ScanningDraw imgHeight={600} galvoDeviceName={deviceName} />
    </VerticalStack>
  );
}

const ScanningDraw = ({ imgHeight, ...props }) => {
  return (
    <div>
      <SectionHeader>Draw Galvo ROIs</SectionHeader>
      <DrawingControlsProvider imgHeight={imgHeight}>
        <GalvoDrawPatterns {...props} />
      </DrawingControlsProvider>
    </div>
  );
};

const GalvoDrawPatterns = ({ galvoDeviceName, ...props }) => {
  const rasterMode = useRectangleMode({
    name: "raster",
    handleCompletedRectangle: generateRaster,
    maxShapes: 1,
  });
  const spiralMode = useCircleMode({
    name: "spiral",
    handleCompletedCircle: generateSpiral,
    maxShapes: 1,
  });
  spiralMode.icon = <img src="spiral.svg" alt="spiral" className="h-6 w-6" />;
  const donutMode = useDonutMode({
    handleCompletedDonut: generateDonut,
    maxShapes: 1,
  });
  const freeformMode = useFreeformMode({
    maxShapes: 1,
    handleCompletedFreeform: generateFreeform,
  });

  const pointsMode = usePointsMode({
    handleCompletedPoints: generatePoints,
  });

  const calibrateMode = useCalibrateMode({
    calculateCalibration: calculateGalvoCalibrationTransform,
    projectCalibrationPattern: projectGalvoCalPattern,
    deviceType: "Scanning_Device",
    deviceName: galvoDeviceName,
  });

  const allModes = [
    rasterMode,
    spiralMode,
    donutMode,
    freeformMode,
    pointsMode,
    calibrateMode,
  ];

  const { lastMode } = useDrawingControls();

  // ensure only 1 shape is drawn at a time
  useEffect(() => {
    // keep only last mode & clear the rest
    allModes.forEach((mode) => {
      if (
        mode.name !== lastMode &&
        !isEmpty(mode.shapes) &&
        mode.name !== "calibrate"
      ) {
        mode.clear();
      }
    });
  }, [lastMode, allModes]);

  return (
    <DrawROIs
      deviceType={"Scanning_Device"}
      deviceName={galvoDeviceName}
      allModes={allModes}
      {...props}
    />
  );
};
