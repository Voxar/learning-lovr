Class = require 'pl.class'
pp = require'pl.pretty'.dump
tablex = require'pl.tablex'
Transform = require 'transform'

ECS = Class.ECS()
function ECS:_init(entities)
    self.entities = entities or {}
    self.systems = {}
end

function ECS:withComponents(components)
    -- todo: iterators!
    --todo track entities in component => entitites maps for lookup speeds
    local list = {}
    for _, entity in ipairs(self.entities) do
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
end

function ECS:withId(id)
    --todo also track an id => entity map for id lookup speed
    for _, entitiy in ipairs(self.entities) do
        if entitiy.id == id then 
            return entitiy
        end
    end
end

--- Implement a system by applying a function to each entity that has a component
function ECS:system(components, onUpdate, onDraw)
    -- TODO: threading
    -- Note: must have parenting checks to make sure the parent processes first and on same thread as child
    table.insert(self.systems, System(components, onUpdate, onDraw))
end

function ECS:addSystem(system)
    table.insert(self.systems, system)
end

function ECS:update(deltaTime)
    for _, system in ipairs(self.systems) do
        if system.update then
            assert(system.requiredComponents, "no components in " .. system._name)
            local entities = self:withComponents(system.requiredComponents)
            system:update(entities, deltaTime)
        end
    end
end

function ECS:draw()
    for _, system in ipairs(self.systems) do
        if system.draw then
            assert(system.requiredComponents, "no components in " .. system._name)
            local entities = self:withComponents(system.requiredComponents)
            system:draw(entities)
        end
    end
end


System = Class.System()
function System:_init(components, onUpdate, onDraw)
    assert(components, "no components")
    self.requiredComponents = components
    if onUpdate then
        self.update = function (self, entities, deltaTime)
            for _, entity in ipairs(entities) do
                self.onUpdate(entity, deltaTime)
            end
        end
    end
    if onDraw then
        self.draw = function (self, entities)
            for _, entity in ipairs(entities) do
                self.onDraw(entity)
            end
        end
    end
    self.onUpdate = onUpdate
    self.onDraw = onDraw
end

return ECS