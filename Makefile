.PHONY: run docs

run:
	julia ./src/MutatedNurses.jl

docs:
	julia ./docs/make.jl