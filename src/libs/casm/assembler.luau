local serde = require("@lune/serde");

local output = require("../output");
local util = require("../util");

local ctype = require("./types");
local classes = require("./classes");
local instructions = require("./instructions");

--[[
    Parses instruction operands into an array of ctypes.
]]
local function parse_operands(arg_str: string, confict_name: string): {ctype.Any}
    local args = {};

    local NULL_STATE = { kind = "null "};

    local read_state = NULL_STATE;
    local character_list = (arg_str or ""):split("");
    local expecting;

    for i, char in character_list do
        local prev = character_list[i-1];
        local fwd = character_list[i+1];

        -- If the state is empty, establish next state
        if read_state == NULL_STATE then
            -- Ignore whitespace during null state
            if char == " " or char == "\t" then
                continue;
            end

            if expecting then
                if char ~= expecting then
                    error(`expected '{expecting}', got '{char}'`);
                else
                    expecting = nil;
                    continue
                end
            end

            -- String literal entry
            if char == "\"" and prev ~= "\\" then
                read_state = {
                    kind = "string_literal",
                    value = "",
                };

            -- Raw entry
            elseif char == "[" and prev ~= "\\" then
                read_state = {
                    kind = "raw_arg",
                    value = "",
                };

            -- Number literal
            elseif tonumber(char) ~= nil or char == "-" then
                read_state = {
                    kind = "number_literal",
                    value = char,
                };
            
            -- Variable
            elseif char == "&" then
                read_state = {
                    kind = "variable",
                    value = "",
                };

            -- Section
            elseif char == "." then
                read_state = {
                    kind = "section",
                    value = "",
                };

            -- Object
            elseif char == "%" then
                read_state = {
                    kind = "object",
                    value = "",
                };
            
            -- Object
            elseif char == "!" then
                read_state = {
                    kind = "argument",
                    value = "",
                };

            -- Object
            elseif char == "~" then
                print("keycode enter")
                read_state = {
                    kind = "key",
                    value = "",
                };

            -- ??
            else
                error(`unexpected token '{char}' while parsing parameter list`);
            end

        -- If state is string_literal, start adding characters to buffer.
        elseif read_state.kind == "string_literal" then
            if char == "\"" and prev ~= "\\" or fwd == nil then
                table.insert(args, ctype.String(read_state.value));
                read_state = NULL_STATE;
                expecting = ",";
            else
                if char == "\\" and fwd == "\"" then
                    continue;
                end
                read_state.value ..= char;
            end

        elseif read_state.kind == "raw_arg" then
            if char == "]" and prev ~= "\\" or fwd == nil then
                table.insert(args, ctype.Raw(read_state.value));
                read_state = NULL_STATE;
                expecting = ",";
            else
                if char == "]" and fwd == "\"" then
                    continue;
                end
                read_state.value ..= char;
            end

        -- If state is number_literal, start adding numbers to buffer.
        elseif read_state.kind == "number_literal" then
            if char == "," or char == " " or char == nil then
                table.insert(args, ctype.Number(tonumber(read_state.value) :: any));
                read_state = NULL_STATE;
                if char ~= "," then
                    expecting = ",";
                end
            else
                if tonumber(char) ~= nil or char == "." then
                    if char == "." then
                        if read_state.decimal_done then
                            error("decimal already used");
                        else
                            read_state.value ..= char;
                        end
                    else
                        read_state.value ..= char;
                    end
                else
                    error("expected number or decimal");
                end
            end

        -- If state is a variable, add chars to buffer
        elseif read_state.kind == "variable" then
            if char == "," or char == " " or char == nil then
                table.insert(args, ctype.Variable(read_state.value));
                read_state = NULL_STATE;
                if char ~= "," then
                    expecting = ",";
                end
            else
                read_state.value ..= char;
            end

        -- If state is a variable, add chars to buffer
        elseif read_state.kind == "section" then
            if char == "," or char == " " or char == nil then
                table.insert(args, ctype.Section(read_state.value));
                read_state = NULL_STATE;
                if char ~= "," then
                    expecting = ",";
                end
            else
                read_state.value ..= char;
            end

        -- If state is a variable, add chars to buffer
        elseif read_state.kind == "object" then
            if char == "," or char == " " or char == nil then
                table.insert(args, ctype.Object(read_state.value));
                read_state = NULL_STATE;
                if char ~= "," then
                    expecting = ",";
                end
            else
                read_state.value ..= char;
            end

        -- If state is a variable, add chars to buffer
        elseif read_state.kind == "key" then
            if char == "," or char == " " or char == nil then
                table.insert(args, ctype.Key(read_state.value));
                read_state = NULL_STATE;
                if char ~= "," then
                    expecting = ",";
                end
            else
                read_state.value ..= char;
            end

        elseif read_state.kind == "argument" then
            if char == "," or char == " " or char == nil then
                table.insert(args, ctype.Variable("____"..confict_name.."__arg__"..read_state.value.."____"));
                read_state = NULL_STATE;
                if char ~= "," then
                    expecting = ",";
                end
            else
                read_state.value ..= char;
            end
        else
            error("unexpected token")
        end
    end

    return args;
end

local function assemble_file(document_source: string, document_name: string?)
    local document = classes.Document.new(document_name or ".casm");
    local current_section;
    
    local lines = document_source:split("\n");

    for line_no, raw in lines do
        local function throw(message: string)
            output.error(`{document_name}:{line_no} - {message}`);
        end

        local function throw_if_false(test: any?, message: string)
            if not test then
                throw(message);
            end
        end

        local line = raw:match("^%s*(.-)%s*$"):gsub(";.-$", "");
        local prefix = line:sub(1, 1);
        
        --// Section Definition
        if prefix == "." then
            local section_name = line:match("^%.([%w_]+)");
            local raw_event = line:match("^%.[%w_]+%s-@%s-([%w_].+)");
            local is_func = line:match("^%.[%w_]+%s-%(");
            local parameters;

            local event;
            if raw_event then
                local evt_type = raw_event:match("^[%w_]+");
                local params = parse_operands(raw_event:gsub("^[%w_]+", "").." ", "");

                event = {
                    raw = raw_event,
                    type = evt_type,
                    params = params
                };
            else
                event = {
                    type = "none",
                    raw = "none",
                    params = {},
                };
            end

            if is_func then
                parameters = util.rm_empty_str(line:match("^%.[%w_]+%s-%((.-)%)"):gsub("%s", ""):split(","));
            end

            local section = classes.Section.new(section_name, event, parameters);
            print(section)
            current_section = section;
            document:add_section(section_name, section);

        --// Constant Definition
        elseif prefix == "$" then
            local key = line:match("^%$([%w_]+)");
            local value = line:match("^%$[%w_]+%s+([^%s]+)");
            document:define_constant(key, value);

        --// Comment & Empty Lines
        elseif prefix == ";" or line == "" then -- Comment
            -- No-op

        --// Instruction?
        else
            throw_if_false(current_section, "attempt to call instruction outside of a section");

            -- Replace constants
            line = (line.." "):gsub("%$([%w_]-[,%s])", function(match)
                local last_char = match:sub(#match, #match);
                local key = match:sub(1, #match-1);
                return document:get_constant(key)..last_char;
            end);

            print(line);

            local mnemonic = (line):match("^(%w+)%s"):lower();
            local param_list = (line.." "):match("^%w+%s(.+)$");
            local instruction = instructions[mnemonic];

            if instruction then
                local ok, params = pcall(parse_operands, param_list, current_section.name);

                throw_if_false(ok, util.rm_error_details(tostring(params)));

                for i, v in instruction.params do
                    throw_if_false(ctype.isa(params[i], v), `parameter #{i} of '{mnemonic}' should be of type {v}, got {if not params[i] then "nil" else params[i].kind}`);
                end
                
                local ok, err = pcall(instruction.func, document, current_section, params);
                throw_if_false(ok, tostring(err));
            else
                throw(`unknown opcode '{mnemonic}'`);
            end
        end
    end

    return serde.encode("json", {document:export()}, true);
end

return assemble_file;