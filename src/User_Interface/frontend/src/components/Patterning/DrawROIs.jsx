import React from "react";
import { useEffect } from "react";
import styled from "styled-components";
import { useDrawingControls } from "./DrawingControlsContext";
import { DrawSettings } from "./DrawSettings";

import { isEmpty } from "lodash";
import { useZoomMode } from "./PatterningModes/useZoomMode";
import { useSnapMode } from "./PatterningModes/useSnapMode";

const imgServerURL = "http://localhost:3011";

export const imgSrc = (imgName) => `${imgServerURL}/${imgName}`;

export const DrawROIs = ({ deviceType, deviceName, allModes, ...props }) => {
  const { setMode, lastMode, popLastMode, clearLastMode } =
    useDrawingControls();

  const undo = () => {
    // undo last shape drawn
    if (lastMode) {
      allModes.find((mode) => mode.name === lastMode).undo?.();
      popLastMode();
    }
  };

  const clear = (resetMode = true) => {
    // clear all shapes drawn
    allModes.forEach((mode) => mode.clear?.());

    if (resetMode) {
      setMode("");
    }
    clearLastMode();
  };

  const handleEsc = () => {
    // If the user presses the escape key, clear the current shape
    allModes.forEach((mode) => mode.clearCurrent?.());
    setMode("");
  };

  // add default modes
  const zoomMode = useZoomMode();
  const snapMode = useSnapMode({ snap: () => console.log("hi") });
  allModes = [snapMode, ...allModes, zoomMode];

  return (
    <>
      <DrawSettings
        clear={clear}
        undo={undo}
        deviceType={deviceType}
        deviceName={deviceName}
        allModes={allModes}
      >
        <ROIDrawer handleEsc={handleEsc} allModes={allModes} {...props} />
      </DrawSettings>
    </>
  );
};

const ROIDrawer = ({ allModes, handleEsc, ...props }) => {
  /*
    This component uses the points state variable to store the shape.
    The handleClick and handleDoubleClick functions are used to capture the user's clicks on the image and add new points to the polygon.
    When the points array is not empty, the component renders an SVG element with the points specified.
    This will fade in the shape on the image as the user clicks on it. 
  */

  const { mode, isDrawing, imgHeight, imgWidth, setImgWidth, imgSelected } =
    useDrawingControls();

  const zoomedCoordinatesToImageCoordinates = (x, y) => {
    const zoomMode = allModes.find((m) => m.type === "zoom");
    const zoomRectangle = zoomMode?.zoomRectangle; // zoomRectangle is in image coordinates
    if (!zoomRectangle) return { x, y };

    const zoomFactor = zoomMode.zoomFactor;
    const imageX = zoomRectangle.x + x / zoomFactor;
    const imageY = zoomRectangle.y + y / zoomFactor;

    return { x: imageX, y: imageY };
  };

  const currentMode = allModes.find((m) => m.name === mode);

  const handleClick = (event) => {
    // Get the x and y coordinates of the click event relative to the image
    const x = event.nativeEvent.offsetX;
    const y = event.nativeEvent.offsetY;

    const imageCoordinates = zoomedCoordinatesToImageCoordinates(x, y);

    currentMode?.handleClick?.(imageCoordinates.x, imageCoordinates.y);
  };

  const handleMouseMove = (event) => {
    // Get the x and y coordinates of the mouse move event relative to the image
    const x = event.nativeEvent.offsetX;
    const y = event.nativeEvent.offsetY;
    const mouseDown = event.nativeEvent.buttons === 1;

    const imageCoordinates = zoomedCoordinatesToImageCoordinates(x, y);

    currentMode?.handleMouseMove?.(
      imageCoordinates.x,
      imageCoordinates.y,
      mouseDown
    );
  };

  const handleDoubleClick = (event) => {
    currentMode?.handleDoubleClick?.(event);
  };

  const handleKeyDown = (event) => {
    // check for escape key
    if (event.keyCode === 27) {
      // clear the current shape
      handleEsc();
    }
  };

  const handleMouseUp = (event) => {
    currentMode?.handleMouseUp?.(event);
  };

  useEffect(() => {
    document.addEventListener("keydown", handleKeyDown);
    return () => {
      document.removeEventListener("keydown", handleKeyDown);
    };
  }, []);

  const src = imgSrc(imgSelected);

  const getAspectRatio = (src) => {
    if (!imgSelected) return 1;
    // get natural dimensions of props.src image
    const img = new Image();
    img.src = src;
    // compute aspect ratio
    const aspectRatio = img.naturalWidth / img.naturalHeight;
    return aspectRatio || 1;
  };

  // set aspect ratio
  useEffect(() => {
    setImgWidth(imgHeight * getAspectRatio(src));
  }, [src, imgHeight]);

  const findShapesOfType = (type) =>
    allModes
      .filter((m) => m.type === type)
      .map((p) => p.shapes)
      .flat();

  const findCurrentShapeOfType = (type) =>
    allModes.find((m) => m.type === type && !isEmpty(m.currentShape))
      ?.currentShape;

  return (
    <ROIShapes
      imgSelected={imgSelected}
      src={src}
      height={imgHeight}
      width={imgWidth}
      handleClick={handleClick}
      handleMouseMove={handleMouseMove}
      handleDoubleClick={handleDoubleClick}
      polygons={[
        ...findShapesOfType("polygon"),
        ...findShapesOfType("freeform"),
        findCurrentShapeOfType("polygon"),
        findCurrentShapeOfType("freeform"),
      ]}
      isDrawing={isDrawing}
      circles={[
        ...findShapesOfType("circle"),
        findCurrentShapeOfType("circle"),
      ]}
      handleMouseUp={handleMouseUp}
      points={findShapesOfType("points")}
      rects={[
        findCurrentShapeOfType("rectangle"),
        ...findShapesOfType("rectangle"),
      ]}
      donuts={[findCurrentShapeOfType("donut"), ...findShapesOfType("donut")]}
      curve={[]}
      drawFull={mode === "full" || mode === "FOV"}
      zoomRectangle={allModes.find((m) => m.type === "zoom")?.zoomRectangle}
      zoomDrawing={findCurrentShapeOfType("zoom")}
    />
  );
};

const computeZoomTransform = (zoomRectangle, width, height) => {
  // Calculate the scale and translate values based on zoomRectangle
  let transform = "";
  if (zoomRectangle) {
    const scale = Math.min(
      width / zoomRectangle.width,
      height / zoomRectangle.height
    );
    const translateX =
      -zoomRectangle.x * scale + (width - zoomRectangle.width * scale) / 2;
    const translateY =
      -zoomRectangle.y * scale + (height - zoomRectangle.height * scale) / 2;
    transform = `translate(${translateX},${translateY}) scale(${scale})`;
  }
  return transform;
};

const ROIShapes = ({
  imgSelected,
  src,
  height,
  width,
  handleClick,
  handleMouseMove,
  handleDoubleClick,
  polygons = [],
  isDrawing,
  circles = [],
  handleMouseUp,
  points = [],
  rects = [],
  donuts = [],
  curve = [],
  drawFull = false, // pass all the light through
  zoomRectangle = null, // the area selected for zooming into
  zoomDrawing = null, // the rectangle being drawn for zooming into
  ...props
}) => {
  const zoomTransform = computeZoomTransform(zoomRectangle, width, height);

  return (
    <Svg
      height={height}
      width={width}
      onClick={handleClick}
      onMouseMove={handleMouseMove}
      onDoubleClick={handleDoubleClick}
      isDrawing={isDrawing}
      onMouseUp={handleMouseUp}
    >
      <g transform={zoomTransform}>
        {imgSelected && <image href={src} height={height} width={width} />}
        {drawFull && <Full />}
        <Polygons polygons={polygons} />
        <Circles circles={circles} />
        <Rects rects={rects} />
        <Donuts donuts={donuts} />
        <Curve curve={curve} />
        <Rect rect={zoomDrawing} blue={true} />
      </g>
    </Svg>
  );
};
//<Points points={points} />

const Full = () => (
  // make a rect that fills the full svg and is orange
  <rect width="100%" height="100%" className="fill-amber-500/50" />
);

const Curve = ({ curve }) => (
  // curve is a set of points. we draw a polyline
  <>
    {curve.length > 0 && (
      <polyline
        points={curve.map((point) => `${point[0]},${point[1]}`).join(" ")}
        className="stroke-amber-600 stroke-[4px] fill-transparent"
      />
    )}
  </>
);

const Donuts = ({ donuts }) => (
  <>
    {donuts.map((donut, i) => (
      <Donut key={i} donut={donut} />
    ))}
  </>
);

const Rects = ({ rects }) => (
  <>
    {rects.map((rect, i) => (
      <Rect key={i} rect={rect} />
    ))}
  </>
);

const Donut = ({ donut }) => (
  // donut = {center, radius1, radius2}
  // need to compute the outer radius and inner radius
  // fill the space in between the two circles and makethe inside transparent

  // make a circle with strokeWidth as abs(radius1 - radius2)

  <>
    {donut && donut.center && donut.radius1 && (
      <circle
        cx={donut.center.x}
        cy={donut.center.y}
        r={donut.radius1}
        className="fill-transparent stroke-amber-600 stroke-2"
      />
    )}
    {donut && donut.center && donut.radius2 && (
      <>
        <circle
          cx={donut.center.x}
          cy={donut.center.y}
          r={donut.radius2}
          className="fill-transparent stroke-amber-600 stroke-2"
        />
        {/* // circle with thickness of abs(radius1 - radius2) */}
        <circle
          cx={donut.center.x}
          cy={donut.center.y}
          r={(donut.radius1 + donut.radius2) / 2}
          // make stroke opacity 50%
          className="fill-transparent stroke-amber-600/50"
          strokeWidth={Math.abs(donut.radius1 - donut.radius2)}
        />
      </>
    )}
  </>
);

const Rect = ({ rect, blue = false }) => (
  <>
    {rect && rect.x && (
      <rect
        x={rect.x}
        y={rect.y}
        width={rect.width}
        height={rect.height}
        className={`${
          blue
            ? "fill-sky-500/50 stroke-sky-600"
            : "fill-amber-500/50 stroke-amber-600"
        } stroke-2`}
      />
    )}
  </>
);

const Points = ({ points }) => (
  <>
    {points.map((point, index) => (
      <circle
        key={index}
        cx={point[0]}
        cy={point[1]}
        r={3}
        className="fill-green-500 stroke-green-500/20 stroke-[10px]"
      />
    ))}
  </>
);

const Circles = ({ circles }) => (
  <>
    {circles.map(
      (circle, index) =>
        circle?.center && (
          <Circle
            key={index}
            cx={circle.center[0]}
            cy={circle.center[1]}
            r={circle.radius}
          />
        )
    )}
  </>
);

const Circle = ({ ...props }) => (
  <circle className="fill-amber-500/50 stroke-amber-600 stroke-2" {...props} />
);

const Polygons = ({ polygons }) => {
  return (
    <>
      {polygons.map(
        (polygon, index) =>
          polygon?.length > 1 && (
            <Polygon
              key={index}
              points={polygon.map((point) => point.join(",")).join(" ")}
            />
          )
      )}
    </>
  );
};

const Polygon = ({ ...props }) => (
  <polygon className="fill-amber-500/50 stroke-amber-600 stroke-2" {...props} />
);
const Svg = styled.svg`
  ${(props) =>
    props.isDrawing
      ? `&:hover {
    cursor: crosshair;
  }`
      : ""}
`;
