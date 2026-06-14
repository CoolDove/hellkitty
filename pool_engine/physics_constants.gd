class_name PhysicsConstants
extends RefCounted

## Billiard Physics Constants
## Based on foobillardplus physics engine

# Ball properties
const BALL_MASS: float = 0.17        # kg (170 grams)
const BALL_DIAMETER: float = 0.05715 # m (57.15 mm standard pool ball)
const BALL_RADIUS: float = BALL_DIAMETER / 2.0

# Moment of inertia for solid sphere: I = 2/5 * m * r^2
const BALL_INERTIA: float = 0.4 * BALL_MASS * BALL_RADIUS * BALL_RADIUS

# Friction coefficients
const MU_ROLL: float = 0.01    # Rolling friction on table
const MU_SLIDE: float = 0.1    # Sliding friction on table
const MU_BALL: float = 0.1     # Ball-to-ball friction

# Contact patch radius for rotational friction
const SPOT_R: float = 0.012    # 12mm

# Thresholds
const SLIDE_THRESH_SPEED: float = 0.01  # 1 cm/s - sliding vs rolling threshold
const OMEGA_MIN: float = SLIDE_THRESH_SPEED / SPOT_R
const VELOCITY_STOP_THRESHOLD: float = 0.001  # Minimum velocity before stopping

# Gravity (for future jump shot support)
const GRAVITY: float = 9.81    # m/s^2

# Cushion/wall properties
const CUSHION_MU: float = 0.1         # Cushion friction
const CUSHION_LOSS0: float = 0.2      # Base energy loss
const CUSHION_LOSS_MAX: float = 0.5   # Maximum energy loss
const CUSHION_LOSS_WSPEED: float = 4.0 # Half-width velocity for loss curve

# Simulation
const DEFAULT_TIMESTEP: float = 0.01  # 10ms physics timestep
