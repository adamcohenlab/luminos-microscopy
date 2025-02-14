import { useState, useEffect, useRef } from "react";
import { computeRadius } from "../../../utils/computeRadius";
import { useDrawingControls } from "../DrawingControlsContext";
import { GrayBox } from "../../GrayBox";
import { isEmpty } from "lodash";
import { PrettyTextInput } from "../../PrettyTextInput";
import { getFactors } from "../../../tabs/DMD";
import { getDistanceFactor } from "../../../tabs/Main/Objectives";

export const useCircleMode = ({
  handleCompletedCircle = (newCircle) => {},
  maxShapes = Infinity,
  name = "circle",
  dmdDeviceName,
} = {}) => {
  const [currentCircle, setCurrentCircle] = useState({});
  const [circles, setCircles] = useState([]);
  const { mode, pushLastMode, imgHeight } = useDrawingControls();
  const [unit, setUnit] = useState("Screen px");
  const [factor, setFactor] = useState(1);
  const lastClickTimeRef = useRef(0);
  const doubleClickThreshold = 250; // milliseconds between clicks to register as a double click
  //console.log("dmdDeviceName: ", dmdDeviceName);
  useEffect(() => {
    const updateFactors = async (dmdDeviceName) => {
      const { cameraFactor, dmdFactor } = await getFactors({ dmdDeviceName }); // Fetch factors
      const distanceFactor = getDistanceFactor();
      switch (unit) {
        case "Screen px":
          setFactor(1);
          break;
        case "Microns":
          setFactor(cameraFactor * distanceFactor * 6.5);
          // Temporarily just multiply by 6.5um. Ideally should import cam.microns_per_pixel. - DI 7/24
          break;
        case "Camera px":
          setFactor(cameraFactor);
          //console.log('Camera px factor: ', cameraFactor);
          break;
        case "DMD px":
          setFactor(dmdFactor);
          //console.log('DMD px factor: ', dmdFactor);
          break;
        default:
          setFactor(1);
      }
    };

    updateFactors(dmdDeviceName);
  }, [unit]);

  const finishCircle = (newCircle) => {
    handleCompletedCircle({
      centerx: newCircle.center[0],
      centery: newCircle.center[1],
      radius: newCircle.radius,
      imgHeight,
    });

    // Limit to maxShapes
    setCircles((prevCircles) => [
      ...prevCircles.slice(0, maxShapes - 1),
      newCircle,
    ]);
    clearCurrent();
    pushLastMode(name);
  };

  const handleClick = (x, y) => {
    const currentTime = Date.now();
    const timeSinceLastClick = currentTime - lastClickTimeRef.current;

    if (timeSinceLastClick < doubleClickThreshold) {
      // Double click detected
      const defaultRadius = 10;
      const previousRadius =
        circles.length > 0 ? circles[circles.length - 1].radius : defaultRadius;
      const newCircle = {
        center: currentCircle.center || [x, y], // If no center set, use current click position
        radius: previousRadius,
      };
      finishCircle(newCircle);
    } else {
      if (currentCircle.center) {
        // If the center has been set, then set the radius
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
        // If the center has not been set, then set the center
        setCurrentCircle({ center: [x, y] });
      }
    }

    lastClickTimeRef.current = currentTime;
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
          { ...lastCircle, radius: radius / factor }, // Adjust the radius according to the current factor
        ]);
      }
    } else {
      setCurrentCircle({
        ...currentCircle,
        radius: radius / factor, // Adjust the radius according to the current factor
      });
    }
  };

  const handleUnitChange = (event) => {
    setUnit(event.target.value);
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
      <GrayBox className="p-5 rounded-none">
        <PrettyTextInput
          name="Radius"
          value={previousCircleRadius ? previousCircleRadius * factor : 0}
          setValue={(val) => setPreviousCircleRadius(val)}
          maxDecimals={2}
        />
        <div className="mt-3">
          {/* <label>Unit:</label> */}
          <div className="flex flex-col space-y-2">
            <div className="flex items-center">
              <input
                type="radio"
                value="Screen px"
                checked={unit.trim() === "Screen px"}
                onChange={handleUnitChange}
                className="mr-2"
              />
              <PrettyTextInput
                name="Screen pixel"
                value=""
                setValue={() => {}}
                readOnly={true}
              />
            </div>
            <div className="flex items-center">
              <input
                type="radio"
                value="Microns"
                checked={unit.trim() === "Microns"}
                onChange={handleUnitChange}
                className="mr-2"
              />
              <PrettyTextInput
                name="Microns"
                value=""
                setValue={() => {}}
                readOnly={true}
              />
            </div>
            <div className="flex items-center">
              <input
                type="radio"
                value="Camera px"
                checked={unit.trim() === "Camera px"}
                onChange={handleUnitChange}
                className="mr-2"
              />
              <PrettyTextInput
                name="Camera pixel"
                value=""
                setValue={() => {}}
                readOnly={true}
              />
            </div>
            <div className="flex items-center">
              <input
                type="radio"
                value="DMD px"
                checked={unit.trim() === "DMD px"}
                onChange={handleUnitChange}
                className="mr-2"
              />
              <PrettyTextInput
                name="DMD pixel"
                value=""
                setValue={() => {}}
                readOnly={true}
              />
            </div>
          </div>
        </div>
      </GrayBox>
    ),
    type: "circle",
    name,
  };
};
