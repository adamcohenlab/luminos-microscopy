import { SunIcon } from "@heroicons/react/24/outline";

export const useFullMode = ({
  handleButtonClick = (prevIsSelected) => {},
  name = "full",
} = {}) => {
  return {
    handleButtonClick: (prevIsSelected) => handleButtonClick(prevIsSelected),
    icon: <SunIcon className="h-6 w-6" />,
    title: "Pass all light through",
    type: "full",
    name,
  };
};
