.PHONY: run docs

run:
	julia ./src/MutatedNurses.jl

docs:
	source .env && julia ./docs/make.jl