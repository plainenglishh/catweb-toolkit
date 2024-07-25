local actions = require("../cs/actions");

--------------------------------------------------------------------------------
--
--  Document Class
--
--  Represents a document
--
--------------------------------------------------------------------------------

local Document = {};
Document.__index = Document;

function Document.new(name: string)
    local self = setmetatable({}, Document);

    self.name = name;
    self.sections = {};
    self.constants = {};

    return self;
end

function Document:add_section(name: string, section)
    assert(not self.sections[name], `section '{name}' already defined`);
    self.sections[name] = section;
end

function Document:get_section(name: string): Section?
    return self.sections[name];
end

function Document:define_constant(key: string, value: string)
    self.constants[key] = value;
end

function Document:get_constant(key: string)
    return self.constants[key] or error(`constant '{key}' not defined`);
end

function Document:export(id: number?)
    local out = {};

    for _, v in self.sections do
        local section = v:export();
        if section.id >= 0 then
            table.insert(out, section);
        end
    end

    return {
        class = "script",
        content = out,
        alias = self.name or ".asm",
        globalid = string.char(id or 100),
    };
end

--------------------------------------------------------------------------------
--
--  Section Class
--
--  Represents a section
--
--------------------------------------------------------------------------------

local Section = {};
Section.__index = Section;

type SectionTrigger = {
    raw: string,
    type: "none"|"pageload"|"keypress",
    params: {},
};

function Section.trigger_to_id(trigger: SectionTrigger): number
    if trigger.type == "none" then
        return -1;
    elseif trigger.type == "pageload" then
        return 0;
    elseif trigger.type == "keypress" then
        return 2;
    end

    return 0;
end

function Section.new(name: string, trigger: SectionTrigger, parameters: {string}?)
    local self = setmetatable({}, Section);

    self.name = name;
    self.trigger = trigger;
    self.actions = {};
    self.callable = parameters ~= nil;
    self.parameters = parameters;

    return self;
end

function Section:add_action(action: any, position: number?)
    if position then
        table.insert(self.actions, position, action);
    else
        table.insert(self.actions, action);
    end
end

function Section:add_actions(actions: {any})
    for _, v in actions do
        self:add_action(v);
    end
end

function Section:export()
    local text = {self.name};

    if self.trigger.type == "keypress" then
        text[2] = actions.parse_type(self.trigger.params[1]);
    end

    return {
        id = Section.trigger_to_id(self.trigger),
        text = text,
        actions = self.actions,
    };
end

function Section:get_actions()
    return table.clone(self.actions);
end


--------------------------------------------------------------------------------

export type Document = typeof(Document.new(""));
export type Section = typeof(Section.new("", {type = "none", raw = "", params = {}}));

return {
    Document = Document,
    Section = Section,
};