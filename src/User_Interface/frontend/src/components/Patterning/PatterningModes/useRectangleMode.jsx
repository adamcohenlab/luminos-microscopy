import { useMemo, useState } from "react";
import { useDrawingControls } from "../DrawingControlsContext";

const computeRectangle = (corner1, corner2, fixedAspectRatio) => {
  /* compute the rectangle object from the corners
    If fixedAspectRatio is set, make sure the rectangle has the correct aspect ratio.
  */

  if (corner1 && corner2) {
    const width = Math.abs(corner1[0] - corner2[0]);
    const height = Math.abs(corner1[1] - corner2[1]);

    // If fixedAspectRatio is set, make sure the rectangle has the correct aspect ratio.
    if (fixedAspectRatio) {
      const rectAspectRatio = width / height;
      if (rectAspectRatio > fixedAspectRatio) {
        // The rectangle is too wide, so reduce the width.
        const newWidth = height * fixedAspectRatio;
        return {
          x: Math.min(corner1[0], corner2[0]),
          y: Math.min(corner1[1], corner2[1]),
          width: newWidth,
          height,
        };
      } else {
        // The rectangle is too tall, so reduce the height.
        const newHeight = width / fixedAspectRatio;
        return {
          x: Math.min(corner1[0], corner2[0]),
          y: Math.min(corner1[1], corner2[1]),
          width,
          height: newHeight,
        };
      }
    } else {
      return {
        x: Math.min(corner1[0], corner2[0]),
        y: Math.min(corner1[1], corner2[1]),
        width,
        height,
      };
    }
  }
  return null;
};

export const useRectangleMode = ({
  handleCompletedRectangle = (rect) => {},
  name = "rectangle",
  fixedAspectRatio = null,
  maxShapes = Infinity,
  useUndo = true, // if true, the rectangle mode will push the last mode to the undo stack when a rectangle is completed
} = {}) => {
  const [rectangles, setRectangles] = useState([]);
  const [corner1, setCorner1] = useState([]);
  const [corner2, setCorner2] = useState([]);

  const rect = computeRectangle(corner1, corner2, fixedAspectRatio);

  const { imgHeight, pushLastMode } = useDrawingControls();

  const handleMouseMove = (x, y, mouseDown) => {
    if (mouseDown) {
      if (corner1.length > 0) {
        setCorner2([x, y]);
      } else {
        setCorner1([x, y]);
      }
    }
  };

  const handleMouseUp = (x, y) => {
    if (corner1.length > 0) {
      finishRectangle();
    } else {
      console.log(
        "Error: corner1 is not set. This should not happen. Please report this bug."
      );
    }
  };

  const finishRectangle = () => {
    const xmin = Math.min(corner1[0], corner2[0]);
    const xmax = Math.max(corner1[0], corner2[0]);
    const ymin = Math.min(corner1[1], corner2[1]);
    const ymax = Math.max(corner1[1], corner2[1]);
    handleCompletedRectangle({ xmin, xmax, ymin, ymax, imgHeight });
    if (useUndo) pushLastMode(name);
    setRectangles([...rectangles.slice(0, maxShapes - 1), rect]);
    clearCurrent();
  };

  const clear = () => {
    clearCurrent();
    setRectangles([]);
  };

  const clearCurrent = () => {
    setCorner1([]);
    setCorner2([]);
  };

  const undo = () => {
    clear();
  };

  return {
    shapes: rectangles,
    setShapes: setRectangles,
    currentShape: rect,
    handleMouseMove,
    handleMouseUp,
    clear,
    clearCurrent,
    undo,
    icon: <div className="w-5 h-5 border-gray-100 border-2 relative" />,
    type: "rectangle", // tells ROIShapes to render as a rectangle
    name,
  };
};
