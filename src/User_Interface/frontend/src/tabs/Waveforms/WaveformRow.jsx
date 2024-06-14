/*Implements waveform rows within each Waveform section. Each row covers a different channel.*/ 
import Menu from "../../components/Menu";
import {
  ChevronDownIcon,
  ChevronRightIcon,
  MinusCircleIcon,
} from "@heroicons/react/20/solid";
import { useState } from "react";
import {
  addValue,
  capitalize,
  portToChannelName,
} from "../../components/Utils";
import { GrayBox } from "../../components/GrayBox";
import { TextInput } from "../../components/TextInput";

const WaveformOptions = ({ args, setOptions, ...props }) => {
  const [open, setOpen] = useState(false);

  const setArg = (argName, value) => {
    // find index of argName in args
    const argIdx = args.findIndex((arg) => arg.name === argName);

    // make a copy of args
    const newArgs = [...args];

    // set the value of the arg
    newArgs[argIdx] = { ...newArgs[argIdx], value: value };

    // set the args
    setOptions(newArgs);
  };

  return (
    <div {...props}>
      <div className="flex flex-row">
        <div className="pr-1">
          <button type="button" onClick={() => setOpen(!open)}>
            {open ? (
              <ChevronDownIcon className="h-5 w-5 text-gray-100" />
            ) : (
              <ChevronRightIcon className="h-5 w-5 text-gray-100" />
            )}
          </button>
        </div>
        <div>
          <div className="text-xs font-bold text-gray-100 pb-3">
            <button
              type="button"
              onClick={(e) => {
                e.preventDefault();
                setOpen(!open);
              }}
            >
              Waveform Options
            </button>
          </div>
          {open && (
            <div className="grid grid-cols-5 gap-4 mb-2 max-w-xl">
              {args.map(({ name, defaultVal, units, value }, idx) => (
                <TextInput
                  name={capitalize(name).replace("_", " ")}
                  defaultVal={defaultVal}
                  units={units}
                  key={idx}
                  value={value}
                  setValue={(value) => setArg(name, value)}
                />
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export function WaveformRow({
  waveform,
  deleteWaveform,
  setProperties,
  options,
  cannotChange,
  ...props
}) {
  return (
    <div {...props}>
      <GrayBox className={`${cannotChange && "pointer-events-none"}`}>
        <div className="flex flex-row">
          {!cannotChange && (
            <div className="w-12 shrink-0 align-middle">
              <button type="button" onClick={deleteWaveform}>
                <MinusCircleIcon className="h-6 w-6 text-slate-400 hover:text-slate-500 ml-1 mt-5" />
              </button>
            </div>
          )}
          <div className={`grow ${cannotChange && "opacity-80"}`}>
            <div className="flex flex-row gap-4">
              <Menu
                items={cannotChange ? [waveform.port] : options.ports}
                heading="Port"
                className="basis-36"
                setSelected={(value) => setProperties({ port: value })}
                selected={waveform.port}
                showWavelengthCircle={true}
              />
              <TextInput
                name="Channel Name"
                defaultVal={portToChannelName(waveform.port)}
                value={waveform.name}
                setValue={(value) => setProperties({ name: value })}
              />
              {waveform.fcn && (
                <Menu
                  items={options.fcns.map((f) => f.name)}
                  heading="Waveform"
                  className="grow"
                  setSelected={(value) => {
                    setProperties({
                      fcn: value,
                      fcn_args: addValue(
                        options.fcns.find((f) => f.name === value).args
                      ),
                    });
                  }}
                  selected={waveform.fcn}
                />
              )}
            </div>
            {options.fcns && (
              <WaveformOptions
                args={waveform.fcn_args}
                setOptions={(value) => setProperties({ fcn_args: value })}
                className="mt-6"
              />
            )}
          </div>
        </div>
      </GrayBox>
    </div>
  );
}
