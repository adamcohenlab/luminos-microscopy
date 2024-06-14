import { Disclosure } from "@headlessui/react";
import ExitButton from "./ExitButton";
import { prettyName } from "./Utils";

export const Nav = ({
  navigationTabs,
  currentTab,
  setCurrentTab,
  ...props
}) => (
  <Disclosure as="nav">
    <div className="mx-auto sm:px-6 lg:px-8 pb-4">
      <div className="flex h-16 items-center justify-between px-4 sm:px-0">
        <div className="flex items-center">
          <AppTitle />
          <TabTitles {...{ navigationTabs, currentTab, setCurrentTab }} />
        </div>
        <ExitButton />
      </div>
    </div>
  </Disclosure>
);

const AppTitle = () => (
  <div className="flex-shrink-0">
    <a className="text-white font-bold text-base cursor-default">
      Luminos v0.2
    </a>
  </div>
);

const TabTitles = ({ navigationTabs, currentTab, setCurrentTab }) => (
  <div className="md:block">
    <div className="ml-10 flex items-baseline space-x-4">
      {navigationTabs.map((item) => (
        <a
          key={item}
          href={"#"}
          className={`${
            item === currentTab
              ? // add border to bottom
                "bg-gray-900 text-cyan-500 border-b-2 border-cyan-500"
              : "text-gray-300 hover:bg-gray-700 hover:text-white rounded-md"
          }
            px-3 py-2 text-sm font-bold`}
          onClick={() => setCurrentTab(item)}
        >
          {prettyName(item)}
        </a>
      ))}
    </div>
  </div>
);
