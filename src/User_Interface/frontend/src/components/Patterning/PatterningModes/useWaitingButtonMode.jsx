import { useState } from "react";
import { CircularProgress } from "@mui/material";
import { PlayIcon } from "@heroicons/react/20/solid";

export const useWaitingButtonMode = ({ handleButtonClick, title } = {}) => {
  const [waiting, setWaiting] = useState(false);

  // play button becomes circle progress when waiting
  const icon = waiting ? (
    <CircularProgress
      size={24}
      style={{
        color: "white",
      }}
    />
  ) : (
    <PlayIcon className="h-6 w-6" />
  );

  const handleButtonClickWrapper = (prevIsSelected, clearAllShapes) => {
    setWaiting(true);
    handleButtonClick(prevIsSelected, clearAllShapes).then((success) =>
      setWaiting(false)
    );
  };

  return {
    icon,
    handleButtonClick: handleButtonClickWrapper,
    name: "button",
    title,
  };
};
