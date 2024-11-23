BK98_CONSTANTS = {}
-- The minimum speed required to be considered for drifting (10 km/h converted to m/s).
BK98_CONSTANTS.ninSpeed = (10 / 3.6)
-- The maximum speed allowed during drift recording (50 km/h converted to m/s).
BK98_CONSTANTS.maxSpeed = (150 / 3.6)
-- The maximum time a player can go without drifting before the recording is cancelled (5 seconds).
BK98_CONSTANTS.maxIdleTime = 1000 * 5
-- A constant representing the increment factor for power calculations.
BK98_CONSTANTS.powerIncrease = 1.8
-- A constant representing the font ID to be used in rendering text.
BK98_CONSTANTS.font = 7
-- A constant representing the vertical position (y-coordinate) where display indicators should be positioned on the screen.
BK98_CONSTANTS.displayIndicatorY = 0.8
-- An array of constants representing different multiplier values for various calculations or transformations.
BK98_CONSTANTS.multiplier = { 350, 1400, 4200, 11200 }
-- Colors
BK98_CONSTANTS.WHITE = { 255, 255, 255, 255 }
BK98_CONSTANTS.RED = { 255, 0, 0, 164 }
BK98_CONSTANTS.BLUE = { 0, 0, 255, 128 }
BK98_CONSTANTS.ORANGE = { 255, 191, 0, 255 }
BK98_CONSTANTS.YELLOW = { 255, 255, 0, 255 }
BK98_CONSTANTS.BLACK = { 0, 0, 0, 255 }