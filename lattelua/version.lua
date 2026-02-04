local version = "0.5.0"
return {
  version = version,
  print_version = function()
    return print("LatteLua version " .. tostring(version))
  end
}
