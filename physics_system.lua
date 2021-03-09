

local physics = require'physics_helper'
PhysicsSystem = Class.PhysicsSystem(System)
function PhysicsSystem:_init()
    self:super({"physics", "transform"})
    self.world = physics.new({gravity = -9, tags = {"wheel", "car"}})
    self.world.world:disableCollisionBetween("wheel", "car")
    self.colliders = {}
end

function PhysicsSystem:update(entities, deltaTime)
    for _, entity in ipairs(entities) do
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
    end

    self.world:update(deltaTime)

    for _, entity in ipairs(entities) do
        local colliders = self.colliders[entity.id]
        for _, collider in ipairs(colliders) do
            local x, y, z = collider:getPosition()
            local a, ax, ay, az = collider:getOrientation()
            entity.transform.position = { x, y, z }
            entity.transform.rotation = { a, ax, ay, az }
        end
    end
end

function PhysicsSystem:draw()
    self.world:draw(true)
end
