import { useState } from "react";
import { computeRadius } from "../../../utils/computeRadius";
import { useDrawingControls } from "../DrawingControlsContext";
import { GrayBox } from "../../GrayBox";
import { isEmpty } from "lodash";
import { PrettyTextInput } from "../../PrettyTextInput";

export const useCircleMode = ({
  handleCompletedCircle = (newCircle) => {},
  maxShapes = Infinity,
  name = "circle", // change if you want to support multiple circle modes
} = {}) => {
  const [currentCircle, setCurrentCircle] = useState({});
  const [circles, setCircles] = useState([]);
  const { mode, pushLastMode, imgHeight } = useDrawingControls();

  const finishCircle = (newCircle) => {
    handleCompletedCircle({
      centerx: newCircle.center[0],
      centery: newCircle.center[1],
      radius: newCircle.radius,
      imgHeight,
    });

    // limit to maxShapes
    setCircles((prevCircles) => [
      ...prevCircles.slice(0, maxShapes - 1),
      newCircle,
    ]);
    clearCurrent();
    pushLastMode(name);
  };

  const handleClick = (x, y) => {
    // circle is complete after 2 clicks (one for the center, and one for the radius)
    // currentCircle is an object with center and radius properties
    if (currentCircle.center) {
      // if the center has been set, then the radius has been set
      const newCircle = {
        center: currentCircle.center,
        radius: computeRadius(
          currentCircle.center[0],
          currentCircle.center[1],
          x,
          y
        ),
      };
      finishCircle(newCircle);
    } else {
      // if the center has not been set, then set the center
      setCurrentCircle({ center: [x, y] });
    }
  };

  const handleMouseMove = (x, y, mouseDown) => {
    if (currentCircle.center !== undefined) {
      // If the center has been set, update the radius to the current mouse position
      setCurrentCircle({
        center: currentCircle.center,
        radius: computeRadius(
          currentCircle.center[0],
          currentCircle.center[1],
          x,
          y
        ),
      });
    }
  };

  const clear = () => {
    setCircles([]);
    setCurrentCircle({});
  };

  const undo = () => {
    setCircles((prevCircles) => prevCircles.slice(0, -1));
  };

  const clearCurrent = () => {
    setCurrentCircle({});
  };

  const circleIcon = (
    <div className="w-5 h-5 rounded-full border-gray-100 border-2"></div>
  );

  const previousCircleRadius = isEmpty(currentCircle)
    ? circles[circles.length - 1]?.radius
    : currentCircle.radius;

  const setPreviousCircleRadius = (radius) => {
    if (isEmpty(currentCircle)) {
      const lastCircle = circles[circles.length - 1];
      if (lastCircle) {
        setCircles((prevCircles) => [
          ...prevCircles.slice(0, -1),
          { ...lastCircle, radius },
        ]);
      }
    } else {
      setCurrentCircle({ ...currentCircle, radius });
    }
  };

  return {
    currentShape: currentCircle,
    shapes: circles,
    setShapes: setCircles,
    handleClick,
    handleMouseMove,
    clearCurrent,
    clear,
    undo,
    icon: circleIcon,
    sideComponent: mode === name && (
      <GrayBox className="p-2 rounded-none">
        <PrettyTextInput
          name="Radius"
          value={previousCircleRadius || 0}
          setValue={setPreviousCircleRadius}
          maxDecimals={2}
        />
      </GrayBox>
    ),
    type: "circle", // tells ROIShapes to render as a circle
    name,
  };
};
