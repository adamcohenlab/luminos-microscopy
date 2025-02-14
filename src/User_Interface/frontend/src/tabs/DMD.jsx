import React, { useState, useEffect, useCallback } from "react";
import { SectionHeader } from "../components/SectionHeader";
import { DrawROIs } from "../components/Patterning/DrawROIs";
import {
  applyDMDMask,
  calculateDMDCalibrationTransform,
  projectDMDCalPattern,
  writeStackToDMD,
  writeWhiteToDMD,
  writeDarkToDMD,
  writeWhiteToCurrentFov,
  ExportShapesToMatlab,
  getImageHeight,
  getImageTform,
} from "../matlabComms/dmdComms";
import { usePolygonMode } from "../components/Patterning/PatterningModes/usePolygonMode";
import { useCircleMode } from "../components/Patterning/PatterningModes/useCircleMode";
import { useAdvancedCalibrateMode } from "../components/Patterning/PatterningModes/useAdvancedCalibrateMode";
import { useFreeformMode } from "../components/Patterning/PatterningModes/useFreeformMode";
import { useFullMode } from "../components/Patterning/PatterningModes/useFullMode";
import { useFovMode } from "../components/Patterning/PatterningModes/useFovMode";
import { useExportToMatlab } from "../components/Patterning/PatterningModes/useExportToMatlab";
import {
  DrawingControlsProvider,
  useDrawingControls,
} from "../components/Patterning/DrawingControlsContext";
import { computeMask } from "../utils/computeMask";
import { useStack } from "../components/Patterning/PatterningModes/useStack";

const imageHeight = 600;

export default function DMD({ deviceName = [] }) {
  return <DMDDraw imgHeight={imageHeight} dmdDeviceName={deviceName} />;
}

const DMDDraw = ({ imgHeight, dmdDeviceName }) => {
  return (
    <div>
      <SectionHeader>Draw DMD ROIs</SectionHeader>
      <DrawingControlsProvider imgHeight={imgHeight}>
        <DMDDrawPatterns dmdDeviceName={dmdDeviceName} />
      </DrawingControlsProvider>
    </div>
  );
};

const DMDDrawPatterns = ({ dmdDeviceName, ...props }) => {
  const polygonMode = usePolygonMode();
  const circleMode = useCircleMode({ dmdDeviceName });
  const calibrateMode = useAdvancedCalibrateMode({
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

  const handleCurrentFovButtonClick = useCallback(
    (prevIsSelected) => {
      if (prevIsSelected) {
        writeDarkToDMD(dmdDeviceName); 
      } else {

      clearLastMode();
        writeWhiteToCurrentFov(dmdDeviceName); 
      }
    },
    [dmdDeviceName] 
  );

  const handleExportButtonClick = useCallback(
    (prevIsSelected = []) => {
      if (!prevIsSelected) {
        getFactors(dmdDeviceName)
          .then(({ cameraFactor, dmdFactor }) => {
            const scalingFactor = cameraFactor;
            const scaleShape = (shape, factor) => {
              if (shape.center && shape.radius) {
                // Circle
                return {
                  center: shape.center.map((coord) => coord * factor),
                  radius: shape.radius * factor,
                };
              } else if (Array.isArray(shape) && Array.isArray(shape[0])) {
                // Polygon
                return shape.map(([x, y]) => [x * factor, y * factor]);
              }
              return shape;
            };

            // Collect shapes
            const shapes = {
              polygons: [...polygonMode.shapes, ...freeformMode.shapes].map(
                (polygon) => scaleShape(polygon, scalingFactor)
              ),
              circles: circleMode.shapes.map((circle) =>
                scaleShape(circle, scalingFactor)
              ),
            };

            // Export shapes to Matlab
            console.log(shapes);
            ExportShapesToMatlab(shapes, dmdDeviceName);
          })
          .catch((error) => {
            console.error("Error in getting image dimensions:", error);
          });
      }
    },
    [polygonMode, freeformMode, circleMode] // Include the modes as dependencies
  );

  const fullMode = useFullMode({
    handleButtonClick: handleFullModeButtonClick,
  });

  const fovMode = useFovMode({
    handleButtonClick: handleCurrentFovButtonClick,
  });

  const exportMode = useExportToMatlab({
    handleButtonClick: handleExportButtonClick,
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
    fovMode,
    freeformMode,
    calibrateMode,
    exportMode,
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
    <div>
      <DrawROIs
        deviceType={"DMD"}
        deviceName={dmdDeviceName}
        allModes={allModes}
        {...props}
      />
    </div>
  );
};

const findShapesOfType = (type, allModes) =>
  allModes
    .filter((m) => m?.type === type)
    .map((p) => p.shapes)
    .flat();

export const getFactors = async (dmdDeviceName) => {
  let cameraFactor;
  let dmdFactor;
  try {
    const cameraDimensions = await getImageHeight({
      deviceType: "DMD",
      deviceName: dmdDeviceName,
    });
    cameraFactor = cameraDimensions / imageHeight;
  } catch (error) {
    console.error(error);
    cameraFactor = 1;
  }

  try {
    const dmdDet = await getImageTform({
      deviceType: "DMD",
      deviceName: dmdDeviceName,
    });

    dmdFactor = cameraFactor * dmdDet;
  } catch (error) {
    console.error(error);
    dmdFactor = 1;
  }
  return { cameraFactor, dmdFactor };
};
