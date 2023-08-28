import React, { useEffect, useState } from "react";
import { GeneralSettingsSection } from "../../components/GeneralSettingsSection";
import { addIds, setIfEmpty } from "../../components/Utils";
import {
  getFilterWheelProperties,
  getModulatorProperties,
  getShutterProperties,
  setFilter,
  setModulator,
  setShutter,
} from "../../matlabComms/mainComms";
import { usePrevious } from "../../components/Utils";

export const GeneralToggles = ({ ...props }) => {
  const [generalSettings, setGeneralSettings] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const prevGeneralSettings = usePrevious(generalSettings);

  const changeRange = (value, min1, max1, min2, max2) =>
    // change range from [min1, max1] to [min2, max2]
    ((value - min1) * (max2 - min2)) / (max1 - min1) + min2;

  useEffect(() => {
    // fetch data from matlab
    const fetchData = async () => {
      const shuttersInfo = (await getShutterProperties(["name", "State"])).map(
        (shutter) => ({
          name: shutter.name,
          value: setIfEmpty(shutter.State, false),
          type: "toggle",
          object: "shutter",
        })
      );

      const modulatorsInfo = (
        await getModulatorProperties(["min", "max", "name", "level"])
      ).map((modulator) => ({
        name: modulator.name,
        value: modulator.level,
        min: modulator.min,
        max: modulator.max,
        type: "slider",
        object: "modulator",
        units: "V",
      }));

      const filterInfo = (
        await getFilterWheelProperties(["name", "active_filter", "filterlist"])
      ).map((filter) => ({
        name: filter.name,
        value: filter.active_filter,
        type: "menu",
        options: filter.filterlist.filter((item) => item.trim() !== "Empty"),
        object: "filter",
      }));

      const data = addIds([...shuttersInfo, ...modulatorsInfo, ...filterInfo]);

      setGeneralSettings(data);
      setIsLoading(false);
    };

    fetchData();
  }, []);

  useEffect(() => {
    // we compare the previous state with the current state to find the changed property
    if (prevGeneralSettings === undefined || prevGeneralSettings.length === 0)
      return;

    // find the changed property
    const changedProperty = generalSettings.find(
      (prop, idx) => prop.value !== prevGeneralSettings[idx].value
    );

    if (changedProperty === undefined) return;

    // send the new value to matlab
    if (changedProperty.object === "shutter") {
      setShutter(changedProperty.value, changedProperty.name);
    } else if (
      changedProperty.object === "modulator" &&
      changedProperty.value !== undefined
    ) {
      setModulator(changedProperty.value, changedProperty.name);
    } else if (changedProperty.object === "filter") {
      setFilter(changedProperty.value, changedProperty.name);
    }
  }, [generalSettings]);

  return (
    <div {...props}>
      <div className="max-w-sm">
        <GeneralSettingsSection
          isLoading={isLoading}
          title="Toggles & Modulators"
          type="vertical"
          properties={generalSettings}
          setProperty={(id, value) => {
            // update the property in the list of properties with matching id
            setGeneralSettings((oldProperties) =>
              oldProperties.map((prop) =>
                prop.id === id ? { ...prop, value } : prop
              )
            );
          }}
        />
      </div>
    </div>
  );
};
