import { useState } from "react";
import { SectionHeader } from "./SectionHeader";
import { SecondaryButton } from "./SecondaryButton";
import UplotReact from "./UplotReact";
import { CircularProgress } from "@mui/material";
import "./Plots.css";

export const Plots = ({
  data,
  names,
  header,
  isAutoPlotting,
  fetchData,
  ...props
}) => {
  const palette = [
    "#1F78C1", // 5: ocean
    "#7EB26D", // 0: pale green
    "#EAB839", // 1: mustard
    "#6ED0E0", // 2: light blue
    "#EF843C", // 3: orange
    "#E24D42", // 4: red
    "#BA43A9", // 6: purple
    "#705DA0", // 7: violet
    "#508642", // 8: dark green
    "#CCA300", // 9: dark sand
  ];

  // const series = [
  //   {
  //     label: "Time (s)",
  //   },
  // ];
  // for (let i = 0; i < names.length; i++) {
  //   console.log("names[i]", names[i]);
  //   series.push({
  //     label: names[i],
  //     width: 2 / devicePixelRatio,
  //     lineInterpolation: 3,
  //     points: { show: false },
  //     stroke: palette[i % palette.length],
  //     fill: palette[i % palette.length] + "1A",
  //   });
  // }

  let series = [
    {
      label: "Time (s)",
    },
  ];

  // Track combined data and their corresponding names
  let combinedDataMap = new Map();
  let processedNames = new Set();

  // Iterate through all names
  names.forEach((name, index) => {
    if (!processedNames.has(name)) {
      // First encounter of the name
      processedNames.add(name);
      combinedDataMap.set(name, [...data[index + 1]]); // Initialize with the current data
      series.push({
        label: name,
        width: 2 / window.devicePixelRatio,
        lineInterpolation: 3,
        points: { show: false },
        stroke: palette[index % palette.length],
        fill: `${palette[index % palette.length]}1A`,
      });
    } else {
      // Duplicate name encountered, combine with existing data
      let existingData = combinedDataMap.get(name);
      let currentData = data[index + 1];

      if (existingData && currentData) {
        combinedDataMap.set(
          name,
          existingData.map((value, i) => value * currentData[i])
        );
      }
    }
  });

  // Convert combinedDataMap to an array format suitable for plotting
  let combinedDataArray = [data[0]]; // Initialize with the time data
  combinedDataMap.forEach((combinedData) => {
    combinedDataArray.push(combinedData);
  });

  // Check if combined data is available for plotting
  const isData =
    combinedDataArray &&
    combinedDataArray[1] &&
    combinedDataArray[1].length > 0;

  const [isPlotting, setIsPlotting] = useState(false);

  return (
    <div {...props}>
      <SectionHeader>
        {header || "Plots"}
        {isAutoPlotting == false &&
          (!isPlotting ? (
            <SecondaryButton
              onClick={() => {
                setIsPlotting(true);
                fetchData().then(() => setIsPlotting(false));
              }}
              className="float-right"
            >
              Plot
            </SecondaryButton>
          ) : (
            <SecondaryButton disabled className="float-right">
              {/* Spinner */}
              <CircularProgress size={20} className="text-white" />
            </SecondaryButton>
          ))}
      </SectionHeader>
      {!isData && (
        <div
          className="text-center h-[300px] flex items-center justify-center"
          style={{ background: "#141619" }}
        >
          No data to plot
        </div>
      )}
      {isData && (
        <UplotReact
          data={combinedDataArray}
          style={{
            background: "#141619",
            color: "#c7d0d9",
            paddingLeft: "20px",
            paddingRight: "20px",
          }}
          options={{
            title: null,
            height: 300,
            cursor: {
              points: {
                size: (u, seriesIdx) => {},
                width: (u, seriesIdx, size) => {},
                stroke: (u, seriesIdx) => {},
                fill: (u, seriesIdx) => {},
              },
              sync: {
                key: 0,
              },
            },
            axes: [
              {
                stroke: "#c7d0d9",
                grid: {
                  width: 1 / devicePixelRatio,
                  stroke: "#2c323599",
                },
                ticks: {
                  width: 1 / devicePixelRatio,
                  stroke: "#2c323599",
                },
              },
              {
                stroke: "#c7d0d9",
                grid: {
                  width: 1 / devicePixelRatio,
                  stroke: "#2c323599",
                },
                ticks: {
                  width: 1 / devicePixelRatio,
                  stroke: "#2c323599",
                },
              },
            ],
            series: series,
            scales: { x: { time: false } },
          }}
        />
      )}
    </div>
  );
};
