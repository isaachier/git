#!/bin/sh

test_description='wildmatch tests'

. ./test-lib.sh

create_test_file() {
	file=$1

	case $file in
	# `touch .` will succeed but obviously not do what we intend
	# here.
	".")
		return 1
		;;
	# We cannot create a file with an empty filename.
	"")
		return 1
		;;
	# The tests that are testing that e.g. foo//bar is matched by
	# foo/*/bar can't be tested on filesystems since there's no
	# way we're getting a double slash.
	*//*)
		return 1
		;;
	# When testing the difference between foo/bar and foo/bar/ we
	# can't test the latter.
	*/)
		return 1
		;;
	esac

	# Turn foo/bar/baz into foo/bar to create foo/bar as a
	# directory structure.
	dirs=$(echo "$file" | sed -r 's!/[^/]+$!!')

	# We touch "./$file" instead of "$file" because even an
	# escaped "touch -- -" means get arguments from stdin.
	if test "$file" != "$dirs"
	then
		mkdir -p -- "$dirs" &&
		touch -- "./$file" &&
		return 0
	else
		touch -- "./$file" &&
		return 0
	fi
	return 1
}

wildtest_file_setup() {
	test_when_finished "
		rm -rf -- * &&
		git reset
	" &&
	git add -A &&
	>expect.err
}

wildtest_stdout_stderr_cmp() {
	tr -d '\0' <actual.raw >actual &&
	test_cmp expect.err actual.err &&
	test_cmp expect actual
}

wildtest() {
	if test "$#" = 6
	then
		# When test-wildmatch and git ls-files produce the same
		# result.
		match_w_glob=$1
		match_f_w_glob=$match_w_glob
		match_w_globi=$2
		match_f_w_globi=$match_w_globi
		match_w_pathmatch=$3
		match_f_w_pathmatch=$match_w_pathmatch
		match_w_pathmatchi=$4
		match_f_w_pathmatchi=$match_w_pathmatchi
		text=$5
		pattern=$6
	elif test "$#" = 10
	then
		match_w_glob=$1
		match_w_globi=$2
		match_w_pathmatch=$3
		match_w_pathmatchi=$4
		match_f_w_glob=$5
		match_f_w_globi=$6
		match_f_w_pathmatch=$7
		match_f_w_pathmatchi=$8
		text=$9
		pattern=$10
	fi

	# $1: Case sensitive glob match: test-wildmatch
	if test "$match_w_glob" = 1
	then
		test_expect_success "wildmatch: match '$text' '$pattern'" "
			test-wildmatch wildmatch '$text' '$pattern'
		"
	elif test "$match_w_glob" = 0
	then
		test_expect_success "wildmatch: no match '$text' '$pattern'" "
			! test-wildmatch wildmatch '$text' '$pattern'
		"
	else
		test_expect_success "PANIC: Test framework error. Unknown matches value $match_w_glob" 'false'
	fi

	# $1: Case sensitive glob match: ls-files
	if test "$match_f_w_glob" = 'E'
	then
		if create_test_file "$text"
		then
			test_expect_success "wildmatch(ls): match dies on '$pattern' '$text'" "
				wildtest_file_setup &&
				printf '%s' '$text' >expect &&
				test_must_fail git --glob-pathspecs ls-files -z -- '$pattern'
			"
		else
			test_expect_failure "wildmatch(ls): match skip '$pattern' '$text'" 'false'
		fi
	elif test "$match_f_w_glob" = 1
	then
		if create_test_file "$text"
		then
			test_expect_success "wildmatch(ls): match '$pattern' '$text'" "
				wildtest_file_setup &&
				printf '%s' '$text' >expect &&
				git --glob-pathspecs ls-files -z -- '$pattern' >actual.raw 2>actual.err &&
				wildtest_stdout_stderr_cmp
			"
		else
			test_expect_failure "wildmatch(ls): match skip '$pattern' '$text'" 'false'
		fi
	elif test "$match_f_w_glob" = 0
	then
		if create_test_file "$text"
		then
			test_expect_success "wildmatch(ls): no match '$pattern' '$text'" "
				wildtest_file_setup &&
				>expect &&
				git --glob-pathspecs ls-files -z -- '$pattern' >actual.raw 2>actual.err &&
				wildtest_stdout_stderr_cmp
			"
		else
			test_expect_failure "wildmatch(ls): no match skip '$pattern' '$text'" 'false'
		fi
	else
		test_expect_success "PANIC: Test framework error. Unknown matches value $match_f_w_glob" 'false'
	fi

	# $2: Case insensitive glob match: test-wildmatch
	if test "$match_w_globi" = 1
	then
		test_expect_success "iwildmatch: match '$text' '$pattern'" "
			test-wildmatch iwildmatch '$text' '$pattern'
		"
	elif test "$match_w_globi" = 0
	then
		test_expect_success "iwildmatch: no match '$text' '$pattern'" "
			! test-wildmatch iwildmatch '$text' '$pattern'
		"
	else
		test_expect_success "PANIC: Test framework error. Unknown matches value $match_w_globi" 'false'
	fi

	# $2: Case insensitive glob match: ls-files
	if test "$match_f_w_globi" = 'E'
	then
		if create_test_file "$text"
		then
			test_expect_success "wildmatch(ls): match dies on '$pattern' '$text'" "
				wildtest_file_setup &&
				printf '%s' '$text' >expect &&
				test_must_fail git --glob-pathspecs --icase-pathspecs ls-files -z -- '$pattern'
			"
		else
			test_expect_failure "wildmatch(ls): match skip '$pattern' '$text'" 'false'
		fi
	elif test "$match_f_w_globi" = 1
	then
		if create_test_file "$text"
		then
			test_expect_success "wildmatch(ls): match '$pattern' '$text'" "
				wildtest_file_setup &&
				printf '%s' '$text' >expect &&
				git --glob-pathspecs --icase-pathspecs ls-files -z -- '$pattern' >actual.raw 2>actual.err &&
				wildtest_stdout_stderr_cmp
			"
		else
			test_expect_failure "wildmatch(ls): match skip '$pattern' '$text'" 'false'
		fi
	elif test "$match_f_w_globi" = 0
	then
		if create_test_file "$text"
		then
			test_expect_success "wildmatch(ls): no match '$pattern' '$text'" "
				wildtest_file_setup &&
				>expect &&
				git --glob-pathspecs --icase-pathspecs ls-files -z -- '$pattern' >actual.raw 2>actual.err &&
				wildtest_stdout_stderr_cmp
			"
		else
			test_expect_failure "wildmatch(ls): no match skip '$pattern' '$text'" 'false'
		fi
	else
		test_expect_success "PANIC: Test framework error. Unknown matches value $match_f_w_globi" 'false'
	fi

	# $3: Case sensitive path match: test-wildmatch
	if test "$match_w_pathmatch" = 1
	then
		test_expect_success "pathmatch: match '$text' '$pattern'" "
			test-wildmatch pathmatch '$text' '$pattern'
		"
	elif test "$match_w_pathmatch" = 0
	then
		test_expect_success "pathmatch: no match '$text' '$pattern'" "
			! test-wildmatch pathmatch '$text' '$pattern'
		"
	else
		test_expect_success "PANIC: Test framework error. Unknown matches value $match_w_pathmatch" 'false'
	fi

	# $4: Case sensitive path match: ls-files
	if test "$match_f_w_pathmatch" = 'E'
	then
		if create_test_file "$text"
		then
			test_expect_success "pathmatch(ls): match dies on '$pattern' '$text'" "
				wildtest_file_setup &&
				printf '%s' '$text' >expect &&
				test_must_fail git ls-files -z -- '$pattern'
			"
		else
			test_expect_failure "pathmatch(ls): match skip '$pattern' '$text'" 'false'
		fi
	elif test "$match_f_w_pathmatch" = 1
	then
		if create_test_file "$text"
		then
			test_expect_success "pathmatch(ls): match '$pattern' '$text'" "
				wildtest_file_setup &&
				printf '%s' '$text' >expect &&
				git ls-files -z -- '$pattern' >actual.raw 2>actual.err &&
				wildtest_stdout_stderr_cmp
			"
		else
			test_expect_failure "pathmatch(ls): match skip '$pattern' '$text'" 'false'
		fi
	elif test "$match_f_w_pathmatch" = 0
	then
		if create_test_file "$text"
		then
			test_expect_success "pathmatch(ls): no match '$pattern' '$text'" "
				wildtest_file_setup &&
				>expect &&
				git ls-files -z -- '$pattern' >actual.raw 2>actual.err &&
				wildtest_stdout_stderr_cmp
			"
		else
			test_expect_failure "pathmatch(ls): no match skip '$pattern' '$text'" 'false'
		fi
	else
		test_expect_success "PANIC: Test framework error. Unknown matches value $match_f_w_pathmatch" 'false'
	fi

	# $4: Case insensitive path match: test-wildmatch
	if test "$match_w_pathmatchi" = 1
	then
		test_expect_success "ipathmatch: match '$text' '$pattern'" "
			test-wildmatch ipathmatch '$text' '$pattern'
		"
	elif test "$match_w_pathmatchi" = 0
	then
		test_expect_success "ipathmatch: no match '$text' '$pattern'" "
			! test-wildmatch ipathmatch '$text' '$pattern'
		"
	else
		test_expect_success "PANIC: Test framework error. Unknown matches value $match_w_pathmatchi" 'false'
	fi

	# $4: Case insensitive path match: ls-files
	if test "$match_f_w_pathmatchi" = 'E'
	then
		if create_test_file "$text"
		then
			test_expect_success "ipathmatch(ls): match dies on '$pattern' '$text'" "
				wildtest_file_setup &&
				printf '%s' '$text' >expect &&
				test_must_fail git --icase-pathspecs ls-files -z -- '$pattern'
			"
		else
			test_expect_failure "pathmatch(ls): match skip '$pattern' '$text'" 'false'
		fi
	elif test "$match_f_w_pathmatchi" = 1
	then
		if create_test_file "$text"
		then
			test_expect_success "ipathmatch(ls): match '$pattern' '$text'" "
				wildtest_file_setup &&
				printf '%s' '$text' >expect &&
				git --icase-pathspecs ls-files -z -- '$pattern' >actual.raw 2>actual.err &&
				wildtest_stdout_stderr_cmp
			"
		else
			test_expect_failure "pathmatch(ls): match skip '$pattern' '$text'" 'false'
		fi
	elif test "$match_f_w_pathmatchi" = 0
	then
		if create_test_file "$text"
		then
			test_expect_success "ipathmatch(ls): no match '$pattern' '$text'" "
				wildtest_file_setup &&
				>expect &&
				git ls-files -z -- '$pattern' >actual.raw 2>actual.err &&
				wildtest_stdout_stderr_cmp
			"
		else
			test_expect_failure "pathmatch(ls): no match skip '$pattern' '$text'" 'false'
		fi
	else
		test_expect_success "PANIC: Test framework error. Unknown matches value $match_f_w_pathmatchi" 'false'
	fi
}

# Basic wildmatch features
wildtest 1 1 1 1 foo foo
wildtest 0 0 0 0 foo bar
wildtest 1 1 1 1 '' ""
wildtest 1 1 1 1 foo '???'
wildtest 0 0 0 0 foo '??'
wildtest 1 1 1 1 foo '*'
wildtest 1 1 1 1 foo 'f*'
wildtest 0 0 0 0 foo '*f'
wildtest 1 1 1 1 foo '*foo*'
wildtest 1 1 1 1 foobar '*ob*a*r*'
wildtest 1 1 1 1 aaaaaaabababab '*ab'
wildtest 1 1 1 1 'foo*' 'foo\*'
wildtest 0 0 0 0 foobar 'foo\*bar'
wildtest 1 1 1 1 'f\oo' 'f\\oo'
wildtest 1 1 1 1 ball '*[al]?'
wildtest 0 0 0 0 ten '[ten]'
wildtest 0 0 1 1 ten '**[!te]'
wildtest 0 0 0 0 ten '**[!ten]'
wildtest 1 1 1 1 ten 't[a-g]n'
wildtest 0 0 0 0 ten 't[!a-g]n'
wildtest 1 1 1 1 ton 't[!a-g]n'
wildtest 1 1 1 1 ton 't[^a-g]n'
wildtest 1 1 1 1 'a]b' 'a[]]b'
wildtest 1 1 1 1 a-b 'a[]-]b'
wildtest 1 1 1 1 'a]b' 'a[]-]b'
wildtest 0 0 0 0 aab 'a[]-]b'
wildtest 1 1 1 1 aab 'a[]a-]b'
wildtest 1 1 1 1 ']' ']'

# Extended slash-matching features
wildtest 0 0 1 1 'foo/baz/bar' 'foo*bar'
wildtest 0 0 1 1 'foo/baz/bar' 'foo**bar'
wildtest 0 0 1 1 'foobazbar' 'foo**bar'
wildtest 1 1 1 1 'foo/baz/bar' 'foo/**/bar'
wildtest 1 1 0 0 'foo/baz/bar' 'foo/**/**/bar'
wildtest 1 1 1 1 'foo/b/a/z/bar' 'foo/**/bar'
wildtest 1 1 1 1 'foo/b/a/z/bar' 'foo/**/**/bar'
wildtest 1 1 0 0 'foo/bar' 'foo/**/bar'
wildtest 1 1 0 0 'foo/bar' 'foo/**/**/bar'
wildtest 0 0 1 1 'foo/bar' 'foo?bar'
wildtest 0 0 1 1 'foo/bar' 'foo[/]bar'
wildtest 0 0 1 1 'foo/bar' 'foo[^a-z]bar'
wildtest 0 0 1 1 'foo/bar' 'f[^eiu][^eiu][^eiu][^eiu][^eiu]r'
wildtest 1 1 1 1 'foo-bar' 'f[^eiu][^eiu][^eiu][^eiu][^eiu]r'
wildtest 1 1 0 0 'foo' '**/foo'
wildtest 1 1 1 1 'XXX/foo' '**/foo'
wildtest 1 1 1 1 'bar/baz/foo' '**/foo'
wildtest 0 0 1 1 'bar/baz/foo' '*/foo'
wildtest 0 0 1 1 'foo/bar/baz' '**/bar*'
wildtest 1 1 1 1 'deep/foo/bar/baz' '**/bar/*'
wildtest 0 0 1 1 'deep/foo/bar/baz/' '**/bar/*'
wildtest 1 1 1 1 'deep/foo/bar/baz/' '**/bar/**'
wildtest 0 0 0 0 'deep/foo/bar' '**/bar/*'
wildtest 1 1 1 1 'deep/foo/bar/' '**/bar/**'
wildtest 0 0 1 1 'foo/bar/baz' '**/bar**'
wildtest 1 1 1 1 'foo/bar/baz/x' '*/bar/**'
wildtest 0 0 1 1 'deep/foo/bar/baz/x' '*/bar/**'
wildtest 1 1 1 1 'deep/foo/bar/baz/x' '**/bar/*/*'

# Various additional tests
wildtest 0 0 0 0 'acrt' 'a[c-c]st'
wildtest 1 1 1 1 'acrt' 'a[c-c]rt'
wildtest 0 0 0 0 ']' '[!]-]'
wildtest 1 1 1 1 'a' '[!]-]'
wildtest 0 0 0 0 '' '\'
wildtest 0 0 0 0 \
	 1 1 1 1 '\' '\'
wildtest 0 0 0 0 'XXX/\' '*/\'
wildtest 1 1 1 1 'XXX/\' '*/\\'
wildtest 1 1 1 1 'foo' 'foo'
wildtest 1 1 1 1 '@foo' '@foo'
wildtest 0 0 0 0 'foo' '@foo'
wildtest 1 1 1 1 '[ab]' '\[ab]'
wildtest 1 1 1 1 '[ab]' '[[]ab]'
wildtest 1 1 1 1 '[ab]' '[[:]ab]'
wildtest 0 0 0 0 '[ab]' '[[::]ab]'
wildtest 1 1 1 1 '[ab]' '[[:digit]ab]'
wildtest 1 1 1 1 '[ab]' '[\[:]ab]'
wildtest 1 1 1 1 '?a?b' '\??\?b'
wildtest 1 1 1 1 'abc' '\a\b\c'
wildtest 0 0 0 0 \
	 E E E E 'foo' ''
wildtest 1 1 1 1 'foo/bar/baz/to' '**/t[o]'

# Character class tests
wildtest 1 1 1 1 'a1B' '[[:alpha:]][[:digit:]][[:upper:]]'
wildtest 0 1 0 1 'a' '[[:digit:][:upper:][:space:]]'
wildtest 1 1 1 1 'A' '[[:digit:][:upper:][:space:]]'
wildtest 1 1 1 1 '1' '[[:digit:][:upper:][:space:]]'
wildtest 0 0 0 0 '1' '[[:digit:][:upper:][:spaci:]]'
wildtest 1 1 1 1 ' ' '[[:digit:][:upper:][:space:]]'
wildtest 0 0 0 0 '.' '[[:digit:][:upper:][:space:]]'
wildtest 1 1 1 1 '.' '[[:digit:][:punct:][:space:]]'
wildtest 1 1 1 1 '5' '[[:xdigit:]]'
wildtest 1 1 1 1 'f' '[[:xdigit:]]'
wildtest 1 1 1 1 'D' '[[:xdigit:]]'
wildtest 1 1 1 1 '_' '[[:alnum:][:alpha:][:blank:][:cntrl:][:digit:][:graph:][:lower:][:print:][:punct:][:space:][:upper:][:xdigit:]]'
wildtest 1 1 1 1 '.' '[^[:alnum:][:alpha:][:blank:][:cntrl:][:digit:][:lower:][:space:][:upper:][:xdigit:]]'
wildtest 1 1 1 1 '5' '[a-c[:digit:]x-z]'
wildtest 1 1 1 1 'b' '[a-c[:digit:]x-z]'
wildtest 1 1 1 1 'y' '[a-c[:digit:]x-z]'
wildtest 0 0 0 0 'q' '[a-c[:digit:]x-z]'

# Additional tests, including some malformed wildmatch patterns
wildtest 1 1 1 1 ']' '[\\-^]'
wildtest 0 0 0 0 '[' '[\\-^]'
wildtest 1 1 1 1 '-' '[\-_]'
wildtest 1 1 1 1 ']' '[\]]'
wildtest 0 0 0 0 '\]' '[\]]'
wildtest 0 0 0 0 '\' '[\]]'
wildtest 0 0 0 0 'ab' 'a[]b'
wildtest 0 0 0 0 \
	 1 1 1 1 'a[]b' 'a[]b'
wildtest 0 0 0 0 \
	 1 1 1 1 'ab[' 'ab['
wildtest 0 0 0 0 'ab' '[!'
wildtest 0 0 0 0 'ab' '[-'
wildtest 1 1 1 1 '-' '[-]'
wildtest 0 0 0 0 '-' '[a-'
wildtest 0 0 0 0 '-' '[!a-'
wildtest 1 1 1 1 '-' '[--A]'
wildtest 1 1 1 1 '5' '[--A]'
wildtest 1 1 1 1 ' ' '[ --]'
wildtest 1 1 1 1 '$' '[ --]'
wildtest 1 1 1 1 '-' '[ --]'
wildtest 0 0 0 0 '0' '[ --]'
wildtest 1 1 1 1 '-' '[---]'
wildtest 1 1 1 1 '-' '[------]'
wildtest 0 0 0 0 'j' '[a-e-n]'
wildtest 1 1 1 1 '-' '[a-e-n]'
wildtest 1 1 1 1 'a' '[!------]'
wildtest 0 0 0 0 '[' '[]-a]'
wildtest 1 1 1 1 '^' '[]-a]'
wildtest 0 0 0 0 '^' '[!]-a]'
wildtest 1 1 1 1 '[' '[!]-a]'
wildtest 1 1 1 1 '^' '[a^bc]'
wildtest 1 1 1 1 '-b]' '[a-]b]'
wildtest 0 0 0 0 '\' '[\]'
wildtest 1 1 1 1 '\' '[\\]'
wildtest 0 0 0 0 '\' '[!\\]'
wildtest 1 1 1 1 'G' '[A-\\]'
wildtest 0 0 0 0 'aaabbb' 'b*a'
wildtest 0 0 0 0 'aabcaa' '*ba*'
wildtest 1 1 1 1 ',' '[,]'
wildtest 1 1 1 1 ',' '[\\,]'
wildtest 1 1 1 1 '\' '[\\,]'
wildtest 1 1 1 1 '-' '[,-.]'
wildtest 0 0 0 0 '+' '[,-.]'
wildtest 0 0 0 0 '-.]' '[,-.]'
wildtest 1 1 1 1 '2' '[\1-\3]'
wildtest 1 1 1 1 '3' '[\1-\3]'
wildtest 0 0 0 0 '4' '[\1-\3]'
wildtest 1 1 1 1 '\' '[[-\]]'
wildtest 1 1 1 1 '[' '[[-\]]'
wildtest 1 1 1 1 ']' '[[-\]]'
wildtest 0 0 0 0 '-' '[[-\]]'

# Test recursion
wildtest 1 1 1 1 '-adobe-courier-bold-o-normal--12-120-75-75-m-70-iso8859-1' '-*-*-*-*-*-*-12-*-*-*-m-*-*-*'
wildtest 0 0 0 0 '-adobe-courier-bold-o-normal--12-120-75-75-X-70-iso8859-1' '-*-*-*-*-*-*-12-*-*-*-m-*-*-*'
wildtest 0 0 0 0 '-adobe-courier-bold-o-normal--12-120-75-75-/-70-iso8859-1' '-*-*-*-*-*-*-12-*-*-*-m-*-*-*'
wildtest 1 1 1 1 'XXX/adobe/courier/bold/o/normal//12/120/75/75/m/70/iso8859/1' 'XXX/*/*/*/*/*/*/12/*/*/*/m/*/*/*'
wildtest 0 0 0 0 'XXX/adobe/courier/bold/o/normal//12/120/75/75/X/70/iso8859/1' 'XXX/*/*/*/*/*/*/12/*/*/*/m/*/*/*'
wildtest 1 1 1 1 'abcd/abcdefg/abcdefghijk/abcdefghijklmnop.txt' '**/*a*b*g*n*t'
wildtest 0 0 0 0 'abcd/abcdefg/abcdefghijk/abcdefghijklmnop.txtz' '**/*a*b*g*n*t'
wildtest 0 0 0 0 foo '*/*/*'
wildtest 0 0 0 0 foo/bar '*/*/*'
wildtest 1 1 1 1 foo/bba/arr '*/*/*'
wildtest 0 0 1 1 foo/bb/aa/rr '*/*/*'
wildtest 1 1 1 1 foo/bb/aa/rr '**/**/**'
wildtest 1 1 1 1 abcXdefXghi '*X*i'
wildtest 0 0 1 1 ab/cXd/efXg/hi '*X*i'
wildtest 1 1 1 1 ab/cXd/efXg/hi '*/*X*/*/*i'
wildtest 1 1 1 1 ab/cXd/efXg/hi '**/*X*/**/*i'

# Extra pathmatch tests
wildtest 0 0 0 0 foo fo
wildtest 1 1 1 1 foo/bar foo/bar
wildtest 1 1 1 1 foo/bar 'foo/*'
wildtest 0 0 1 1 foo/bba/arr 'foo/*'
wildtest 1 1 1 1 foo/bba/arr 'foo/**'
wildtest 0 0 1 1 foo/bba/arr 'foo*'
wildtest 0 0 1 1 \
	 1 1 1 1 foo/bba/arr 'foo**'
wildtest 0 0 1 1 foo/bba/arr 'foo/*arr'
wildtest 0 0 1 1 foo/bba/arr 'foo/**arr'
wildtest 0 0 0 0 foo/bba/arr 'foo/*z'
wildtest 0 0 0 0 foo/bba/arr 'foo/**z'
wildtest 0 0 1 1 foo/bar 'foo?bar'
wildtest 0 0 1 1 foo/bar 'foo[/]bar'
wildtest 0 0 1 1 foo/bar 'foo[^a-z]bar'
wildtest 0 0 1 1 ab/cXd/efXg/hi '*Xg*i'

# Extra case-sensitivity tests
wildtest 0 1 0 1 'a' '[A-Z]'
wildtest 1 1 1 1 'A' '[A-Z]'
wildtest 0 1 0 1 'A' '[a-z]'
wildtest 1 1 1 1 'a' '[a-z]'
wildtest 0 1 0 1 'a' '[[:upper:]]'
wildtest 1 1 1 1 'A' '[[:upper:]]'
wildtest 0 1 0 1 'A' '[[:lower:]]'
wildtest 1 1 1 1 'a' '[[:lower:]]'
wildtest 0 1 0 1 'A' '[B-Za]'
wildtest 1 1 1 1 'a' '[B-Za]'
wildtest 0 1 0 1 'A' '[B-a]'
wildtest 1 1 1 1 'a' '[B-a]'
wildtest 0 1 0 1 'z' '[Z-y]'
wildtest 1 1 1 1 'Z' '[Z-y]'

test_done
