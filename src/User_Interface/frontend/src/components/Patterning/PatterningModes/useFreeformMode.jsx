import { useState } from "react";
import { useDrawingControls } from "../DrawingControlsContext";
import { PencilIcon } from "@heroicons/react/24/outline";

export const useFreeformMode = ({
  handleCompletedFreeform = (freeform) => {},
  maxShapes = Infinity,
  name = "freeform",
} = {}) => {
  const [currentFreeform, setCurrentFreeform] = useState([]);
  const [freeforms, setFreeforms] = useState([]);
  const { pushLastMode, imgHeight } = useDrawingControls();

  const handleClick = (x, y) => {};

  const handleMouseMove = (x, y, mouseDown) => {
    if (mouseDown) {
      setCurrentFreeform((prevShape) => [...prevShape, [x, y]]);
    }
  };

  const finishFreeform = (newShape) => {
    const xPoints = currentFreeform.map((point) => point[0]);
    const yPoints = currentFreeform.map((point) => point[1]);
    handleCompletedFreeform({ xPoints, yPoints, imgHeight });

    setFreeforms((prevShapes) => [
      ...prevShapes.slice(0, maxShapes - 1),
      newShape,
    ]);
    clearCurrent();
    pushLastMode("freeform");
  };

  const handleMouseUp = (x, y) => {
    finishFreeform(currentFreeform);
  };

  const clear = () => {
    setFreeforms([]);
    setCurrentFreeform([]);
  };

  const undo = () => {
    setFreeforms((prevFreeforms) => prevFreeforms.slice(0, -1));
  };

  const clearCurrent = () => {
    setCurrentFreeform([]);
  };

  return {
    shapes: freeforms,
    setShapes: setFreeforms,
    currentShape: currentFreeform,
    handleClick,
    handleMouseMove,
    handleMouseUp,
    clearCurrent,
    clear,
    undo,
    icon: <PencilIcon className="h-6 w-6" />,
    type: "freeform", // tells ROIShapes to render as a freeform
    name,
  };
};
