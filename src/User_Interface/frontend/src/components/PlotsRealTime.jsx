import { useState, useEffect } from "react";
import { SectionHeader } from "./SectionHeader";
import UplotReact from "./UplotReact";
import "./Plots.css";

export const Plots = ({
  data, // Array of [x, y] pairs
  names,
  header,
  fetchData,
  ...props
}) => {
  const palette = [
    "#1F78C1",
    "#EAB839",
    "#7EB26D",
    "#6ED0E0",
    "#EF843C",
    "#E24D42",
    "#BA43A9",
    "#705DA0",
    "#508642",
    "#CCA300",
  ];

  // Update plot key when data length changes
  const [plotKey, setPlotKey] = useState(0);
  useEffect(() => {
    setPlotKey((prevKey) => prevKey + 1); // Increment key to reset on data size change
  }, [data.length]);

  const isDataAvailable = data.some(
    ([x, y]) =>
      Array.isArray(x) && x.length > 0 && Array.isArray(y) && y.length > 0
  );

  return (
    <div {...props}>
      <SectionHeader>{header || "Plots"}</SectionHeader>
      {!isDataAvailable && (
        <div
          className="text-center h-[300px] flex items-center justify-center"
          style={{ background: "#141619" }}
        >
          No data to plot
        </div>
      )}
      {isDataAvailable &&
        data.map(([xArray, yArray], index) => (
          <div key={`${plotKey}-${index}`} style={{ marginBottom: "20px" }}>
            <UplotReact
              data={[xArray, yArray]}
              style={{
                background: "#141619",
                color: "#c7d0d9",
                paddingLeft: "20px",
                paddingRight: "20px",
                paddingTop: "20px",
                paddingBottom: "20px",
              }}
              options={{
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
                series: [
                  { label: "Time (s)" }, // X-axis label
                  {
                    label: names[index], // Y-axis label from the names array
                    width: 2 / window.devicePixelRatio,
                    lineInterpolation: 3,
                    points: { show: false },
                    stroke: palette[index % palette.length],
                    fill: `${palette[index % palette.length]}1A`,
                  },
                ],
                scales: { x: { time: false } },
              }}
            />
          </div>
        ))}
    </div>
  );
};
