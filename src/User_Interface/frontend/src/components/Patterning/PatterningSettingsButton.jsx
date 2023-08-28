import React from "react";
import { capitalize } from "../Utils";
import { useDrawingControls } from "./DrawingControlsContext";
import { twMerge } from "tailwind-merge";

export const PatterningSettingsButton = ({
  children,
  buttonMode = null,
  handleOnClick = () => {},
  title,
  className = "",
  disabled = false,
  isSelected = undefined,
  ...props
}) => {
  const { mode, setMode } = useDrawingControls();

  // either isSelected is passed in as a prop, or isSelected is true if buttonMode is the current mode
  isSelected = isSelected || (buttonMode && buttonMode == mode);
  const standardClassName = `
    text-white font-bold py-2 px-4 rounded w-fit
    ${
      isSelected
        ? "bg-gray-500 hover:bg-gray-400"
        : "bg-gray-800 hover:bg-gray-700"
    }
    ${disabled ? "opacity-50 cursor-not-allowed" : ""}`;
  return (
    <button
      title={title ? title : buttonMode ? capitalize(buttonMode) : null}
      className={twMerge(standardClassName, className)}
      onClick={() => {
        if (disabled) return;
        handleOnClick(isSelected);
        if (buttonMode != null) {
          if (isSelected) {
            setMode("");
          } else {
            setMode(buttonMode);
          }
        }
      }}
      disabled={disabled}
      {...props}
    >
      {children}
    </button>
  );
};
