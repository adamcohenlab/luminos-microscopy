import Menu from "./Menu";
import { capitalize, getWavelength, prettyName } from "./Utils";
import { SliderWithText } from "./SliderWithText";
import { Toggle } from "./Toggle";
import { SectionHeader } from "./SectionHeader";
import { GrayBox } from "./GrayBox";
import { WavelengthCircle } from "./WavelengthCircle";
import { TextInput } from "./TextInput";

export const GeneralSettings = ({ properties, setProperty, type }) => {
  // add idx to properties
  properties = properties.map((prop, idx) => ({ ...prop, id: idx }));
  const nonButtonProps = properties
    .filter((prop) => prop.type != "button")
    .sort(
      // sort by wavelength then by type
      (a, b) => {
        const aWavelength = getWavelength(a.name);
        const bWavelength = getWavelength(b.name);

        if (aWavelength == bWavelength) {
          return a.type > b.type ? -1 : 1;
        } else {
          return aWavelength > bWavelength ? -1 : 1;
        }
      }
    );
  const buttonProps = properties.filter((prop) => prop.type == "button");

  return (
    <div
      className={`flex ${
        type == "vertical" ? "flex-col gap-6" : "flex-row gap-4"
      }`}
    >
      {nonButtonProps.map((prop, idx) => {
        const displayName = prop.displayName || capitalize(prop.name);
        switch (prop.type) {
          case "text" || "number":
            return (
              <TextInput
                key={idx}
                name={displayName}
                defaultVal={prop.defaultVal}
                units={prop.units}
                value={prop.value}
                setValue={(value) => setProperty(prop.id, value)}
                className="w-24"
              />
            );
          case "menu":
            return (
              <Menu
                key={idx}
                items={prop.options}
                heading={displayName}
                setSelected={(value) => setProperty(prop.id, value)}
                selected={prop.value}
                type={type}
              />
            );
          case "slider":
            return (
              <SliderWithText
                key={idx}
                value={prop.value}
                setValue={(value) => setProperty(prop.id, value)}
                minVal={prop.min}
                maxVal={prop.max}
                textInputWidth="w-40"
                units={prop.units || "%"}
              >
                <div className="flex flex-row gap-1">
                  <span className={"pr-1 font-semibold"}>
                    {prettyName(prop.name)}
                  </span>
                  <WavelengthCircle textContainingWavelength={prop.name} />
                </div>
              </SliderWithText>
            );
          case "button":
            return (
              // add font weight
              <button
                key={idx}
                className="bg-gray-600 py-1 px-2 rounded-md font-semibold w-fit text-gray-100 hover:bg-gray-700 hover:text-gray-200 border border-gray-500"
              >
                {prop.name}
              </button>
            );
          case "toggle":
            return (
              <Toggle
                key={idx}
                enabled={prop.value}
                setEnabled={(value) => setProperty(prop.id, value)}
              >
                <div className="flex flex-row gap-1">
                  <span className={"pr-1 font-semibold"}>
                    {prettyName(prop.name)}
                  </span>
                  <WavelengthCircle textContainingWavelength={prop.name} />
                </div>
              </Toggle>
            );
          default:
            return <div key={idx}>Unknown type</div>;
        }
      })}
      {/* add vertical line */}
      {buttonProps.length > 0 && type == "vertical" && (
        <div className="border border-gray-500 border-x-0 border-t-0 border-b-1 w-full h-0 border-opacity-50 -my-1"></div>
      )}
      {buttonProps.map((prop, idx) => (
        <button
          key={idx}
          className="bg-gray-600 py-1 px-2 rounded-md font-semibold w-fit text-gray-100 hover:bg-gray-700 hover:text-gray-200 border border-gray-500"
        >
          {prop.name}
        </button>
      ))}
    </div>
  );
};

export const GeneralSettingsSection = ({
  properties,
  setProperty,
  title,
  type,
  children,
  ...props
}) => {
  return (
    <div {...props}>
      <SectionHeader>{title}</SectionHeader>
      <GrayBox>
        <GeneralSettings
          properties={properties}
          setProperty={setProperty}
          type={type}
        />
        {children}
      </GrayBox>
    </div>
  );
};
