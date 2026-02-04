package = "lattelua"
version = "0.5.1-1"

source = {
	url = "git://github.com/mzujev/lattelua.git"
}

description = {
	summary = "A programmer friendly language that compiles to Lua",
	detailed = "A programmer friendly language that compiles to Lua",
	maintainer = "Mikhail Zujev <z.m.c@list.ru>",
	license = "MIT"
}

dependencies = {
	"lua >= 5.1",
	"lpeg >= 0.10, ~= 0.11"
}

build = {
	type = "make",
	makefile = "llua/Makefile",
	install = {
		bin = {
			["llua"] = "bin/llua"
		},
		lua = {
			["lattelua"] = "lattelua/init.lua",
			["lattelua.dump"] = "lattelua/dump.lua",
			["lattelua.util"] = "lattelua/util.lua",
			["lattelua.data"] = "lattelua/data.lua",
			["lattelua.types"] = "lattelua/types.lua",
			["lattelua.errors"] = "lattelua/errors.lua",
			["lattelua.version"] = "lattelua/version.lua",
			["lattelua.runtime"] = "lattelua/runtime.lua",
			["lattelua.line_tables"] = "lattelua/line_tables.lua",
			["lattelua.compile"] = "lattelua/compile.lua",
			["lattelua.compile.value"] = "lattelua/compile/value.lua",
			["lattelua.compile.statement"] = "lattelua/compile/statement.lua",
			["lattelua.parse"] = "lattelua/parse.lua",
			["lattelua.parse.env"] = "lattelua/parse/env.lua",
			["lattelua.parse.util"] = "lattelua/parse/util.lua",
			["lattelua.parse.literals"] = "lattelua/parse/literals.lua",
			["lattelua.transform"] = "lattelua/transform.lua",
			["lattelua.transform.class"] = "lattelua/transform/class.lua",
			["lattelua.transform.comprehension"] = "lattelua/transform/comprehension.lua",
			["lattelua.transform.transformer"] = "lattelua/transform/transformer.lua",
			["lattelua.transform.statements"] = "lattelua/transform/statements.lua",
			["lattelua.transform.names"] = "lattelua/transform/names.lua",
			["lattelua.transform.statement"] = "lattelua/transform/statement.lua",
			["lattelua.transform.value"] = "lattelua/transform/value.lua",
			["lattelua.transform.destructure"] = "lattelua/transform/destructure.lua",
			["lattelua.transform.accumulator"] = "lattelua/transform/accumulator.lua"
		}
	}
}

