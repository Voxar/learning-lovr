local physics = require "physics"
package.path = "lib/share/lua/5.4/?.lua;" ..
    "lib/share/lua/5.4/?/init.lua;" ..
    "imgui2/lua/?.lua;" ..
    package.path
Class = require 'pl.class'
pp = require'pl.pretty'.dump
tablex = require'pl.tablex'
Transform = require 'transform'

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


local Cube = {
    id = NewEntityIdentifier(),
    transform = {
        position = {0, 0, -3},
        rotation = {math.pi/2, 1, 0, 0}
    },
    render = {
        color = newVec4(1, 0, 0, 1),
        draw = function(self)
            lovr.graphics.setColor(self.color:unpack())
            lovr.graphics.cube("line")
        end,
    },
    -- speed = {
    --     movementSpeed = newVec3(0.1, 0, 1),
    --     rotationSpeed = newQuat(1, 0, 1, 0),
    -- },
    keyboard = {
        x = {
            down = { physics = { torque = {0, 0, 20} } },
            up = { physics = { torque = {0,0,0} } }
        },
        z = {
            down = { physics = { torque = {0, 0, -20} } },
            up = { physics = { torque = {0,0,0} } }
        },
    },
    physics = {
        friction = 10000000,
        shapes = {
            {
                type = "box",
                position = { 0, 0.4, 0 },
                size = { 0.4, 0.2, 0.2 },
                rotation = { 0, 1, 0, 0 },
            },
            {
                type = "sphere",
                radius = 0.3,
            },
            {
                type = "capsule",
                radius = 0.2,
                length = 1
            },
            {
                type = "cylinder",
                radius = 0.2,
                length = 1.4,
                rotation = { 3.14/2, 0, 1, 0},
            }
        },--shapes
    },
}

local Floor = {
    id = NewEntityIdentifier(),
    transform = {
        position = {0, -1, 0}
    },
    physics = {
        friction = 10000000,
        shapes = {
            {
                type = "box",
                size = {30, 0.1, 30},
            }
        },
        static = true,
        ignoresGravity = true,
    }
}

local Sphere = {
    id = NewEntityIdentifier(),
    transform = {
        position = { 0.6, 0, 0.9 }
    },
    render = {
        color = newVec4(0, 2, 0, 1),
        draw = function(self)
            lovr.graphics.setColor(self.color:unpack())
            lovr.graphics.sphere(0,0,0,0.1)
        end,
    },
    parent = Cube.id,
    physics = {
        type="sphere",
        radius = 0.2
    }
}

local Sphere2 = {
    id = NewEntityIdentifier(),
    transform = {
        position = {0, 2, 0}
    },
    render = {
        color = newVec4(0, 0, 1, 1),
        draw = function(self)
            lovr.graphics.setColor(self.color:unpack())
            lovr.graphics.sphere(0,0,0,0.1)
        end,
    },
    -- parent = Cube.id,
    physics = {
        type="sphere",
        radius = 0.2
    }
}


local car_body = {
    id = 'car_body',
    transform = {
        position = {0, 3, 0},   
    },
    physics = {
        id = "car_body",
        type = "box",
        size = {3.5, 0.5, 1.5},
        static = false,
        ignoresGravity = false,
        tags = {"car"}
    }
}

local steering = {
    id = 'steering',
    transform = {
        position = { -1.2, 2.6, 0}
    },
    physics = {
        type = "box",
        size = {0.2, 0.2, 2},
        joints = {
            {
                type = "hinge",
                from = "car_body",
                axis = {0, 1, 0},
                limits = { -0.35, 0.35 }
            }
        }
    },
    keyboard = {
        c = {
            down = { physics = { torque = { 0, 50, 0 } } },
            up = { physics = { torque = { 0, 0, 0 } } },
        },
        v = {
            down = { physics = { torque = { 0, -50, 0 } } },
            up = { physics = { torque = { 0, 0, 0 } } },
        }
    }
}


function makeWheel(position, steers)
    return {
        id = "wheel" .. NewEntityIdentifier(),
        transform = {
            position = position,
        },
        physics = {
            type = "cylinder",
            radius = 0.5,
            length = 0.1,
            static = false,
            ignoresGravity = false,
            joints = {
                {
                    type = "hinge",
                    from = steers and 'steering' or 'car_body',
                    axis = {0, 0, 1},
                }
            },
            tags = {"wheel"}
        },
        keyboard = {
            x = {
                down = { physics = { torque = {0, 0, 20} } },
                up = { physics = { torque = {0,0,0} } }
            },
            z = {
                down = { physics = { torque = {0, 0, -20} } },
                up = { physics = { torque = {0,0,0} } }
            },
        },
    }
end

local entities = {
    -- Cube,
    -- Sphere,
    -- Sphere2,
    Floor,
    car_body,
    steering, 
    makeWheel({-1.2, 2.5, 1.1}, true),
    makeWheel({-1.2, 2.5, -1.1}, true),
    makeWheel({1.2, 2.9, 1.1}),
    makeWheel({1.2, 2.9, -1.1}),

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
    self.world = physics.new({gravity = -9, tags = {"wheel", "car"}})
    self.world.world:disableCollisionBetween("wheel", "car")
    self.colliders = {}
end

function Physics:update(deltaTime)
    system({"physics", "transform"}, function(entity)
        local colliders = self.colliders[entity.id]
        if not colliders then
            colliders = {}
            for _, colliderSpec in ipairs(entity.physics.colliders or {entity.physics}) do
                local collider
                assert(next(colliderSpec) ~= nil, "No colliders specified")
                collider = self.world.world:newCollider(table.unpack(colliderSpec.position or {}))
                for i, shapeSpec in ipairs(colliderSpec.shapes or {colliderSpec}) do
                    local shape
                    if shapeSpec.type == "sphere" then
                        shape = lovr.physics.newSphereShape()
                    elseif shapeSpec.type == "box" then
                        shape = lovr.physics.newBoxShape()
                    elseif shapeSpec.type == "capsule" then
                        shape = lovr.physics.newCapsuleShape()
                    elseif shapeSpec.type == "cylinder" then
                        shape = lovr.physics.newCylinderShape()
                    else
                        assert("Invalid shape type")
                    end

                    collider:addShape(shape)
                    if shapeSpec.radius then shape:setRadius(shapeSpec.radius) end
                    if shapeSpec.length then shape:setLength(shapeSpec.length) end
                    if shapeSpec.size then shape:setDimensions(table.unpack(shapeSpec.size)) end
                    shape:setPosition(table.unpack(shapeSpec.position or {}))
                    shape:setOrientation(table.unpack(shapeSpec.rotation or {}))
                end --shapes
                collider:setKinematic(entity.physics.static)
                collider:setGravityIgnored(entity.physics.ignoresGravity)
                if entity.transform.position then collider:setPosition(table.unpack(entity.transform.position)) end
                if entity.transform.rotation then collider:setOrientation(table.unpack(entity.transform.rotation)) end
                if colliderSpec.friction then collider:setFriction(colliderSpec.friction) end
                table.insert(colliders, collider)
                if colliderSpec.tag then collider:setTag(colliderSpec.tag) end
                if colliderSpec.joints then 
                    for _, jointSpec in ipairs(colliderSpec.joints) do
                        local joint
                        local other = self.colliders[jointSpec.from][1]
                        assert(other)
                        if jointSpec.type == "hinge" then
                            local x, y, z = collider:getPosition()
                            local ax, ay, az = table.unpack(jointSpec.axis)
                            joint = physics.newHingeJoint(other, collider, x, y, z, ax, ay, az)
                            if jointSpec.limits then 
                                joint:setLimits(table.unpack(jointSpec.limits))
                            end
                        end
                    end
                end
            end --colliderSpecs

            

            self.colliders[entity.id] = colliders
        end

        for _, collider in ipairs(colliders) do
            local t = entity.transform
            if t.position then collider:setPosition(table.unpack(t.position)) end
            if t.rotation then collider:setOrientation(table.unpack(t.rotation)) end
            if entity.physics.torque then
                local rot = quat(collider:getOrientation())
                local adjusted = rot:mul(vec3(table.unpack(entity.physics.torque)))
                collider:applyTorque(adjusted)
            end
        end
    end)

    self.world:update(deltaTime)

    system({"physics"}, function(entity)
        local colliders = self.colliders[entity.id]
        for _, collider in ipairs(colliders) do
            local x, y, z = collider:getPosition()
            local a, ax, ay, az = collider:getOrientation()
            entity.transform.position = { x, y, z }
            entity.transform.rotation = { a, ax, ay, az }
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
    -- Set up transform to parent links
    system({"parent", "transform"}, function (entity)
        local parent = entities:withId(entity.parent)
        entity.transform.space = parent.transform
    end)

    -- Move things that needs to move
    system({"speed", "transform"}, function(entity)
        if entity.speed.movementSpeed then 
            local speed = vec3(entity.speed.movementSpeed):mul(deltaTime)
            -- entity.transform:position():add(speed)
        end

        if entity.speed.rotationSpeed then 
            local a, x, y, z = quat(entity.speed.rotationSpeed):unpack()
            entity.transform:rotate(a*deltaTime, x, y, z)
        end
    end)

    systems.physics:update(deltaTime)

    for i, entity in ipairs(entities:withComponents({"transform"})) do
        -- entity.transform.position.x = entity.transform.position.x + 1 * deltaTime
    end
end


local function drawAxis(transform)
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

local function drawBox(t, size, style)
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

    local a = Transform(vec3(0,0,0))
    -- a:scale(vec3(2, 2, 2))
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


    systems.physics:draw(true)

    -- Draw everything
    system({"render", "transform"}, function(entity)
        -- pp(entity)
        local x, y, z = table.unpack(entity.transform.position or {})
        local a, ax, ay, az = table.unpack(entity.transform.rotation or {})
        local pose = mat4(x, y, z, a, ax, ay, az)
        lovr.graphics.push()
        if pose then 
            lovr.graphics.transform(pose)
        end
        entity.render:draw()
        lovr.graphics.pop()
        drawAxis(Transform(vec3(x, y, z), quat(a, ax, ay, az)))
    end)
end



local function merge(t, u)
    if t == nil or u == nil then return end
    for key, _ in pairs(u) do
        local left = t[key]
        local right = u[key]
        if type(left) == "table" and type(right) == "table" then
            merge(left, right)
        else
            if type(u[key]) == "table" then 
                t[key] = tablex.deepcopy(u[key])
            else
                t[key] = u[key]
            end
        end
    end
end


function lovr.keypressed(key, code, repeated)
    if repeated then return end
print(key)
    system({"keyboard"}, function(entity)
        local state = entity.keyboard[key]
        if state then
            state.pressed = true
            merge(entity, state.down)
            pp(state)
        end
    end)
end

function lovr.keyreleased(key, code)
    system({"keyboard"}, function(entity)
        local state = entity.keyboard[key]
        if state then
            state.pressed = false
            merge(entity, state.up)
        end
    end)
end

