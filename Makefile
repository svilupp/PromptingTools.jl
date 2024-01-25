# This is not a true makefile, just a collection of convenient scripts

default: help

format:
	# assumes you have JuliaFormatter installed in your global env / somewhere on LOAD_PATH
	julia -e 'using JuliaFormatter; format(".")'


help:
	echo "make help - show this help"
	echo "make format - format the code"