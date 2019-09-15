/**
 * @name Spline3d
 * @description An implementation of Kochanek-Bartels splines in three dimensions.
 * @author Allen Woods
 **/

// Declare our class
class Spline3d {
  constructor (knotVectorData) {
    // Set boolean flag that allows instantiation
    let ALLOW = true

    // If vector data has been passed in
    if (knotVectorData) {
      // If the data is delivered as an Array
      if (is(knotVectorData, 'Array')) {
        // Search the Array
        for (let kv = 0; kv < knotVectorData.length; kv++) {
          // If the Array contains anything that is not a Vector
          if (!is(knotVectorData[ kv ], 'Vector')) {
            // Disallow instantiation and break
            ALLOW = false
            break
          }
        }
        // If we are allowed, store the Array in the .knots property
        if (ALLOW) this.knots = knotVectorData
        // If the data is delivered as a single Vector
      } else if (is(knotVectorData, 'Vector')) {
        // Store the Vector as first item in .knots property's Array
        this.knots = [knotVectorData]
      } else {
        // If we didn't find any compatible data, disallow
        ALLOW = false
      }
    } else {
      // If no data was passed at all, disallow
      ALLOW = false
    }

    // If this instance was disallowed
    if (!ALLOW) {
      // Throw an error
      throw new Error('You must pass at least one knot vector to Spline3d.')
    } else {

    }
  }

  /* Helper methods for adding points */

  prependKnot (vectorObj) {
    if (is(vectorObj, 'Vector')) {
      this.knots.unshift(vectorObj)
    }
  }

  appendKnot (vectorObj) {
    if (is(vectorObj, 'Vector')) {
      this.knots.push(vectorObj)
    }
  }

  /* Helper methods for accessing points */

  firstKnot () {
    return this.knots[0]
  }

  lastKnot () {
    return this.knots[this.knots.length - 1]
  }

  nthKnot (idx) {
    if (is(idx, 'Number')) {
      return this.knots[idx]
    }
  }

  seriesOfKnots (startIdx, endIdx) {
    if (startIdx && is(startIdx, 'Number') && endIdx && is(endIdx, 'Number')) {
      if (Math.sign(startIdx) !== (-1) && Math.sign(endIdx) !== (-1)) {
        endIdx += 1
        return this.knots.slice(startIdx, endIdx)
      }
    }
  }

  /* Getter and Setter methods for all knots */

  get knots () {
    return this.knotsArray
  }

  set knots (vectorArray) {
    let tempKnots = []
    if (is(vectorArray, 'Array')) {
      vectorArray.forEach(vector => {
        if (is(vector, 'Vector')) {
          tempKnots.push(vector)
        }
      })
    }
    if (tempKnots.length > 0) {
      this.knotsArray = tempKnots
    }
  }

  /* Hermite basis functions */

  h0 (t) {
    return (1 + (2 * t)) * ((1 - t) * (1 - t))
  }
  h1 (t) {
    return t * ((1 - t) * (1 - t))
  }
  h2 (t) {
    return (t * t) * (3 - (2 * t))
  }
  h3 (t) {
    return (t * t) * (t - 1)
  }

  // This function calculates a hypotenuse between the given point and the next point forward
  hypotenuseAtKnot (knotNumber) {
    let v1 = this.nthKnot(knotNumber)
    let v2 = this.nthKnot(knotNumber + 1)
    let x = v2.coords[0] - v1.coords[0]
    let y = v2.coords[1] - v1.coords[1]
    let z = v2.coords[2] - v1.coords[2]

    return Math.sqrt((x * x) + (y * y) + (z * z))
  }

  sumHypotenuseOfAllKnots () {
    this.hypSum = 0
    for (let k = 1; k < this.knots.length - 1; k++) {
      this.hypSum += this.hypotenuseAtKnot(k)
    }

    return this.hypSum
  }

  // This function receives a value of "x" and calculates a "t" value based on its progression
  // within the hypotenuse yielded by the preceding point and the next nearest point.
  arbitraryInterval (x) {
    let hyps = []
    let sum = this.sumHypotenuseOfAllKnots()

    for (let k = 1; k < this.knots.length - 1; k++) {
      let hyp = {
        x: 0,
        l: this.hypotenuseAtKnot(k)
      }

      if (hyps.length > 0) {
        hyp.x = hyps[ hyps.length - 1 ].x + hyps[ hyps.length - 1 ].l
      }

      hyps.push(hyp)
    }

    let lastNearestKnot = false

    if (x < 0) {
      return 0
    } else if (x > sum) {
      return 1
    } else {
      let t = 0
      for (let h = 0; h < hyps.length; h++) {
        if (x >= hyps[ h ].x && x <= (hyps[ h ].x + hyps[ h ].l)) {
          t = (x - hyps[ h ].x) / hyps[ h ].l
          lastNearestKnot = h + 1
          break
        }
      }
      return { t: t, k: lastNearestKnot }
    }
  }

  // Kochanek-Bartels functions //

  // We pass in the index "i" that is the starting point for the piece we are drawing.
  d (i) {
    // create an empty array to fill with calculations
    let tangentsArray = []

    // get the points at indexes "i-1", "i", "i+1", and "i+2"
    let ptm1 = this.knots[ i - 1 ]
    let pt0 = this.knots[ i ]
    let ptp1 = this.knots[ i + 1 ]
    let ptp2 = this.knots[ i + 2 ]

    // For each of the two tangents we need
    for (let j = 0; j < 2; j++) {
      // Create an empty temporary object
      let tempTangent = new TensionVector(0, 0, 0, 0, 0, 0)

      let f0 = 0
      let f1 = 0
      let delta0 = 0
      let delta1 = 0

      // If this is the first tangent
      if (j === 0) {
        // Calculate the fractions for tension, continuity, and bias on this point
        f0 = ((1 - pt0.t) * (1 + pt0.b) * (1 + pt0.c)) * 0.5
        f1 = ((1 - pt0.t) * (1 - pt0.b) * (1 - pt0.c)) * 0.5

        // store pointers to the points whose distances are measured
        delta0 = {
          p0: pt0,
          p1: ptm1
        }
        delta1 = {
          p0: ptp1,
          p1: pt0
        }
      } else {
        // Calculate the fractions for tension, continuity, and bias on the next point
        f0 = ((1 - ptp1.t) * (1 + ptp1.b) * (1 - ptp1.c)) * 0.5
        f1 = ((1 - ptp1.t) * (1 - ptp1.b) * (1 + ptp1.c)) * 0.5

        // store pointers to the points whose distances are measured
        delta0 = {
          p0: ptp1,
          p1: pt0
        }
        delta1 = {
          p0: ptp2,
          p1: ptp1
        }
      }
      // for each axis of "x", "y", and "z"
      for (let k = 0; k < 3; k++) {
        // Calculate first and second terms of the equation on this tangent
        let term0 = f0 * (delta0.p0.coords[ k ] - delta0.p1.coords[ k ])
        let term1 = f1 * (delta1.p0.coords[ k ] - delta1.p1.coords[ k ])

        // Assign the addition of the terms to the axis of the tangent
        tempTangent.coords[ k ] = term0 + term1
      }

      // store the resulting object
      tangentsArray.push(tempTangent)
    }

    // return the two calculated tangents
    return tangentsArray
  }

  calcPosition (t, k) {
    // Create a null object to store calculations in
    let positionObject = new TensionVector(0, 0, 0, 0, 0, 0)

    // Create pointers to the start and end points of this piece
    let pt0 = this.knots[ k ]
    let pt1 = this.knots[ k + 1 ]

    // Create local pointer to the tangents for this piece
    let dTan = this.d(k)

    // For each axis of this curve
    for (let n = 0; n < 3; n++) {
      // Calculate the terms of the interpolation polynomial
      let term0 = this.h0(t) * pt0.coords[ n ]
      let term1 = this.h1(t) * dTan[0].coords[ n ]
      let term2 = this.h2(t) * pt1.coords[ n ]
      let term3 = this.h3(t) * dTan[1].coords[ n ]

      // Store the point location in the gixen axis
      positionObject.coords[ n ] = term0 + term1 + term2 + term3
    }

    // Return the resulting location in space
    return positionObject
  }

  drawCurve (canvasContext) {
    // Prevent drawing altogether if there aren't enough points to draw a line
    if (this.knots.length >= 2) {
      // The math of this curve requires specific point locations. So...
      // Prepend a duplicate of the first point before the start of the curve
      this.knots.unshift(this.knots[0])

      // Append duplicates of the last point after the end of the curve
      for (let i = 0; i < 2; i++) {
        this.knots.push(this.knots[this.knots.length - 1])
      }

      let randR = Math.floor(Math.random() * 255) + 1
      let randG = Math.floor(Math.random() * 255) + 1
      let randB = Math.floor(Math.random() * 255) + 1

      // For each knot along this spline
      let incrementalSpeed = 8
      for (let x = 0; x <= this.sumHypotenuseOfAllKnots(); x += incrementalSpeed) {
        let t = this.arbitraryInterval(x)
        if (!isNaN(t.t)) {
          let curveTraceVector = this.calcPosition(t.t, t.k)
          let drawPosition = new TensionVector(
            curveTraceVector.coords[ 0 ],
            curveTraceVector.coords[ 1 ],
            curveTraceVector.coords[ 2 ],
            0,
            0,
            0
          )
          if (t.t === 0) {
            canvasContext.strokeStyle = `rgba(${randR},${randG},${randB},1)`
            canvasContext.moveTo(drawPosition.coords[0], drawPosition.coords[1])
          } else {
            canvasContext.lineTo(drawPosition.coords[0], drawPosition.coords[1])
          }
        }
      }

      canvasContext.stroke()
    }

    // Remove the appended points
    for (let i = 0; i < 2; i++) {
      this.knots.pop()
    }

    // Remove the prepended point
    this.knots.shift()
  }
}

document.addEventListener('DOMContentLoaded', function() {
  let testCanvas = document.createElement('canvas')
document.body.appendChild(testCanvas)
testCanvas.setAttribute('id', 'canvas')
testCanvas.setAttribute('width', `${window.innerWidth}`)
testCanvas.setAttribute('height', `${window.innerHeight}`)
let testContext = document.getElementById('canvas').getContext('2d')

let seedKnots = []
for (let seedNum = 0; seedNum < 10; seedNum++) {
  seedKnots.push(
    new TensionVector(
      Math.floor(Math.random() * window.innerWidth),
      Math.floor(Math.random() * window.innerHeight),
      Math.floor(Math.random() * window.innerWidth),
      0,
      0,
      0
    )
  )
}

let testCurve = new Spline3d(seedKnots)
testCurve.drawCurve(testContext)
})

