import React from "react";
import { getWavelength } from "./Utils";

export const WavelengthCircle = ({ textContainingWavelength }) => {
  const wavelength = getWavelength(textContainingWavelength);
  if (!wavelength) return <></>;
  const wavelengthToStyle = {
    435: ["bg-purple-600", "border-purple-600"],
    500: ["bg-blue-600", "border-blue-600"],
    520: ["bg-sky-600", "border-sky-600"],
    565: ["bg-green-600", "border-green-600"],
    600: ["bg-yellow-600", "border-yellow-600"],
    Infinity: ["bg-red-600", "border-red-600"],
  };
  // ^ would ideally avoid the array, but tailwind doesn't let you construct class names dynamically
  // see https://tailwindcss.com/docs/content-configuration#dynamic-class-names
  let styleList;
  for (let [key, value] of Object.entries(wavelengthToStyle)) {
    if (wavelength < key) {
      styleList = value;
      break;
    }
  }

  return <Circle styleList={styleList} />;
};
const Circle = ({ styleList }) => (
  // make circle filled in with wavelength color
  <div
    className={`w-3 h-3 my-auto rounded-full border ${styleList.join(" ")}`}
  ></div>
);
