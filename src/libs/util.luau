local util = {};

--[[
    Removes empty strings from an array,
    used to remove the residue left by  using string.split on an empty string.
]]
function util.rm_empty_str(arr: {string}): {string}
    local out = {};

    for _, v in arr do
        if v ~= "" then
            table.insert(out, v);
        end
    end

    return out;
end

function util.rm_error_details(err)
    return err:gsub("%[string .-\"]:%d-: ", "");
end


return util;
