
return (function (path)
  local noAutoLoad = "SKELETON.lua init.lua engine.lua";
  local filelist = {};
  for _, fn in ipairs(love.filesystem.getDirectoryItems(path:gsub("%.","/"))) do
    if fn:find(".lua$") and not noAutoLoad:find(fn) then
      table.insert(filelist, path.."."..fn:sub(1, -5));
    end;
  end;
  table.sort(filelist);
  for _, m in ipairs(filelist) do  require(m); end;
  return require (path .. ".engine");
end)(...)

