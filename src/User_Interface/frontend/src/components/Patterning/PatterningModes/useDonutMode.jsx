import { useState } from "react";
import { computeRadius } from "../../../utils/computeRadius";
import { useDrawingControls } from "../DrawingControlsContext";

export const useDonutMode = ({
  handleCompletedDonut = (donut) => {},
  name = "donut",
  maxShapes = Infinity,
} = {}) => {
  // we suppport drawing only one donut at a time for now
  const [donuts, setDonuts] = useState([]);
  const [center, setCenter] = useState(null);
  const [radius1, setRadius1] = useState(null);
  const [radius2, setRadius2] = useState(null);
  const [step, setStep] = useState(0);

  const donut = {
    center,
    radius1,
    radius2,
  };

  const { setMode, pushLastMode, imgHeight } = useDrawingControls();

  const finishDonut = () => {
    setDonuts((prevDonuts) => [...prevDonuts.slice(0, maxShapes - 1), donut]);
    pushLastMode(name);
    clearCurrent();

    // send data to matlab
    const innerRadius = Math.min(radius1, radius2);
    const outerRadius = Math.max(radius1, radius2);
    handleCompletedDonut({
      centerx: center.x,
      centery: center.y,
      innerRadius,
      outerRadius,
      imgHeight,
    });
  };

  const handleClick = (x, y) => {
    // watch for 3 clicks:
    // 0. set the center
    // 1. set the radius of the first circle
    // 2. set the radius of the second circle

    if (step === 0) {
      // if the center of the first circle has not been set, then set the center
      setCenter({ x, y });
      setStep(1);
    } else if (step === 1) {
      // if the radius of the first circle has been set, then set the radius of the second circle
      setRadius1(computeRadius(center.x, center.y, x, y));
      setStep(2);
    } else if (step === 2) {
      // if the radius of the second circle has been set, finish the donut
      setRadius2(computeRadius(center.x, center.y, x, y));
      finishDonut();
    }
  };

  const handleMouseMove = (x, y, mouseDown) => {
    if (step === 1) {
      setRadius1(computeRadius(center.x, center.y, x, y));
    } else if (step === 2) {
      // if the radius of the first circle has been set, then update the radius of the second circle
      setRadius2(computeRadius(center.x, center.y, x, y));
    }
  };

  const clear = () => {
    clearCurrent();
    setDonuts([]);
  };

  const clearCurrent = () => {
    setCenter(null);
    setRadius1(null);
    setRadius2(null);
    setStep(0);
  };

  const undo = () => {
    clear();
  };

  return {
    shapes: donuts,
    currentShape: donut,
    setShapes: setDonuts,
    handleClick,
    handleMouseMove,
    clear,
    clearCurrent,
    undo,
    icon: (
      <img
        src="/spiral_hole.svg" // https://www.flaticon.com/free-icon/celtic_4005055?term=spiral&page=1&position=2&origin=tag&related_id=4005055 (should attribute the author)
        alt="spiral"
        className="h-6 w-6"
      />
    ),
    type: "donut", // tells ROIShapes to render as a donut
    name,
  };
};
