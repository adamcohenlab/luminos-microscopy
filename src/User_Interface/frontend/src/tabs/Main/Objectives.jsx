import React, { useState, useEffect } from "react";
import { SectionHeader } from "../../components/SectionHeader";
import { GrayBox } from "../../components/GrayBox";
import { TextInput } from "../../components/TextInput";
import { useMatlabVariable } from "../../matlabComms/matlabHelpers";

const brandFactors = {
  Olympus: 180,
  Zeiss: 165,
  Thorlabs: 200,
  Leica: 200,
  Nikon: 200,
  Mitutoyo: 200,
};


let magnificationRef = { current: 1 }; // Static variable to store magnification

const ObjTL = ({ cameraName, ...props }) => {
  const [objectiveBrand, setObjectiveBrand] = useState("Olympus");
  const [tubeLensBrand, setTubeLensBrand] = useState("Olympus");
  const [objectiveField1, setObjectiveField1] = useState("3.6"); // Magnification
  const [objectiveField2, setObjectiveField2] = useState("50"); // Focal length
  const [tubeLensField1, setTubeLensField1] = useState("3.6");
  const [tubeLensField2, setTubeLensField2] = useState("50");
  const [magnification, setMagnification] = useState(1);
  const [magMatlab, setMagMatlab] = useMatlabVariable("magnification", "Camera", "Simulated_Cam");

  // Helper for formatting numbers for display
  const formatForDisplay = (value) => {
    if (isNaN(value)) return "";
    return parseFloat(value).toFixed(1);
  };

  // Calculate focal length based on magnification
  const calculateFocalLength = (magnification, brand) => {
    const factor = brandFactors[brand];
    const mag = parseFloat(magnification);
    if (!isNaN(mag) && mag !== 0) {
      return (factor / mag).toFixed(6);
    }
    return "";
  };

  // Calculate magnification based on focal length
  const calculateMagnification = (focalLength, brand) => {
    const factor = brandFactors[brand];
    const fl = parseFloat(focalLength);
    if (!isNaN(fl) && fl !== 0) {
      return (factor / fl).toFixed(6);
    }
    return "";
  };

  // Update objective focal length when magnification changes
  useEffect(() => {
    const calculatedFocalLength = calculateFocalLength(objectiveField1, objectiveBrand);
    if (calculatedFocalLength !== objectiveField2) {
      setObjectiveField2(calculatedFocalLength);
    }
  }, [objectiveField1, objectiveBrand]);

  // Update objective magnification when focal length changes
  useEffect(() => {
    const calculatedMagnification = calculateMagnification(objectiveField2, objectiveBrand);
    if (calculatedMagnification !== objectiveField1) {
      setObjectiveField1(calculatedMagnification);
    }
  }, [objectiveField2, objectiveBrand]);

  // Update tube lens focal length when magnification changes
  useEffect(() => {
    const calculatedFocalLength = calculateFocalLength(tubeLensField1, tubeLensBrand);
    if (calculatedFocalLength !== tubeLensField2) {
      setTubeLensField2(calculatedFocalLength);
    }
  }, [tubeLensField1, tubeLensBrand]);

  // Update tube lens magnification when focal length changes
  useEffect(() => {
    const calculatedMagnification = calculateMagnification(tubeLensField2, tubeLensBrand);
    if (calculatedMagnification !== tubeLensField1) {
      setTubeLensField1(calculatedMagnification);
    }
  }, [tubeLensField2, tubeLensBrand]);

  // Compute overall magnification when focal lengths change
  useEffect(() => {
    const objFL = parseFloat(objectiveField2);
    const tubeFL = parseFloat(tubeLensField2);
    if (!isNaN(objFL) && !isNaN(tubeFL) && tubeFL !== 0) {
      const newMag = parseFloat((objFL / tubeFL).toFixed(6));
      if (newMag !== magnification) {
        setMagnification(newMag);
        setMagMatlab(1 / newMag);
      }
    } else {
      setMagnification(NaN);
      setMagMatlab(NaN);
    }
  }, [objectiveField2, tubeLensField2]);

  return (
    <div {...props}>
      <SectionHeader>Objectives & Tube Lenses</SectionHeader>
      <GrayBox className="max-w-sm">
        {/* Objective Section */}
        <div>
          <label className="block text-sm font-bold mb-1">Objective</label>
          <div className="pb-1">
            <div className="h-6 flex items-center text-gray-100 rounded-sm border border-gray-600 border-opacity-0 hover:border-opacity-100 focus-within:border-blue-600 focus-within:outline-blue-600">
              <span className="text-gray-400 text-xs ml-2">Manufacturer</span>
              <select
                style={{ width: '400px' }}
                value={objectiveBrand}
                onChange={(e) => setObjectiveBrand(e.target.value)}
                className="bg-black bg-opacity-0 outline-none b-0 min-w-0 w-full text-xs border-0 py-0 cursor-pointer focus:ring-0 focus:border-0 ml-4"
              >
                {Object.keys(brandFactors).map((brand) => (
                  <option key={brand} value={brand} className="bg-gray-800">
                    {brand}
                  </option>
                ))}
              </select>
            </div>
          </div>
          <div className="flex justify-between">
            <div>
              <TextInput
                value={formatForDisplay(objectiveField1)}
                setValue={setObjectiveField1}
                defaultVal="3.6"
                name="Magnification"
                suffix="x"
                style={{ width: '160px' }}
                units="x"
              />
            </div>
            <div>
              <TextInput
                value={formatForDisplay(objectiveField2)}
                setValue={setObjectiveField2}
                defaultVal="50"
                name="Focal Length"
                suffix="mm"
                style={{ width: '160px' }}
                units="mm"
              />
            </div>
          </div>
        </div>
        <div className="my-4 bg-gray-700" style={{ height: '1px' }}></div>

        {/* Tube Lens Section */}
        <div>
          <label className="block text-sm font-bold mb-1">Tube Lens</label>
          <div className="pb-1">
            <div className="h-6 flex items-center text-gray-100 rounded-sm border border-gray-600 border-opacity-0 hover:border-opacity-100 focus-within:border-blue-600 focus-within:outline-blue-600">
              <span className="text-gray-400 text-xs ml-2">Manufacturer</span>
              <select
                style={{ width: '400px' }}
                value={tubeLensBrand}
                onChange={(e) => setTubeLensBrand(e.target.value)}
                className="bg-black bg-opacity-0 outline-none b-0 min-w-0 w-full text-xs border-0 py-0 cursor-pointer focus:ring-0 focus:border-0 ml-4"
              >
                {Object.keys(brandFactors).map((brand) => (
                  <option key={brand} value={brand} className="bg-gray-800">
                    {brand}
                  </option>
                ))}
              </select>
            </div>
          </div>
          <div className="flex justify-between">
            <div>
              <TextInput
                value={formatForDisplay(tubeLensField1)}
                setValue={setTubeLensField1}
                defaultVal="3.6"
                name="Magnification"
                suffix="x"
                style={{ width: '160px' }}
                units="x"
              />
            </div>
            <div>
              <TextInput
                value={formatForDisplay(tubeLensField2)}
                setValue={setTubeLensField2}
                defaultVal="50"
                name="Focal Length"
                suffix="mm"
                style={{ width: '160px' }}
                units="mm"
              />
            </div>
          </div>
        </div>

        {/* Total Magnification Section */}
        <div className="my-4 bg-gray-700" style={{ height: '1px' }}></div>
        <div className="flex items-center space-x-2">
          <label className="text-gray-0 text-sm ml-14 mt-1">Total Magnification:</label>
          <TextInput
            value={formatForDisplay(1 / magnification)}
            readOnly={true}
            disabled={true}
            suffix="x"
            style={{ width: '80px' }}
            units="x"
          />
        </div>
        <div className="text-gray-400 text-xs ml-2 mt-4">
          Select focal lengths or manufacturer and magnification to calculate total magnification of infinity corrected system. Right-click on two points in stream to measure distances.
        </div>
      </GrayBox>
    </div>
  );
};



// Export the getDistanceFactor function
export const getDistanceFactor = () => {
  return magnificationRef.current;
};

export default ObjTL;
