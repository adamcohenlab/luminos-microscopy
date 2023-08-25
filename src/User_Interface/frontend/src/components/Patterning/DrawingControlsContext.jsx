import { createContext, useContext, useState } from "react";

// Create a context for the mode.
const DrawingControlsContext = createContext();

// Create a provider for the mode.
export const DrawingControlsProvider = ({ children, imgHeight }) => {
  const [mode, setMode] = useState("");
  const [lastModes, setLastModes] = useState([]);

  const switchMode = (newMode) => {
    setLastModes(mode);
    setMode(newMode);
  };

  const popLastMode = () => {
    setLastModes((lastMode) => lastMode.slice(0, -1));
  };

  const pushLastMode = (mode) => {
    setLastModes((lastMode) => [...lastMode, mode]);
  };

  const clearLastMode = () => {
    setLastModes([]);
  };

  const lastMode = lastModes[lastModes.length - 1];

  const [imgWidth, setImgWidth] = useState(imgHeight);
  const [imgSelected, setImgSelected] = useState("");

  return (
    <DrawingControlsContext.Provider
      value={{
        mode,
        setMode,
        lastMode,
        switchMode,
        popLastMode,
        pushLastMode,
        clearLastMode,
        isDrawing: mode !== "" && mode !== "full", // full is for passing all light through
        imgHeight,
        imgWidth,
        setImgWidth,
        imgSelected,
        setImgSelected,
      }}
    >
      {children}
    </DrawingControlsContext.Provider>
  );
};

// Create a custom hook to use the mode context.
export const useDrawingControls = () => {
  const context = useContext(DrawingControlsContext);
  if (!context) {
    throw new Error(`useDrawingControls must be used within a ModeProvider`);
  }
  return context;
};
