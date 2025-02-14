import React from "react";
import { twMerge } from "tailwind-merge";

export const CustomGrayBox = ({ children, className, style, ...props }) => {
  return (
    <div
      style={style} // Allow inline style overrides
      className={twMerge(`bg-gray-800 bg-opacity-75 p-4 rounded-md`, className)}
      {...props}
    >
      {children}
    </div>
  );
};
