const isPointInsidePolygon = (point, vertices) => {
  // ray-casting algorithm based on
  // https://stackoverflow.com/questions/22521982/check-if-point-is-inside-a-polygon

  // e.g.
  // let polygon = [ [ 1, 1 ], [ 1, 2 ], [ 2, 2 ], [ 2, 1 ] ];
  // inside([ 1.5, 1.5 ], polygon); // true

  var x = point[0],
    y = point[1];

  var inside = false;
  for (var i = 0, j = vertices.length - 1; i < vertices.length; j = i++) {
    var xi = vertices[i][0],
      yi = vertices[i][1];
    var xj = vertices[j][0],
      yj = vertices[j][1];

    var intersect =
      yi > y != yj > y && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi;
    if (intersect) inside = !inside;
  }

  return inside;
};

const isPointInsideCircle = (point, circleCenter, circleRadius) => {
  const [x, y] = point;
  const [cx, cy] = circleCenter;

  const distance = Math.sqrt((x - cx) ** 2 + (y - cy) ** 2);
  return distance <= circleRadius;
};

export const computeMask = ({ polygons, circles, height, width }) => {
  // compute a binary mask from the polygons and circles
  // mask should be of size [height, width]
  const mask = new Array(height)
    .fill(0)
    .map(() => new Array(Math.floor(width)).fill(0));

  // fill in the mask with 1s inside the polygons
  polygons.forEach((polygon) => {
    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        if (isPointInsidePolygon([x, y], polygon)) {
          mask[y][x] = 1;
        }
      }
    }
  });

  // fill in the mask with 1s inside the circles
  circles.forEach((circle) => {
    const { center, radius } = circle;
    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        if (isPointInsideCircle([x, y], center, radius)) {
          mask[y][x] = 1;
        }
      }
    }
  });

  return mask;
};
