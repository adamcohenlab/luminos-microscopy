import { Nav } from "./components/Nav";
import { createTheme, ThemeProvider } from "@mui/material";
import { NotificationsProvider } from "./components/Notifications";
import {
  GlobalAppVariablesProvider,
  useGlobalAppVariables,
} from "./components/GlobalAppVariablesContext";
import { useTabs } from "./hooks/useTabs";

export default function App() {
  const { tabs, currentTab, setCurrentTab } = useTabs();

  // for material ui theme
  const darkTheme = createTheme({
    palette: {
      mode: "dark",
    },
  });

  return (
    <ThemeProvider theme={darkTheme}>
      <NotificationsProvider>
        <GlobalAppVariablesProvider>
          <PageWrapper>
            <Nav
              navigationTabs={Object.keys(tabs)}
              currentTab={currentTab}
              setCurrentTab={setCurrentTab}
            />
            <CurrentTab tabs={tabs} currentTab={currentTab} />
          </PageWrapper>
        </GlobalAppVariablesProvider>
      </NotificationsProvider>
    </ThemeProvider>
  );
}

const CurrentTab = ({ tabs, currentTab }) => (
  // renders the current tab
  <TabWrapper>
    {Object.entries(tabs).map(([tab, { component: Component, props }]) => {
      if (tab === currentTab) {
        return (
          <div key={tab}>
            <Component {...props} />
          </div>
        );
      } else {
        return (
          <div key={tab} className="hidden">
            <Component {...props} />
          </div>
        );
      }
    })}
  </TabWrapper>
);

const TabWrapper = ({ children }) => (
  // applies styling to the tab content
  <main>
    <div className="container mx-auto px-8 max-w-7xl pb-12">{children}</div>
  </main>
);

const PageWrapper = ({ children }) => {
  const { isMatlabOnline } = useGlobalAppVariables();

  // applies styling to the whole page
  return (
    <div className="font-sans bg-slate-900 text-xs text-gray-100 select-none">
      {isMatlabOnline ? children : <MatlabOffline />}
    </div>
  );
};

const MatlabOffline = () => (
  <div className=" h-screen flex items-center justify-center text-2xl">
    Matlab is offline
  </div>
);
