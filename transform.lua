Class = require 'pl.class'

local lovr = lovr
local newVec3 = lovr.math.newVec3
local newQuat = lovr.math.newQuat

local vec3 = lovr.math.vec3
local mat4 = lovr.math.mat4
local quat = lovr.math.quat

local EntityCounter = 0
function NewEntityIdentifier()
    EntityCounter = EntityCounter + 1
    return EntityCounter
end

Transform = Class.Transform()
function Transform:_init(position, rotation, scale, space)
    if type(position) == "table" and position._name == "Transform" then
        space = position.space
        scale = position._scale
        rotation = position._rotation
        position = position._position
    elseif type(rotation) == "table" and rotation._name == "Transform" then
        space = rotation
        rotation = nil
    elseif type(scale) == "table" and scale._name == "Transform" then
        space = scale
        scale = nil
    end
    self._scale = newVec3(scale or vec3(1,1,1))
    self._position = newVec3(position)
    self._rotation = newQuat(rotation)
    self.space = space -- nil means world space
end

--- Rotates the Transform by `a` radians on the `x`, `y`, `z` axis
function Transform:rotate(a, x, y, z)
    self._rotation:mul(quat(a,x,y,z))
end

--- Moves the Transform by `x, y, z`
function Transform:translate(x, y, z)
    self._position:add(vec3(x,y,z))
end

--- Returns or sets the position
function Transform:position(newValue)
    if newValue then 
        self._position:set(newValue)
    end
    return vec3(self._position)
end

--- Returns or sets the rotation
function Transform:rotation(newValue)
    if newValue then 
        self._rotation:set(newValue)
    end
    return quat(self._rotation)
end

--- Returns or sets the scale
function Transform:scale(newValue)
    if newValue then 
        self._scale:set(newValue)
    end
    return vec3(self._scale)
end

--- Returns a direction vector pointing forward
function Transform:forward()
    -- -z
    return self._rotation:mul(vec3(0, 0, -1))
end

--- Returns a direction vector pointing up
function Transform:up()
    -- y
    return self._rotation:mul(vec3(0,1,0))
end

--- Returns a direction vector pointing right
function Transform:right()
    -- x
    return self._rotation:mul(vec3(1,0,0))
end

--- Return the `lovr.math.mat4` for this Transform
function Transform:mat4()
    local mat = mat4()
    mat:scale(self:scale())
    mat:translate(self:position())
    mat:rotate(self:rotation())
    return mat
end


--- Returns the pose on the `x, y, z, a, ax, ay, ax` format
function Transform:pose()
    local x,y,z = self:position():unpack()
    local a, ax, ay, az = self:rotation():unpack()
    return x, y, z, a, ax, ay, az
end

--- Return self as local to the world space
-- If self.space is nil then a copy of self is returned
function Transform:toWorld()
    if self.space then
        local parent = self.space:toWorld():mat4()
        return Transform(
            parent:mul(self:position()),
            quat(parent):mul(self:rotation()),
            parent:mul(self:scale())
        )
        -- local parent = self.space:toWorld()
        -- return Transform(
        --     parent:position():add(parent:rotation():mul(self:position())),
        --     parent:rotation():mul(self:rotation())
        -- )
    else
        return Transform(self)
    end
end

--- Return a self as local to `parentSpace`
-- If parentSpace is nil then `toWorld()` is returned
function Transform:toLocal(parentSpace)
    -- if parentSpace == nil is same as toWorldSpace
    if parentSpace == nil then
        return self:toWorld()
    end
    -- get parentspace in world space
    local parent = parentSpace:toWorld():mat4():invert()
    -- get ourself into world space
    local world = self:toWorld()
    -- get ourselves local to parent
    return Transform(
        -- position is the vector between parent and us
        parent:mul(world:position()),
        -- rotation is the difference between our and parents world rotation
        quat(parent):mul(world:rotation()),
        -- scale, how does that work?
        parent:mul(world:scale()),
        -- set the space
        parentSpace
    )
end

--- Set pose to `transform`
-- Converts between spaces automatically
function Transform:set(transform)
    -- if the new transform is in the same space as ours then we are all right
    if self.space == transform.space then 
        self._position:set(transform:position())
        self._rotation:set(transform:rotation())
        self._scale:set(transform:scale())
    else
        -- otherwise we convert the new transform to our parent space
        local t = transform:toLocal(self.space)
        self._position:set(t:position())
        self._rotation:set(t:rotation())
        self._scale:set(t:scale())
    end
end

--- Rotate self so that its forward direction points towards transform
function Transform:lookAt(transform)
    assert(transform)
    -- use our space
    local from = self
    local to = transform:toLocal(self.space)
    -- use the mat4 lookat method
    local m = mat4():lookAt(from:position(), to:position(), from:up())
    local t = Transform(vec3(m), quat(m), self:scale(), self.space)
    self:set(t)

    -- -- use our space
    -- local from = self:toWorld()
    -- local to = transform:toWorld()
    -- -- use the mat4 lookat method
    -- local m = mat4():lookAt(from:position(), to:position(), from:up())
    -- local t = Transform(vec3(m), quat(m))
    -- self:set(t)
end



function some_test_code()
    local f = Transform(vec3(3,4, 5), quat(math.pi/4*0, 0, 0, 1))
    local g = Transform(vec3(10,10, 10), quat(math.pi/4*0, 0, 0, 1))
    local q = Transform(vec3(1, 1, 0), quat(math.pi/4, 0, 0, 1), f)
    local w = Transform(vec3(1, 2, 0), quat(math.pi/4, 0, 0, 1), q)
    print("Q", formatTransform(q))
    print("Q:w", formatTransform(q:toWorld()))
    print("Q:w:l", formatTransform(q:toWorld():toLocal(q.space)))

    print("W", formatTransform(w))
    print("W:w", formatTransform(w:toWorld()))
    print("W:w:l", formatTransform(q:toWorld():toLocal(w.space)))

    print("Q:w", formatTransform(q:toWorld()))
    print("Q:g:w", formatTransform(q:toLocal(g):toWorld()))
    print("Q:g:f:w", formatTransform(q:toLocal(g):toLocal(f):toWorld()))
    print("Q:f:w", formatTransform(q:toLocal(f):toWorld()))
    print("Q:w", formatTransform(q:toWorld()))
    -- local a = Transform(vec3(1, 0, 0))
    -- print("pos", formatVec3(a:position()))
    -- print("fwd", formatVec3(a:forward()))
    -- print(" up", formatVec3(a:up()))
    -- print("rgt", formatVec3(a:right()))
    -- print()

    -- local a = Transform(vec3(1,1,1), quat(1, 0, 1, 0))
    -- local b = Transform(vec3(2,2,2), quat(1, 0, 1, 0))
    -- b.space = a
    -- pp(b:toWorld())
    -- b:set(Transform(vec3(5,5,5)))
    -- print(b.rotation:unpack())
end

return Transform