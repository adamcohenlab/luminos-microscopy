import { useEffect, useState } from "react";
import { useDrawingControls } from "../DrawingControlsContext";

export const usePointsMode = ({
  handleCompletedPoints,
  name = "points",
} = {}) => {
  const [clickedPoints, setClickedPoints] = useState([]);

  const { imgHeight, pushLastMode } = useDrawingControls();

  const onCompletedPoints = (points) => {
    handleCompletedPoints({
      xPoints: points.map((p) => p[0]), // convert to array of x values
      yPoints: points.map((p) => p[1]), // convert to array of y values
      imgHeight,
    });
    pushLastMode(name);
  };

  const handleClick = (x, y) => {
    onCompletedPoints([...clickedPoints, [x, y]]);

    // append new points
    setClickedPoints((prevPoints) => [...prevPoints, [x, y]]);
  };

  const clear = () => {
    setClickedPoints([]);
  };

  const undo = () => {
    onCompletedPoints(clickedPoints.slice(0, -1));
    setClickedPoints((prevPoints) => prevPoints.slice(0, -1));
  };

  const pointsIcon = (
    <div className="text-sm font-medium" title="Add points">
      Points
    </div>
  );

  return {
    shapes: clickedPoints,
    setShapes: (pts) => {
      setClickedPoints(pts);
    },
    clear,
    clearCurrent: clear,
    undo,
    handleClick,
    icon: pointsIcon,
    type: "points", // tells ROIShapes to render as points
    name,
  };
};
