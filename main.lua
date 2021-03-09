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


local Obstacle = {
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
        position = { 4.6, 5, 0.9 }
    },
    physics = {
        type="sphere",
        radius = 2
    }
}

local Sphere2 = {
    id = NewEntityIdentifier(),
    transform = {
        position = {0, 2, 4}
    },
    -- parent = Cube.id,
    physics = {
        type="sphere",
        radius = 0.6
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

local ECS = require 'ecs'
local ecs = ECS({
    Obstacle,
    Sphere,
    Sphere2,
    Floor,
    car_body,
    steering, 
    makeWheel({-1.2, 2.5, 1.1}, true),
    makeWheel({-1.2, 2.5, -1.1}, true),
    makeWheel({1.2, 2.9, 1.1}),
    makeWheel({1.2, 2.9, -1.1}),
})

require('physics_system')
ecs:addSystem(PhysicsSystem())

-- Draw everything
ecs:system({"render", "transform"}, nil, function(entity)
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

-- Move things that needs to move
ecs:system({"speed", "transform"}, function(entity, deltaTime)
    if entity.speed.movementSpeed then 
        local speed = vec3(entity.speed.movementSpeed):mul(deltaTime)
        -- entity.transform:position():add(speed)
    end

    if entity.speed.rotationSpeed then 
        local a, x, y, z = quat(entity.speed.rotationSpeed):unpack()
        entity.transform:rotate(a*deltaTime, x, y, z)
    end
end)

function lovr.update(deltaTime)
    ecs:update(deltaTime)
end


local time = 0
function lovr.draw()
    local deltaTime = 1/60
    time = time + deltaTime

    lovr.graphics.setCullingEnabled(false)
    lovr.graphics.setBackgroundColor(.58, .58, .60)


    -- Get viewport 1
    local m = mat4()
    lovr.graphics.getViewPose(1, m, false)
    local camera1 = Transform()
    camera1:position(m)
    camera1:rotation(m)

    -- set a custom camera for viewport 2
    local camera2 = Transform(vec3(0, 25, 0))
    camera2:rotation(quat(-math.pi/2, 1, 0, 0))
    lovr.graphics.setViewPose(2, camera2:toWorld():mat4(), false)


    -- Draw gizmos at the camera locations
    drawAxis(camera1)
    drawAxis(camera2)

    -- draw all entities
    ecs:draw()
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

local savedState = tablex.deepcopy(ecs.entities)

function lovr.keypressed(key, code, repeated)
    if repeated then return end
    if key == "k" then 
        savedState = tablex.deepcopy(ecs.entities)
    end
    if key == "l" then 
        ecs.entities = tablex.deepcopy(savedState)
    end
    ecs:system({"keyboard"}, function(entity)
        local state = entity.keyboard[key]
        if state then
            state.pressed = true
            merge(entity, state.down)
            pp(state)
        end
    end)
end

function lovr.keyreleased(key, code)
    ecs:system({"keyboard"}, function(entity)
        local state = entity.keyboard[key]
        if state then
            state.pressed = false
            merge(entity, state.up)
        end
    end)
end

