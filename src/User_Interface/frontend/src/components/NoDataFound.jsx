import React from "react";

export const NoDataFound = () => (
  <div className="flex flex-col items-center justify-center h-full p-8 bg-gray-800 rounded-md">
    <div className="text-xl font-semibold text-red-500">No data found.</div>
    <div className="text-base text-gray-300">
      Check the browser console for errors.
    </div>
  </div>
);
