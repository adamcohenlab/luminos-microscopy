import React from "react";
import { Switch } from "@headlessui/react";

export const Toggle = ({ children, enabled, setEnabled, ...props }) => {
  return (
    <div {...props}>
      <Switch.Group>
        {/* align the switch to the right of the text */}
        <div className="flex justify-between">
          <Switch.Label
            className={`cursor-pointer font-medium ml-0 text-gray-100 m-y-auto ${
              children ? "" : "w-0"
            }`}
          >
            {children}
          </Switch.Label>
          <Switch
            checked={enabled}
            onChange={(x) => {
              setEnabled(x);
            }}
            className={`${
              enabled ? "bg-blue-600" : "bg-gray-700"
            } relative inline-flex h-5 w-8 items-center rounded-full transition-colors `}
          >
            <span
              className={`${
                enabled ? "translate-x-4" : "translate-x-0"
              } inline-block h-4 w-4 transform rounded-full bg-white transition-transform`}
            />
          </Switch>
        </div>
      </Switch.Group>
    </div>
  );
};
