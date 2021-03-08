local m = {}
local physics

m.anatomy = {
  thumb  = { 6,  5,  4, 3}, -- four bones from fingertip towards palm
  index  = {11, 10,  9, 8},
  middle = {16, 15, 14, 13},
  ring   = {21, 20, 19, 18},
  pinky  = {26, 25, 24, 23},
  palm   = {2, 7, 12, 17},
  wrist  = {1},
  fingers = {'thumb', 'index', 'middle', 'ring', 'pinky'},
  isTip  = {[6] = true, [11] = true, [16] = true, [21] = true, [26] = true},
  size = { -- size of collider representing each bone
    0.065, -- palm
    0.075, -- wrist
    0.050, -- thumb
    0.055,
    0.037,
    0.025,
    0.050, -- thumb mc
    0.045, -- index
    0.035,
    0.027,
    0.025,
    0.050, -- index mc
    0.055, -- middle
    0.035,
    0.030,
    0.027,
    0.050, -- middle mc
    0.050, -- ring
    0.033,
    0.030,
    0.027,
    0.037, -- ring mc
    0.043, -- pinky
    0.027,
    0.025,
    0.020,
  },
  parent = { -- parent bone for each bone
    1,
    1, 2, 3, 4, 5,
    1, 7, 8, 9, 10,
    1, 12, 13, 14, 15,
    1, 17, 18, 19, 20,
  }
}

m.handNames = {'hand/left', 'hand/right'}

m['hand/left'] = {
  otherHand   = nil,
  colliders   = {},
  skeleton    = {},
  tracked     = false,
  initialized = false,
  gripping    = false,
  gripStart   = false,
  gripEnd     = false,
  pinching    = false,
  pinchStart  = false,
  pinchEnd    = false,
}

m['hand/right'] = {
  otherHand   = nil, 
  colliders   = {},
  skeleton    = {},
  tracked     = false,
  initialized = false,
  gripping    = false,
  gripStart   = false,
  gripEnd     = false,
  pinching    = false,
  pinchStart  = false,
  pinchEnd    = false,
}

m['hand/left'].otherHand, m['hand/right'].otherHand = m['hand/right'], m['hand/left']

function m.load(config)
  physics = config.physics
end

function m.createBoneMesh()
  local solids = require'solids'
  local mesh = solids.sphere(1)
  mesh = solids.transform(mesh, mat4(0,0,0, 1, 1, 1,  math.pi/2, 1,0,0))
  for vi = 1, mesh:getVertexCount() do
    local v = {mesh:getVertex(vi)}
    local sx, sy, sz = 1, 1, 1
    sx = 1 + 2 * math.abs(v[3])
    sy = 1 + 2 * math.abs(v[3])
    v[1], v[2], v[3] = sx * v[1], sy * v[2], sz * v[3]
    mesh:setVertex(vi, v)
  end
  solids.updateNormals(mesh)
  return mesh
end


local function constructBoneColliders(handness)
  local boneMesh = m.createBoneMesh()
  local skeleton = m[handness].skeleton
  for bi, bone in ipairs(skeleton) do
    local length = m.anatomy.size[bi]
    local boneCollider = physics:box{
        position = vec3(unpack(bone)),
        size = lovr.math.newVec3(length * 0.5, length * 0.5, length * 0.8),
        mesh = boneMesh,
        restitution = 0,
        friction = 1000,
        outline = 1,
        gravityIgnored = true,
        linearDamping = 0.8,
        angularDamping = 0.4,
        color = 0xffd8a0,
        density = 1 / length^3,
        isHand = true,
      }
    boneCollider:setTag('hands')
    m[handness].colliders[bi] = boneCollider
  end
  m[handness].initialized = true
end


local function syncColliders(dt, handness)
  local force = 50000
  local torque = 3
  local skeleton = m[handness].skeleton
  for bi, collider in ipairs(m[handness].colliders) do
    local bone = skeleton[bi]
    local rw = mat4(unpack(bone))
  local vr = mat4(collider:getPose())
    local angle, ax,ay,az = quat(rw):mul(quat(vr):conjugate()):unpack()
    angle = ((angle + math.pi) % (2 * math.pi) - math.pi) -- for minimal motion wrap to (-pi, +pi) range
    collider:applyForce((vec3(rw:mul(0,0,0)) - vec3(vr:mul(0,0,0))):mul(dt * force))
    collider:applyTorque(vec3(ax, ay, az):mul(dt * angle * torque))
  end
end


local function recreateMetacarpal(handness)
  -- oclulus api is missing possition of metacarpal bones, interpolated here
  local skeleton = m[handness].skeleton
  local wrist = vec3(skeleton[1][1], skeleton[1][2], skeleton[1][3])
  local wristD = quat(skeleton[1][4], skeleton[1][5], skeleton[1][6], skeleton[1][7])
  local proximalD, bone, position
  local positionRatio  = 0.4
  local directionRatio = 0.7
  bone = skeleton[8]
  position = vec3(unpack(bone)):lerp(wrist, positionRatio)
  proximalD = quat(bone[4], bone[5], bone[6], bone[7]):slerp(wristD, directionRatio)
  skeleton[1] =  {position.x,
                  position.y,
                  position.z,
                  proximalD:unpack()
                  }
  bone = skeleton[13]
  position = vec3(unpack(bone)):lerp(wrist, positionRatio)
  proximalD = quat(bone[4], bone[5], bone[6], bone[7]):slerp(wristD, directionRatio)
  skeleton[7] =  {position.x,
                  position.y,
                  position.z,
                  proximalD:unpack()}
  bone = skeleton[18]
  position = vec3(unpack(bone)):lerp(wrist, positionRatio)
  proximalD = quat(bone[4], bone[5], bone[6], bone[7]):slerp(wristD, directionRatio)
  skeleton[12] = {position.x,
                  position.y,
                  position.z,
                  proximalD:unpack()}
  bone = skeleton[23]
  position = vec3(unpack(bone)):lerp(wrist, positionRatio)
  proximalD = quat(bone[4], bone[5], bone[6], bone[7]):slerp(wristD, directionRatio)
  skeleton[17] = {position.x,
                  position.y,
                  position.z,
                  proximalD:unpack()}
end


local function updateGripping(handness)
  local NEAR = 0.02
  local skeleton = m[handness].skeleton
  local middleTip = vec3(unpack( skeleton[m.anatomy.middle[1]] ))
  local wrist     = vec3(unpack( skeleton[m.anatomy.wrist[1]] ))
  local current = #(middleTip - wrist) < NEAR
  m[handness].gripStart = not m[handness].gripping and current
  m[handness].gripEnd   = m[handness].gripping and not current
  m[handness].gripping  = current
end


local function updatePinching(handness)
  local NEAR = 0.01
  local skeleton = m[handness].skeleton
  local indexTip = vec3(unpack( skeleton[m.anatomy.index[1]] ))
  local thumbTip = vec3(unpack( skeleton[m.anatomy.thumb[1]] ))
  local current = #(indexTip - thumbTip) < NEAR
  m[handness].pinchStart = not m[handness].pinching and current
  m[handness].pinchEnd   = m[handness].pinching and (not current)
  m[handness].pinching   = current
end


local function updatePhysics(dt, handness)
  if not m[handness].initialized then constructBoneColliders(handness) end
  syncColliders(dt, handness)
end


function m.update(dt)
  for _, handness in ipairs(lovr.headset.getHands()) do
    m[handness].tracked = true
    local skeleton = lovr.headset.getSkeleton(handness)
    if skeleton then
      m[handness].skeleton = skeleton
      recreateMetacarpal(handness)
      updatePhysics(dt, handness)
      updateGripping(handness)
      updatePinching(handness)
    end
  end
end

function m.setColor(color)
  for _, handness in ipairs(m.handNames) do
    for _, collider in ipairs(m[handness].colliders) do
      local ud = collider:getUserData()
      ud.color = color
      collider:setUserData(ud)
    end
  end
end


return m