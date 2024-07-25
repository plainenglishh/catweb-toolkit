local process = require("@lune/process");
local output = require("./libs/output");

local commands = {
    --["build"] = require("./commands/build"),
    ["as"] = require("./commands/assemble")
};

local function main()
    local args = table.clone(process.args);
    local command = table.remove(args, 1);

    output.assert(command, "specify command");

    if commands[command] then
        commands[command](args);
    else
        output.error(`no command '{command}'`);
    end
end

main();