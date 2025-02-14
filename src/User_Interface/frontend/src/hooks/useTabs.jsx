import { useState } from "react";
import Waveforms from "../tabs/Waveforms/Waveforms";
import Main from "../tabs/Main/Main";
import DMD from "../tabs/DMD";
import Lasers from "../tabs/Lasers";
import Scanning from "../tabs/Scanning/Scanning";
import { useEffect } from "react";
import SLM from "../tabs/SLM/SLM";
import SpinningDisk from "../tabs/SpinningDisk";
import AdvancedImaging from "../tabs/AdvancedImaging/AdvancedImaging";
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
    AdvancedImaging,
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
    // DI 10/24: It's useful to have the name even if there's only one DMD. This way, we can refer to it by name in all functions.
    const namesArray = Array.isArray(tabInfo.names) ? tabInfo.names : [tabInfo.names];
  
    // Iterate over all device names for that tab
    for (let i = 0; i < namesArray.length; i++) {
      const TabComponent = allTabs[tabInfo.type]; // dynamically get the React Component for that tab type
      if (TabComponent) {
        tabs[`${namesArray[i]}`] = {
          component: TabComponent,
          props: {
            deviceName: namesArray[i],
          },
        };
      }
    }
  }
  

  return { tabs, currentTab, setCurrentTab };
};
