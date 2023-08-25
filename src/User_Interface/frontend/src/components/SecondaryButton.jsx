import React from "react";

export const SecondaryButton = ({ children, disabled = false, ...props }) => (
  <span {...props}>
    <button
      type="button"
      className={`inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded-lg shadow-sm  ${
        disabled
          ? "bg-gray-400/50 text-gray-400 cursor-not-allowed"
          : "bg-gray-400/50 hover:bg-gray-500/50 text-white"
      }`}
      disabled={disabled}
    >
      {children}
    </button>
  </span>
);
