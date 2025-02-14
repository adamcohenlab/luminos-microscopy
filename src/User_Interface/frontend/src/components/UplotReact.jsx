// based on @skalinichev/uplot-wrappers https://github.com/skalinichev/uplot-wrappers/blob/master/react/uplot-react.tsx
// documentation for uplot: https://github.com/leeoniya/uPlot

import React, { useEffect, useRef } from "react";

import uPlot from "uplot";
import "uplot/dist/uPlot.min.css";

// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/is
if (!Object.is) {
  // eslint-disable-next-line
  Object.defineProperty(Object, "is", {
    value: (x, y) =>
      (x === y && (x !== 0 || 1 / x === 1 / y)) || (x !== x && y !== y),
  });
}

// method to check if two objects are equal
const isObjectsEqual = (a, b) => {
  if (Object.keys(a).length !== Object.keys(b).length) {
    return 0;
  }
  for (const k of Object.keys(a)) {
    if (!Object.is(a[k], b[k])) {
      // make sure we don't compare functions
      if (typeof a[k] === "function" || typeof b[k] === "function") {
        continue;
      } else if (typeof a[k] === "object" && typeof b[k] === "object") {
        // recurse if we have an object
        if (!isObjectsEqual(a[k], b[k])) {
          return 0;
        }
      }
    }
  }
  return 1;
};

const optionsUpdateState = (_lhs, _rhs) => {
  const { width: lhsWidth, height: lhsHeight, ...lhs } = _lhs;
  const { width: rhsWidth, height: rhsHeight, ...rhs } = _rhs;

  let state = "keep";
  if (lhsHeight !== rhsHeight || lhsWidth !== rhsWidth) {
    state = "update";
  }
  if (!isObjectsEqual(lhs, rhs)) {
    state = "create";
  }

  return state;
};

export const dataMatch = (lhs, rhs) => {
  if (lhs.length !== rhs.length) {
    return false;
  }
  return lhs.every((lhsOneSeries, seriesIdx) => {
    const rhsOneSeries = rhs[seriesIdx];
    if (lhsOneSeries.length !== rhsOneSeries.length) {
      return false;
    }
    return lhsOneSeries.every(
      (value, valueIdx) => value === rhsOneSeries[valueIdx]
    );
  });
};

const UplotReact = ({
  options,
  data,
  target,
  onDelete = () => {},
  onCreate = () => {},
  resetScales = true,
  ...props
}) => {
  const chartRef = useRef(null);
  const targetRef = useRef(null);

  const destroy = (chart) => {
    if (chart) {
      onDelete(chart);
      chart.destroy();
      chartRef.current = null;
    }
  };

  const create = () => {
    const newChart = new uPlot(options, data, target || targetRef.current);
    chartRef.current = newChart;
    onCreate(newChart);
    updateWindowSize();
  };

  // componentDidMount + componentWillUnmount
  useEffect(() => {
    create();
    return () => {
      destroy(chartRef.current);
    };
  }, []);

  const updateWindowSize = () => {
    const clientWidth = targetRef.current
      ? targetRef.current.clientWidth
      : chartRef.current?.width;
    const clientHeight = targetRef.current
      ? targetRef.current.clientHeight
      : chartRef.current?.height;

    const width = options.width || clientWidth;
    const height = options.height || clientHeight;

    if (height && width)
      chartRef.current.setSize({
        width,
        height,
      });
  };

  useEffect(updateWindowSize, []);

  useEffect(() => {
    window.addEventListener("resize", updateWindowSize);
  }, []);

  // componentDidUpdate
  const prevProps = useRef({ options, data, target }).current;
  useEffect(() => {
    if (prevProps.options !== options) {
      const optionsState = optionsUpdateState(prevProps.options, options);
      if (!chartRef.current || optionsState === "create") {
        destroy(chartRef.current);
        create();
      }
    }
    if (prevProps.data !== data) {
      // data changed
      if (!chartRef.current) {
        create();
      } else if (!dataMatch(prevProps.data, data)) {
        if (resetScales) {
          chartRef.current.setData(data, true);
        } else {
          chartRef.current.setData(data, false);
          chartRef.current.redraw();
        }
      }
    }
    if (prevProps.target !== target) {
      destroy(chartRef.current);
      create();
    }

    return () => {
      prevProps.options = options;
      prevProps.data = data;
      prevProps.target = target;
    };
  }, [options, data, target, resetScales]);

  return target ? null : (
    <div {...props}>
      <div ref={targetRef}></div>
    </div>
  );
};

export default UplotReact;