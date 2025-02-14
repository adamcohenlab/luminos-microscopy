import { StopIcon } from "@heroicons/react/24/outline";

export const useFovMode = ({
  handleButtonClick = (prevIsSelected) => {},
  name = "FOV",
} = {}) => {
  return {
    handleButtonClick: (prevIsSelected) => handleButtonClick(prevIsSelected),
    icon: <StopIcon className="h-6 w-6" />,
    title: "Pass all light for current field of view",
    type: "FOV",
    name,
  };
};
