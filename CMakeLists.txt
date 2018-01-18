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

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/version" AND
   NOT IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/version")
  file(READ "${CMAKE_CURRENT_SOURCE_DIR}/version" GIT_VERSION)
elseif(IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/.git")
  find_package(Git)
  if(GIT_FOUND)
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
  endif()
else()
  set(GIT_VERSION "${DEFAULT_VERSION}")
endif()

string(REGEX REPLACE "^v([0-9]+\\.[0-9]+\\.[0-9]+).*$" "\\1"
       simplified_version "${GIT_VERSION}")
project(git VERSION "${simplified_version}" LANGUAGES C)
message(STATUS "PROJECT_VERSION: ${PROJECT_VERSION}")

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
    "${CMAKE_CURRENT_SOURCE_DIR}/credential-store.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/daemon.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/fast-import.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/http-backend.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/imap-send.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/sh-i18n--envsubst.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/shell.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/show-index.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/upload-pack.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/remote-testsvn.c")

if(ENABLE_TESTING)
  set(test_program_src
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-chmtime.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-ctype.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-config.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-date.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-delta.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-drop-caches.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-dump-cache-tree.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-dump-fsmonitor.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-dump-split-index.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-dump-untracked-cache.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-example-decorate.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-fake-ssh.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-genrandom.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-hashmap.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-index-version.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-lazy-init-name-hash.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-line-buffer.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-match-trees.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-mergesort.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-mktemp.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-online-cpus.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-parse-options.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-path-utils.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-prio-queue.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-read-cache.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-write-cache.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-ref-store.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-regex.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-revision-walking.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-run-command.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-scrap-cache-tree.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-sha1.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-sha1-array.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-sigchain.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-strcmp-offset.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-string-list.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-submodule-config.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-subprocess.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-svn-fe.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-urlmatch-normalization.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/t/helper/test-wildmatch.c")
endif()

set(lib_src
    "${CMAKE_CURRENT_SOURCE_DIR}/abspath.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/advice.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/alias.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/alloc.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/apply.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/archive.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/archive-tar.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/archive-zip.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/argv-array.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/attr.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/base85.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/bisect.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/blame.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/blob.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/branch.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/bulk-checkin.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/bundle.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/cache-tree.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/checkout.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/color.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/column.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/combine-diff.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/commit.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/compat/obstack.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/compat/terminal.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/config.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/connect.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/connected.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/convert.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/copy.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/credential.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/csum-file.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/ctype.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/date.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/decorate.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/diffcore-break.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/diffcore-delta.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/diffcore-order.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/diffcore-pickaxe.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/diffcore-rename.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/diff-delta.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/diff-lib.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/diff-no-index.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/diff.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/dir.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/dir-iterator.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/editor.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/entry.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/environment.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/ewah/bitmap.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/ewah/ewah_bitmap.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/ewah/ewah_io.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/ewah/ewah_rlw.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/exec_cmd.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/fetch-pack.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/fsck.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/fsmonitor.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/gettext.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/gpg-interface.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/graph.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/grep.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/hashmap.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/help.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/hex.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/ident.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/kwset.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/levenshtein.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/line-log.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/line-range.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/list-objects.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/list-objects-filter.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/list-objects-filter-options.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/ll-merge.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/lockfile.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/log-tree.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/mailinfo.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/mailmap.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/match-trees.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/merge.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/merge-blobs.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/merge-recursive.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/mergesort.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/mru.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/name-hash.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/notes.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/notes-cache.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/notes-merge.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/notes-utils.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/object.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/oidmap.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/oidset.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/packfile.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/pack-bitmap.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/pack-bitmap-write.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/pack-check.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/pack-objects.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/pack-revindex.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/pack-write.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/pager.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/parse-options.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/parse-options-cb.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/patch-delta.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/patch-ids.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/path.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/pathspec.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/pkt-line.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/preload-index.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/pretty.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/prio-queue.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/progress.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/prompt.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/protocol.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/quote.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/reachable.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/read-cache.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/reflog-walk.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/refs.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/refs/files-backend.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/refs/iterator.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/refs/packed-backend.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/refs/ref-cache.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/ref-filter.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/remote.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/replace_object.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/repository.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/rerere.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/resolve-undo.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/revision.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/run-command.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/send-pack.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/sequencer.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/server-info.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/setup.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/sha1-array.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/sha1-lookup.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/sha1_file.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/sha1_name.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/shallow.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/sideband.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/sigchain.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/split-index.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/strbuf.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/streaming.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/string-list.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/submodule.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/submodule-config.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/sub-process.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/symlinks.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/tag.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/tempfile.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/tmp-objdir.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/trace.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/trailer.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/transport.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/transport-helper.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/tree-diff.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/tree.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/tree-walk.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/unpack-trees.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/url.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/urlmatch.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/usage.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/userdiff.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/utf8.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/varint.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/version.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/versioncmp.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/walker.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/wildmatch.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/worktree.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/wrapper.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/write_or_die.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/ws.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/wt-status.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/xdiff-interface.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/zlib")

set(builtin_src
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/add.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/am.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/annotate.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/apply.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/archive.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/bisect--helper.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/blame.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/branch.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/bundle.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/cat-file.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/check-attr.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/check-ignore.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/check-mailmap.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/check-ref-format.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/checkout-index.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/checkout.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/clean.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/clone.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/column.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/commit-tree.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/commit.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/config.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/count-objects.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/credential.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/describe.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/diff-files.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/diff-index.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/diff-tree.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/diff.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/difftool.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/fast-export.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/fetch-pack.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/fetch.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/fmt-merge-msg.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/for-each-ref.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/fsck.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/gc.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/get-tar-commit-id.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/grep.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/hash-object.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/help.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/index-pack.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/init-db.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/interpret-trailers.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/log.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/ls-files.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/ls-remote.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/ls-tree.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/mailinfo.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/mailsplit.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/merge.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/merge-base.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/merge-file.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/merge-index.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/merge-ours.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/merge-recursive.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/merge-tree.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/mktag.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/mktree.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/mv.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/name-rev.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/notes.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/pack-objects.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/pack-redundant.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/pack-refs.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/patch-id.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/prune-packed.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/prune.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/pull.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/push.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/read-tree.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/rebase--helper.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/receive-pack.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/reflog.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/remote.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/remote-ext.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/remote-fd.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/repack.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/replace.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/rerere.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/reset.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/rev-list.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/rev-parse.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/revert.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/rm.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/send-pack.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/shortlog.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/show-branch.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/show-ref.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/stripspace.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/submodule--helper.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/symbolic-ref.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/tag.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/unpack-file.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/unpack-objects.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/update-index.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/update-ref.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/update-server-info.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/upload-archive.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/var.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/verify-commit.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/verify-pack.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/verify-tag.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/worktree.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/builtin/write-tree.c")

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

# Force RUNTIME_PREFIX for relocatable build
set(compat_defs "-DRUNTIME_PREFIX")

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

list(APPEND basic_defs "-DGIT_HOST_CPU=${CMAKE_SYSTEM_PROCESSOR}")
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
  list(APPEND compat_src "${CMAKE_CURRENT_SOURCE_DIR}/compat/snprintf.c")
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
  list(APPEND compat_src "${CMAKE_CURRENT_SOURCE_DIR}/compat/fopen.c")
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
  list(APPEND program_src "${CMAKE_CURRENT_SOURCE_DIR}/http-fetch.c")
else()
  set(NO_CURL "1")
  list(APPEND basic_defs "-DNO_CURL")
endif()

find_package(EXPAT)
cmake_dependent_option(EXPAT "Enable expat for HTTP parsing" ON
                      "EXPAT_FOUND" OFF)
# EXPAT_NEEDS_XMLPARSE_H not handled in CMake build, seeing as CMake FindEXPAT
# explicitly relies on the existence of "expat.h" to find includes directory.
if(EXPAT)
  list(APPEND include_dirs ${EXPAT_INCLUDE_DIRS})
  list(APPEND libs ${EXPAT_LIBRARIES})
endif()

if(CURL AND CURL_VERSION_STRING VERSION_GREATER_EQUAL "7.9.8" AND EXPAT)
  list(APPEND program_src "${CMAKE_CURRENT_SOURCE_DIR}/http-push.c")
endif()

if(CURL AND CURL_VERSION_STRING VERSION_GREATER_EQUAL "7.22.0")
  list(APPEND basic_defs "-DUSE_CURL_FOR_IMAP_SEND")
  set(imap_send_builddeps "${CMAKE_CURRENT_SOURCE_DIR}/http.c")
  set(libs ${CURL_LIBRARIES})
endif()

find_package(Gettext)
find_package(Intl)
cmake_dependent_option(GETTEXT "Translate git output" ON
                       "GETTEXT_FOUND;Intl_FOUND" OFF)

find_library(iconv_lib NAMES iconv libiconv libiconv-2)
if(NOT iconv_lib)
  # Clear to avoid linking against "iconv-NOTFOUND"
  set(iconv_lib)
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
  list(APPEND compat_src "${CMAKE_CURRENT_SOURCE_DIR}/compat/strcasestr.c")
endif()

check_function_exists(hstrerror HSTRERROR)
print_bool(HSTRERROR)
if(NOT HSTRERROR)
  list(APPEND compat_defs "-DNO_HSTRERROR")
  list(APPEND compat_src "${CMAKE_CURRENT_SOURCE_DIR}/compat/hstrerror.c")
endif()

check_function_exists(memmem MEMMEM)
print_bool(MEMMEM)
if(NOT MEMMEM)
  list(APPEND compat_defs "-DNO_MEMMEM")
  list(APPEND compat_src "${CMAKE_CURRENT_SOURCE_DIR}/compat/memmem.c")
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
  list(APPEND compat_src "${CMAKE_CURRENT_SOURCE_DIR}/compat/strlcpy.c")
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
       "${CMAKE_CURRENT_SOURCE_DIR}/compat/strtoumax.c"
       "${CMAKE_CURRENT_SOURCE_DIR}/compat/strtoimax.c")
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
  list(APPEND compat_src "${CMAKE_CURRENT_SOURCE_DIR}/compat/setenv.c")
endif()

check_function_exists(unsetenv UNSETENV)
print_bool(UNSETENV)
if(NOT UNSETENV)
  list(APPEND compat_defs "-DNO_UNSETENV")
  list(APPEND compat_src "${CMAKE_CURRENT_SOURCE_DIR}/compat/unsetenv.c")
endif()

check_function_exists(mkdtemp MKDTEMP)
print_bool(MKDTEMP)
if(NOT MKDTEMP)
  list(APPEND compat_defs "-DNO_MKDTEMP")
  list(APPEND compat_src "${CMAKE_CURRENT_SOURCE_DIR}/compat/mkdtemp.c")
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
  list(APPEND compat_src "${CMAKE_CURRENT_SOURCE_DIR}/compat/mkdir.c")
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
  list(APPEND compat_src "${CMAKE_CURRENT_SOURCE_DIR}/compat/basename.c")
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
  list(APPEND lib_src "${CMAKE_CURRENT_SOURCE_DIR}/compat/sha1-chunked.c")
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
  list(APPEND lib_src "${CMAKE_CURRENT_SOURCE_DIR}/block-sha1/sha1.c")
  list(APPEND basic_defs "-DSHA1_BLK")
elseif(SHA1_IMPLEMENTATION STREQUAL "PPC_SHA1")
  list(APPEND lib_src
       "${CMAKE_CURRENT_SOURCE_DIR}/ppc/sha1.c"
       "${CMAKE_CURRENT_SOURCE_DIR}/ppc/sha1ppc.c")
  list(APPEND basic_defs "-DSHA1_PPC")
elseif(SHA1_IMPLEMENTATION STREQUAL "APPLE_COMMON_CRYPTO")
  list(APPEND compat_defs "-DCOMMON_DIGEST_FOR_OPENSSL")
  list(APPEND basic_defs "-DSHA1_APPLE")
else()
  if(NOT SHA1_IMPLEMENTATION STREQUAL "DC_SHA1")
    message(FATAL_ERROR "Invalid SHA1_IMPLEMENTATION: ${SHA1_IMPLEMENTATION}")
  endif()
  list(APPEND basic_defs "-DSHA1_DC")
  list(APPEND lib_src "${CMAKE_CURRENT_SOURCE_DIR}/sha1dc_git.c")

  if(DC_SHA1_EXTERNAL)
    if(DC_SHA1_SUBMODULE)
      message(FATAL_ERROR
        "Only set DC_SHA1_EXTERNAL or DC_SHA1_SUBMODULE, not both")
    endif()
    list(APPEND basic_defs "-DDC_SHA1_EXTERNAL")
    list(APPEND libs sha1detectcoll)
  elseif(DC_SHA1_SUBMODULE)
    list(APPEND lib_src
         "${CMAKE_CURRENT_SOURCE_DIR}/sha1collisiondetection/lib/sha1.c"
         "${CMAKE_CURRENT_SOURCE_DIR}/sha1collisiondetection/lib/ubc_check.c")
    list(APPEND basic_defs "-DDC_SHA1_SUBMODULE")
  else()
    list(APPEND lib_src
         "${CMAKE_CURRENT_SOURCE_DIR}/sha1collisiondetection/sha1.c"
         "${CMAKE_CURRENT_SOURCE_DIR}/sha1collisiondetection/ubc_check.c")
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
    list(APPEND compat_src "${CMAKE_CURRENT_SOURCE_DIR}/compat/win32mmap.c")
  endif()
else()
  list(APPEND compat_defs "-DNO_MMAP")
  list(APPEND compat_src "${CMAKE_CURRENT_SOURCE_DIR}/compat/mmap.c")
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
  list(APPEND compat_include_dirs "${CMAKE_CURRENT_SOURCE_DIR}/compat/poll")
  list(APPEND compat_src "${CMAKE_CURRENT_SOURCE_DIR}/compat/poll/poll.c")
endif()

if(NOT SYS_POLL_H)
  list(APPEND basic_defs "-DNO_SYS_POLL_H")
endif()

find_package(Threads)
cmake_dependent_option(PTHREADS "Use pthreads" ON "CMAKE_USE_PTHREADS_INIT" OFF)
print_bool(PTHREADS)

if(PTHREADS)
  list(APPEND libs Threads::Threads)
  list(APPEND lib_src "${CMAKE_CURRENT_SOURCE_DIR}/thread-utils.c")
else()
  list(APPEND basic_defs "-DNO_PTHREADS")
endif()

check_function_exists(pread have_pread)
cmake_dependent_option(PREAD "Use pread system call" ON "have_pread" OFF)
print_bool(PREAD)
if(NOT PREAD)
  list(APPEND compat_defs "-DNO_PREAD")
  list(APPEND compat_src "${CMAKE_CURRENT_SOURCE_DIR}/compat/pread.c")
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
  list(APPEND compat_src "${CMAKE_CURRENT_SOURCE_DIR}/compat/stat.c")
endif()

option(IPV6 "System supports IPv6" ON)
print_bool(IPV6)
if(NOT IPV6)
  list(APPEND basic_defs "-DNO_IPV6")
endif()

check_function_exists(inet_ntop HAVE_INET_NTOP)
if(NOT HAVE_INET_NTOP)
  list(APPEND lib_src "${CMAKE_CURRENT_SOURCE_DIR}/compat/inet_ntop.c")
  list(APPEND basic_defs "-DNO_INET_NTOP")
endif()

check_function_exists(inet_pton HAVE_INET_PTON)
if(NOT HAVE_INET_PTON)
  list(APPEND lib_src "${CMAKE_CURRENT_SOURCE_DIR}/compat/inet_pton.c")
  list(APPEND basic_defs "-DNO_INET_PTON")
endif()

check_symbol_exists(AF_UNIX "${socket_headers}" UNIX_SOCKETS)
print_bool(UNIX_SOCKETS)
if(NOT UNIX_SOCKETS)
  list(APPEND lib_src "${CMAKE_CURRENT_SOURCE_DIR}/unix-socket.c")
  list(APPEND program_src
       "${CMAKE_CURRENT_SOURCE_DIR}/credential-cache.c"
       "${CMAKE_CURRENT_SOURCE_DIR}/credential-cache--daemon.c")
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
    LINK_LIBRARIES "${iconv_lib}"
    OUTPUT_VARIABLE new_iconv_output)
  if(NOT new_iconv)
    try_compile(OLD_ICONV
      "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/CMakeTmp"
      SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/cmake/iconv_test.c"
      COMPILE_DEFINITIONS "-DCONST=const"
      LINK_LIBRARIES "${iconv_lib}"
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
  list(APPEND compat_src "${CMAKE_CURRENT_SOURCE_DIR}/compat/qsort.c")
endif()

check_function_exists(qsort_s HAVE_ISO_QSORT_S)
print_bool(HAVE_ISO_QSORT_S)
if(HAVE_ISO_QSORT_S)
  list(APPEND compat_defs "-DHAVE_ISO_QSORT_S")
else()
  list(APPEND compat_src "${CMAKE_CURRENT_SOURCE_DIR}/compat/qsort_s.c")
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

option(
  USE_NED_ALLOCATOR "Use nedmalloc allocator instead of platform allocator" OFF)
print_bool(USE_NED_ALLOCATOR)

if(USE_NED_ALLOCATOR)
  list(APPEND compat_include_dirs
       "${CMAKE_CURRENT_SOURCE_DIR}/compat/nedmalloc")
  list(APPEND compat_src
       "${CMAKE_CURRENT_SOURCE_DIR}/compat/nedmallloc/nedmalloc.c")
endif()

if(NOT USE_NED_ALLOCATOR)
  set(not_use_ned_allocator ON)
endif()
cmake_dependent_option(
  OVERRIDE_STRDUP "Override libc strdup" OFF "not_use_ned_allocator" ON)
print_bool(OVERRIDE_STRDUP)

if(OVERRIDE_STRDUP)
  list(APPEND compat_defs "-DOVERRIDE_STRDUP")
  list(APPEND compat_src "${CMAKE_CURRENT_SOURCE_DIR}/compat/strdup.c")
endif()

check_symbol_exists(REG_STARTEND "regex.h" REGEX)
print_bool(REGEX)

if(NOT REGEX)
  list(APPEND compat_include_dirs "${CMAKE_CURRENT_SOURCE_DIR}/compat/regex")
  list(APPEND compat_src "${CMAKE_CURRENT_SOURCE_DIR}/compat/regex/regex.c")
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

set(GIT_USER_AGENT "git/${PROJECT_VERSION}" CACHE STRING
    "User-agent used for network interactions")
message(STATUS "GIT_USER_AGENT: ${GIT_USER_AGENT}")

set(help_formats man info html)
set(DEFAULT_HELP_FORMAT "man" CACHE FILEPATH "\"git help\" format")
set_property(CACHE DEFAULT_HELP_FORMAT PROPERTY STRINGS "${help_formats}")
message(STATUS "DEFAULT_HELP_FORMAT: ${DEFAULT_HELP_FORMAT}")
list(APPEND basic_defs "-DDEFAULT_HELP_FORMAT=${DEFAULT_HELP_FORMAT}")

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
  list(APPEND compat_src "${CMAKE_CURRENT_SOURCE_DIR}/compat/gmtime.c")
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
list(APPEND basic_defs "-DPAGER_ENV=${PAGER_ENV}")

find_program(SHELL_PATH sh)
message(STATUS "SHELL_PATH: ${SHELL_PATH}")
list(APPEND basic_defs "-DSHELL_PATH=${SHELL_PATH}")

# Build rules

list(APPEND lib_src ${compat_src})
list(APPEND basic_defs ${compat_defs})

add_library(libgit STATIC ${lib_src})
target_compile_definitions(libgit PUBLIC ${basic_defs})

set(src_defs
    "GIT_EXEC_PATH=\"${git_exec_dir}\""
    "BINDIR=\"${bin_dir}\""
    "PREFIX=\"${CMAKE_INSTALL_PREFIX}\"")
set_source_files_properties(
  "${CMAKE_CURRENT_SOURCE_DIR}/exec_cmd.c"
  PROPERTIES
  COMPILE_DEFINITIONS "${src_defs}")

set_source_files_properties(
  "${CMAKE_CURRENT_SOURCE_DIR}/builtin/init-db.c"
  PROPERTIES
  COMPILE_DEFINITIONS "DEFAULT_GIT_TEMPLATE_DIR=\"${template_dir}\"")

set_source_files_properties(
  "${CMAKE_CURRENT_SOURCE_DIR}/config.c"
  PROPERTIES
  COMPILE_DEFINITIONS "ETC_GITCONFIG=\"${etc_gitconfig}\"")

set_source_files_properties(
  "${CMAKE_CURRENT_SOURCE_DIR}/attr.c"
  PROPERTIES
  COMPILE_DEFINITIONS "ETC_GITATTRIBUTES=\"${etc_gitattributes}\"")

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

list(APPEND script_sh "${CMAKE_CURRENT_SOURCE_DIR}/git-bisect.sh")
list(APPEND script_sh "${CMAKE_CURRENT_SOURCE_DIR}/git-difftool--helper.sh")
list(APPEND script_sh "${CMAKE_CURRENT_SOURCE_DIR}/git-filter-branch.sh")
list(APPEND script_sh "${CMAKE_CURRENT_SOURCE_DIR}/git-merge-octopus.sh")
list(APPEND script_sh "${CMAKE_CURRENT_SOURCE_DIR}/git-merge-one-file.sh")
list(APPEND script_sh "${CMAKE_CURRENT_SOURCE_DIR}/git-merge-resolve.sh")
list(APPEND script_sh "${CMAKE_CURRENT_SOURCE_DIR}/git-mergetool.sh")
list(APPEND script_sh "${CMAKE_CURRENT_SOURCE_DIR}/git-quiltimport.sh")
list(APPEND script_sh "${CMAKE_CURRENT_SOURCE_DIR}/git-rebase.sh")
list(APPEND script_sh "${CMAKE_CURRENT_SOURCE_DIR}/git-remote-testgit.sh")
list(APPEND script_sh "${CMAKE_CURRENT_SOURCE_DIR}/git-request-pull.sh")
list(APPEND script_sh "${CMAKE_CURRENT_SOURCE_DIR}/git-stash.sh")
list(APPEND script_sh "${CMAKE_CURRENT_SOURCE_DIR}/git-submodule.sh")
list(APPEND script_sh "${CMAKE_CURRENT_SOURCE_DIR}/git-web--browse.sh")

list(APPEND script_lib "${CMAKE_CURRENT_SOURCE_DIR}/git-mergetool--lib.sh")
list(APPEND script_lib "${CMAKE_CURRENT_SOURCE_DIR}/git-parse-remote.sh")
list(APPEND script_lib "${CMAKE_CURRENT_SOURCE_DIR}/git-rebase--am.sh")
list(APPEND script_lib "${CMAKE_CURRENT_SOURCE_DIR}/git-rebase--interactive.sh")
list(APPEND script_lib "${CMAKE_CURRENT_SOURCE_DIR}/git-rebase--merge.sh")
list(APPEND script_lib "${CMAKE_CURRENT_SOURCE_DIR}/git-sh-setup.sh")
list(APPEND script_lib "${CMAKE_CURRENT_SOURCE_DIR}/git-sh-i18n.sh")

foreach(script_path ${script_sh})
  get_filename_component(output_name "${script_path}" NAME_WE)
  munge_script("${script_path}" "${output_name}")
  if(NOT script_path STREQUAL
     "${CMAKE_CURRENT_SOURCE_DIR}/git-remote-testgit.sh")
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

list(APPEND script_perl "${CMAKE_CURRENT_SOURCE_DIR}/git-add--interactive.perl")
list(APPEND script_perl "${CMAKE_CURRENT_SOURCE_DIR}/git-archimport.perl")
list(APPEND script_perl "${CMAKE_CURRENT_SOURCE_DIR}/git-cvsexportcommit.perl")
list(APPEND script_perl "${CMAKE_CURRENT_SOURCE_DIR}/git-cvsimport.perl")
list(APPEND script_perl "${CMAKE_CURRENT_SOURCE_DIR}/git-cvsserver.perl")
list(APPEND script_perl "${CMAKE_CURRENT_SOURCE_DIR}/git-send-email.perl")
list(APPEND script_perl "${CMAKE_CURRENT_SOURCE_DIR}/git-svn.perl")
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
    fix_shebang("${CMAKE_CURRENT_SOURCE_DIR}/unimplemented.sh"
                "${SHELL_PATH}" script_content)
    string(REPLACE "@@REASON@@" "PERL=OFF" script_content "${script_content}")
    get_filename_component(output_name "${script_path}" NAME_WE)
    file(GENERATE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${output_name}"
         CONTENT "${script_content}")
    install(PROGRAMS "${CMAKE_CURRENT_BINARY_DIR}/${output_name}"
            DESTINATION "${git_exec_dir}")
  endforeach()
endif()

list(APPEND script_python "${CMAKE_CURRENT_SOURCE_DIR}/git-p4.py")
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
    fix_shebang("${CMAKE_CURRENT_SOURCE_DIR}/unimplemented.sh"
                "${SHELL_PATH}" script_content)
    string(REPLACE "@@REASON@@" "PYTHON=OFF" script_content "${script_content}")
    get_filename_component(output_name "${script_path}" NAME_WE)
    file(GENERATE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${output_name}"
         CONTENT "${script_content}")
    install(PROGRAMS "${CMAKE_CURRENT_BINARY_DIR}/${output_name}"
            DESTINATION "${git_exec_dir}")
  endforeach()
endif()
