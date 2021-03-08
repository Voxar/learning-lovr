local m = {}   -- helpers for lovr.physics module
m.__index = m

local solids = require'solids'

local sphere = solids.sphere(1)
solids.updateNormals(sphere)

-- expose functions so that module can completely replace lovr.physics
m.newBoxShape = lovr.physics.newBoxShape
m.newCapsuleShape = lovr.physics.newCapsuleShape
m.newCylinderShape = lovr.physics.newCylinderShape
m.newSphereShape = lovr.physics.newSphereShape
m.newBallJoint = lovr.physics.newBallJoint -- pins objects at anchor, allows rotation
m.newDistanceJoint = lovr.physics.newDistanceJoint -- constrains distance between anchors, allows rotation around anchors
m.newHingeJoint = lovr.physics.newHingeJoint -- constrains distance, constrains rotation to hinge axis
m.newSliderJoint = lovr.physics.newSliderJoint -- constrains rotation, constrains relative movement to 1 axis

function m.new(config)
  config = config or {}
  local gravity = config.gravity or 2
  local sleepingAllowed = config.sleepingAllowed or false
  local self = setmetatable({}, m)
  self.__index = self
  self.world = lovr.physics.newWorld(0, gravity, 0, sleepingAllowed, config.tags)
  self.world:setLinearDamping(config.linearDamping or 0.02, 0)
  self.world:setAngularDamping(config.angularDamping or 0.02, 0)
  m.instance = self
  return self
end


function m:registerCollisionCallback(collider, callback)
  m.collisionCallbacks = m.collisionCallbacks or {}
  for _, shape in ipairs(collider:getShapes()) do
    m.collisionCallbacks[shape] = callback
  end
  -- will be called with callback(otherCollider, world)
end


function m:update(dt)
  if not m.collisionCallbacks then
    self.world:update(1 / 72)
  else
    -- override collision resolver to alert registered colliders with callbacks
    self.world:update(1 / 72, function(world)
      world:computeOverlaps()
      for shapeA, shapeB in world:overlaps() do
        local areColliding = world:collide(shapeA, shapeB)
        if areColliding then
          cbA = m.collisionCallbacks[shapeA]
          if cbA then cbA(shapeB:getCollider(), world) end
          cbB = m.collisionCallbacks[shapeB]
          if cbB then cbB(shapeA:getCollider(), world) end
        end
      end
    end)
  end
end


-- convenience access to all collider setters via table entries
function setPhysicalProperties(collider, config)
  local parameterMap = {
    position        = collider.setPosition,
    orientation     = collider.setOrientation,
    restitution     = collider.setRestitution,
    friction        = collider.setFriction,
    linearDamping   = collider.setLinearDamping,
    angularDamping  = collider.setAngularDamping,
    kinematic       = collider.setKinematic,
    sleepingAllowed = collider.setSleepingAllowed,
    gravityIgnored  = collider.setGravityIgnored,
    tag             = collider.setTag,
  }
  for key,value in pairs(config) do
    if parameterMap[key] then
      parameterMap[key](collider, value)
    end
  end
  local totalMass = 0
  for _, shape in ipairs(collider:getShapes()) do
    if config.sensor then
      shape:setSensor(true)
    end
    local cx, cy, cz, mass, inertia = shape:getMass(config.density)
    totalMass = totalMass + mass
  end
  if totalMass > 0 and not config.kinematic then
    collider:setMass(totalMass)
  end
end


function m:box(config)
  config = config or {}
  config.density = config.density or 1000
  local x,y,z, sx,sy,sz, angle,ax,ay,az = 0,0,0, 1,1,1, 0,0,1,0
  if config.pose then
    x,y,z, sx,sy,sz, angle,ax,ay,az = config.pose:unpack()
  end
  if config.size then
    sx,sy,sz = config.size:unpack()
  end
  local c = self.world:newBoxCollider(x, y, z, sx, sy, sz)
  c:setOrientation(angle, ax, ay, az)
  setPhysicalProperties(c, config)
  c:setUserData(config)
  return c
end


function m:sphere(config)
  config = config or {}
  config.density = config.density or 1000
  local x,y,z,   sx,sy,sz,  angle,ax,ay,az = 0,0,0, 1,1,1, 0, 0,1,0
  if config.pose then
    x,y,z,   sx,sy,sz,  angle,  ax,ay,az = config.pose:unpack()
  end
  if config.size then
    sx,sy,sz = config.size:unpack()
  end
  local r = config.radius or math.sqrt(sx^2 + sy^2 + sz^2) / 2
  local c = self.world:newSphereCollider(x, y, z, r)
  setPhysicalProperties(c, config)
  c:setUserData(config)
  return c
end


function m:cylinder(config)
  config = config or {}
  config.density = config.density or 1000
  local x,y,z,   sx,sy,sz,  angle,ax,ay,az = 0,0,0, 1,1,1, 0, 0,1,0
  if config.pose then
    x,y,z,   sx,sy,sz,  angle,  ax,ay,az = config.pose:unpack()
  end
  if config.size then
    sx,sy,sz = config.size:unpack()
  end
  local r = config.radius or math.sqrt(sx^2 + sz^2) / 2
  local length = config.length or sy
  local c = self.world:newCylinderCollider(x, y, z, r, length)
  c:setOrientation(angle, ax, ay, az)
  setPhysicalProperties(c, config)
  c:setUserData(config)
  return c
end


function m:capsule(config)
  config = config or {}
  config.density = config.density or 1000
  local x,y,z,   sx,sy,sz,  angle,ax,ay,az = 0,0,0, 1,1,1, 0, 0,1,0
  if config.pose then
    x,y,z,   sx,sy,sz,  angle,  ax,ay,az = config.pose:unpack()
  end
  if config.size then
    sx,sy,sz = config.size:unpack()
  end
  local r = config.radius or math.sqrt(sx^2 + sz^2) / 2
  local length = config.length or sy
  local c = self.world:newCapsuleCollider(x, y, z, r, length)
  c:setOrientation(angle, ax, ay, az)
  setPhysicalProperties(c, config)
  c:setUserData(config)
  return c
end


function m:mesh(config, vertices, indices)
  config = config or {}
  config.density = config.density or 1000
  local x,y,z, angle,ax,ay,az = 0,0,0, 0,0,1,0
  if config.pose then
    x,y,z, _,_,_, angle,ax,ay,az = config.pose:unpack()
  end
  local c = self.world:newMeshCollider(vertices, indices or {})
  c:setPosition(-x,-y,-z)
  c:setOrientation(angle, ax, ay, az)
  setPhysicalProperties(c, config)
  c:setUserData(config)
  local mesh = lovr.graphics.newMesh(vertices, 'triangles', 'static', true)
  mesh:setVertexMap(indices)
  config.mesh = mesh
  return c
end


function m:raycast(transform, minDistance, maxDistance)
  minDistance, maxDistance = minDistance or 0, maxDistance or 50
  local ox, oy, oz = transform:unpack(false)
  local tx, ty, tz = transform:mul(v3(0, 0, -maxDistance)):unpack()
  local origin = v3(ox, oy, oz)
  local hits = {}
  self.world:raycast(ox, oy, oz, tx, ty, tz,
    function(shape, hx, hy, hz, nx, ny, nz)
      local position = v3(hx, hy, hz)
      local distance = (origin - position):length()
      if distance > minDistance then
        local normal = v3(nx, ny, nz)
        local collider = shape:getCollider()
        table.insert(hits, {collider= collider, shape= shape, position= position, normal= normal, distance= distance})
      end
    end)
  table.sort(hits, function(a,b) return a.distance < b.distance end)
  return hits
end


function m:draw(drawJoints)
  lovr.math.setRandomSeed(0) -- use random colors, but always same for same objects
  for i, collider in ipairs(self.world:getColliders()) do
    self:drawCollider(collider)
    if drawJoints then
      drawAttachedJoints(collider)
    end
  end
end


function m:drawCollider(collider)
  local userData = collider:getUserData()
  if userData and userData.draw then
    lovr.graphics.push()
    lovr.graphics.transform(mat4(collider:getPose()))
    userData.draw(userData)
    lovr.graphics.pop()
    return
  end
  -- color
  if userData and userData.color then
    lovr.graphics.setColor(userData.color)
  else
    local shade = 0.4 + 0.4 * lovr.math.random()
    lovr.graphics.setColor(shade, shade, shade)
  end
  local shape = collider:getShapes()[1]
  if false and shape:isSensor() then
    local r,g,b = lovr.graphics.getColor()
    lovr.graphics.setColor(r,g,b,0.8)
  end
  if userData and userData.mesh then
    local shape = collider:getShapes()[1]
    local pose = mat4(collider:getPose()):translate(shape:getPosition()):rotate(shape:getOrientation())
    if userData.size then
      pose:scale(userData.size:unpack())
    end
    lovr.graphics.setColor(userData.color)
    userData.mesh:draw(pose)    
    return
  end
  -- shapes
  for _, shape in ipairs(collider:getShapes()) do
    local shapeType = shape:getType()
    --local x,y,z, angle, ax,ay,az = collider:getPose()
    local pose = mat4(collider:getPose()):translate(shape:getPosition()):rotate(shape:getOrientation())
    local x,y,z, _,_,_, angle, ax,ay,az = pose:unpack()
    -- draw primitive at collider's position with correct dimensions
    if shapeType == 'box' and shape then
      local sx, sy, sz = shape:getDimensions()
      lovr.graphics.box('fill', x,y,z, sx,sy,sz, angle, ax,ay,az)
    elseif shapeType == 'sphere' then
      local d = shape:getRadius() * 2
      sphere:draw(x,y,z, d,d,d, angle, ax,ay,az)
      --lovr.graphics.sphere(x,y,z, shape:getRadius(), angle, ax,ay,az)
    elseif shapeType == 'cylinder' then
      local l, r = shape:getLength(), shape:getRadius()
      --local x,y,z, angle, ax,ay,az = collider:getPose()
      lovr.graphics.cylinder(x,y,z, l, angle, ax,ay,az, r, r, true, 10)
    elseif shapeType == 'capsule' then
      local l, r = shape:getLength(), shape:getRadius()
      --local x,y,z, angle, ax,ay,az = collider:getPose()
      local m = mat4(x,y,z, 1,1,1, angle, ax,ay,az)
      lovr.graphics.cylinder(x,y,z, l, angle, ax,ay,az, r, r, false)
      lovr.graphics.sphere(vec3(m:mul(0, 0,  l/2)), r)
      lovr.graphics.sphere(vec3(m:mul(0, 0, -l/2)), r)
    end
  end
end


local function drawAnchor(origin)
  lovr.graphics.sphere(origin, .02)
end


local function drawAxis(origin, axis)
  lovr.graphics.line(origin, origin + axis)
end

function drawAttachedJoints(collider)
  lovr.graphics.setColor(1,1,1,0.3)
  -- joints are attached to two colliders; function draws joint for second collider
  for j, joint in ipairs(collider:getJoints()) do
    local anchoring, attached = joint:getColliders()
    if attached == collider then
      jointType = joint:getType()
      if jointType == 'ball' then
        local x1, y1, z1, x2, y2, z2 = joint:getAnchors()
        drawAnchor(vec3(x1,y1,z1))
        drawAnchor(vec3(x2,y2,z2))
      elseif jointType == 'slider' then
        local position = joint:getPosition()
        local x,y,z = anchoring:getPosition()
        drawAxis(vec3(x,y,z), vec3(joint:getAxis()))
      elseif jointType == 'distance' then
        local x1, y1, z1, x2, y2, z2 = joint:getAnchors()
        --drawAnchor(vec3(x1,y1,z1))
        --drawAnchor(vec3(x2,y2,z2))
        drawAxis(vec3(x2,y2,z2), vec3(x1, y1, z1) - vec3(x2,y2,z2))
      elseif jointType == 'hinge' then
        local x1, y1, z1, x2, y2, z2 = joint:getAnchors()
        drawAnchor(vec3(x1,y1,z1))
        drawAnchor(vec3(x2,y2,z2))
        drawAxis(vec3(x1,y1,z1), vec3(joint:getAxis()))
      end
    end
  end
end


return m
