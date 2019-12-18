.PHONY: all clean dep publish promote test test-all docker depext push

all: test
	@dune build @site
	@echo Site has been generated in _build/default/static/
	cp -r _build/default/static/* docs/
	git add docs

test: tool
	@dune build @runtest
	@dune exec -- otb-dep $(CURDIR)

test-all:
	@dune build @runtest-all

tool:
	@dune build @install

promote:
	@dune promote

clean:
	@dune clean

push:
	git commit -am "editing book ..." && \
	git push origin `git branch | grep \* | cut -d ' ' -f2`
