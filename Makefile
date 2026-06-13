do.test:
	ruby src/tests/test_$1.rb

do.test.ast:
	make do.test 1=ast

do.test.parse:
	make do.test 1=parse

do.test.tokenize:
	make do.test 1=tokenize

do.test.iterate:
	make do.test 1=iterate

do.test.all:
	make do.test.ast
	make do.test.parse
	make do.test.tokenize
	make do.test.iterate