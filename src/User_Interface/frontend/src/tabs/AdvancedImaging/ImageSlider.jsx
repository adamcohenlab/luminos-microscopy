import React, { useState, useEffect, useRef } from "react";
import { loadDmdPatterns, getDmdDimensions } from "../../matlabComms/dmdComms";

function unpackBinaryData(packedData) {
  const unpackedData = [];
  for (let byte of packedData) {
    for (let bit = 0; bit < 8; bit++) {
      unpackedData.push((byte >> bit) & 1);
    }
  }
  return unpackedData;
}

function reshapeData(flatArray, dimensions) {
  const [width, height] = dimensions;
  const depth = flatArray.length / (height * width);

  if (!Number.isInteger(depth)) {
    throw new Error(
      "The flat array length is not compatible with the provided spatial dimensions."
    );
  }

  const reshapedArray = [];
  let index = 0;

  for (let d = 0; d < depth; d++) {
    const layer = [];
    for (let h = 0; h < height; h++) {
      layer.push(flatArray.slice(index, index + width));
      index += width;
    }
    reshapedArray.push(layer);
  }

  return reshapedArray;
}

const ImageSlider = ({ dmdName }) => {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [dmdPatterns, setDmdPatterns] = useState([]);
  const canvasRef = useRef(null);

  useEffect(() => {
    const fetchPatterns = async () => {
      try {
        const packedData = await loadDmdPatterns({ deviceName: dmdName });
        if (packedData && packedData.length > 0) {
          const binaryData = unpackBinaryData(packedData);
          const dimensions = await getDmdDimensions({ deviceName: dmdName });
          if (dimensions && dimensions.length > 0) {
            const reshapedPatterns = reshapeData(binaryData, dimensions);
            setDmdPatterns(reshapedPatterns);
          } else {
            console.warn("Received invalid dimensions for DMD patterns.");
            setDmdPatterns([]);
          }
        } else {
          console.warn("No DMD pattern data received.");
          setDmdPatterns([]);
        }
      } catch (error) {
        console.error("Failed to load or reshape DMD patterns:", error);
        setDmdPatterns([]);
      }
    };

    fetchPatterns();
  }, [dmdName]); // Refetch patterns if the dmdName changes

  useEffect(() => {
    if (dmdPatterns.length > 0 && canvasRef.current) {
      const canvas = canvasRef.current;
      const context = canvas.getContext("2d");
      const pattern = dmdPatterns[currentIndex];
      const originalWidth = pattern[0].length;
      const originalHeight = pattern.length;

      canvas.width = originalHeight;
      canvas.height = originalWidth;

      const imageData = context.createImageData(originalHeight, originalWidth);

      for (let y = 0; y < originalHeight; y++) {
        for (let x = 0; x < originalWidth; x++) {
          const value = pattern[y][x] * 255;
          const transposedIndex = (x * originalHeight + y) * 4;
          imageData.data[transposedIndex] = value;
          imageData.data[transposedIndex + 1] = value;
          imageData.data[transposedIndex + 2] = value;
          imageData.data[transposedIndex + 3] = 255;
        }
      }
      context.putImageData(imageData, 0, 0);
    }
  }, [dmdPatterns, currentIndex]);

  const displayWidth = 350;
  const displayHeight =
    dmdPatterns.length > 0
      ? (displayWidth * dmdPatterns[0][0].length) / dmdPatterns[0].length
      : 0;

  const handleSliderChange = (event) => {
    setCurrentIndex(parseInt(event.target.value, 10));
  };

  return (
    <div className="max-w-sm p-4 bg-gray-800 rounded-md shadow-md text-center">
      <h3 className="text-m font-semibold text-white mb-2">
        Preview patterns on {dmdName}
      </h3>
      {dmdPatterns.length > 0 ? (
        <div className="relative border border-gray-600 mb-4 bg-gray-900 bg-center">
          <canvas
            ref={canvasRef}
            style={{
              width: `${displayWidth}px`,
              height: `${displayHeight}px`,
            }}
          />
          <span className="absolute top-2 right-2 bg-gray-700 text-white text-xs px-2 py-1 rounded">
            {currentIndex + 1}/{dmdPatterns.length}
          </span>
        </div>
      ) : (
        <div className="w-full h-40 flex items-center justify-center border border-gray-600 mb-4 bg-gray-900 text-gray-400 text-sm">
          Patterns empty or loading.
        </div>
      )}

      {dmdPatterns.length > 1 && (
        <input
          type="range"
          min="0"
          max={dmdPatterns.length - 1}
          value={currentIndex}
          onChange={handleSliderChange}
          className="w-full"
        />
      )}
    </div>
  );
};

export default ImageSlider;
