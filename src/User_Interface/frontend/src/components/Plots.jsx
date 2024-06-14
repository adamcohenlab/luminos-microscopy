import { SectionHeader } from "./SectionHeader";
import { SecondaryButton } from "./SecondaryButton";
import UplotReact from "./UplotReact";
import "./Plots.css";
import { useState } from "react";
import { CircularProgress } from "@mui/material";

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

  let series = [{
    label: "Time (s)",
  }];

  const combineWaveforms = (indices) => {
    // Ensure indices array is correctly offset to match data array structure
    const waveformIndices = indices.map(index => index + 1);
    return waveformIndices.slice(1).reduce((combined, currentIndex) => {
      const currentWaveform = data[currentIndex];
      return combined.map((value, i) => value * currentWaveform[i]);
    }, [...data[waveformIndices[0]]]); // Use a copy of the first waveform as the starting point
  };

  // Identify duplicates and their indices
  let nameIndices = {};
  names.forEach((name, index) => {
    if (!nameIndices.hasOwnProperty(name)) {
      nameIndices[name] = [index];
    } else {
      nameIndices[name].push(index);
    }
  });

  // Process each name, combine waveforms if necessary
  Object.entries(nameIndices).forEach(([name, indices]) => {
    if (indices.length === 1) {
      // Only one waveform, no combination needed
      let i = indices[0];
      series.push({
        label: names[i],
        width: 2 / window.devicePixelRatio,
        lineInterpolation: 3,
        points: { show: false },
        stroke: palette[i % palette.length],
        fill: `${palette[i % palette.length]}1A`,
      });
    } else {
      // Multiple waveforms, combine them
      let combinedData = combineWaveforms(indices);
      // Replace the data of the first occurrence
      data[indices[0] + 1] = combinedData;
      // Update the name to reflect combination
      names[indices[0]] = `${name} (combined)`;

      series.push({
        label: names[indices[0]],
        width: 2 / window.devicePixelRatio,
        lineInterpolation: 3,
        points: { show: false },
        stroke: palette[indices[0] % palette.length],
        fill: `${palette[indices[0] % palette.length]}1A`,
      });

      // Remove the extra entries from names and data
      indices.slice(1).reverse().forEach(index => {
        names.splice(index, 1);
        data.splice(index + 1, 1);
      });
    }
  });

  const [isPlotting, setIsPlotting] = useState(false);
//  const isData = modifiedData && modifiedData[1].length > 0;

  // data is 2xn
  const isData = data && data[1].length > 0;

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
          data={data}
          style={{
            background: "#141619",
            color: "#c7d0d9",
            // marginRight: "-60px",
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
                //	font: `12px 'Roboto'`,
                //	labelFont: `12px 'Roboto'`,
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
                //	font: `12px 'Roboto'`,
                //	labelFont: `12px 'Roboto'`,
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
