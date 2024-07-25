local fs = require("@lune/fs");

local output = require("../libs/output");

--[==[local ctype = require("../libs/casm/types");

--[[
    Removes empty strings from an array,
    used to remove the residue left by  using string.split on an empty string.
]]
local function rm_empty_str(arr: {string}): {string}
    local out = {};

    for _, v in arr do
        if v ~= "" then
            table.insert(out, v);
        end
    end

    return out;
end


--[[
    Converts an CASM datatype into a CatScript datatype.
]]
local function parse_type(casm_type: ctype.Any)
    output.assert(casm_type, "missing argument");

    if casm_type.kind == "string" then
        return {
            value = casm_type.value,
            t = "string",
        };
    elseif casm_type.kind == "variable" then
        return {
            value = "{"..casm_type.value.."}",
            t = "string",
        };
    elseif casm_type.kind == "number" then
        return {
            value = tostring(casm_type.value),
            t = "number",
        };
    elseif casm_type.kind == "object" then
        return {
            value = string.char(casm_type.value),
            t = "object",
        };
    else
        output.error(`unknown argument type '{casm_type.kind}'`);
    end

    return;
end


--[[
    Creates a base action.
]]
local function create_action(id: number, text: {string}): {[any]: any}
    return {
        id = tostring(id),
        --t = 0,
        text = text
    };
end

--[[
    List of action buillders.
]]
local action = {
    error = function(reason: ctype.Any)
        return create_action(2, {"", parse_type(reason)});
    end,

    warn = function(message: ctype.Any)
        return create_action(1, {"", parse_type(message)});
    end,

    log = function(message: ctype.Any)
        return create_action(0, {"", parse_type(message)});
    end,

    wait = function(delay_s: ctype.VNumber)
        return create_action(3, {"", parse_type(delay_s), ""});
    end,

    set_var = function(var: ctype.Variable, to: ctype.Variable)
        return create_action(11, {"", parse_type(var), "", parse_type(to)});
    end,

    if_eq = function(l: ctype.Any, r: ctype.Any)
        return create_action(18, {"", parse_type(l), "", parse_type(r)});
    end,

    if_neq = function(l: ctype.Any, r: ctype.Any)
        return create_action(19, {"", parse_type(l), "", parse_type(r)});
    end,

    if_gt = function(l: ctype.Any, r: ctype.Any)
        return create_action(20, {"", parse_type(l), "", parse_type(r)});
    end,

    
    if_lt = function(l: ctype.Any, r: ctype.Any)
        return create_action(21, {"", parse_type(l), "", parse_type(r)});
    end,

    set_prop = function(obj: ctype.Object, prop: ctype.VString, var: ctype.Variable)
        return create_action(31, {
            "",
            parse_type(prop),
            "",
            parse_type(obj),
            "",
            parse_type(var),
        });
    end,

    get_input = function(var: ctype.Variable, obj: ctype.Object)
        return create_action(30, {"", parse_type(var), "", parse_type(obj)});
    end,

    increment = function(var: ctype.Variable, by: ctype.VNumber)
        return create_action(12, {"", parse_type(var), "", parse_type(by)});
    end,

    ["end"] = function()
        return create_action(25, {""});
    end,
};

local opcodes;
opcodes = {
    --[[
        Throw an error
    ]]
    ERR = function(section, args)
        table.insert(
            section.actions,
            action.error(args[1])
        );
    end,

    --[[
        Halt program execution
    ]]
    HLT = function(section, args)
        table.insert(
            section.actions,
            action.error(ctype.String("Program Halt"))
        );
    end,

    --[[
        Write a warning to stdout
    ]]
    WRN = function(section, args)
        table.insert(
            section.actions,
            action.warn(args[1])
        );
    end,

    --[[
        Write a message to stdout
    ]]
    LOG = function(section, args)
        table.insert(
            section.actions,
            action.log(args[1])
        );
    end,

    --[[
        Delay for some seconds
    ]]
    DEL = function(section, args)
        table.insert(
            section.actions,
            action.wait(args[1])
        );
    end,

    --[[
        Set a variable
    ]]
    SET = function(section, args)
        table.insert(
            section.actions,
            action.set_var(args[1], args[2])
        );
    end,

    --[[
        Branch always
    ]]
    BRA = function(section, args, sections)
        local called_section;

        for _, v in sections do
            if v.text[1] == args[1].text then
                called_section = v;
            end
        end

        for _, v in called_section.actions do
            table.insert(section.actions, v);
        end
    end,

    --[[
        Call
    ]]
    CLL = function(section, args, sections)
        local func_name = table.remove(args, 1)
        local return_var = table.remove(args, 1);
        
        local called_section;

        for _, v in sections do
            if v.text[1] == func_name.text then
                called_section = v;
            end
        end

        output.assert(called_section, `section '{func_name.text}' not found`)
        output.assert(called_section.id == -2, "section is not callable, use branch instead");

        for i, param in called_section.params do
            table.insert(called_section.actions, 1, action.set_var(
                ctype.Variable("____"..called_section.text[1].."__arg__"..param.."____"),
                args[i]
            ));
        end

        for _, v in called_section.actions do
            table.insert(section.actions, v);
        end

        table.insert(section.actions, action.set_var(
            return_var,
            ctype.Variable("____"..called_section.text[1].."__return____")
        ));
    end,

    RET = function(section, args, sections)
        table.insert(section.actions, action.set_var(
            ctype.Variable("____"..section.text[1].."__return____"),
            args[1]
        ));
    end,

    --[[
        If equal
    ]]
    IFE = function(section, args)
        table.insert(section.actions, action.if_eq(args[1], args[2]));
    end,

    IFN = function(section, args)
        table.insert(section.actions, action.if_neq(args[1], args[2]));
    end,

    IFG = function(section, args)
        table.insert(section.actions, action.if_gt(args[1], args[2]));
    end,

    IFL = function(section, args)
        table.insert(section.actions, action.if_lt(args[1], args[2]));
    end,

    --[[
        End
    ]]
    END = function(section, args)
        table.insert(section.actions, action["end"]());
    end,

    --[[
        Branch if equal
    ]]
    BRE = function(section, args, sections)
        opcodes["IFE"](section, {args[2], args[3]}, sections);
        opcodes["BRA"](section, {args[1]}, sections);
        opcodes["END"](section, {}, sections);
    end,

    --[[
        Set property to
    ]]
    SPR = function(section, args, sections)
        table.insert(section.actions, action.set_prop(args[1], args[2], args[3]));
    end,

    --[[
        Get input
    ]]
    INP = function(section, args, sections)
        table.insert(section.actions, action.get_input(args[2], args[1]))
    end,

    --[[
        Add
    ]]
    ADD = function(section, args, sections)
        table.insert(section.actions, action.increment(args[1], args[2]))
    end
}

local function assemble_file(src: string, name: string?)
    local sections = {};
    
    local lines = src:split("\n");
    local current_section;

    local constants = {};

    for line_no, raw in lines do
        local line = raw:match("^%s*(.-)%s*$"):gsub(";.-$", "");
        local prefix = line:sub(1, 1);
        
        if prefix == "." then -- Section def
            local section_name = line:match("^%.([%w_]+)");
            
            local section_body = {
                id = -1,
                text = {section_name},
                actions = {},
            };

            local is_func = line:match("^%.[%w_]+%s-%(");
            if is_func then
                section_body.id = -2;
                section_body.params = rm_empty_str(line:match("^%.[%w_]+%s-%((.-)%)"):gsub("%s", ""):split(","));
            else
                local event = line:match("^%.[%w_]+%s-@%s-([%w_]+)");
                if event == "pageload" then
                    section_body.id = 0;
                end
            end

            current_section = section_body;
            sections[section_name] = section_body;
        elseif prefix == "$" then
            local constant_name = line:match("^%$([%w_]+)");
            local constant_value = line:match("^%$[%w_]+%s-(.+)");
            constants[constant_name] = constant_value;
        elseif prefix == ";" or line == "" then -- Comment
        else
            output.assert(current_section, "operand must be in section");
            line = (line.." "):gsub("%$([%w_]-)[,%s]", function(const)
                return constants[const]..",";
            end);

            local opcode = (line):match("^(%w+)%s"):upper();
            local operand = (line):match("^%w+%s(.+)$");
            if opcodes[opcode] then
                local args = {};

                local NULL_STATE = { kind = "null "};

                local state = NULL_STATE;
                local chars = if not operand then {} else operand:split("");
                local expect;

                for i, char in chars do
                    --print(char)
                    local prev = chars[i-1];
                    local fwd = chars[i+1];

                    -- If the state is empty, establish next state
                    if state == NULL_STATE then
                        -- Ignore whitespace during null state
                        if char == " " or char == "\t" then
                            continue;
                        end

                        if expect then
                            if char ~= expect then
                                output.error(`expected '{expect}', got '{char}'`);
                            else
                                expect = nil;
                                continue
                            end
                        end

                        -- String literal entry
                        if char == "\"" and prev ~= "\\" then
                            state = {
                                kind = "string_literal",
                                value = "",
                            };

                        -- Number literal
                        elseif tonumber(char) ~= nil then
                            state = {
                                kind = "number_literal",
                                value = char,
                            };
                        
                        -- Variable
                        elseif char == "&" then
                            state = {
                                kind = "variable",
                                value = "",
                            }

                        -- Section
                        elseif char == "." then
                            state = {
                                kind = "section",
                                value = "",
                            }


                        -- Object
                        elseif char == "%" then
                            state = {
                                kind = "object",
                                value = "",
                            }
                        
                        -- Object
                        elseif char == "!" then
                            state = {
                                kind = "argument",
                                value = "",
                            }

                        -- ??
                        else
                            output.error("unexpected argument");

                        end

                    -- If state is string_literal, start adding characters to buffer.
                    elseif state.kind == "string_literal" then
                        if char == "\"" and prev ~= "\\" or fwd == nil then
                            table.insert(args, ctype.String(state.value));
                            state = NULL_STATE;
                            expect = ",";
                        else
                            if char == "\\" and fwd == "\"" then
                                continue;
                            end
                            state.value ..= char;
                        end

                    -- If state is number_literal, start adding numbers to buffer.
                    elseif state.kind == "number_literal" then
                        if char == "," or char == " " or char == nil then
                            table.insert(args, ctype.Number(tonumber(state.value) :: any));
                            state = NULL_STATE;
                            if char ~= "," then
                                expect = ",";
                            end
                        else
                            if tonumber(char) ~= nil then
                                state.value ..= char;
                            else
                                output.error("expected number");
                            end
                        end

                    -- If state is a variable, add chars to buffer
                    elseif state.kind == "variable" then
                        if char == "," or char == " " or char == nil then
                            table.insert(args, ctype.Variable(state.value));
                            state = NULL_STATE;
                            if char ~= "," then
                                expect = ",";
                            end
                        else
                            state.value ..= char;
                        end

                    -- If state is a variable, add chars to buffer
                    elseif state.kind == "section" then
                        if char == "," or char == " " or char == nil then
                            table.insert(args, ctype.Section(state.value));
                            state = NULL_STATE;
                            if char ~= "," then
                                expect = ",";
                            end
                        else
                            state.value ..= char;
                        end

                    -- If state is a variable, add chars to buffer
                    elseif state.kind == "object" then
                        if char == "," or char == " " or char == nil then
                            table.insert(args, ctype.Object(state.value));
                            state = NULL_STATE;
                            if char ~= "," then
                                expect = ",";
                            end
                        else
                            state.value ..= char;
                        end

                    elseif state.kind == "argument" then
                            if char == "," or char == " " or char == nil then
                                table.insert(args, ctype.Variable("____"..current_section.text[1].."__arg__"..state.value.."____"));
                                state = NULL_STATE;
                                if char ~= "," then
                                    expect = ",";
                                end
                            else
                                state.value ..= char;
                            end
                    end
                end

                opcodes[opcode](current_section, args, sections);
            else
                output.error(`unknown opcode '{opcode}'`);
            end
        end
    end

    local out = {};

    for _, v in sections do
        if v.id >= 0 then
            table.insert(out, v);
        end
    end

    return serde.encode("json", {{
        class = "script",
        content = out,
        alias = name or ".asm",
        globalid = "\f"
    }}, true);
end
]==]

local assemble = require("../libs/casm/assembler");

return function(args)
    for _, path in args do
        output.write(`assembling {path}`);
        output.assert(fs.isFile(path), `cannot find file '{path}'`);
        local source = fs.readFile(path);
        local out_path = path..".json";
        fs.writeFile(out_path, assemble(source, path));
        output.write(`wrote {path} to {out_path}`);
    end
end