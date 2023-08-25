import React, { useState, useEffect } from "react";
import {
  applyLaserMode,
  applyLaserPower,
  getLasersInfo,
  toggleLaser,
} from "../matlabComms/laserComms";
import Menu from "../components/Menu";
import { SliderWithText } from "../components/SliderWithText";
import { Toggle } from "../components/Toggle";
import { GrayBox } from "../components/GrayBox";
import { WavelengthCircle } from "../components/WavelengthCircle";
import { NoDataFound } from "../components/NoDataFound";

const Lasers = () => {
  const [lasers, setLasers] = useState([
    // {
    //   id: 1,
    //   name: "670",
    //   on: false,
    //   mode: "CWP",
    //   modeOptions: ["CWP", "Pulse", "CW", "Pulsed"],
    //   power: 10,
    //   maxPower: 100,
    // },
    // {
    //   id: 2,
    //   name: "470",
    //   on: false,
    //   mode: "CWP",
    //   modeOptions: ["CWP", "Pulse", "CW", "Pulsed"],
    //   power: 10,
    //   maxPower: 100,
    // },
  ]);

  const setProperty = (id, property, value) => {
    setLasers((lasers) =>
      lasers.map((laser) => {
        if (laser.id === id) {
          return {
            ...laser,
            [property]: value,
          };
        }
        return laser;
      })
    );
  };

  useEffect(() => {
    // get laser info on startup
    const fetchData = async () => {
      const lasersInfo = await getLasersInfo();
      if (lasersInfo.length) setLasers(lasersInfo);
    };
    fetchData();
  }, []);
  if (lasers.length == 0)
    return (
      // center text in the middle in a box
      <NoDataFound />
    );

  return (
    <div className="flex flex-col gap-4">
      {lasers.map((laser, idx) => (
        <GrayBox key={idx}>
          <div
            className="flex flex-row gap-12 w-fit  items-center
          "
            key={idx}
          >
            <div className="flex flex-row gap-4 text-gray-100 text-base">
              <WavelengthCircle textContainingWavelength={laser.name} />
              <span className={"font-semibold"}>{`Laser ${laser.name}`}</span>
            </div>
            <Toggle
              enabled={laser.on}
              setEnabled={(value) => {
                setProperty(laser.id, "on", value); // set the state in javascript
                toggleLaser(value, laser.name); // send the state to matlab
              }}
            />
            <Menu
              items={laser.modeOptions}
              setSelected={(value) => {
                setProperty(laser.id, "mode", value);
                applyLaserMode(value, laser.name);
              }}
              selected={laser.mode}
              type={"vertical"}
            />
            <SliderWithText
              value={laser.power}
              setValue={(value) => {
                setProperty(laser.id, "power", value);
                applyLaserPower(value, laser.name);
              }}
              minVal={0}
              maxVal={laser.maxPower}
              units="mW"
            />
          </div>
        </GrayBox>
      ))}
    </div>
  );
};

export default Lasers;
