package.path = "lib/share/lua/5.4/?.lua;" ..
    "lib/share/lua/5.4/?/init.lua;" ..
    "imgui2/lua/?.lua;" ..
    package.path
Class = require 'pl.class'
pp = require'pl.pretty'.dump


local lovr = lovr
local newVec3 = lovr.math.newVec3
local newVec4 = lovr.math.newVec4
local newQuat = lovr.math.newQuat
local newMat4 = lovr.math.newMat4

local vec3 = lovr.math.vec3
local mat4 = lovr.math.mat4
local quat = lovr.math.quat

local EntityCounter = 0
function NewEntityIdentifier()
    EntityCounter = EntityCounter + 1
    return EntityCounter
end

Transform = Class.Transform()
function Transform:_init(position, rotation, space)
    if type(position) == "table" and position._name == "Transform" then
        space = position.space
        rotation = quat(position._rotation)
        position = newVec3(position._position)
    end
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
            quat(parent):mul(self:rotation())
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
    else
        -- otherwise we convert the new transform to our parent space
        local t = transform:toLocal(self.space)
        self._position:set(t:position())
        self._rotation:set(t:rotation())
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
    local t = Transform(vec3(m), quat(m), self.space)
    self:set(t)

    -- -- use our space
    -- local from = self:toWorld()
    -- local to = transform:toWorld()
    -- -- use the mat4 lookat method
    -- local m = mat4():lookAt(from:position(), to:position(), from:up())
    -- local t = Transform(vec3(m), quat(m))
    -- self:set(t)
end


function printMat4(m)
    local m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15, m16 = m:unpack(true)
    print(string.format("%.1f\t%.1f\t%.1f\t%.1f", m1, m2, m3, m4))
    print(string.format("%.1f\t%.1f\t%.1f\t%.1f", m5, m6, m7, m8))
    print(string.format("%.1f\t%.1f\t%.1f\t%.1f", m9, m10, m11, m12))
    print(string.format("%.1f\t%.1f\t%.1f\t%.1f", m13, m14, m15, m16))
end

function formatVec3(v)
    return string.format("%.1f\t%.1f\t%.1f", v.x, v.y, v.z)
end

function formatQuat(v)
    return string.format("%.1f\t%.1f\t%.1f\t%.1f", v.x, v.y, v.z, v.w)
end

function formatTransform(t)
    return string.format("%s, %s", formatVec3(t:position()), formatQuat(t:rotation()))
end

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

local Cube = {
    id = NewEntityIdentifier(),
    transform = Transform(vec3(0, 0, -3)),
    render = {
        color = newVec4(1, 0, 0, 1),
        draw = function(self)
            lovr.graphics.setColor(self.color:unpack())
            lovr.graphics.cube("line")
        end,
    },
    speed = {
        movementSpeed = newVec3(0.1, 0, 1),
        rotationSpeed = newQuat(1, 0, 1, 0),
    },
    physics = {

    },
}

local Sphere = {
    id = NewEntityIdentifier(),
    transform = Transform(vec3(0, 0, 1)),
    render = {
        color = newVec4(0, 1, 0, 1),
        draw = function(self)
            lovr.graphics.setColor(self.color:unpack())
            lovr.graphics.sphere(0,0,0,0.1)
        end,
    },
    parent = Cube.id,
    physics = {}
}
local Sphere2 = {
    id = NewEntityIdentifier(),
    transform = Transform(vec3(0, 2, 0)),
    render = {
        color = newVec4(0, 0, 1, 1),
        draw = function(self)
            lovr.graphics.setColor(self.color:unpack())
            lovr.graphics.sphere(0,0,0,0.1)
        end,
    },
    -- parent = Cube.id,
    physics = {

    }
}

local entities = {
    Cube,
    Sphere,
    Sphere2,

    withComponents = function(self, components)
        -- todo: iterators!
        local list = {}
        for _, entity in ipairs(self) do
            local has_all = true
            for _, component in ipairs(components) do
                if not entity[component] then
                    has_all = false
                    break
                end
            end
            if has_all then
                table.insert(list, entity)
            end
        end
        return list
    end,
    withId = function(self, id)
        for _, entitiy in ipairs(self) do
            if entitiy.id == id then 
                return entitiy
            end
        end
    end
}


function system(components, f)
    for i, entity in ipairs(entities:withComponents(components)) do
        f(entity)
    end
end

local physics = require'physics'
Physics = Class.PhysicsSystem()
function Physics:_init()
    self.world = physics.new({gravity = -0.2})
    self.colliders = {}
end

function Physics:update(deltaTime)
    system({"physics"}, function(entity)
        local collider = self.colliders[entity.id]
        if not collider then 
            local config = {}
            local r,g,b,a = entity.render and entity.render.color and entity.render.color:unpack()
            if r and g and b and a then 
                config.color = {r,g,b,a}
            end
            collider = self.world:box(config)

            if entity.parent and entity.transform then
                local parent = entities:withId(entity.parent)
                if parent.transform.position and parent.physics and parent.physics.collider then
                    local p = parent.transform.position
                    local m = entity.transform.position
                    -- physics.newDistanceJoint(
                    --     parent.physics.collider, entity.physics.collider,
                    --     p.x, p.y, p.z, m.x, m.y, m.z
                    -- )
                end
            end

            self.colliders[entity.id] = collider
        end

        if entity.transform then
            local p = entity.transform.position

            local parent = entity.parent and entities:withId(entity.parent)
            if parent and parent.transform.position then
                p = vec3(parent.transform.position):add(p)
            end
            collider:setPosition(p.x, p.y, p.z)
        end
        if entity.transform.rotation then
            collider:setOrientation(entity.transform.rotation:unpack())
        end
    end)

    self.world:update(deltaTime)

    system({"physics"}, function(entity)
        local collider = self.colliders[entity.id]
        if entity.transform.position then
            local x, y, z = collider:getPosition()
            entity.transform.position:set(x, y, z)
        end
        if entity.transform.rotation then
            local a, x, y, z = collider:getOrientation()
            entity.transform.rotation:set(a, x, y, z)
        end
    end)
end

function Physics:draw()
    self.world:draw(true)
end


local systems = {
    physics = Physics(),
}

function lovr.update(deltaTime)

    system({"speed", "transform"}, function(entity)
        if entity.speed.movementSpeed then 
            local speed = vec3(entity.speed.movementSpeed):mul(deltaTime)
            -- entity.transform.position:add(speed)
        end

        if entity.speed.rotationSpeed then 
            local a, x, y, z = quat(entity.speed.rotationSpeed):unpack()
            -- entity.transform.rotation:mul(quat(a*deltaTime, x, y, z))
        end
    end)

    -- systems.physics:update(deltaTime)

    system({"parent", "transform"}, function (entity)
        local parent = entities:withId(entity.parent)
        entity.transform.space = parent.transform
    end)

    for i, entity in ipairs(entities:withComponents({"transform"})) do
        -- entity.transform.position.x = entity.transform.position.x + 1 * deltaTime
    end
end


function drawAxis(transform)
    function line(pos, dir)
        local x1, y1, z1 = pos:unpack()
        local x2, y2, z2 = pos:add(dir):unpack()
        lovr.graphics.line(x1, y1, z1, x2, y2, z2)
    end
    lovr.graphics.setColor(1, 0, 0)
    line(transform:position(), transform:right())

    lovr.graphics.setColor(0, 1, 0)
    line(transform:position(), transform:up())

    lovr.graphics.setColor(0, 0, 1)
    line(transform:position(), transform:forward())
end

function drawBox(t, size, style)
    size = size or 0.2
    style = style or "fill"
    local x, y, z, a, ax, ay, az = t:toWorld():pose()
    lovr.graphics.box(style, x, y, z, size, size, size, a, ax, ay, az)
end

local time = 0
function lovr.draw()
    local deltaTime = 1/60
    time = time + deltaTime

    lovr.graphics.setCullingEnabled(false)
    lovr.graphics.setBackgroundColor(.58, .58, .60)

    -- systems.physics:draw(true)

    local a = Transform(vec3(0,0,0))
    local b = Transform(vec3(1,0,0))
    local c = Transform(vec3(1,0,0))
    b.space = a
    c.space = b
    b:rotate(time, 0, 1, 0)

    -- c:rotate(-time*3, 1, 0, 0)

    local d = Transform()
    -- d:translate(1, 1, -1)
    d:translate(0,1,2)
    d.space = b
    d:lookAt(a)

    local camera2 = Transform()

    local camera = Transform(vec3(0, 10, 0))
    camera.space = a
    camera:rotation(quat(-math.pi/2, 1, 0, 0))
    local manualCamera = true
    if manualCamera then 
        -- camera:lookAt(d)
        -- remove the lovr camera positioning

        lovr.graphics.setViewPose(2, camera:toWorld():mat4(), false)
        -- local viewPose = lovr.graphics.getViewPose(1, mat4(), false)
        -- lovr.graphics.transform(viewPose)
        -- -- move camera to follow a transform
        -- lovr.graphics.transform(camera:toWorld():mat4():invert())
    end
    local m = mat4()
    lovr.graphics.getViewPose(1, m, false)
    camera2:position(m)
    camera2:rotation(m)


    -- c:rotate(b:rotation():conjugate())
    -- c:set(Transform(c:position(), quat(), b))
    drawAxis(a:toWorld())
    drawAxis(b:toWorld())
    drawAxis(c:toWorld())
    drawAxis(d:toWorld())
    drawAxis(camera:toWorld())
    drawAxis(camera2:toWorld())

    drawBox(d)
    
    -- Draw connections
    lovr.graphics.setColor(1,1,0,1)
    for i, node in ipairs({a, b, c, d}) do
        local root = node
        while root do
            if root.space then 
                local x1, y1, z1 = node.space:toWorld():position():unpack()
                local x2, y2, z2 = node:toWorld():position():unpack()
                lovr.graphics.line(x1, y1, z1, x2, y2, z2)
            end
            root = root.space
        end
    end

    lovr.graphics.setColor(1,1,1,1)
    -- box at player height
    lovr.graphics.cube("line", 0, 1.7, 0)

    -- marks the origin
    lovr.graphics.sphere(0,0,0,0.1)

    local ball = c:toWorld()
    local x, y, z, a, ax, ay, az = ball:pose()
    lovr.graphics.box("fill", x, y, z, 0.2, 0.2, 0.2, a, ax, ay, az)

    -- -- Draw everything
    -- system({"render"}, function(entity)
    --     -- pp(entity)
    --     local pose = entity.transform and entity.transform:worldPose()
    --     lovr.graphics.push()
    --     if pose then 
    --         lovr.graphics.transform(pose)
    --     end
    --     entity.render:draw()
    --     drawAxis(entity.transform)
    --     lovr.graphics.pop()
    -- end)

end


