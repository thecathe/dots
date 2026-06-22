require("conform").formatters.dune_format = {
	command = "dune",
	args = { "format-dune-file" },
	stdin = true,
}

require("conform").formatters_by_ft.dune = { "dune_format" }
