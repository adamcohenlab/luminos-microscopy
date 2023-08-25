import { Fragment } from "react";
import { Listbox, Transition } from "@headlessui/react";
import { CheckIcon } from "@heroicons/react/20/solid";
import { ChevronDownIcon } from "@heroicons/react/24/outline";
import { twJoin } from "tailwind-merge";
import { prettyName } from "./Utils";
import { WavelengthCircle } from "./WavelengthCircle";

function classNames(...classes) {
  return classes.filter(Boolean).join(" ");
}

export default function Menu({
  items,
  heading,
  setSelected,
  selected,
  type = "horizontal", // type of the general settings section
  classNameButton = "",
  showWavelengthCircle = false,
  ...props
}) {
  return (
    <div {...props}>
      <Listbox value={selected} onChange={setSelected}>
        {({ open }) => (
          <div
            className={`flex ${
              type == "horizontal"
                ? "flex-col"
                : "flex-row gap-4 justify-between"
            }`}
          >
            {heading && (
              <Listbox.Label
                className={`block text-xs font-medium text-gray-100 ${
                  type == "horizontal" ? "mb-1" : "my-auto"
                }`}
              >
                {prettyName(heading)}
              </Listbox.Label>
            )}
            <div className="relative mt-1">
              <Listbox.Button
                type="button"
                className={twJoin(
                  "hover:bg-gray-600 w-44 relative text-gray-100 rounded-md bg-gray-700 bg-opacity-75 py-2 pl-3 pr-10 text-left shadow-sm focus:outline-none text-xs",
                  classNameButton
                )}
              >
                <span className="truncate flex flex-row gap-2">
                  {showWavelengthCircle && (
                    <WavelengthCircle textContainingWavelength={selected} />
                  )}
                  {selected}
                </span>
                <span className="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-2">
                  <ChevronDownIcon className="h-3 w-3" aria-hidden="true" />
                </span>
              </Listbox.Button>

              <Transition
                show={open}
                as={Fragment}
                leave="transition ease-in duration-100"
                leaveFrom="opacity-100"
                leaveTo="opacity-0"
              >
                <Listbox.Options className="absolute w-44 z-10 mt-1 max-h-60 overflow-auto rounded-md bg-gray-700 py-1 shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none text-xs">
                  {items.map((item, idx) => (
                    <Listbox.Option
                      key={idx}
                      className={({ active }) =>
                        classNames(
                          active ? "text-white bg-gray-600" : "text-gray-200",
                          "relative cursor-pointer select-none py-2 pl-3 pr-6 text-xs"
                        )
                      }
                      value={item}
                      title={item}
                    >
                      {({ selected, active }) => (
                        <>
                          <span
                            className={classNames(
                              selected ? "font-bold" : "font-normal",
                              "flex truncate flex-row gap-2"
                            )}
                          >
                            {showWavelengthCircle && (
                              <WavelengthCircle
                                textContainingWavelength={item}
                              />
                            )}
                            {item}
                          </span>

                          {selected ? (
                            <span
                              className={classNames(
                                active ? "text-white" : "text-gray-200",
                                "absolute inset-y-0 right-0 flex items-center pr-2"
                              )}
                            >
                              <CheckIcon
                                className="h-4 w-4"
                                aria-hidden="true"
                              />
                            </span>
                          ) : null}
                        </>
                      )}
                    </Listbox.Option>
                  ))}
                </Listbox.Options>
              </Transition>
            </div>
          </div>
        )}
      </Listbox>
    </div>
  );
}
