package = "cpml"
version = "scm-1"
source = {
   url = "git://github.com/excessive/cpml.git"
}
description = {
   summary = "Cirno's Perfect Math Library",
   detailed = "Various useful bits of game math. 3D line intersections, ray casting, vectors, matrices, quaternions, etc.",
   homepage = "http://github.com/excessive/cpml.git",
   license = "MIT"
}
dependencies = {
   "lua ~> 5.1"
}
build = {
   type = "builtin",
   modules = {
      ["cpml"] = "init.lua",
      ["cpml.modules.color"] = "modules/color.lua",
      ["cpml.modules.constants"] = "modules/constants.lua",
      ["cpml.modules.intersect"] = "modules/intersect.lua",
      ["cpml.modules.mat4"] = "modules/mat4.lua",
      ["cpml.modules.mesh"] = "modules/mesh.lua",
      ["cpml.modules.octree"] = "modules/octree.lua",
      ["cpml.modules.quat"] = "modules/quat.lua",
      ["cpml.modules.simplex"] = "modules/simplex.lua",
      ["cpml.modules.utils"] = "modules/utils.lua",
      ["cpml.modules.vec2"] = "modules/vec2.lua",
      ["cpml.modules.vec3"] = "modules/vec3.lua",
   }
}
