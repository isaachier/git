cmake_minimum_required(VERSION 3.3)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

set(bin_dir "bin")
set(lib_dir "lib")
set(git_exec_dir "libexec/git-core")
set(mergetools_dir "${git_exec_dir}/mergetools")
set(share_dir "share")
set(man_dir "${share_dir}/man")
set(info_dir "${share_dir}/info")
set(gitweb_dir "${share_dir}/gitweb")
set(locale_dir "${share_dir}/locale")
set(template_dir "${share_dir}/git-core/templates")
set(html_dir "${share_dir}/doc/git-doc")
set(etc_gitconfig "etc/gitconfig")
set(etc_gitattributes "etc/gitattributes")

find_package(Git)
if(IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/.git" AND GIT_FOUND)
  execute_process(COMMAND ${GIT_EXECUTABLE} rev-parse -q --verify HEAD
                  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                  OUTPUT_VARIABLE GIT_BUILT_FROM_COMMIT
                  OUTPUT_STRIP_TRAILING_WHITESPACE)
  message(STATUS "GIT_BUILT_FROM_COMMIT: ${GIT_BUILT_FROM_COMMIT}")
endif()

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/version" AND
   NOT IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/version")
  file(READ "${CMAKE_CURRENT_SOURCE_DIR}/version" GIT_VERSION)
elseif(IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/.git" AND GIT_FOUND)
  execute_process(COMMAND ${GIT_EXECUTABLE} describe --match "v[0-9]*" HEAD
                  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                  OUTPUT_VARIABLE GIT_VERSION
                  OUTPUT_STRIP_TRAILING_WHITESPACE)
  if(GIT_VERSION MATCHES "v[0-9]*")
    string(REPLACE "-" "." GIT_VERSION "${GIT_VERSION}")
    execute_process(COMMAND ${GIT_EXECUTABLE} diff-index --name-only HEAD --
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                    OUTPUT_VARIABLE git_diff_index_output
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(git_diff_index_output)
      set(GIT_VERSION "${GIT_VERSION}.dirty")
    endif()
    message(STATUS "GIT_VERSION: ${GIT_VERSION}")
  else()
    message(FATAL_ERROR "Cannot determine project version")
  endif()
else()
  set(GIT_VERSION "${DEFAULT_VERSION}")
endif()

string(REGEX REPLACE "^v([0-9]+\\.[0-9]+\\.[0-9]+).*$" "\\1"
       simplified_version "${GIT_VERSION}")
project(git VERSION "${simplified_version}" LANGUAGES C)
message(STATUS "PROJECT_VERSION: ${PROJECT_VERSION}")

set(GIT_USER_AGENT "git/${PROJECT_VERSION}" CACHE STRING
    "User-agent used for network interactions")
message(STATUS "GIT_USER_AGENT: ${GIT_USER_AGENT}")

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

include(CheckCCompilerFlag)
include(CheckIncludeFile)
include(CheckFunctionExists)
include(CheckLibraryExists)
include(CheckPrototypeDefinition)
include(CheckStructHasMember)
include(CheckSymbolExists)
include(CheckTypeSize)
include(CMakeDependentOption)
include(CTest)

include(GenerateCmdlist)

generate_cmdlist()

macro(print_bool arg_name)
  if(${arg_name})
    message(STATUS "${arg_name}: true")
  else()
    message(STATUS "${arg_name}: false")
  endif()
endmacro()

macro(add_c_flag c_flags flag)
  string(MAKE_C_IDENTIFIER "${flag}" flag_var)
  check_c_compiler_flag("${flag}" have_${flag_var})
  if(have_${flag_var})
    set(${c_flags} "${${c_flags}} ${flag}")
  endif()
endmacro()

# Sources defined here to append to during configuration stage.

set(program_src
    "credential-store.c"
    "daemon.c"
    "fast-import.c"
    "http-backend.c"
    "sh-i18n--envsubst.c"
    "shell.c"
    "show-index.c"
    "upload-pack.c")

if(ENABLE_TESTING)
  set(test_program_src
    "t/helper/test-chmtime.c"
    "t/helper/test-ctype.c"
    "t/helper/test-config.c"
    "t/helper/test-date.c"
    "t/helper/test-delta.c"
    "t/helper/test-drop-caches.c"
    "t/helper/test-dump-cache-tree.c"
    "t/helper/test-dump-fsmonitor.c"
    "t/helper/test-dump-split-index.c"
    "t/helper/test-dump-untracked-cache.c"
    "t/helper/test-example-decorate.c"
    "t/helper/test-fake-ssh.c"
    "t/helper/test-genrandom.c"
    "t/helper/test-hashmap.c"
    "t/helper/test-index-version.c"
    "t/helper/test-lazy-init-name-hash.c"
    "t/helper/test-line-buffer.c"
    "t/helper/test-match-trees.c"
    "t/helper/test-mergesort.c"
    "t/helper/test-mktemp.c"
    "t/helper/test-online-cpus.c"
    "t/helper/test-parse-options.c"
    "t/helper/test-path-utils.c"
    "t/helper/test-prio-queue.c"
    "t/helper/test-read-cache.c"
    "t/helper/test-write-cache.c"
    "t/helper/test-ref-store.c"
    "t/helper/test-regex.c"
    "t/helper/test-revision-walking.c"
    "t/helper/test-run-command.c"
    "t/helper/test-scrap-cache-tree.c"
    "t/helper/test-sha1.c"
    "t/helper/test-sha1-array.c"
    "t/helper/test-sigchain.c"
    "t/helper/test-strcmp-offset.c"
    "t/helper/test-string-list.c"
    "t/helper/test-submodule-config.c"
    "t/helper/test-subprocess.c"
    "t/helper/test-svn-fe.c"
    "t/helper/test-urlmatch-normalization.c"
    "t/helper/test-wildmatch.c")
endif()

set(lib_src
    "abspath.c"
    "advice.c"
    "alias.c"
    "alloc.c"
    "apply.c"
    "archive.c"
    "archive-tar.c"
    "archive-zip.c"
    "argv-array.c"
    "attr.c"
    "base85.c"
    "bisect.c"
    "blame.c"
    "blob.c"
    "branch.c"
    "bulk-checkin.c"
    "bundle.c"
    "cache-tree.c"
    "checkout.c"
    "color.c"
    "column.c"
    "combine-diff.c"
    "commit.c"
    "compat/obstack.c"
    "compat/terminal.c"
    "config.c"
    "connect.c"
    "connected.c"
    "convert.c"
    "copy.c"
    "credential.c"
    "csum-file.c"
    "ctype.c"
    "date.c"
    "decorate.c"
    "diffcore-break.c"
    "diffcore-delta.c"
    "diffcore-order.c"
    "diffcore-pickaxe.c"
    "diffcore-rename.c"
    "diff-delta.c"
    "diff-lib.c"
    "diff-no-index.c"
    "diff.c"
    "dir.c"
    "dir-iterator.c"
    "editor.c"
    "entry.c"
    "environment.c"
    "ewah/bitmap.c"
    "ewah/ewah_bitmap.c"
    "ewah/ewah_io.c"
    "ewah/ewah_rlw.c"
    "exec_cmd.c"
    "fetch-pack.c"
    "fsck.c"
    "fsmonitor.c"
    "gettext.c"
    "gpg-interface.c"
    "graph.c"
    "grep.c"
    "hashmap.c"
    "help.c"
    "hex.c"
    "ident.c"
    "kwset.c"
    "levenshtein.c"
    "line-log.c"
    "line-range.c"
    "list-objects.c"
    "list-objects-filter.c"
    "list-objects-filter-options.c"
    "ll-merge.c"
    "lockfile.c"
    "log-tree.c"
    "mailinfo.c"
    "mailmap.c"
    "match-trees.c"
    "merge.c"
    "merge-blobs.c"
    "merge-recursive.c"
    "mergesort.c"
    "mru.c"
    "name-hash.c"
    "notes.c"
    "notes-cache.c"
    "notes-merge.c"
    "notes-utils.c"
    "object.c"
    "oidmap.c"
    "oidset.c"
    "packfile.c"
    "pack-bitmap.c"
    "pack-bitmap-write.c"
    "pack-check.c"
    "pack-objects.c"
    "pack-revindex.c"
    "pack-write.c"
    "pager.c"
    "parse-options.c"
    "parse-options-cb.c"
    "patch-delta.c"
    "patch-ids.c"
    "path.c"
    "pathspec.c"
    "pkt-line.c"
    "preload-index.c"
    "pretty.c"
    "prio-queue.c"
    "progress.c"
    "prompt.c"
    "protocol.c"
    "quote.c"
    "reachable.c"
    "read-cache.c"
    "reflog-walk.c"
    "refs.c"
    "refs/files-backend.c"
    "refs/iterator.c"
    "refs/packed-backend.c"
    "refs/ref-cache.c"
    "ref-filter.c"
    "remote.c"
    "replace_object.c"
    "repository.c"
    "rerere.c"
    "resolve-undo.c"
    "revision.c"
    "run-command.c"
    "send-pack.c"
    "sequencer.c"
    "server-info.c"
    "setup.c"
    "sha1-array.c"
    "sha1-lookup.c"
    "sha1_file.c"
    "sha1_name.c"
    "shallow.c"
    "sideband.c"
    "sigchain.c"
    "split-index.c"
    "strbuf.c"
    "streaming.c"
    "string-list.c"
    "submodule.c"
    "submodule-config.c"
    "sub-process.c"
    "symlinks.c"
    "tag.c"
    "tempfile.c"
    "tmp-objdir.c"
    "trace.c"
    "trailer.c"
    "transport.c"
    "transport-helper.c"
    "tree-diff.c"
    "tree.c"
    "tree-walk.c"
    "unpack-trees.c"
    "url.c"
    "urlmatch.c"
    "usage.c"
    "userdiff.c"
    "utf8.c"
    "varint.c"
    "version.c"
    "versioncmp.c"
    "walker.c"
    "wildmatch.c"
    "worktree.c"
    "wrapper.c"
    "write_or_die.c"
    "ws.c"
    "wt-status.c"
    "xdiff-interface.c"
    "zlib")

set(builtin_src
    "builtin/add.c"
    "builtin/am.c"
    "builtin/annotate.c"
    "builtin/apply.c"
    "builtin/archive.c"
    "builtin/bisect--helper.c"
    "builtin/blame.c"
    "builtin/branch.c"
    "builtin/bundle.c"
    "builtin/cat-file.c"
    "builtin/check-attr.c"
    "builtin/check-ignore.c"
    "builtin/check-mailmap.c"
    "builtin/check-ref-format.c"
    "builtin/checkout-index.c"
    "builtin/checkout.c"
    "builtin/clean.c"
    "builtin/clone.c"
    "builtin/column.c"
    "builtin/commit-tree.c"
    "builtin/commit.c"
    "builtin/config.c"
    "builtin/count-objects.c"
    "builtin/credential.c"
    "builtin/describe.c"
    "builtin/diff-files.c"
    "builtin/diff-index.c"
    "builtin/diff-tree.c"
    "builtin/diff.c"
    "builtin/difftool.c"
    "builtin/fast-export.c"
    "builtin/fetch-pack.c"
    "builtin/fetch.c"
    "builtin/fmt-merge-msg.c"
    "builtin/for-each-ref.c"
    "builtin/fsck.c"
    "builtin/gc.c"
    "builtin/get-tar-commit-id.c"
    "builtin/grep.c"
    "builtin/hash-object.c"
    "builtin/help.c"
    "builtin/index-pack.c"
    "builtin/init-db.c"
    "builtin/interpret-trailers.c"
    "builtin/log.c"
    "builtin/ls-files.c"
    "builtin/ls-remote.c"
    "builtin/ls-tree.c"
    "builtin/mailinfo.c"
    "builtin/mailsplit.c"
    "builtin/merge.c"
    "builtin/merge-base.c"
    "builtin/merge-file.c"
    "builtin/merge-index.c"
    "builtin/merge-ours.c"
    "builtin/merge-recursive.c"
    "builtin/merge-tree.c"
    "builtin/mktag.c"
    "builtin/mktree.c"
    "builtin/mv.c"
    "builtin/name-rev.c"
    "builtin/notes.c"
    "builtin/pack-objects.c"
    "builtin/pack-redundant.c"
    "builtin/pack-refs.c"
    "builtin/patch-id.c"
    "builtin/prune-packed.c"
    "builtin/prune.c"
    "builtin/pull.c"
    "builtin/push.c"
    "builtin/read-tree.c"
    "builtin/rebase--helper.c"
    "builtin/receive-pack.c"
    "builtin/reflog.c"
    "builtin/remote.c"
    "builtin/remote-ext.c"
    "builtin/remote-fd.c"
    "builtin/repack.c"
    "builtin/replace.c"
    "builtin/rerere.c"
    "builtin/reset.c"
    "builtin/rev-list.c"
    "builtin/rev-parse.c"
    "builtin/revert.c"
    "builtin/rm.c"
    "builtin/send-pack.c"
    "builtin/shortlog.c"
    "builtin/show-branch.c"
    "builtin/show-ref.c"
    "builtin/stripspace.c"
    "builtin/submodule--helper.c"
    "builtin/symbolic-ref.c"
    "builtin/tag.c"
    "builtin/unpack-file.c"
    "builtin/unpack-objects.c"
    "builtin/update-index.c"
    "builtin/update-ref.c"
    "builtin/update-server-info.c"
    "builtin/upload-archive.c"
    "builtin/var.c"
    "builtin/verify-commit.c"
    "builtin/verify-pack.c"
    "builtin/verify-tag.c"
    "builtin/worktree.c"
    "builtin/write-tree.c")

add_c_flag(CMAKE_C_FLAGS "-Wall")

option(DEVELOPER "Enable developer warnings" OFF)
if(DEVELOPER)
  set(dev_c_flags
      "-Werror"
      "-Wdeclaration-after-statement"
      "-Wno-format-zero-length"
      "-Wold-style-definition"
      "-Woverflow"
      "-Wpointer-arith"
      "-Wstrict-prototypes"
      "-Wunused"
      "-Wvla")
  foreach(flag ${dev_c_flags})
    add_c_flag(CMAKE_C_FLAGS "${flag}")
  endforeach()
endif()

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(SANITIZE "" CACHE STRING "Comma-delimited list of sanitizer flags")
if(SANITIZE)
  add_c_flag(CMAKE_C_FLAGS "-fsanitize=${SANITIZE}")
  add_c_flag(CMAKE_C_FLAGS "-fno-sanitize-recover=${SANITIZE}")
  add_c_flag(CMAKE_C_FLAGS "-fno-omit-frame-pointer")
  string(REPLACE "," ";" SANITIZERS "${SANITIZE}")
  if("undefined" IN_LIST SANITIZERS)
    list(APPEND basic_defs "-DNO_UNALIGNED_LOADS")
  endif()
  if("leak" IN_LIST SANITIZERS)
    list(APPEND basic_defs "-DSUPPRESS_ANNOTATED_LEAKS")
  endif()
endif()

message(STATUS "CMAKE_C_FLAGS: ${CMAKE_C_FLAGS}")

list(APPEND basic_defs "-DGIT_HOST_CPU=\"${CMAKE_SYSTEM_PROCESSOR}\"")
message(STATUS "GIT_HOST_CPU: ${CMAKE_SYSTEM_PROCESSOR}")

if(WIN32)
  set(socket_headers "winsock2.h;ws2tcpip.h")
else()
  set(socket_headers "sys/types.h;sys/socket.h")
endif()

set(CMAKE_EXTRA_INCLUDE_FILES ${socket_headers})
check_type_size(socklen_t sizeof_socklen_t)
if(sizeof_socklen_t)
  set(SOCKLEN_T "socklen_t")
else()
  set(SOCKLEN_T "size_t")
endif()
set(CMAKE_EXTRA_INCLUDE_FILES)
message(STATUS "socklen_t type: ${SOCKLEN_T}")
if(SOCKLEN_T)
  list(APPEND basic_defs "-Dsocklen_t=${SOCKLEN_T}")
endif()

set(INLINE "")
foreach(inline_keyword "inline" "__inline" "__inline__")
  try_compile(inline_compile_result
    "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/CMakeTmp"
    SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/cmake/inline_test.c"
    COMPILE_DEFINITIONS "-DINLINE=${inline_keyword}")
  if(inline_compile_result)
    set(INLINE "${inline_keyword}")
    break()
  endif()
endforeach()
message(STATUS "INLINE: ${INLINE}")
if(INLINE)
  list(APPEND basic_defs "-DINLINE=${INLINE}")
endif()

if(NOT CMAKE_CROSSCOMPILING)
  string(REPLACE "-Wall" "" flags_warning_disabled "${CMAKE_C_FLAGS}")
  string(REPLACE "-Werror" "" flags_warning_disabled
         "${flags_warning_disabled}")
  try_run(snprintf_run_result
          snprintf_compile_result
          "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/CMakeTmp"
          "${CMAKE_CURRENT_SOURCE_DIR}/cmake/snprintf_test.c"
          CMAKE_FLAGS "-DCMAKE_C_FLAGS=${flags_warnings_disabled}"
          COMPILE_OUTPUT_VARIABLE snprintf_compile_output)
  if(snprintf_compile_result)
    if(snprintf_run_result EQUAL -1)
      set(SNPRINTF_RETURNS_BOGUS ON)
    elseif(NOT snprintf_run_result EQUAL 2)
      message(WARNING
        "Invalid return value for snprintf_test: ${snprintf_run_result}")
      set(SNPRINTF_RETURNS_BOGUS ON)
    endif()
  else()
    message(WARNING "Cannot compile snprintf_test: ${snprintf_compile_output}")
    set(SNPRINTF_RETURNS_BOGUS ON)
  endif()
endif()
print_bool(SNPRINTF_RETURNS_BOGUS)
if(SNPRINTF_RETURNS_BOGUS)
  list(APPEND compat_defs "-DSNPRINTF_RETURNS_BOGUS")
  list(APPEND compat_src "compat/snprintf.c")
endif()

if(NOT CMAKE_CROSSCOMPILING)
  try_run(fopen_dir_run_result
          fopen_dir_compile_result
          "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/CMakeTmp"
          "${CMAKE_CURRENT_SOURCE_DIR}/cmake/fopen_dir_test.c"
          COMPILE_OUTPUT_VARIABLE fopen_dir_compile_output
          ARGS "${CMAKE_CURRENT_SOURCE_DIR}")
  if(fopen_dir_compile_result)
    if(fopen_dir_run_result EQUAL 0)
      set(FREAD_READS_DIRECTORIES ON)
    endif()
  else()
    message(WARNING "Cannot compile fopen_dir_test: "
            "${fopen_dir_compile_output}")
  endif()
endif()
print_bool(FREAD_READS_DIRECTORIES)
if(FREAD_READS_DIRECTORIES)
  list(APPEND compat_defs "-DFREAD_READS_DIRECTORIES")
  list(APPEND compat_src "compat/fopen.c")
endif()

find_package(OpenSSL)
cmake_dependent_option(OPENSSL "Use OpenSSL" ON "OPENSSL_FOUND" OFF)

set(PCRE_VERSION "" CACHE STRING "pcre version (1 or 2), leave blank to omit")
set_property(CACHE PCRE_VERSION PROPERTY STRINGS "1;2")
if(PCRE_VERSION AND NOT PCRE_VERSION MATCHES "^(1|2)$")
  message(FATAL_ERROR "Invalid pcre version, must be blank, 1, or 2")
endif()

if(PCRE_VERSION)
  if(NOT DEFINED PCRE_LIBRARY OR NOT DEFINED PCRE_INCLUDE_DIR)
    if(PCRE_VERSION STREQUAL "2")
      find_path(PCRE_INCLUDE_DIR "pcre2.h")
      find_library(PCRE_LIBRARY NAMES pcre2)
    else()
      set(PCRE_VERSION "1")
      find_path(PCRE_INCLUDE_DIR "pcre.h")
      find_library(PCRE_LIBRARY NAMES pcre)
    endif()
    mark_as_advanced(PCRE_LIBRARY PCRE_INCLUDE_DIR)

    message(STATUS "PCRE_VERSION: ${PCRE_VERSION}")
    message(STATUS "PCRE_INCLUDE_DIR: ${PCRE_INCLUDE_DIR}")
    message(STATUS "PCRE_LIBRARY: ${PCRE_LIBRARY}")
  endif()

  if(PCRE_INCLUDE_DIR AND PCRE_LIBRARY)
    list(APPEND basic_defs "-DUSE_LIBPCRE${PCRE_VERSION}")
    list(APPEND include_dirs ${PCRE_INCLUDE_DIR})
    list(APPEND libs ${PCRE_LIBRARY})

    if(PCRE_VERSION STREQUAL "1" AND PCRE_LIBRARY)
      check_symbol_exists(PCRE_JIT_CONFIG "pcre.h" has_jit)
      set(CMAKE_REQUIRED_INCLUDES)
      if(has_jit)
        set(LIBPCRE1_JIT ON)
      endif()
      print_bool(LIBPCRE1_JIT)
      if(NOT LIBPCRE1_JIT)
        list(APPEND basic_defs "-DNO_LIBPCRE1_JIT")
      endif()
    endif()
  endif()
endif()

check_include_file("alloca.h" HAVE_ALLOCA_H)
print_bool(HAVE_ALLOCA_H)
if(HAVE_ALLOCA_H)
  list(APPEND basic_defs "-DHAVE_ALLOCA_H")
endif()

find_package(CURL)
cmake_dependent_option(CURL "Use libcurl, needed for HTTP transport" ON
                       "CURL_FOUND" OFF)
if(CURL)
  set(NO_CURL "0")
else()
  set(NO_CURL "1")
  list(APPEND basic_defs "-DNO_CURL")
endif()

find_package(EXPAT)
cmake_dependent_option(EXPAT "Enable expat for HTTP parsing" ON
                      "EXPAT_FOUND" OFF)
# EXPAT_NEEDS_XMLPARSE_H not handled in CMake build, seeing as CMake FindEXPAT
# explicitly relies on the existence of "expat.h" to find includes directory.

if(CURL AND CURL_VERSION_STRING VERSION_GREATER_EQUAL "7.22.0")
  list(APPEND basic_defs "-DUSE_CURL_FOR_IMAP_SEND")
  set(imap_send_builddeps "http.c")
  set(imap_send_libs ${CURL_LIBRARIES})
endif()

find_package(Gettext)
find_package(Intl)
cmake_dependent_option(GETTEXT "Translate git output" ON
                       "GETTEXT_FOUND;Intl_FOUND" OFF)

find_library(iconv_lib_path NAMES iconv libiconv libiconv-2)
if(iconv_lib_path)
  set(iconv_lib ${iconv_lib_path})
endif()

if(NOT GETTEXT)
  list(APPEND basic_defs "-DNO_GETTEXT")
  set(no_gettext ON)
endif()
cmake_dependent_option(USE_GETTEXT_SCHEME_FALLTHROUGH "${doc_string}" OFF
                       "no_gettext" ON)
if(GETTEXT)
  set(doc_string "Enable if you do not trust installed gettext translation")
  set(doc_string "${doc_string} of the shell scripts output")

  check_include_file("libcharset.h" HAVE_LIBCHARSET_H)
  if(HAVE_LIBCHARSET_H)
    list(APPEND basic_defs "-DHAVE_LIBCHARSET_H")
    check_library_exists(charset locale_charset "" have_libcharset)
    if(have_libcharset)
      set(CHARSET_LIB charset)
    elseif(iconv_lib)
      check_library_exists(${iconv_lib} locale_charset "" have_locale_charset_libiconv)
      if(have_locale_charset_libiconv)
        set(CHARSET_LIB ${iconv_lib})
      else()
        message(FATAL_ERROR "Cannot find library that defines locale_charset")
      endif()
    endif()
    list(APPEND libs ${CHARSET_LIB})
  endif()

  check_function_exists(nl_langinfo LIBC_CONTAINS_LIBINTL)
  print_bool(LIBC_CONTAINS_LIBINTL)
  if(NOT LIBC_CONTAINS_LIBINTL)
    list(APPEND libs ${Intl_LIBRARY})
    set(CMAKE_REQUIRED_LIBRARIES "${Intl_LIBRARY}")
    check_function_exists(nl_langinfo nl_langinfo_found)
    if(NOT nl_langinfo_found)
      message(FATAL_ERROR "nl_langinfo cannot be found in ${Intl_LIBRARY}")
    endif()
    set(CMAKE_REQUIRED_LIBRARIES)
  endif()

  # TODO: MSGFMT_EXTENDED_OPTIONS?
endif()

check_include_file("paths.h" HAVE_PATHS_H)
print_bool(HAVE_PATHS_H)
if(HAVE_PATHS_H)
  list(APPEND basic_defs "-DHAVE_PATHS_H")
endif()

check_include_file("inttypes.h" HAVE_INTTYPES_H)
print_bool(HAVE_INTTYPES_H)
if(NOT HAVE_INTTYPES_H)
  list(APPEND basic_defs "-DNO_INTTYPES_H")
endif()

check_symbol_exists(DT_UNKNOWN "dirent.h" have_dt_unknown)
if(have_dt_unknown)
  check_struct_has_member("struct dirent" d_type "dirent.h" have_d_type)
  if(have_d_type)
    set(D_TYPE_IN_DIRENT ON)
  endif()
  print_bool(D_TYPE_IN_DIRENT)
else()
  set(D_TYPE_IN_DIRENT ON)
endif()

if(NOT D_TYPE_IN_DIRENT)
  list(APPEND basic_defs "-DNO_D_TYPE_IN_DIRENT")
endif()

check_include_file("strings.h" HAVE_STRINGS_H)
print_bool(HAVE_STRINGS_H)
if(HAVE_STRINGS_H)
  list(APPEND basic_defs "-DHAVE_STRINGS_H")
endif()

check_function_exists(strcasestr STRCASESTR)
print_bool(STRCASESTR)
if(NOT STRCASESTR)
  list(APPEND compat_defs "-DNO_STRCASESTR")
  list(APPEND compat_src "compat/strcasestr.c")
endif()

check_function_exists(hstrerror HSTRERROR)
print_bool(HSTRERROR)
if(NOT HSTRERROR)
  list(APPEND compat_defs "-DNO_HSTRERROR")
  list(APPEND compat_src "compat/hstrerror.c")
endif()

check_function_exists(memmem MEMMEM)
print_bool(MEMMEM)
if(NOT MEMMEM)
  list(APPEND compat_defs "-DNO_MEMMEM")
  list(APPEND compat_src "compat/memmem.c")
endif()

check_function_exists(getpagesize GETPAGESIZE)
print_bool(GETPAGESIZE)
if(NOT GETPAGESIZE)
  list(APPEND compat_defs "-DNO_GETPAGESIZE")
endif()

check_function_exists(strlcpy STRLCPY)
print_bool(STRLCPY)
if(NOT STRLCPY)
  list(APPEND compat_defs "-DNO_STRLCPY")
  list(APPEND compat_src "compat/strlcpy.c")
endif()

check_function_exists(strtoimax have_strtoimax)
if(NOT have_strtoimax)
  check_function_exists(strtoumax have_strtoumax)
endif()
if(have_strtoimax OR have_strtoumax)
  set(STRTOUMAX ON)
endif()
print_bool(STRTOUMAX)
if(NOT STRTOUMAX)
  list(APPEND compat_defs "-DNO_STRTOUMAX")
  list(APPEND compat_src
       "compat/strtoumax.c"
       "compat/strtoimax.c")
endif()

check_function_exists(strtoull STRTOULL)
print_bool(STRTOULL)
if(NOT STRTOULL)
  list(APPEND compat_defs "-DNO_STRTOULL")
endif()

check_function_exists(setenv SETENV)
print_bool(SETENV)
if(NOT SETENV)
  list(APPEND compat_defs "-DNO_SETENV")
  list(APPEND compat_src "compat/setenv.c")
endif()

check_function_exists(unsetenv UNSETENV)
print_bool(UNSETENV)
if(NOT UNSETENV)
  list(APPEND compat_defs "-DNO_UNSETENV")
  list(APPEND compat_src "compat/unsetenv.c")
endif()

check_function_exists(mkdtemp MKDTEMP)
print_bool(MKDTEMP)
if(NOT MKDTEMP)
  list(APPEND compat_defs "-DNO_MKDTEMP")
  list(APPEND compat_src "compat/mkdtemp.c")
endif()

check_function_exists(initgroups INITGROUPS)
print_bool(INITGROUPS)
if(NOT INITGROUPS)
  list(APPEND compat_defs "-DNO_INITGROUPS")
endif()

if(NOT CMAKE_CROSSCOMPILING)
  set(test_dir_path "${CMAKE_CURRENT_BINARY_DIR}/mkdir_test_dir")
  try_run(mkdir_run_result
          mkdir_compile_result
          "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/CMakeTmp"
          "${CMAKE_CURRENT_SOURCE_DIR}/cmake/mkdir_test.c"
          COMPILE_OUTPUT_VARIABLE mkdir_compile_output
          ARGS "${test_dir_path}/")
  if(mkdir_compile_result)
    if(mkdir_run_result EQUAL 0 AND IS_DIRECTORY "${test_dir_path}")
      file(REMOVE_RECURSE "${test_dir_path}")
      set(MKDIR_W_TRAILING_SLASH ON)
    endif()
  else()
    message(WARNING "Failed to compile mkdir_test: ${mkdir_compile_output}")
  endif()
endif()
print_bool(MKDIR_W_TRAILING_SLASH)
if(NOT MKDIR_W_TRAILING_SLASH)
  list(APPEND compat_defs "-DMKDIR_WO_TRAILING_SLASH")
  list(APPEND compat_src "compat/mkdir.c")
endif()

check_struct_has_member("struct passwd" pw_gecos "pwd.h" GECOS_IN_PWENT)
print_bool(GECOS_IN_PWENT)
if(NOT GECOS_IN_PWENT)
  list(APPEND basic_defs "-DNO_GECOS_IN_PWENT")
endif()

check_include_file("libgen.h" LIBGEN_H)
print_bool(LIBGEN_H)
if(NOT LIBGEN_H)
  list(APPEND compat_defs "-DNO_LIBGEN_H")
  list(APPEND compat_src "compat/basename.c")
endif()

check_function_exists(dirname libc_has_dirname)
if(NOT libc_has_dirname)
  set(NEEDS_LIBGEN ON)
endif()
print_bool(NEEDS_LIBGEN)
if(NEEDS_LIBGEN)
  list(APPEND libs gen)
endif()

check_include_file("sys/select.h" SYS_SELECT_H)
print_bool(SYS_SELECT_H)
if(NOT SYS_SELECT_H)
  list(APPEND basic_defs "-DNO_SYS_SELECT_H")
endif()

if(NOT WIN32)
  set(not_windows ON)
endif()
cmake_dependent_option(
  SYMLINK_HEAD "Occasionally use symbolic link for .git/HEAD" ON
  "not_windows" OFF)
print_bool(SYMLINK_HEAD)
if(NOT SYMLINK_HEAD)
  list(APPEND basic_defs "-DNO_SYMLINK_HEAD")
endif()

option(SVN_TESTS "Build time-consuming SVN tests" ON)
print_bool(SVN_TESTS)

if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
  set(doc_template "Use @tool@ installations when present in @location@ for")
  set(doc_template "${doc_template} includes/libraries")

  set(tool "Fink")
  set(location "/sw")
  string(CONFIGURE doc_string "${doc_template}")
  option(FINK "${doc_string}" ON)
  print_bool(FINK)
  if(FINK AND IS_DIRECTORY "/sw")
    if(IS_DIRECTORY "/sw/include")
      list(APPEND include_dirs "/sw/include")
    endif()
    if(IS_DIRECTORY "/sw/lib")
      list(APPEND link_dirs "/sw/lib")
    endif()
  endif()

  set(tool "DarwinPorts")
  set(location "/opt/local")
  string(CONFIGURE doc_string "${doc_template}")
  option(DARWIN_PORTS "${doc_string}" ON)
  print_bool(DARWIN_PORTS)
  if(DARWIN_PORTS AND IS_DIRECTORY "/opt/local")
    if(IS_DIRECTORY "/opt/local/include")
      list(APPEND include_dirs "/opt/local/include")
    endif()
    if(IS_DIRECTORY "/opt/local/lib")
      list(APPEND link_dirs "/opt/local/lib")
    endif()
  endif()

  option(APPLE_COMMON_CRYPTO "Use Apple's CommonCrypto library" ON)
  print_bool(APPLE_COMMON_CRYPTO)
  if(APPLE_COMMON_CRYPTO)
    list(APPEND compat_defs "-DAPPLE_COMMON_CRYPTO")
  endif()
endif()

set(doc_string
    "Limit the amount of data that will be hashed in one call to the "
    "platform's SHA1_Update()")
if(APPLE_COMMON_CRYPTO)
  set(SHA1_MAX_BLOCK_SIZE "1024L*1024L*1024L" CACHE STRING "${doc_string}")
else()
  set(SHA1_MAX_BLOCK_SIZE "" CACHE STRING "${doc_string}")
endif()

if(SHA1_MAX_BLOCK_SIZE)
  list(APPEND basic_defs "-DSHA1_MAX_BLOCK_SIZE=\"${SHA1_MAX_BLOCK_SIZE}\"")
  list(APPEND lib_src "compat/sha1-chunked.c")
endif()

if(OPENSSL)
  set(sha1_default_implementation "OPENSSL_SHA1")
else()
  set(sha1_default_implementation "BLK_SHA1")
endif()
set(SHA1_IMPLEMENTATION "${sha1_default_implementation}" CACHE STRING
    "Source to use for SHA1 implementation")
set_property(CACHE SHA1_IMPLEMENTATION PROPERTY STRINGS
             "OPENSSL_SHA1;BLK_SHA1;PPC_SHA1;DC_SHA1")
message(STATUS "SHA1_IMPLEMENTATION: ${SHA1_IMPLEMENTATION}")
if(SHA1_IMPLEMENTATION STREQUAL "DC_SHA1")
  set(DC_SHA1_EXTERNAL "" CACHE STRING "external SHA1 collision-detect library")
  set(doc_string
      "use the sha1collisiondetection shipped as a submodule instead of the")
  set(doc_string "${doc_string} non-submodule copy in sha1dc")
  message(STATUS "DC_SHA1_EXTERNAL: ${DC_SHA1_EXTERNAL}")

  option(DC_SHA1_SUBMODULE "${doc_string}" OFF)
  print_bool(DC_SHA1_SUBMODULE)
endif()

if(SHA1_IMPLEMENTATION STREQUAL "OPENSSL_SHA1")
  list(APPEND include_dirs ${OPENSSL_INCLUDE_DIRS})
  list(APPEND libs ${OPENSSL_LIBRARIES})
  list(APPEND basic_defs "-DSHA1_OPENSSL")
elseif(SHA1_IMPLEMENTATION STREQUAL "BLK_SHA1")
  list(APPEND lib_src "block-sha1/sha1.c")
  list(APPEND basic_defs "-DSHA1_BLK")
elseif(SHA1_IMPLEMENTATION STREQUAL "PPC_SHA1")
  list(APPEND lib_src
       "ppc/sha1.c"
       "ppc/sha1ppc.c")
  list(APPEND basic_defs "-DSHA1_PPC")
elseif(SHA1_IMPLEMENTATION STREQUAL "APPLE_COMMON_CRYPTO")
  list(APPEND compat_defs "-DCOMMON_DIGEST_FOR_OPENSSL")
  list(APPEND basic_defs "-DSHA1_APPLE")
else()
  if(NOT SHA1_IMPLEMENTATION STREQUAL "DC_SHA1")
    message(FATAL_ERROR "Invalid SHA1_IMPLEMENTATION: ${SHA1_IMPLEMENTATION}")
  endif()
  list(APPEND basic_defs "-DSHA1_DC")
  list(APPEND lib_src "sha1dc_git.c")

  if(DC_SHA1_EXTERNAL)
    if(DC_SHA1_SUBMODULE)
      message(FATAL_ERROR
        "Only set DC_SHA1_EXTERNAL or DC_SHA1_SUBMODULE, not both")
    endif()
    list(APPEND basic_defs "-DDC_SHA1_EXTERNAL")
    list(APPEND libs sha1detectcoll)
  elseif(DC_SHA1_SUBMODULE)
    list(APPEND lib_src
         "sha1collisiondetection/lib/sha1.c"
         "sha1collisiondetection/lib/ubc_check.c")
    list(APPEND basic_defs "-DDC_SHA1_SUBMODULE")
  else()
    list(APPEND lib_src
         "sha1collisiondetection/sha1.c"
         "sha1collisiondetection/ubc_check.c")
  endif()
  list(APPEND basic_defs
       "-DSHA1DC_NO_STANDARD_INCLUDES"
       "-DSHA1DC_INIT_SAFE_HASH_DEFAULT=0"
       "-DSHA1DC_CUSTOM_INCLUDE_SHA1_C=\"cache.h\""
       "-DSHA1DC_CUSTOM_INCLUDE_UBC_CHECK_C=\"git-compat-util.h\"")
endif()

set(CMAKE_EXTRA_INCLUDE_FILES "stdint.h")

check_type_size(intptr_t INTPTR_T)
print_bool(INTPTR_T)
if(NOT INTPTR_T)
  list(APPEND compat_defs "-DNO_INTPTR_T")
endif()

check_type_size(uintmax_t UINTMAX_T)
print_bool(UINTMAX_T)
if(NOT UINTMAX_T)
  list(APPEND compat_defs "-Duintmax_t=uint32_t")
endif()

set(CMAKE_EXTRA_INCLUDE_FILES)

check_function_exists(mmap have_mmap)
cmake_dependent_option(MMAP "Use mmap" ON "have_mmap" OFF)
print_bool(MMAP)

cmake_dependent_option(
  USE_WIN32_MMAP "Use Windows mmap" OFF "WIN32;MMAP" OFF)
if(MMAP)
  if(USE_WIN32_MMAP)
    list(APPEND compat_defs "-DUSE_WIN32_MMAP")
    list(APPEND compat_src "compat/win32mmap.c")
  endif()
else()
  list(APPEND compat_defs "-DNO_MMAP")
  list(APPEND compat_src "compat/mmap.c")
endif()

if(MMAP)
  if(CMAKE_CROSSCOMPILING)
    set(MMAP_PREVENTS_DELETE ON)
  else()
    file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/cmake/mmap_test.c"
         DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/CMakeTmp")
    try_run(mmap_run_result
            mmap_compile_result
            "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/CMakeTmp"
            "${CMAKE_CURRENT_SOURCE_DIR}/cmake/mmap_test.c"
            COMPILE_OUTPUT_VARIABLE mmap_compile_output
            ARGS "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/CMakeTmp/mmap_test.c")
    if(mmap_compile_result)
      if(NOT mmap_run_result EQUAL 0)
        set(MMAP_PREVENTS_DELETE ON)
      endif()
    else()
      message(WARNING "Failed to compile mmap_test: ${mmap_compile_output}")
      set(MMAP_PREVENTS_DELETE ON)
    endif()
  endif()
  print_bool(MMAP_PREVENTS_DELETE)
endif()

if(MMAP_PREVENTS_DELETE)
  list(APPEND basic_defs "-DMMAP_PREVENTS_DELETE")
endif()

option(POLL "Use poll()" ON)
if(POLL)
  check_include_file("sys/poll.h" SYS_POLL_H)
  print_bool(SYS_POLL_H)
  if(NOT SYS_POLL_H)
    list(APPEND basic_defs "-DNO_SYS_POLL_H")
  endif()
else()
  list(APPEND compat_defs "-DNO_POLL")
  list(APPEND compat_include_dirs "compat/poll")
  list(APPEND compat_src "compat/poll/poll.c")
endif()

if(NOT SYS_POLL_H)
  list(APPEND basic_defs "-DNO_SYS_POLL_H")
endif()

find_package(Threads)
cmake_dependent_option(PTHREADS "Use pthreads" ON "CMAKE_USE_PTHREADS_INIT" OFF)
print_bool(PTHREADS)

if(PTHREADS)
  list(APPEND libs Threads::Threads)
  list(APPEND lib_src "thread-utils.c")
else()
  list(APPEND basic_defs "-DNO_PTHREADS")
endif()

check_function_exists(pread have_pread)
cmake_dependent_option(PREAD "Use pread system call" ON "have_pread" OFF)
print_bool(PREAD)
if(NOT PREAD)
  list(APPEND compat_defs "-DNO_PREAD")
  list(APPEND compat_src "compat/pread.c")
endif()

set(CMAKE_EXTRA_INCLUDE_FILES "sys/time.h")
check_type_size("struct itimerval" STRUCT_ITIMERVAL)
print_bool(STRUCT_ITIMERVAL)
set(CMAKE_EXTRA_INCLUDE_FILES)
if(STRUCT_ITIMERVAL)
  check_function_exists(setitimer SETITIMER)
  print_bool(SETITIMER)
else()
  list(APPEND "-DNO_STRUCT_ITIMERVAL")
endif()

if(NOT SETITIMER)
  list(APPEND compat_defs "-DNO_SETITIMER")
endif()

option(FAST_WORKING_DIRECTORY
  "Accessing working directory is faster than accessing objects in pack files"
  ON)
print_bool(FAST_WORKING_DIRECTORY)
if(NOT FAST_WORKING_DIRECTORY)
  list(APPEND basic_defs "-DNO_FAST_WORKING_DIRECTORY")
endif()

option(TRUSTABLE_FILEMODE "Filesystem supports executable file mode" ON)
print_bool(TRUSTABLE_FILEMODE)
if(NOT TRUSTABLE_FILEMODE)
  list(APPEND basic_defs "-DNO_TRUSTABLE_FILEMODE")
endif()

option(NEEDS_MODE_TRANSLATION
       "OS strays from the typical file type bits in mode values"
       OFF)
print_bool(NEEDS_MODE_TRANSLATION)
if(NEEDS_MODE_TRANSLATION)
  list(APPEND compat_defs "-DNEEDS_MODE_TRANSLATION")
  list(APPEND compat_src "compat/stat.c")
endif()

option(IPV6 "System supports IPv6" ON)
print_bool(IPV6)
if(NOT IPV6)
  list(APPEND basic_defs "-DNO_IPV6")
endif()

check_function_exists(inet_ntop HAVE_INET_NTOP)
if(NOT HAVE_INET_NTOP)
  list(APPEND lib_src "compat/inet_ntop.c")
  list(APPEND basic_defs "-DNO_INET_NTOP")
endif()

check_function_exists(inet_pton HAVE_INET_PTON)
if(NOT HAVE_INET_PTON)
  list(APPEND lib_src "compat/inet_pton.c")
  list(APPEND basic_defs "-DNO_INET_PTON")
endif()

check_symbol_exists(AF_UNIX "${socket_headers}" UNIX_SOCKETS)
print_bool(UNIX_SOCKETS)
if(UNIX_SOCKETS)
  list(APPEND lib_src "unix-socket.c")
  list(APPEND program_src
       "credential-cache.c"
       "credential-cache--daemon.c")
endif()

set(CMAKE_EXTRA_INCLUDE_FILES "${socket_headers}")
check_type_size("struct sockaddr" SOCKADDR_STORAGE)
set(CMAKE_EXTRA_INCLUDE_FILES)
print_bool(SOCKADDR_STORAGE)
if(NOT SOCKADDR_STORAGE)
  if(IPV6)
    list(APPEND basic_defs "-Dsockaddr_storage=sockaddr_in6")
  else()
    list(APPEND basic_defs "-Dsockaddr_storage=sockaddr_in")
  endif()
endif()

check_include_file("iconv.h" have_iconv_h)
if(have_iconv_h)
  try_compile(new_iconv
    "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/CMakeTmp"
    SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/cmake/iconv_test.c"
    COMPILE_DEFINITIONS "-DCONST="
    LINK_LIBRARIES $<$<BOOL:${iconv_lib}>:${iconv_lib}>
    OUTPUT_VARIABLE new_iconv_output)
  if(NOT new_iconv)
    try_compile(OLD_ICONV
      "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/CMakeTmp"
      SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/cmake/iconv_test.c"
      COMPILE_DEFINITIONS "-DCONST=const"
      LINK_LIBRARIES $<$<BOOL:${iconv_lib}>:${iconv_lib}>
      OUTPUT_VARIABLE old_iconv_output)
    if(NOT OLD_ICONV)
      message(WARNING "Cannot compile call to iconv"
              "New iconv test output: ${new_iconv_output}"
              "Old iconv test output: ${old_iconv_output}")
    endif()
  endif()
else()
  set(NO_ICONV ON)
endif()
print_bool(OLD_ICONV)
print_bool(NO_ICONV)

if(NO_ICONV)
  list(APPEND basic_defs "-DNO_ICONV")
endif()

if(OLD_ICONV)
  list(APPEND basic_defs "-DOLD_ICONV")
endif()

if(UNIX)
  set(POSIX_GOODIES ON)
endif()
print_bool(POSIX_GOODIES)

if(NOT POSIX_GOODIES)
  list(APPEND basic_defs "-DNO_POSIX_GOODIES")
endif()

find_package(ZLIB)
if(ZLIB_FOUND)
  list(APPEND include_dirs ${ZLIB_INCLUDE_DIRS})
  list(APPEND libs ${ZLIB_LIBRARIES})

  set(CMAKE_REQUIRED_LIBRARIES "${ZLIB_LIBRARIES}")
  check_function_exists(deflateBound DEFLATE_BOUND)
  set(CMAKE_REQUIRED_LIBRARIES)
  if(NOT DEFLATE_BOUND)
    list(APPEND basic_defs "-DNO_DEFLATE_BOUND")
  endif()
endif()
print_bool(DEFLATE_BOUND)

option(NORETURN "Use of attribute((__noreturn__))" ON)
print_bool(NORETURN)
if(NOT NORETURN)
  list(APPEND basic_defs "-DNO_NORETURN")
endif()

check_struct_has_member("struct stat" st_ctimespec "sys/stat.h" USE_ST_TIMESPEC)
print_bool(USE_ST_TIMESPEC)
if(USE_ST_TIMESPEC)
  list(APPEND basic_defs "-DUSE_ST_TIMESPEC")
endif()

check_struct_has_member("struct stat" "st_ctim.tv_nsec" "sys/stat.h" HAVE_NSEC)
print_bool(HAVE_NSEC)
if(NOT HAVE_NSEC)
  list(APPEND basic_defs "-DNO_NSEC")
endif()

cmake_dependent_option(
  USE_NSEC "Use subsecond file mtimes and ctimes" OFF "HAVE_NSEC" OFF)
print_bool(USE_NSEC)
if(USE_NSEC)
  list(APPEND basic_defs "-DUSE_NSEC")
endif()

check_struct_has_member(
  "struct stat" st_blocks "sys/stat.h" ST_BLOCKS_IN_STRUCT_STAT)
print_bool(ST_BLOCKS_IN_STRUCT_STAT)
if(NOT ST_BLOCKS_IN_STRUCT_STAT)
  list(APPEND basic_defs "-DNO_ST_BLOCKS_IN_STRUCT_STAT")
endif()

find_program(PERL_PATH perl)
message(STATUS "PERL_PATH: ${PERL_PATH}")

cmake_dependent_option(PERL "Enable Perl scripts and libraries" ON
                       "PERL_PATH" OFF)
print_bool(PERL)

find_program(PYTHON_PATH python)
message(STATUS "PYTHON_PATH: ${PYTHON_PATH}")

cmake_dependent_option(PYTHON "Enable Python scripts and libraries" ON
                       "PYTHON_PATH" OFF)
print_bool(PYTHON)

find_package(TCL)
set(TCLTK_PATH "${TK_WISH}")
message(STATUS "TCLTK_PATH: ${TCLTK_PATH}")

cmake_dependent_option(TCLTK "Enable Tcl/Tk GUI" ON "TCLTK_PATH" OFF)
print_bool(TCLTK)
if(TCLTK)
  set(TCL_PATH "${TCL_TCLSH}")
  message(STATUS "TCL_PATH: ${TCL_PATH}")
endif()

set(doc_string "Set to -a if using recent versions of GNU grep that are picky")
set(doc_string "${doc_string} with non-ASCII data")
set(SANE_TEXT_GREP "" CACHE STRING "${doc_string}")
message(STATUS "SANE_TEXT_GREP: ${SANE_TEXT_GREP}")

option(INTERNAL_QSORT "Use git's internal qsort" OFF)
print_bool(INTERNAL_QSORT)
if(INTERNAL_QSORT)
  list(APPEND compat_defs "-DINTERNAL_QSORT")
  list(APPEND compat_src "compat/qsort.c")
endif()

check_function_exists(qsort_s HAVE_ISO_QSORT_S)
print_bool(HAVE_ISO_QSORT_S)
if(HAVE_ISO_QSORT_S)
  list(APPEND compat_defs "-DHAVE_ISO_QSORT_S")
else()
  list(APPEND compat_src "compat/qsort_s.c")
endif()

if(NOT CMAKE_CROSSCOMPILING)
  try_run(fstat_run_result
          fstat_compile_result
          "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/CMakeTmp"
          "${CMAKE_CURRENT_SOURCE_DIR}/cmake/fstat_test.c"
          COMPILE_OUTPUT_VARIABLE fstat_compile_output
          ARGS "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/CMakeTmp/fstat_tmp.txt")
  if(fstat_compile_result)
    if(fstat_run_result EQUAL 0)
      set(UNRELIABLE_FSTAT ON)
    endif()
  else()
    message(WARNING "Cannot compile fstat_test: ${fstat_compile_output}")
  endif()
endif()
print_bool(UNRELIABLE_FSTAT)
if(UNRELIABLE_FSTAT)
  list(APPEND basic_defs "-DUNRELIABLE_FSTAT")
endif()

cmake_dependent_option(
  OBJECT_CREATION_USES_RENAMES
  "Use file rename instead of hardlink with immediate unlink"
  OFF
  "not_windows"
  ON)
print_bool(OBJECT_CREATION_USES_RENAMES)
if(OBJECT_CREATION_USES_RENAMES)
  list(APPEND compat_defs "-DOBJECT_CREATION_MODE=1")
endif()

option(USE_NED_ALLOCATOR
       "Use nedmalloc allocator instead of platform allocator"
       OFF)
print_bool(USE_NED_ALLOCATOR)

if(USE_NED_ALLOCATOR)
  list(APPEND compat_include_dirs
       "compat/nedmalloc")
  list(APPEND compat_src
       "compat/nedmalloc/nedmalloc.c")
endif()

if(NOT USE_NED_ALLOCATOR)
  set(not_use_ned_allocator ON)
endif()
cmake_dependent_option(
  OVERRIDE_STRDUP "Override libc strdup" OFF "not_use_ned_allocator" ON)
print_bool(OVERRIDE_STRDUP)

if(OVERRIDE_STRDUP)
  list(APPEND compat_defs "-DOVERRIDE_STRDUP")
  list(APPEND compat_src "compat/strdup.c")
endif()

check_symbol_exists(REG_STARTEND "regex.h" REGEX)
print_bool(REGEX)

if(NOT REGEX)
  list(APPEND compat_include_dirs "compat/regex")
  list(APPEND compat_src "compat/regex/regex.c")
endif()

if(CMAKE_SYSTEM_NAME MATCHES "Linux|Darwin|SunOS")
  set(default_have_dev_tty ON)
else()
  set(default_have_dev_tty OFF)
endif()
option(
  HAVE_DEV_TTY
  "System can open /dev/tty to interact with user"
  ${default_have_dev_tty})
print_bool(HAVE_DEV_TTY)
if(HAVE_DEV_TTY)
  list(APPEND basic_defs "-DHAVE_DEV_TTY")
endif()

option(GETTEXT_POISON "Debug choice of strings marked for translation" OFF)
print_bool(GETTEXT_POISON)
if(GETTEXT_POISON)
  list(APPEND basic_defs "-DGETTEXT_POISON")
endif()

find_program(LESS_PATH less)
set(DEFAULT_PAGER "${LESS_PATH}" CACHE FILEPATH "Sensible pager command")
list(APPEND basic_defs "-DDEFAULT_PAGER=\"${DEFAULT_PAGER}\"")
message(STATUS "DEFAULT_PAGER: ${DEFAULT_PAGER}")

find_program(VI_PATH vi)
set(DEFAULT_EDITOR "${VI_PATH}" CACHE FILEPATH "Sensible editor command")
list(APPEND basic_defs "-DDEFAULT_EDITOR=\"${DEFAULT_EDITOR}\"")
message(STATUS "DEFAULT_EDITOR: ${DEFAULT_EDITOR}")

if(WIN32 OR MINGW)
  set(NATIVE_CRLF ON)
endif()
print_bool(NATIVE_CRLF)

if(NATIVE_CRLF)
  list(APPEND basic_defs "-DNATIVE_CRLF")
endif()

set(help_formats man info html)
set(DEFAULT_HELP_FORMAT "man" CACHE FILEPATH "\"git help\" format")
set_property(CACHE DEFAULT_HELP_FORMAT PROPERTY STRINGS "${help_formats}")
message(STATUS "DEFAULT_HELP_FORMAT: ${DEFAULT_HELP_FORMAT}")
list(APPEND basic_defs "-DDEFAULT_HELP_FORMAT=\"${DEFAULT_HELP_FORMAT}\"")

set(TEST_GIT_INDEX_VERSION "" CACHE STRING "Version of indexfile to test")
set_property(CACHE TEST_GIT_INDEX_VERSION PROPERTY STRINGS "2;3;4")

if(NOT CMAKE_CROSSCOMPILING)
  try_run(gmtime_run_result
          gmtime_compile_result
          "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/CMakeTmp"
          "${CMAKE_CURRENT_SOURCE_DIR}/cmake/gmtime_test.c"
          COMPILE_OUTPUT_VARIABLE gmtime_compile_output)
  if(gmtime_compile_result)
    if(gmtime_run_result EQUAL 0)
      set(GMTIME_UNRELIABLE_ERRORS ON)
    endif()
  else()
    message(WARNING "Cannot compile gmtime_test: ${gmtime_compile_output}")
  endif()
endif()
print_bool(GMTIME_UNRELIABLE_ERRORS)

if(GMTIME_UNRELIABLE_ERRORS)
  list(APPEND compat_defs "-DGMTIME_UNRELIABLE_ERRORS")
  list(APPEND compat_src "compat/gmtime.c")
endif()

check_function_exists(clock_gettime libc_has_clock_gettime)
if(libc_has_clock_gettime)
  set(HAVE_CLOCK_GETTIME ON)
else()
  set(CMAKE_REQUIRED_LIBRARIES rt)
  check_function_exists(clock_gettime librt_has_clock_gettime)
  if(librt_has_clock_gettime)
    set(HAVE_CLOCK_GETTIME ON)
    set(NEEDS_LIBRT ON)
  endif()
endif()
print_bool(HAVE_CLOCK_GETTIME)
print_bool(NEEDS_LIBRT)

if(HAVE_CLOCK_GETTIME)
  list(APPEND basic_defs "-DHAVE_CLOCK_GETTIME")
endif()

if(NEEDS_LIBRT)
  list(APPEND libs rt)
endif()

check_symbol_exists(CLOCK_MONOTONIC "time.h" HAVE_CLOCK_MONOTONIC)
print_bool(HAVE_CLOCK_MONOTONIC)

if(HAVE_CLOCK_MONOTONIC)
  list(APPEND basic_defs "-DHAVE_CLOCK_MONOTONIC")
endif()

try_compile(USE_PARENS_AROUND_GETTEXT_N
  "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/CMakeTmp"
  SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/cmake/parens_test.c")
print_bool(USE_PARENS_AROUND_GETTEXT_N)
if(USE_PARENS_AROUND_GETTEXT_N)
  list(APPEND basic_defs "-DUSE_PARENS_AROUND_GETTEXT_N=1")
else()
  list(APPEND basic_defs "-DUSE_PARENS_AROUND_GETTEXT_N=0")
endif()

try_compile(HAVE_BSD_SYSCTL
  "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/CMakeTmp"
  SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/cmake/sysctl_test.c")
print_bool(HAVE_BSD_SYSCTL)

if(HAVE_BSD_SYSCTL)
  list(APPEND basic_defs "-DHAVE_BSD_SYSCTL")
endif()

check_function_exists(getdelim HAVE_GETDELIM)
print_bool(HAVE_GETDELIM)

if(HAVE_GETDELIM)
  list(APPEND basic_defs "-DHAVE_GETDELIM")
endif()

set(doc_string "SP separated VAR=VAL pairs to define default environment")
set(doc_string "${doc_string} variables to be passed when a pager is spawned")
set(PAGER_ENV "LESS=FRX LV=-c" CACHE STRING "${doc_string}")
message(STATUS "PAGER_ENV: ${PAGER_ENV}")
list(APPEND basic_defs "-DPAGER_ENV=\"${PAGER_ENV}\"")

find_program(SHELL_PATH sh)
message(STATUS "SHELL_PATH: ${SHELL_PATH}")
list(APPEND basic_defs "-DSHELL_PATH=\"${SHELL_PATH}\"")

# Build rules

list(APPEND lib_src ${compat_src})
list(APPEND basic_defs ${compat_defs})

add_library(libgit STATIC ${lib_src})

set(xdiff_src
  "xdiff/xdiffi.c"
  "xdiff/xprepare.c"
  "xdiff/xutils.c"
  "xdiff/xemit.c"
  "xdiff/xmerge.c"
  "xdiff/xpatience.c"
  "xdiff/xhistogram.c")
add_library(xdiff STATIC ${xdiff_src})

set(vcssvn_src
  "vcs-svn/line_buffer.c"
  "vcs-svn/sliding_window.c"
  "vcs-svn/fast_export.c"
  "vcs-svn/svndiff.c"
  "vcs-svn/svndump.c")
add_library(vcssvn STATIC ${vcssvn_src})

target_compile_definitions(libgit PUBLIC ${basic_defs})
target_include_directories(libgit PUBLIC ${compat_include_dirs})
target_link_libraries(libgit PUBLIC ${libs})

set(src_defs
    "GIT_HTML_PATH=\"${html_dir}\""
    "GIT_MAN_PATH=\"${man_dir}\""
    "GIT_INFO_PATH=\"${info_dir}\"")
set_source_files_properties(
  "git.c" "builtin/help.c"
  PROPERTIES
  COMPILE_DEFINITIONS "${src_defs}")

set(src_defs
    "GIT_VERSION=\"${GIT_VERSION}\""
    "GIT_USER_AGENT=\"${GIT_USER_AGENT}\""
    "GIT_BUILT_FROM_COMMIT=\"${GIT_BUILT_FROM_COMMIT}\"")
set_source_files_properties(
  "version.c"
  PROPERTIES
  COMPILE_DEFINITIONS "${src_defs}")

set(src_defs
    "GIT_EXEC_PATH=\"${git_exec_dir}\""
    "BINDIR=\"${bin_dir}\""
    "PREFIX=\"${CMAKE_INSTALL_PREFIX}\"")
set_source_files_properties(
  "exec_cmd.c"
  PROPERTIES
  COMPILE_DEFINITIONS "${src_defs}")

set_source_files_properties(
  "builtin/init-db.c"
  PROPERTIES
  COMPILE_DEFINITIONS "DEFAULT_GIT_TEMPLATE_DIR=\"${template_dir}\"")

set_source_files_properties(
  "config.c"
  PROPERTIES
  COMPILE_DEFINITIONS "ETC_GITCONFIG=\"${etc_gitconfig}\"")

set_source_files_properties(
  "attr.c"
  PROPERTIES
  COMPILE_DEFINITIONS "ETC_GITATTRIBUTES=\"${etc_gitattributes}\"")

set_source_files_properties(
  "gettext.c"
  PROPERTIES
  COMPILE_DEFINITIONS "GIT_LOCALE_PATH=\"${locale_dir}\"")

# TODO: Sparse
if(SPARSE)
  set_source_files_properties(
    "http-push.c" "http.c" "http-walker.c" "remote-curl.c" "imap-send.c"
    PROPERTIES
    COMPILE_DEFINITIONS "CURL_DISABLE_TYPECHECK")
endif()

if(NOT EXPAT)
  set_source_files_properties(
    "http-walker.c"
    PROPERTIES
    COMPILE_DEFINITIONS "NO_EXPAT")
endif()

if(NOT REGEX)
  set_source_files_properties(
    "compat/regex/regex.c"
    PROPERTIES
    COMPILE_DEFINITIONS "GAWK;NO_MBSUPPORT")
endif()

if(USE_NED_ALLOCATOR)
  if(SPARSE)
    add_c_flag(SPARSE_FLAGS "-Wno-non-pointer-null")
  endif()
  set_source_files_properties(
    "compat/nedmalloc/nedmalloc.c"
    PROPERTIES
    COMPILE_DEFINITIONS "NDEBUG;REPLACE_SYSTEM_ALLOCATOR"
    COMPILE_FLAGS "${SPARSE_FLAGS}")
  # TODO: Decide how this relates to Debug/Release modes
endif()

add_library(common-main "common-main.c" ${builtin_src})
target_link_libraries(common-main PUBLIC libgit xdiff)

add_executable(git "git.c")
target_link_libraries(git PUBLIC common-main)

add_executable(git-imap-send "imap-send.c" ${imap_send_builddeps})
target_link_libraries(git-imap-send PUBLIC ${imap_send_libs} common-main)

if(CURL)
  add_executable(git-http-fetch "http.c" "http-walker.c" "http-fetch.c")
  target_include_directories(git-http-fetch PUBLIC ${CURL_INCLUDE_DIRS})
  target_link_libraries(git-http-fetch PUBLIC ${CURL_LIBRARIES} common-main)

  if(EXPAT)
    if(CURL_VERSION_STRING VERSION_GREATER_EQUAL "7.9.8")
      add_executable(git-http-push "http.c" "http-push.c")
      target_include_directories(git-http-push PUBLIC
        ${CURL_INCLUDE_DIRS} ${EXPAT_INCLUDE_DIRS})
      target_link_libraries(git-http-push PUBLIC
        ${CURL_LIBRARIES} ${EXPAT_LIBRARIES} common-main)
    endif()

    add_executable(git-remote-http "remote-curl.c" "http.c" "http-walker.c")
    target_link_libraries(git-remote-http PUBLIC
      ${CURL_LIBRARIES} ${EXPAT_LIBRARIES} common-main)
    foreach(remote_curl_alias "git-remote-https" "git-remote-ftp"
            "git-remote-ftps")
      if(UNIX)
        set(cmake_subcommand "create_symlink")
      else()
        set(cmake_subcommand "copy")
      endif()
      add_custom_command(
        TARGET git-remote-http
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E ${cmake_subcommand}
                git-remote-http "${remote_curl_alias}"
        VERBATIM
        WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")
    endforeach()
  endif()
endif()

add_executable(git-remote-testsvn "remote-testsvn.c")
target_link_libraries(git-remote-testsvn PUBLIC common-main vcssvn)

foreach(src ${program_src})
  get_filename_component(base "${src}" NAME_WE)
  add_executable("git-${base}" "${src}")
  target_link_libraries("git-${base}" PUBLIC common-main)
endforeach()

foreach(src ${builtin_src})
  get_filename_component(base "${src}" NAME_WE)
  if(UNIX)
    set(cmake_subcommand "create_symlink")
  else()
    set(cmake_subcommand "copy")
  endif()

  set(src "git")
  set(dst "git-${base}")
  add_custom_command(
    TARGET git POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E ${cmake_subcommand} "${src}" "${dst}"
    VERBATIM
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")
  install(PROGRAMS "${CMAKE_CURRENT_BINARY_DIR}/${dst}"
          DESTINATION "${bin_dir}")
endforeach()

# Scripts

find_program(DIFF diff)
message(STATUS "DIFF: ${DIFF}")

set(doc_string "Set to colon-separated list of paths to prepend to PATH if")
set(doc_string "${doc_string} your tools in /usr/bin are broken")
set(SANE_TOOL_PATH "" CACHE STRING "${doc_string}")

function(fix_shebang script_path program_path output_content)
  file(STRINGS "${script_path}" line LIMIT_COUNT 1)
  string(LENGTH "${line}" offset)
  file(READ "${script_path}" content OFFSET ${offset})
  if(line MATCHES "#!")
    set(${output_content} "#!${program_path}${content}" PARENT_SCOPE)
  else()
    set(${output_content} "${line}${content}" PARENT_SCOPE)
  endif()
endfunction()

function(munge_script script_path output_name)
  fix_shebang("${script_path}" "${SHELL_PATH}" script_content)
  string(REPLACE "@SHELL_PATH@" "${SHELL_PATH}"
         script_content "${script_content}")
  string(REPLACE "@@DIFF@@" "${DIFF}" script_content "${script_content}")
  string(REPLACE "@@LOCALEDIR@@" "${locale_dir}"
         script_content "${script_content}")
  string(REPLACE "@@NO_CURL@@" "${NO_CURL}"
         script_content "${script_content}")
  if(USE_GETTEXT_SCHEME_FALLTHROUGH)
    string(REPLACE "@@USE_GETTEXT_SCHEME@@" "fallthrough"
           script_content "${script_content}")
  endif()

  if(SANE_TOOL_PATH)
    set(broken_path_fix "git_broken_path_fix ${SANE_TOOL_PATH}")
  endif()
  string(REGEX REPLACE "^# @@BROKEN_PATH_FIX@@$" "${broken_path_fix}"
         script_content "${script_content}")

  string(REPLACE "@@GITWEBDIR@@" "${gitweb_dir}"
         script_content "${script_content}")
  string(REPLACE "@@PERL@@" "${PERL}" script_content "${script_content}")
  string(REPLACE "@@SANE_TEXT_GREP@@" "${SANE_TEXT_GREP}"
         script_content "${script_content}")
  string(REPLACE "@@PAGER_ENV@@" "${PAGER_ENV}"
         script_content "${script_content}")

  file(GENERATE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${output_name}"
       CONTENT "${script_content}")
endfunction()

list(APPEND script_sh "git-bisect.sh")
list(APPEND script_sh "git-difftool--helper.sh")
list(APPEND script_sh "git-filter-branch.sh")
list(APPEND script_sh "git-merge-octopus.sh")
list(APPEND script_sh "git-merge-one-file.sh")
list(APPEND script_sh "git-merge-resolve.sh")
list(APPEND script_sh "git-mergetool.sh")
list(APPEND script_sh "git-quiltimport.sh")
list(APPEND script_sh "git-rebase.sh")
list(APPEND script_sh "git-remote-testgit.sh")
list(APPEND script_sh "git-request-pull.sh")
list(APPEND script_sh "git-stash.sh")
list(APPEND script_sh "git-submodule.sh")
list(APPEND script_sh "git-web--browse.sh")

list(APPEND script_lib "git-mergetool--lib.sh")
list(APPEND script_lib "git-parse-remote.sh")
list(APPEND script_lib "git-rebase--am.sh")
list(APPEND script_lib "git-rebase--interactive.sh")
list(APPEND script_lib "git-rebase--merge.sh")
list(APPEND script_lib "git-sh-setup.sh")
list(APPEND script_lib "git-sh-i18n.sh")

foreach(script_path ${script_sh})
  get_filename_component(output_name "${script_path}" NAME_WE)
  munge_script("${script_path}" "${output_name}")
  if(NOT script_path STREQUAL
     "git-remote-testgit.sh")
    install(PROGRAMS "${CMAKE_CURRENT_BINARY_DIR}/${output_name}"
            DESTINATION "${git_exec_dir}")
  endif()
endforeach()
foreach(script_path ${script_lib})
  get_filename_component(output_name "${script_path}" NAME_WE)
  munge_script("${script_path}" "${output_name}")
  install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${output_name}"
          DESTINATION "${git_exec_dir}")
endforeach()
install(FILES ${script_lib_gen} DESTINATION "${git_exec_dir}")

list(APPEND script_perl "git-add--interactive.perl")
list(APPEND script_perl "git-archimport.perl")
list(APPEND script_perl "git-cvsexportcommit.perl")
list(APPEND script_perl "git-cvsimport.perl")
list(APPEND script_perl "git-cvsserver.perl")
list(APPEND script_perl "git-send-email.perl")
list(APPEND script_perl "git-svn.perl")
if(PERL)
  foreach(script_path ${script_perl})
    fix_shebang("${script_path}" "${PERL_PATH}" script_content)
    string(FIND "${script_content}" "\n" first_line_ending)
    string(SUBSTRING "${script_content}" 0 ${first_line_ending} first_line)
    string(SUBSTRING "${script_content}" ${first_line_ending} -1 rest_of_script)
    # ${lib_dir} relative to ${git_exec_dir} is "../../${lib_dir}"
    string(CONCAT script_content
      "${first_line}\n"
      "use FindBin;\n"
      "use lib (split(/$(pathsep)/, \$ENV{GITPERLLIB} || "
      "\"$FindBin::Bin/../../${lib_dir}\"));"
      "${rest_of_script}")
    string(REPLACE "@@GIT_VERSION@@" "${GIT_VERSION}"
           script_content "${script_content}")
    string(REPLACE "$<" "$UID" script_content "${script_content}")

    get_filename_component(output_name "${script_path}" NAME_WE)
    file(GENERATE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${output_name}"
         CONTENT "${script_content}")
    install(PROGRAMS "${CMAKE_CURRENT_BINARY_DIR}/${output_name}"
            DESTINATION "${git_exec_dir}")
  endforeach()
else()
  foreach(script_path ${script_perl})
    fix_shebang("unimplemented.sh"
                "${SHELL_PATH}" script_content)
    string(REPLACE "@@REASON@@" "PERL=OFF" script_content "${script_content}")
    get_filename_component(output_name "${script_path}" NAME_WE)
    file(GENERATE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${output_name}"
         CONTENT "${script_content}")
    install(PROGRAMS "${CMAKE_CURRENT_BINARY_DIR}/${output_name}"
            DESTINATION "${git_exec_dir}")
  endforeach()
endif()

list(APPEND script_python "git-p4.py")
if(PYTHON)
  foreach(script_path ${script_python})
    fix_shebang("${script_path}" "${PYTHON_PATH}" script_content)
    get_filename_component(output_name "${script_path}" NAME_WE)
    file(GENERATE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${output_name}"
         CONTENT "${script_content}")
    install(PROGRAMS "${CMAKE_CURRENT_BINARY_DIR}/${output_name}"
            DESTINATION "${git_exec_dir}")
  endforeach()
else()
  foreach(script_path ${script_python})
    fix_shebang("unimplemented.sh"
                "${SHELL_PATH}" script_content)
    string(REPLACE "@@REASON@@" "PYTHON=OFF" script_content "${script_content}")
    get_filename_component(output_name "${script_path}" NAME_WE)
    file(GENERATE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${output_name}"
         CONTENT "${script_content}")
    install(PROGRAMS "${CMAKE_CURRENT_BINARY_DIR}/${output_name}"
            DESTINATION "${git_exec_dir}")
  endforeach()
endif()
