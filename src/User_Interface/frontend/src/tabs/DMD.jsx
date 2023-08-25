import React, { useEffect } from "react";
import { SectionHeader } from "../components/SectionHeader";
import { DrawROIs } from "../components/Patterning/DrawROIs";
import {
  applyDMDMask,
  calculateDMDCalibrationTransform,
  projectDMDCalPattern,
  writeStackToDMD,
  writeWhiteToDMD,
} from "../matlabComms/dmdComms";
import { usePolygonMode } from "../components/Patterning/PatterningModes/usePolygonMode";
import { useCircleMode } from "../components/Patterning/PatterningModes/useCircleMode";
import { useCalibrateMode } from "../components/Patterning/PatterningModes/useCalibrateMode";
import { useFreeformMode } from "../components/Patterning/PatterningModes/useFreeformMode";
import { useFullMode } from "../components/Patterning/PatterningModes/useFullMode";
import {
  DrawingControlsProvider,
  useDrawingControls,
} from "../components/Patterning/DrawingControlsContext";
import { useCallback } from "react";
import { computeMask } from "../utils/computeMask";
import { useStack } from "../components/Patterning/PatterningModes/useStack";

export default function DMD({ deviceName = [] }) {
  return <DMDDraw imgHeight={600} dmdDeviceName={deviceName} />;
}

const DMDDraw = ({ imgHeight, ...props }) => {
  return (
    <div>
      <SectionHeader>Draw DMD ROIs</SectionHeader>
      <DrawingControlsProvider imgHeight={imgHeight}>
        <DMDDrawPatterns {...props} />
      </DrawingControlsProvider>
    </div>
  );
};

const DMDDrawPatterns = ({ dmdDeviceName, ...props }) => {
  const polygonMode = usePolygonMode();
  const circleMode = useCircleMode();
  const calibrateMode = useCalibrateMode({
    calculateCalibration: calculateDMDCalibrationTransform,
    projectCalibrationPattern: projectDMDCalPattern,
    deviceType: "DMD",
    deviceName: dmdDeviceName,
  });
  const freeformMode = useFreeformMode();

  const handleFullModeButtonClick = useCallback(
    (prevIsSelected) => {
      if (!prevIsSelected) writeWhiteToDMD(dmdDeviceName);

      // clear all shapes drawn
      allModes.forEach((mode) => mode.clear?.());
      clearLastMode();
    },
    [dmdDeviceName]
  );

  const fullMode = useFullMode({
    handleButtonClick: handleFullModeButtonClick,
  });

  // const { allModes, stack, isStackMode } = useStack({
  //   allModes: [polygonMode, circleMode, fullMode, freeformMode, calibrateMode],
  //   handleWriteStack: () => {},
  // });

  // remove stack mode until the feature is tested
  const allModes = [
    polygonMode,
    circleMode,
    fullMode,
    freeformMode,
    calibrateMode,
  ];
  const isStackMode = false;
  const stack = [];

  const { imgHeight, imgWidth, mode, clearLastMode, imgSelected } =
    useDrawingControls();

  // listen for changes in the shapes and update the mask
  useEffect(() => {
    if (mode !== "calibrate" && mode !== "full" && !isStackMode) {
      if (!imgSelected) return;

      // compute a binary mask from the polygons and circles
      // mask should be of size [height, width]
      const mask = computeMask({
        polygons: [...polygonMode.shapes, ...freeformMode.shapes],
        circles: circleMode.shapes,
        height: imgHeight,
        width: imgWidth,
      });
      applyDMDMask(mask, dmdDeviceName);
    }

    if (isStackMode) {
      const masks = stack.map((stackItem) =>
        computeMask({
          polygons: findShapesOfType("polygon", stackItem),
          circles: findShapesOfType("circle", stackItem),
          height: imgHeight,
          width: imgWidth,
        })
      );

      writeStackToDMD(masks, dmdDeviceName);
    }
  }, [polygonMode.shapes, circleMode.shapes, freeformMode.shapes, imgSelected]);

  return (
    <DrawROIs
      deviceType={"DMD"}
      deviceName={dmdDeviceName}
      allModes={allModes}
      {...props}
    />
  );
};

const findShapesOfType = (type, allModes) =>
  allModes
    .filter((m) => m?.type === type)
    .map((p) => p.shapes)
    .flat();
