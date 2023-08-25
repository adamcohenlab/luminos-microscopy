import { twMerge } from "tailwind-merge";

export const HoverableButton = ({ children, className, ...props }) => (
  <button
    className={twMerge(
      "hover:text-gray-300 hover:bg-gray-600 p-1 rounded-full text-center",
      className
    )}
    {...props}
  >
    {children}
  </button>
);
