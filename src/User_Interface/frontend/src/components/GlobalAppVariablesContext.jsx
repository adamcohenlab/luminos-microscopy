import { createContext, useContext, useState } from "react";
import { useWaveformControls } from "../tabs/Waveforms/hooks/useWaveformControls";

// Create a context for the mode.
const AppContext = createContext();

// Create a provider for the mode.
export const GlobalAppVariablesProvider = ({ children }) => {
  // variables that are shared between all tabs

  const waveformControls = useWaveformControls();
  const [experimentName, setExperimentName] = useState("");
  const [isMatlabOnline, setIsMatlabOnline] = useState(true);

  return (
    <AppContext.Provider
      value={{
        experimentName,
        setExperimentName,
        waveformControls,
        isMatlabOnline,
        setIsMatlabOnline,
      }}
    >
      {children}
    </AppContext.Provider>
  );
};

// Create a custom hook to use the mode context.
export const useGlobalAppVariables = () => {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error(`useDrawingControls must be used within a ModeProvider`);
  }
  return context;
};
