# Data Model: Real-time Acceleration Display MVP

**Date**: 2025-10-26
**Phase**: 1 - Design & Contracts

## Overview

This document defines the core data structures and entities for the acceleration display MVP. All models are pure Dart classes with no implementation details.

---

## Core Entities

### 1. AccelerationReading

Represents a single point-in-time measurement from the accelerometer sensor.

**Purpose**: Capture raw or processed acceleration data from device sensors with temporal context.

**Fields**:
- `x` (double): Acceleration along X-axis in m/s² (lateral: left/right)
- `y` (double): Acceleration along Y-axis in m/s² (longitudinal: forward/backward)
- `z` (double): Acceleration along Z-axis in m/s² (vertical: up/down)
- `timestamp` (DateTime): When the reading was captured
- `magnitude` (double, computed): Total acceleration magnitude in G-forces (1g = 9.81 m/s²)

**Validation Rules**:
- All axis values must be finite numbers (not NaN or infinite)
- Timestamp must not be in the future
- Magnitude calculated as: `sqrt(x² + y² + z²) / 9.81`

**Relationships**:
- Source data for TrajectoryPoint generation
- Consumed by AccelerometerService
- Displayed in real-time by AccelerationGauge widget

**State Transitions**: Immutable value object (no state changes)

**Example**:
```dart
AccelerationReading(
  x: 2.45,           // 0.25g lateral (right turn)
  y: 4.91,           // 0.5g longitudinal (acceleration)
  z: 0.98,           // 0.1g vertical (small bump)
  timestamp: DateTime.now(),
  magnitude: 0.56,   // sqrt(2.45² + 4.91² + 0.98²) / 9.81
)
```

---

### 2. TrajectoryPoint

Represents a historical acceleration data point used for trajectory path visualization.

**Purpose**: Store position data for rendering acceleration history as a 2D trajectory path over time.

**Fields**:
- `x` (double): Horizontal position on canvas (mapped from acceleration.x)
- `y` (double): Vertical position on canvas (mapped from acceleration.y)
- `timestamp` (DateTime): When this trajectory point was recorded
- `magnitude` (double): G-force magnitude at this point (for color coding)

**Validation Rules**:
- Position coordinates must be finite numbers
- Timestamp must not be in the future
- Magnitude must be non-negative

**Relationships**:
- Derived from AccelerationReading
- Stored in TrajectoryBuffer (FIFO queue)
- Consumed by TrajectoryPainter for rendering

**State Transitions**: Immutable value object (no state changes)

**Buffer Management**:
- Maximum 300 points in buffer (10 seconds × 30 Hz)
- Oldest points removed when buffer exceeds capacity (FIFO)
- Memory footprint: ~48 bytes per point × 300 = ~14.4 KB

**Example**:
```dart
TrajectoryPoint(
  x: 120.5,          // Canvas X position (scaled from acceleration)
  y: 85.3,           // Canvas Y position (scaled from acceleration)
  timestamp: DateTime.now(),
  magnitude: 0.56,   // G-force for color intensity
)
```

---

### 3. GForceData

Aggregated acceleration information for display purposes.

**Purpose**: Provide user-friendly acceleration data for UI components.

**Fields**:
- `lateral` (double): Lateral G-force (left/right) in G units
- `longitudinal` (double): Longitudinal G-force (forward/backward) in G units
- `vertical` (double): Vertical G-force (up/down) in G units
- `totalMagnitude` (double): Combined G-force magnitude
- `direction` (AccelerationDirection, enum): Primary direction of acceleration
- `timestamp` (DateTime): When this data was calculated

**Validation Rules**:
- All G-force values must be finite
- totalMagnitude must match calculation from components
- Timestamp must not be in the future

**Derived Properties**:
- `isHardAcceleration` (bool): Returns true if totalMagnitude > 0.5g
- `isNearStationary` (bool): Returns true if totalMagnitude < 0.1g

**Relationships**:
- Computed from AccelerationReading
- Consumed by UI widgets (AccelerationGauge, DirectionIndicator)
- Used for user-facing displays

**Example**:
```dart
GForceData(
  lateral: 0.25,              // 0.25g right turn
  longitudinal: 0.50,         // 0.5g acceleration
  vertical: 0.10,             // 0.1g vertical
  totalMagnitude: 0.56,       // sqrt(0.25² + 0.50² + 0.10²)
  direction: AccelerationDirection.forwardRight,
  timestamp: DateTime.now(),
)
```

---

### 4. TrajectoryBuffer

Manages the sliding window of trajectory points for visualization.

**Purpose**: Maintain a fixed-size FIFO buffer of recent trajectory points, automatically removing old data.

**Fields**:
- `points` (List<TrajectoryPoint>, read-only): Current trajectory points
- `maxPoints` (int, const): Maximum buffer size (300 for 10 seconds at 30 Hz)
- `capacity` (int, computed): Current number of points in buffer

**Operations**:
- `addPoint(TrajectoryPoint point)`: Add new point, remove oldest if at capacity
- `clear()`: Remove all points
- `getPointsInRange(DateTime start, DateTime end)`: Filter points by time range

**Validation Rules**:
- Buffer never exceeds maxPoints (300)
- Points maintained in chronological order
- Oldest points removed first (FIFO)

**State Management**:
- Extends ChangeNotifier for reactive UI updates
- Notifies listeners when points added/removed
- Efficient for 30 Hz updates (O(1) add, O(1) remove)

**Memory Management**:
- Fixed capacity prevents unbounded growth
- Old references released for garbage collection
- Total memory: ~14.4 KB for full buffer

---

## Enumerations

### AccelerationDirection

Represents the primary direction of acceleration for visual indicators.

**Values**:
- `forward`: Predominantly forward acceleration (y > 0, |y| > |x|)
- `backward`: Predominantly backward acceleration (y < 0, |y| > |x|)
- `left`: Predominantly left acceleration (x < 0, |x| > |y|)
- `right`: Predominantly right acceleration (x > 0, |x| > |y|)
- `forwardLeft`: Combined forward and left
- `forwardRight`: Combined forward and right
- `backwardLeft`: Combined backward and left
- `backwardRight`: Combined backward and right
- `stationary`: Minimal acceleration (magnitude < 0.1g)

**Calculation Logic**:
```dart
// Pseudo-code for direction determination
if (magnitude < 0.1) return stationary;

double angle = atan2(y, x); // Angle in radians
if (angle between -π/8 and π/8) return right;
if (angle between π/8 and 3π/8) return forwardRight;
if (angle between 3π/8 and 5π/8) return forward;
// ... etc for all 8 directions
```

---

### PermissionStatus

Represents the state of sensor permissions.

**Values**:
- `notDetermined`: Permission not yet requested
- `granted`: User granted permission
- `denied`: User explicitly denied permission
- `restricted`: Permission restricted by system (iOS parental controls)
- `permanentlyDenied`: User denied with "don't ask again" (Android)

**Usage**: Determines UI flow for permission handling

---

### SensorAvailability

Represents the availability and status of accelerometer hardware.

**Values**:
- `available`: Sensor present and functioning
- `unavailable`: Device has no accelerometer
- `malfunctioning`: Sensor present but returning errors
- `unknown`: Status not yet determined

**Usage**: Error handling and user messaging

---

## Data Flow

### Sensor → Display Pipeline

```
1. Device Sensor (hardware)
   ↓
2. sensors_plus plugin (AccelerometerEvent)
   ↓
3. AccelerationReading (domain model)
   ↓
4. GForceData (UI-friendly model)
   ↓
5. UI Widgets (display to user)
```

### Trajectory Visualization Pipeline

```
1. AccelerationReading (from sensor)
   ↓
2. TrajectoryPoint (mapped to canvas coordinates)
   ↓
3. TrajectoryBuffer (sliding window, FIFO)
   ↓
4. TrajectoryPainter (CustomPainter rendering)
   ↓
5. Canvas (visual trajectory path)
```

---

## Memory Footprint Analysis

### Per-Object Size Estimates

**AccelerationReading**:
- 3 doubles (x, y, z): 24 bytes
- 1 DateTime: 8 bytes
- 1 double (magnitude): 8 bytes
- **Total**: ~40 bytes

**TrajectoryPoint**:
- 2 doubles (x, y): 16 bytes
- 1 DateTime: 8 bytes
- 1 double (magnitude): 8 bytes
- **Total**: ~32 bytes

**TrajectoryBuffer** (full):
- 300 × TrajectoryPoint: 9.6 KB
- Queue overhead: ~4.8 KB
- **Total**: ~14.4 KB

### Continuous Operation (1 hour)

**Data generation**:
- 30 readings/second × 3600 seconds = 108,000 readings
- Only last 300 kept in buffer (10 seconds)
- **Memory**: Stable at ~14.4 KB (FIFO prevents growth)

**Garbage collection**:
- 29,700 old readings/minute discarded
- Dart GC handles efficiently (no manual management needed)

---

## Validation & Error Handling

### Input Validation

**AccelerationReading creation**:
```dart
assert(!x.isNaN && !x.isInfinite, 'X acceleration must be finite');
assert(!y.isNaN && !y.isInfinite, 'Y acceleration must be finite');
assert(!z.isNaN && !z.isInfinite, 'Z acceleration must be finite');
assert(timestamp.isBefore(DateTime.now().add(Duration(seconds: 1))),
       'Timestamp cannot be in future');
```

**TrajectoryBuffer capacity**:
```dart
assert(points.length <= maxPoints, 'Buffer exceeded capacity');
assert(maxPoints == 300, 'Buffer size must be 300 for MVP');
```

### Error Scenarios

**Sensor malfunction**: AccelerometerService catches sensor stream errors
**Invalid data**: Validation in model constructors throws ArgumentError
**Permission denied**: PermissionStatus enum tracks state for UI handling
**Missing sensor**: SensorAvailability enum indicates device compatibility

---

## Testing Considerations

### Mock Data Generation

**Stationary vehicle**:
```dart
AccelerationReading(x: 0.0, y: 0.0, z: 9.81, timestamp: now)
// Magnitude: 1.0g (gravity only)
```

**Moderate acceleration**:
```dart
AccelerationReading(x: 0.0, y: 4.91, z: 0.0, timestamp: now)
// Magnitude: 0.5g forward
```

**Hard braking**:
```dart
AccelerationReading(x: 0.0, y: -9.81, z: 0.0, timestamp: now)
// Magnitude: 1.0g backward
```

**Right turn**:
```dart
AccelerationReading(x: 4.91, y: 0.0, z: 0.0, timestamp: now)
// Magnitude: 0.5g lateral right
```

### Unit Test Coverage

- ✅ AccelerationReading magnitude calculation
- ✅ TrajectoryPoint validation
- ✅ GForceData direction determination
- ✅ TrajectoryBuffer FIFO behavior
- ✅ TrajectoryBuffer capacity limits
- ✅ AccelerationDirection angle calculations
- ✅ Edge cases (NaN, Infinity, null)

---

## Future Extensions (Post-MVP)

### Driving Score Calculation
**New Entity**: DrivingSession
- sessionId, startTime, endTime
- averageGForce, maxGForce
- smoothnessScore (based on G-force variance)
- List<AccelerationReading> historicalData

### User Profiles
**New Entity**: UserProfile
- userId, name, vehicleType
- List<DrivingSession> sessions
- overallScore, ranking

### Analytics
**New Entity**: AccelerationStatistics
- mean, median, standardDeviation
- histogram data (G-force distribution)
- peak events (hard braking, aggressive turns)

These are explicitly **out of scope** for MVP but documented for future reference.

---

## Summary

**Core Models**: 4 (AccelerationReading, TrajectoryPoint, GForceData, TrajectoryBuffer)
**Enums**: 3 (AccelerationDirection, PermissionStatus, SensorAvailability)
**Memory footprint**: ~14.4 KB (stable, FIFO-managed)
**Update frequency**: 30 Hz (33ms per reading)
**Buffer capacity**: 300 points (10 seconds history)

All models designed for:
- ✅ Immutability (value objects)
- ✅ Validation (runtime checks)
- ✅ Performance (efficient memory, fast operations)
- ✅ Testability (pure functions, mockable)
- ✅ Clarity (self-documenting fields and constraints)
