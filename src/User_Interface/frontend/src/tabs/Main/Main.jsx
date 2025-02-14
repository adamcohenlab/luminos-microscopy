/* Main Tab */
import React from "react";
import { SectionHeader } from "../../components/SectionHeader";
import { GrayBox } from "../../components/GrayBox";
import { TextInput } from "../../components/TextInput";
import Notes from "./Notes";
import StageController from "./StageController";
import ZStage from "./ZStage";
import ObjTL from "./Objectives";
import { Cameras } from "./Camera/Cameras";
import { GeneralToggles } from "./GeneralToggles";
import { ROIPlotter } from "./ROIPlotter";
import { VerticalStack } from "../../components/VerticalStack";
import { useGlobalAppVariables } from "../../components/GlobalAppVariablesContext";

export default function Main() {
  return (
    // two columns
    <div className="grid grid-cols-2">
      <VerticalStack>
        <Experiment />
        <GeneralToggles />
        <StageController />
        <ZStage />
        <Notes />
      </VerticalStack>
      <VerticalStack>
        <Cameras />
        <ROIPlotter />
        <ObjTL />
      </VerticalStack>
    </div>
  );
}

const Experiment = () => {
  const { experimentName, setExperimentName } = useGlobalAppVariables();
  return (
    <div>
      <SectionHeader>Experiment</SectionHeader>
      <GrayBox className="max-w-sm">
        <TextInput
          value={experimentName}
          setValue={setExperimentName}
          defaultVal="Experiment Name"
          name="Experiment Name"
        />
      </GrayBox>
    </div>
  );
};
