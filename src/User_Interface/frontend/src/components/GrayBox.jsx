import React from "react";
import { twMerge } from "tailwind-merge";

export const GrayBox = ({ children, className, ...props }) => {
  return (
    <div
      className={twMerge(`bg-gray-800 bg-opacity-75 p-4 rounded-md`, className)}
    >
      {children}
    </div>
  );
};
