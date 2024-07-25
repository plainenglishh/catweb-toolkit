local ctypes = require("./types");
local classes = require("./classes");
local actions = require("../cs/actions");

type InstructionFunc = (doc: classes.Document, section: classes.Section, params: {ctypes.Any})->();

local instructions = {};

local function def(mnemonic: string, params: {string}, func: InstructionFunc)
    assert(not instructions[mnemonic], `instruction '{mnemonic}' already defined`);
    
    instructions[mnemonic] = {
        params = params,
        func = func,
    };
end

--[=[
    `log` Instruction

    Usage:
        log "Hello, World!"

    Description:
        Writes the passed data to the console.

    Parameters:
        1. String|Variable - The message to be logged
]=]

def("log", {ctypes.spec.VString}, function(doc, section, params)
    section:add_action(actions.log(params[1]));
end);


--[=[
    `wrn` Instruction

    Usage:
        warn "Hello, World!"

    Description:
        Writes the passed data to the console, formatted as a warning.

    Parameters:
        1. String|Variable - The message to be logged
]=]

def("wrn", {ctypes.spec.VString}, function(doc, section, params)
    section:add_action(actions.warn(params[1]));
end);


--[=[
    `err` Instruction

    Usage:
        err "Hello, World!"

    Description:
        Throws an error.

    Parameters:
        1. String|Variable - The message to be logged
]=]

def("err", {ctypes.spec.VString}, function(doc, section, params)
    section:add_action(actions.error(params[1]));
end);


--[=[
    `del` Instruction

    Usage:
        del 5

    Description:
        Delays exection for x seconds

    Parameters:
        1. Number|Variable - The time to wait
]=]
def("del", {ctypes.spec.VNumber}, function(doc, section, params)
    section:add_action(actions.wait(params[1]));
end);


--[=[
    `set` Instruction

    Usage:
        set &var_name, "Hi"

    Description:
        Stores data in a variable

    Parameters:
        1. Variable - The variable to store the data in
        2. Any - The data to be stored
]=]
def("set", {"Variable", ctypes.spec.Any}, function(doc, section, params)
    section:add_action(actions.set_var(params[1], params[2]));
end);


--[=[
    `ifeq` Instruction

    Usage:
        ifeq 5, 5

    Description:
        Starts an if-equal block, tests if both params are equal.
        If the evaluation fails, it'll skip to the next 'end'.

    Parameters:
        1. left  - The left side of the comparison
        2. right - The right side of the comparison
]=]
def("ifeq", {ctypes.spec.Any, ctypes.spec.Any}, function(doc, section, params)
    section:add_action(actions.if_eq(params[1], params[2]));
end);


--[=[
    `ifne` Instruction

    Usage:
        ifne 5, 5

    Description:
        Starts an if-not-equal block, tests if both params aren't equal.
        If the evaluation fails, it'll skip to the next 'end'.

    Parameters:
        1. left  - The left side of the comparison
        2. right - The right side of the comparison
]=]
def("ifne", {ctypes.spec.Any, ctypes.spec.Any}, function(doc, section, params)
    section:add_action(actions.if_neq(params[1], params[2]));
end);


--[=[
    `ifgt` Instruction

    Usage:
        ifgt 5, 5

    Description:
        Starts an if-greater-than block, tests if the left param is larger than
        the right param.
        If the evaluation fails, it'll skip to the next 'end'.

    Parameters:
        1. left  - The left side of the comparison
        2. right - The right side of the comparison
]=]
def("ifgt", {ctypes.spec.VNumber, ctypes.spec.VNumber}, function(doc, section, params)
    section:add_action(actions.if_gt(params[1], params[2]));
end);


--[=[
    `iflt` Instruction

    Usage:
        iflt 5, 5

    Description:
        Starts an if-less-than block, tests if the right param is larger than
        the left param.
        If the evaluation fails, it'll skip to the next 'end'.

    Parameters:
        1. left  - The left side of the comparison
        2. right - The right side of the comparison
]=]
def("iflt", {ctypes.spec.VNumber, ctypes.spec.VNumber}, function(doc, section, params)
    section:add_action(actions.if_lt(params[1], params[2]));
end);


--[=[
    `end` Instruction

    Usage:
        end

    Description:
        Concludes a block (i.e if, rep, etc)n
]=]
def("end", {}, function(doc, section, params)
    section:add_action(actions._end());
end);


--[=[
    `sop` Instruction

    Usage:
        sop "Text", %53, &var

    Description:
        Sets property x of x to x

    Parameters:
        1. property - The name of the property
        2. object - The object to modify
        3. value - The value to set
]=]
def("sop", {ctypes.spec.VString, "Object", ctypes.spec.Any}, function(doc, section, params)
    section:add_action(actions.set_prop(params[2], params[1], params[3]));
end);


--[=[
    `add` Instruction

    Usage:
        add &reg, 5

    Description:
        Adds a number to a variable

    Parameters:
        1. variable - The variable to be modified
        2. object - The number to add
]=]
def("add", {"Variable", ctypes.spec.VNumber}, function(doc, section, params)
    section:add_action(actions.increment(params[1], params[2]));
end);


--[=[
    `sub` Instruction

    Usage:
        sub &reg, 5

    Description:
        Subtracts a number from a variable

    Parameters:
        1. variable - The variable to be modified
        2. object - The number to subtract
]=]
def("sub", {"Variable", ctypes.spec.VNumber}, function(doc, section, params)
    section:add_action(actions.subtract(params[1], params[2]));
end);


--[=[
    `div` Instruction

    Usage:
        div &reg, 5

    Description:
        Divide a variable with a number

    Parameters:
        1. variable - The variable to be modified
        2. object - The number to divide
]=]
def("div", {"Variable", ctypes.spec.VNumber}, function(doc, section, params)
    section:add_action(actions.divide(params[1], params[2]));
end);


--[=[
    `mul` Instruction

    Usage:
        mul &reg, 5

    Description:
        Multiplies a number and a variable

    Parameters:
        1. variable - The variable to be modified
        2. object - The number to multiply
]=]
def("mul", {"Variable", ctypes.spec.VNumber}, function(doc, section, params)
    section:add_action(actions.multiply(params[1], params[2]));
end);


--[=[
    `bra` Instruction

    Usage:
        bra .section_name

    Description:
        Branches to the specified section

    Parameters:
        1. Section - The section to branch to
]=]
def("bra", {"Section"}, function(doc, section, params)
    local branch_section = doc:get_section(params[1].value);
    assert(branch_section, `section '{params[1].value}' not defined`);
    section:add_actions(branch_section:get_actions());
end);


--[=[
    `breq` Instruction

    Usage:
        breq .section_name, 5, 5

    Description:
        Branches to the specified section if param 1&2 are equal.

    Parameters:
        1. Section - The section to branch to
        2. left - The left side of the test
        3. right - The right side of the test
]=]
def("breq", {"Section"}, function(doc, section, params)
    local branch_section = doc:get_section(params[1].value);
    assert(branch_section, `section '{params[1].value}' not defined`);

    section:add_action(actions.if_eq(params[2], params[3]));
    section:add_actions(branch_section:get_actions());
    section:add_action(actions._end());
end);


--[=[
    `brne` Instruction

    Usage:
        brne .section_name, 5, 5

    Description:
        Branches to the specified section if param 1&2 aren't equal.

    Parameters:
        1. Section - The section to branch to
        2. left - The left side of the test
        3. right - The right side of the test
]=]
def("brne", {"Section"}, function(doc, section, params)
    local branch_section = doc:get_section(params[1].value);
    assert(branch_section, `section '{params[1].value}' not defined`);

    section:add_action(actions.if_neq(params[2], params[3]));
    section:add_actions(branch_section:get_actions());
    section:add_action(actions._end());
end);


--[=[
    `brgt` Instruction

    Usage:
        brgt .section_name, 5, 6

    Description:
        Branches to the specified section if param 1 > param 2.

    Parameters:
        1. Section - The section to branch to
        2. left - The left side of the test
        3. right - The right side of the test
]=]
def("brgt", {"Section"}, function(doc, section, params)
    local branch_section = doc:get_section(params[1].value);
    assert(branch_section, `section '{params[1].value}' not defined`);

    section:add_action(actions.if_gt(params[2], params[3]));
    section:add_actions(branch_section:get_actions());
    section:add_action(actions._end());
end);


--[=[
    `brlt` Instruction

    Usage:
        brlt .section_name, 5, 6

    Description:
        Branches to the specified section if param 1 < param 2.

    Parameters:
        1. Section - The section to branch to
        2. left - The left side of the test
        3. right - The right side of the test
]=]
def("brlt", {"Section"}, function(doc, section, params)
    local branch_section = doc:get_section(params[1].value);
    assert(branch_section, `section '{params[1].value}' not defined`);

    section:add_action(actions.if_lt(params[2], params[3]));
    section:add_actions(branch_section:get_actions());
    section:add_action(actions._end());
end);


--[=[
    `hlt` Instruction

    Usage:
        hlt

    Description:
        Throws a blank error to stop the script
]=]
def("hlt", {}, function(doc, section, params)
    section:add_action(actions.error(ctypes.String("Halt Instruction")));
end);


--[=[
    `rpti` Instruction

    Usage:
        rpti

    Description:
        Repeats the following block infinitely.
]=]
def("rpti", {}, function(doc, section, params)
    section:add_action(actions.repeat_forever());
end);


--[=[
    `nop` Instruction

    Usage:
        nop

    Description:
        Does nothing.
]=]
def("nop", {}, function(doc, section, params)
end);



--[=[
    `call` Instruction

    Usage:
        

    Description:
       

    Parameters:
        
]=]
def("_call", {"Section"}, function(doc, section, params)
    --TODO:
end);

--[=[
    `ret` Instruction

    Usage:
        

    Description:
       

    Parameters:
        
]=]
def("_ret", {"Section"}, function(doc, section, params)
    --TODO:
end);

--inp

return instructions;
