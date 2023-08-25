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
  isLoading = false,
  ...props
}) => {
  return (
    <div {...props}>
      <SectionHeader>{title}</SectionHeader>
      <GrayBox>
        {isLoading && <Loader />}
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

const Loader = () => (
  <div role="status" className="flex items-center justify-center">
    <svg
      aria-hidden="true"
      class="inline w-8 h-8 mr-2 text-gray-200 animate-spin dark:text-gray-600 fill-gray-600 dark:fill-gray-300"
      viewBox="0 0 100 101"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z"
        fill="currentColor"
      />
      <path
        d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z"
        fill="currentFill"
      />
    </svg>
    <span class="sr-only">Loading...</span>
  </div>
);
