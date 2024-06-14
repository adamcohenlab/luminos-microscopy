import { useState } from "react";
import Waveforms from "../tabs/Waveforms/Waveforms";
import Main from "../tabs/Main/Main";
import DMD from "../tabs/DMD";
import Lasers from "../tabs/Lasers";
import Scanning from "../tabs/Scanning/Scanning";
import { useEffect } from "react";
import SLM from "../tabs/SLM/SLM";
import SpinningDisk from "../tabs/SpinningDisk";
import Hadamard from "../tabs/Hadamard";
import { getTabs } from "../matlabComms/miscellaneousComms";

export const useTabs = () => {
  let allTabs = {
    Main,
    Waveforms,
    DMD,
    Lasers,
    Scanning,
    SLM,
    SpinningDisk,
    Hadamard,
  };

  // tabs that are in use (e.g. if DMD is not in use, don't show the DMD tab)
  const [activeTabs, setActiveTabs] = useState([]);

  // special tabs are tabs that have multiple instances (e.g. multiple DMDs)
  const [specialTabs, setSpecialTabs] = useState([]);

  // tab that the user is currently on
  const [currentTab, setCurrentTab] = useState("Main");

  // get tabs from matlab on page load
  useEffect(() => {
    getTabs().then((tabsFromMatlab) => {
      // split tabs into tabs that have multiple instances (e.g. multiple DMDs) and tabs that don't
      setActiveTabs(tabsFromMatlab.filter((tabInfo) => !tabInfo.type));
      setSpecialTabs(tabsFromMatlab.filter((tabInfo) => !!tabInfo.type));
    });
  }, []);

  let tabs = {};

  // add active tabs
  for (const tabName of activeTabs) {
    tabs[tabName] = { component: allTabs[tabName], props: {} };
  }

  // add special tabs (for multiple instances of certain tab types e.g. DMDs, Scanning)
  for (const tabInfo of specialTabs) {
    // iterate over all deviceNames for that tab
    for (let i = 0; i < tabInfo.names.length; i++) {
      const TabComponent = allTabs[tabInfo.type]; // dynamically get the React Component for that tab type
      if (TabComponent) {
        tabs[`${tabInfo.names[i]}`] = {
          component: TabComponent,
          props: {
            deviceName: tabInfo.names[i],
          },
        };
      }
    }
  }

  return { tabs, currentTab, setCurrentTab };
};
