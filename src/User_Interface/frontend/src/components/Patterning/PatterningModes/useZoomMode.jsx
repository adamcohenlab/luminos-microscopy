import {
  MagnifyingGlassMinusIcon,
  MagnifyingGlassPlusIcon,
} from "@heroicons/react/24/outline";
import { useRectangleMode } from "./useRectangleMode";
import { HoverableButton } from "../../HoverableButton";
import { useDrawingControls } from "../DrawingControlsContext";
import { useEffect } from "react";

export const useZoomMode = () => {
  const { imgHeight, imgWidth, setMode } = useDrawingControls();
  const zoomMode = useRectangleMode({
    maxShapes: 1,
    name: "zoom",
    fixedAspectRatio: imgWidth / imgHeight,
    useUndo: false,
  });

  const zoomRectangle = zoomMode.shapes[0];
  const isZoomedIn = zoomRectangle !== undefined;
  const zoomFactor = isZoomedIn
    ? Math.min(imgWidth / zoomRectangle.width, imgHeight / zoomRectangle.height)
    : 1;

  // leave zoom mode after the user selected the zoom rectangle
  useEffect(() => {
    if (zoomRectangle) setMode("");
  }, [zoomRectangle]);

  return {
    ...zoomMode, // this means copy all the properties from zoomMode
    type: "zoom",
    clear: () => {}, // overwrite the clear function from the rectangle mode
    undo: () => {},
    icon: <MagnifyingGlassPlusIcon className="h-6 w-6" />,
    zoomRectangle,
    zoomFactor,
    sideComponent: (
      <>
        {isZoomedIn && (
          <div className="flex items-center space-x-2">
            <ZoomOutButton onClick={zoomMode.clear} title="Zoom out" />
            <div>{zoomFactor.toFixed(2)} x</div>
          </div>
        )}
      </>
    ),
  };
};

const ZoomOutButton = ({ onClick }) => (
  <HoverableButton
    className="bg-gray-700/50 rounded-full p-2"
    onClick={onClick}
  >
    <MagnifyingGlassMinusIcon className="h-5 w-5" />
  </HoverableButton>
);
