import React from "react";
import { twMerge } from "tailwind-merge";

export const Button = ({ children, className = "", onClick, ...props }) => (
  <span {...props}>
    <button
      type="button"
      className={twMerge(
        "inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded-lg shadow-sm text-white bg-indigo-600 hover:bg-indigo-700",
        className
      )}
      onClick={onClick}
    >
      {children}
    </button>
  </span>
);
