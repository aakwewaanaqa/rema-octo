do.test:
	ruby tests/test_$1.rb

do.test.example:
	ruby bin/main.rb docs/usage/examples/$1/oppl.oppl

do.test.ast:
	make do.test 1=ast

do.test.tokenize:
	make do.test 1=tokenize

do.test.iterate:
	make do.test 1=iterate

do.test.magical.tokenize:
	make do.test 1=magical_tokenize

do.test.magical.ast:
	make do.test 1=magical_ast

do.test.magical.iterate:
	make do.test 1=magical_iterate

do.test.each:
	make do.test 1=each

do.test.all:
	make do.test.ast
	make do.test.tokenize
	make do.test.iterate
	make do.test.each
	make do.test.magical.tokenize
	make do.test.magical.ast
	make do.test.magical.iterate

do.clean:
	find . -type f -name '*.out.*' | while read -r o; do \
		rm "$$o"; \
	done

repl:
	ruby bin/repl.rb