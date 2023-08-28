import { useState } from "react";
import { useDrawingControls } from "../DrawingControlsContext";

export const usePolygonMode = ({ name = "polygon" } = {}) => {
  const [currentPoint, setCurrentPoint] = useState([]);
  const [polygons, setPolygons] = useState([]);
  const [currentPolygonPoints, setCurrentPolygonPoints] = useState([]);
  const { pushLastMode, isDrawing } = useDrawingControls();

  const handleClick = (x, y) => {
    setCurrentPolygonPoints((prevShape) => [...prevShape, [x, y]]);
  };

  const handleMouseMove = (x, y, mouseDown) => {
    if (currentPolygonPoints.length > 0) {
      // If there are existing points, update the last point to the current mouse position
      setCurrentPoint([x, y]);
    }
  };

  const finishPolygon = (newPolygon) => {
    setPolygons((prevPolygons) => [...prevPolygons, newPolygon]);
    clearCurrent();
    pushLastMode(name);
  };

  const handleDoubleClick = (event) => {
    // Complete the polygon when the user double-clicks
    const newPolygon = [...currentPolygonPoints, currentPolygonPoints[0]];
    finishPolygon(newPolygon);
  };

  const clear = () => {
    setPolygons([]);
    setCurrentPoint([]);
    setCurrentPolygonPoints([]);
  };

  const undo = () => {
    setPolygons((prevPolygons) => prevPolygons.slice(0, -1));
  };

  const clearCurrent = () => {
    setCurrentPoint([]);
    setCurrentPolygonPoints([]);
  };

  // store a component as a variable
  const polygonImg = (
    <img
      src="/polygon.png"
      alt="polygon"
      className="h-6 w-6"
      style={{
        filter: "invert(100%)",
      }}
    />
  );

  return {
    shapes: polygons,
    currentShape: isDrawing
      ? currentPoint.length > 0
        ? [...currentPolygonPoints, currentPoint]
        : currentPolygonPoints
      : [],
    setShapes: setPolygons,
    handleClick,
    handleMouseMove,
    handleDoubleClick,
    clearCurrent,
    clear,
    undo,
    icon: polygonImg,
    type: "polygon",
    name,
    helperText: "Double-click to complete polygon",
  };
};
