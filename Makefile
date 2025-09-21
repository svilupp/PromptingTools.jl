# This is not a true makefile, just a collection of convenient scripts

default: help

format:
	# assumes you have JuliaFormatter installed in your global env / somewhere on LOAD_PATH
	julia --project=@Fmt -e 'using JuliaFormatter; format(".")'

test:
	julia --project=. -e 'using Pkg; Pkg.test()'

help:
	echo "make help - show this help"
	echo "make format - format the code"