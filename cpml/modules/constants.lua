--- Various useful constants
-- @module constants

--- Constants
-- @table constants
-- @field FLT_EPSILON Floating point precision breaks down
-- @field DBL_EPSILON Double-precise floating point precision breaks down
-- @field DOT_THRESHOLD Close enough to 1 for interpolations to occur
local constants = {}

-- same as C's FLT_EPSILON
constants.FLT_EPSILON = 1.19209290e-07

-- same as C's DBL_EPSILON
constants.DBL_EPSILON = 2.2204460492503131e-16

-- used for quaternion.slerp
constants.DOT_THRESHOLD = 0.9995

return constants
