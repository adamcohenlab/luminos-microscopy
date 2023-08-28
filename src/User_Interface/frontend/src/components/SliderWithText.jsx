import React from "react";
import Slider from "@mui/material/Slider";
import { TextInput } from "./TextInput";
import { keepNDecimals } from "./Utils";

export const SliderWithText = ({
  minVal = 0,
  maxVal = 1,
  children,
  value,
  setValue,
  units = null,
  textInputWidth = "",
  ...props
}) => {
  // slider value is between 0 and 100, but matlab value is between minVal and maxVal
  const valueToUnscaledValue = (value) =>
    ((value - minVal) / (maxVal - minVal)) * 100;
  const unscaledValueToValue = (unscaledValue) =>
    (unscaledValue / 100) * (maxVal - minVal) + minVal;

  const handleSliderChange = (event, newValue) => {
    setValue(keepNDecimals(unscaledValueToValue(newValue), 4));
  };

  const handleInputChange = (inputVal) => {
    let val = "";
    if (Number(inputVal) > maxVal) {
      val = maxVal;
    } else if (Number(inputVal) < minVal) {
      val = minVal;
    } else {
      val = inputVal;
    }
    setValue(val);
  };

  return (
    <div {...props}>
      <div className="">
        <div className="flex flex-row gap-6">
          <label
            htmlFor={`slider-${props.key}`}
            className={
              "block textSize font-semibold text-gray-100 w-fit whitespace-nowrap my-auto"
            }
          >
            {children}
          </label>
          <Slider
            value={valueToUnscaledValue(value)}
            onChange={handleSliderChange}
            size="small"
            name={`slider-${props.key}`}
            style={{
              margin: "auto",
            }}
            sx={{
              color: "rgb(209 213 219)", // TODO change mark color
            }}
          />
          <TextInput
            value={value}
            setValue={handleInputChange}
            units={units}
            defaultVal={0}
            className={textInputWidth}
          />
        </div>
      </div>
    </div>
  );
};
