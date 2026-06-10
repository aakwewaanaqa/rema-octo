do.test:
	ruby src/tests/test_$1.rb

do.test.ast:
	make do.test 1=ast