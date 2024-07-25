local ctype = {spec = {}};

--------------------------------------------------------------------------------
--
--  Primative Types
--
--------------------------------------------------------------------------------

--[=[
    Object Type

    Refers to an instance in the DOM.
]=]
export type Object = {
    kind: "Object",
    value: number,
};

function ctype.Object(num: number)
    return {
        kind = "Object",
        value = num,
    };
end

--[=[
    Section Type

    Refers to an CASM code section.
]=]
export type Section = {
    kind: "Section",
    value: string,
};

function ctype.Section(var: string)
    return {
        kind = "Section",
        value = var,
    };
end

--[=[
    Variable Type

    Refers to a CatScript variable.
]=]
export type Variable = {
    kind: "Variable",
    value: string,
};

function ctype.Variable(var: string)
    return {
        kind = "Variable",
        value = var,
    };
end

--[=[
    Number Type

    Refers to a number.
]=]
export type Number = {
    kind: "Number",
    value: number,
};

function ctype.Number(num: number)
    return {
        kind = "Number",
        value = num,
    };
end

--[=[
    String Type

    Refers to a string.
]=]
export type String = {
    kind: "String",
    value: string,
};

function ctype.String(value: string)
    return {
        kind = "String",
        value = value,
    };
end

--[=[
    Key Type

    Refers to a key.
]=]
export type Key = {
    kind: "Key",
    value: Key,
};

function ctype.Key(value: string)
    return {
        kind = "Key",
        value = value,
    };
end

--[=[
    Raw Type

    Refers to an argument using raw catscript syntax.
]=]
export type Raw = {
    kind: "Raw",
    value: string,
};

function ctype.Raw(value: string)
    return {
        kind = "Raw",
        value = value,
    };
end


--------------------------------------------------------------------------------
--
--  Utility Types
--
--------------------------------------------------------------------------------

--[=[
    Any
    
    Refers to any casm_type.
]=]
export type Any = Object|String|Number|Variable|Section|Raw|Key;
ctype.spec.Any = "Object|String|Number|Variable|Section|Raw|Key";

--[=[
    VNumber

    Refers to either a Number or a Variable
]=]
export type VNumber = Number|Variable;
ctype.spec.VNumber = "Number|Variable";

--[=[
    VString

    Refers to either a String or a Variable
]=]
export type VString = String|Variable;
ctype.spec.VString = "String|Variable";


--------------------------------------------------------------------------------
--
--  Utility Functions
--
--------------------------------------------------------------------------------

function ctype.typeof(value: Any): string
    return value.kind or error("not a casm_type");
end

function ctype.isa(value: Any?, is: string): boolean
    local raw_type = is;
    local can_be_nil = is:sub(#is, #is) == "?";
    if can_be_nil then
        raw_type = raw_type:sub(1, #is-1)
    end
    if value == nil then
        if can_be_nil then
            return true
        else
            return false;
        end
    end

    if value.kind == "Raw" then
        return true;
    end

    return table.find(raw_type:gsub("%s", ""):split("|"), value.kind) ~= nil;
end

return ctype;
