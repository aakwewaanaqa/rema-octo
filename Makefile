do.test:
	ruby tests/test_$1.rb

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

repl:
	ruby bin/repl.rb