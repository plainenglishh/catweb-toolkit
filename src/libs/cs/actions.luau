local ctype = require("../casm/types");

--[[
    List of action buillders.
]]

local actions = {};

--[[
    Converts an CASM datatype into a CatScript datatype.
]]
function actions.parse_type(casm_type: ctype.Any)
    assert(casm_type, "missing argument");

    if casm_type.kind == "String" then
        return {
            value = casm_type.value,
            t = "string",
        };
    elseif casm_type.kind == "Variable" then
        return {
            value = "{"..casm_type.value.."}",
            t = "string",
        };
    elseif casm_type.kind == "Number" then
        return {
            value = tostring(casm_type.value),
            t = "number",
        };
    elseif casm_type.kind == "Object" then
        return {
            value = string.char(casm_type.value),
            t = "object",
        };
    elseif casm_type.kind == "Raw" then
        return {
            value = casm_type.value,
            t = "any",
        };
    elseif casm_type.kind == "Key" then
        return {
            value = casm_type.value,
            t = "key",
        };
    else
        error(`unknown argument type '{casm_type.kind}'`);
    end
end


--[[
    Creates a base action.
]]
function actions.create_action(id: number, text: {string}): {[any]: any}
    return {
        id = tostring(id),
        --t = 0,
        text = text
    };
end

--// Console

function actions.log(message: ctype.Any)
    return actions.create_action(0, {"", actions.parse_type(message)});
end

function actions.warn(message: ctype.Any)
    return actions.create_action(1, {"", actions.parse_type(message)});
end

function actions.error(reason: ctype.Any)
    return actions.create_action(2, {"", actions.parse_type(reason)});
end


--// Logic

function actions.wait(delay_s: ctype.VNumber)
    return actions.create_action(3, {"", actions.parse_type(delay_s), ""});
end

function actions.if_eq(l: ctype.Any, r: ctype.Any)
    return actions.create_action(18, {"", actions.parse_type(l), "", actions.parse_type(r)});
end

function actions.if_neq(l: ctype.Any, r: ctype.Any)
    return actions.create_action(19, {"", actions.parse_type(l), "", actions.parse_type(r)});
end

function actions.if_gt(l: ctype.Any, r: ctype.Any)
    return actions.create_action(20, {"", actions.parse_type(l), "", actions.parse_type(r)});
end

function actions.if_lt(l: ctype.Any, r: ctype.Any)
    return actions.create_action(21, {"", actions.parse_type(l), "", actions.parse_type(r)});
end


--// Loops

function actions.repeat_n(n: ctype.VNumber)
    return actions.create_action(22, {"", actions.parse_type(n), ""});
end

function actions.repeat_forever()
    return actions.create_action(23, {""});
end


--// Navigation

function actions.redirect(url: ctype.VString)
    return actions.create_action(4, {"", actions.parse_type(url)});
end


--// Audio

function actions.play_audio(id: ctype.VString)
    return actions.create_action(5, {"", actions.parse_type(id)});
end

function actions.play_audio_loop(id: ctype.VString)
    return actions.create_action(26, {"", actions.parse_type(id)});
end

function actions.set_audio_volume(vol: ctype.VNumber)
    return actions.create_action(6, {"", actions.parse_type(vol)});
end

function actions.stop_all_audio()
    return actions.create_action(7, {""});
end

function actions.pause_all_audio()
    return actions.create_action(28, {""});
end

function actions.resume_all_audio()
    return actions.create_action(29, {""});
end

--// Looks

function actions.make_invisible(obj: ctype.Object)
    return actions.create_action(8, {"", actions.parse_type(obj), ""});
end

function actions.make_visible(obj: ctype.Object)
    return actions.create_action(9, {"", actions.parse_type(obj), ""});
end

function actions.set_text(obj: ctype.Object, text: ctype.VString)
    return actions.create_action(10, {"", actions.parse_type(obj), "", actions.parse_type(text)});  
end

function actions.set_prop(obj: ctype.Object, prop: ctype.VString, var: ctype.Variable)
    return actions.create_action(31, {
        "",
        actions.parse_type(prop),
        "",
        actions.parse_type(obj),
        "",
        actions.parse_type(var),
    });
end


--// Maths

function actions.set_var(var: ctype.Variable, to: ctype.Variable)
    return actions.create_action(11, {"", actions.parse_type(var), "", actions.parse_type(to)});
end

function actions.increment(var: ctype.Variable, by: ctype.VNumber)
    return actions.create_action(12, {"", actions.parse_type(var), "", actions.parse_type(by)});
end

function actions.subtract(var: ctype.Variable, by: ctype.VNumber)
    return actions.create_action(13, {"", actions.parse_type(var), "", actions.parse_type(by)});
end

function actions.multiply(var: ctype.Variable, by: ctype.VNumber)
    return actions.create_action(14, {"", actions.parse_type(var), "", actions.parse_type(by)});
end

function actions.divide(var: ctype.Variable, by: ctype.VNumber)
    return actions.create_action(15, {"", actions.parse_type(var), "", actions.parse_type(by)});
end

function actions.round(var: ctype.Variable)
    return actions.create_action(16, {"", actions.parse_type(var)});
end

function actions.floor(var: ctype.Variable)
    return actions.create_action(17, {"", actions.parse_type(var)});
end

function actions.random(var: ctype.Variable, min: ctype.VNumber, max: ctype.VNumber)
    return actions.create_action(27, {"", actions.parse_type(var), "", actions.parse_type(min), "", actions.parse_type(max)});
end

function actions.get_input(var: ctype.Variable, obj: ctype.Object)
    return actions.create_action(30, {"", actions.parse_type(var), "", actions.parse_type(obj)});
end


--// Misc

function actions._end()
    return actions.create_action(25, {""});
end

return actions;