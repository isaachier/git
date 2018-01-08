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
    list(APPEND defs "-DNO_UNALIGNED_LOADS")
  endif()
  if("leak" IN_LIST SANITIZERS)
    list(APPEND defs "-DSUPPRESS_ANNOTATED_LEAKS")
  endif()
endif()

message(STATUS "CMAKE_C_FLAGS: ${CMAKE_C_FLAGS}")

list(APPEND defs "-DGIT_HOST_CPU=${CMAKE_SYSTEM_PROCESSOR}")
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
  list(APPEND defs "-Dsocklen_t=${SOCKLEN_T}")
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
  list(APPEND defs "-DINLINE=${INLINE}")
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

if(NOT CMAKE_CROSSCOMPILING)
  try_run(fopen_dir_run_result
          fopen_dir_compile_result
          COMPILE_OUTPUT_VARIABLE fopen_dir_compile_output
          "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/CMakeTmp"
          "${CMAKE_CURRENT_SOURCE_DIR}/cmake/fopen_dir_test.c"
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
    list(APPEND defs "-DUSE_LIBPCRE${PCRE_VERSION}")
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
        list(APPEND defs "-DNO_LIBPCRE1_JIT")
      endif()
    endif()
  endif()
endif()

check_include_file("alloca.h" HAVE_ALLOCA_H)
print_bool(HAVE_ALLOCA_H)
if(HAVE_ALLOCA_H)
  list(APPEND defs "-DHAVE_ALLOCA_H")
endif()

find_package(CURL)
cmake_dependent_option(CURL "Use libcurl, needed for HTTP transport" ON
                       "CURL_FOUND" OFF)
if(CURL)
  set(NO_CURL "0")
else()
  set(NO_CURL "1")
  list(APPEND defs "-DNO_CURL")
endif()

find_package(EXPAT)
cmake_dependent_option(EXPAT "Enable expat for HTTP parsing" ON
                      "EXPAT_FOUND" OFF)
# EXPAT_NEEDS_XMLPARSE_H not handled in CMake build, seeing as CMake FindEXPAT
# explicitly relies on the existence of "expat.h" to find includes directory.

find_package(Gettext)
find_package(Intl)
cmake_dependent_option(GETTEXT "Translate git output" ON
                       "GETTEXT_FOUND;Intl_FOUND" OFF)

if(NOT GETTEXT)
  set(no_gettext ON)
endif()
cmake_dependent_option(USE_GETTEXT_SCHEME_FALLTHROUGH "${doc_string}" OFF
                       "no_gettext" ON)

if(GETTEXT)
  set(doc_string "Enable if you do not trust installed gettext translation")
  set(doc_string "${doc_string} of the shell scripts output")

  check_include_file("libcharset.h" HAVE_LIBCHARSET_H)
  if(HAVE_LIBCHARSET_H)
    check_library_exists(charset locale_charset "" have_libcharset)
    if(have_libcharset)
      set(CHARSET_LIB charset)
    else()
      check_library_exists(iconv locale_charset "" have_locale_charset_libiconv)
      if(have_locale_charset_libiconv)
        set(CHARSET_LIB iconv)
      else()
        message(FATAL_ERROR "Cannot find library that defines locale_charset")
      endif()
    endif()
  endif()

  check_function_exists(nl_langinfo LIBC_CONTAINS_LIBINTL)
  print_bool(LIBC_CONTAINS_LIBINTL)
  if(NOT LIBC_CONTAINS_LIBINTL)
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

check_symbol_exists(DT_UNKNOWN "dirent.h" have_dt_unknown)
if(have_dt_unknown)
  check_struct_has_member("struct dirent" d_type "dirent.h" have_d_type)
  if(have_d_type)
    set(D_TYPE_IN_DIRENT ON)
  endif()
  print_bool(D_TYPE_IN_DIRENT)
endif()

check_include_file("strings.h" HAVE_STRINGS_H)
print_bool(HAVE_STRINGS_H)

check_function_exists(strcasestr STRCASESTR)
print_bool(STRCASESTR)

check_function_exists(memmem MEMMEM)
print_bool(MEMMEM)

check_function_exists(getpagesize GETPAGESIZE)
print_bool(GETPAGESIZE)

check_function_exists(strlcpy STRLCPY)
print_bool(STRLCPY)

check_function_exists(strtoimax have_strtoimax)
if(NOT have_strtoimax)
  check_function_exists(strtoumax have_strtoumax)
endif()
if(have_strtoimax OR have_strtoumax)
  set(STRTOUMAX ON)
endif()
print_bool(STRTOUMAX)

check_function_exists(setenv SETENV)
print_bool(SETENV)

check_function_exists(unsetenv UNSETENV)
print_bool(UNSETENV)

check_function_exists(mkdtemp MKDTEMP)
print_bool(MKDTEMP)

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

check_struct_has_member("struct passwd" pw_gecos "pwd.h" GECOS_IN_PWENT)
print_bool(GECOS_IN_PWENT)

check_include_file("libgen.h" LIBGEN_H)
print_bool(LIBGEN_H)
if(NOT LIBGEN_H)
  list(APPEND compat_defs "-DNO_LIBGEN_H")
endif()

check_function_exists(dirname libc_has_dirname)
if(NOT libc_has_dirname)
  set(NEEDS_LIBGEN ON)
endif()
print_bool(NEEDS_LIBGEN)

check_include_file("sys/select.h" SYS_SELECT_H)
print_bool(SYS_SELECT_H)

if(NOT WIN32)
  set(not_windows ON)
endif()
cmake_dependent_option(
  SYMLINK_HEAD "Occasionally use symbolic link for .git/HEAD" ON
  "not_windows" OFF)
print_bool(SYMLINK_HEAD)

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

  # Disable REGEX?
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

set(CMAKE_EXTRA_INCLUDE_FILES "stdint.h")
check_type_size(intptr_t INTPTR_T)
print_bool(INTPTR_T)
check_type_size(uintmax_t UINTMAX_T)
print_bool(UINTMAX_T)
set(CMAKE_EXTRA_INCLUDE_FILES)

check_function_exists(mmap have_mmap)
cmake_dependent_option(MMAP "Use mmap" ON "have_mmap" OFF)
print_bool(MMAP)

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

check_include_file("sys/poll.h" SYS_POLL_H)
print_bool(SYS_POLL_H)

cmake_dependent_option(POLL "Use poll()" ON "SYS_POLL_H" OFF)

find_package(Threads)
cmake_dependent_option(PTHREADS "Use pthreads" ON "CMAKE_USE_PTHREADS_INIT" OFF)
print_bool(PTHREADS)

check_function_exists(pread have_pread)
cmake_dependent_option(PREAD "Use pread system call" ON "have_pread" OFF)
print_bool(PREAD)

check_function_exists(setitimer SETITIMER)
print_bool(SETITIMER)

set(CMAKE_EXTRA_INCLUDE_FILES "sys/time.h")
check_type_size("struct itimerval" STRUCT_ITIMERVAL)
print_bool(STRUCT_ITIMERVAL)
set(CMAKE_EXTRA_INCLUDE_FILES)

option(FAST_WORKING_DIRECTORY
  "Accessing working directory is faster than accessing objects in pack files"
  ON)
print_bool(FAST_WORKING_DIRECTORY)

option(TRUSTABLE_FILEMODE "Filesystem supports executable file mode" ON)
print_bool(TRUSTABLE_FILEMODE)

option(NEEDS_MODE_TRANSLATION
       "OS strays from the typical file type bits in mode values"
       OFF)
print_bool(NEEDS_MODE_TRANSLATION)

option(IPV6 "System supports IPv6" ON)
print_bool(IPV6)

check_symbol_exists(AF_UNIX "${socket_headers}" UNIX_SOCKETS)
print_bool(UNIX_SOCKETS)

set(CMAKE_EXTRA_INCLUDE_FILES "${socket_headers}")
check_type_size("struct sockaddr" SOCKADDR_STORAGE)
print_bool(SOCKADDR_STORAGE)
set(CMAKE_EXTRA_INCLUDE_FILES)

find_package(ZLIB)
if(ZLIB_FOUND)
  set(CMAKE_REQUIRED_LIBRARIES "${ZLIB_LIBRARIES}")
  check_function_exists(deflateBound DEFLATE_BOUND)
  set(CMAKE_REQUIRED_LIBRARIES)
endif()
print_bool(DEFLATE_BOUND)

option(NORETURN "Use of attribute((__noreturn__))" ON)
print_bool(NORETURN)

check_struct_has_member("struct stat" st_ctimespec "sys/stat.h" USE_ST_TIMESPEC)
print_bool(USE_ST_TIMESPEC)

check_struct_has_member("struct stat" "st_ctim.tv_nsec" "sys/stat.h" HAVE_NSEC)
print_bool(HAVE_NSEC)

cmake_dependent_option(
  USE_NSEC "Use subsecond file mtimes and ctimes" OFF "HAVE_NSEC" OFF)
print_bool(USE_NSEC)

option(USE_STDEV
       "Consider underlying device change as inode change for update-index"
       OFF)
print_bool(USE_STDEV)

check_struct_has_member(
  "struct stat" st_blocks "sys/stat.h" ST_BLOCKS_IN_STRUCT_STAT)
print_bool(ST_BLOCKS_IN_STRUCT_STAT)

option(DOCBOOK_XSL_172 "Format man pages with DocBook XSL v1.72" OFF)
print_bool(DOCBOOK_XSL_172)

option(ASCIIDOC_ROFF "DocBook XSL does not escape raw roff directives" OFF)
print_bool(ASCIIDOC_ROFF)

option(GNU_ROFF "Target system uses GNU groff" OFF)
print_bool(GNU_ROFF)

option(USE_ASCIIDOCTOR "Use Asciidoctor instead of Asciidoc" OFF)
print_bool(USE_ASCIIDOCTOR)

set(ASCIIDOCTOR_EXTENSIONS_LAB "" CACHE STRING
    "Location of Asciidoctor Extensions Lab")
message(STATUS "ASCIIDOCTOR_EXTENSIONS_LAB: ${ASCIIDOCTOR_EXTENSIONS_LAB}")

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

check_function_exists(qsort_s HAVE_ISO_QSORT_S)
print_bool(HAVE_ISO_QSORT_S)

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

cmake_dependent_option(
  OBJECT_CREATION_USES_RENAMES
  "Use file rename instead of hardlink with immediate unlink"
  OFF
  "not_windows"
  ON)
print_bool(OBJECT_CREATION_USES_RENAMES)

option(
  USE_NED_ALLOCATOR "Use nedmalloc allocator instead of platform allocator" OFF)
print_bool(USE_NED_ALLOCATOR)

if(NOT USE_NED_ALLOCATOR)
  set(not_use_ned_allocator ON)
endif()
cmake_dependent_option(
  OVERRIDE_STRDUP "Override libc strdup" OFF "not_use_ned_allocator" ON)
print_bool(OVERRIDE_STRDUP)

check_symbol_exists(REG_STARTEND "regex.h" REGEX)
print_bool(REGEX)

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

option(GETTEXT_POISON "Debug choice of strings marked for translation" OFF)
print_bool(GETTEXT_POISON)

set(JSMIN "" CACHE FILEPATH "Path to JavaScript minifier for gitweb.js")
message(STATUS "JSMIN: ${JSMIN}")

set(CSSMIN "" CACHE FILEPATH "Path to CSS minifier for gitweb.css")
message(STATUS "CSSMIN: ${CSSMIN}")

find_program(LESS_PATH less)
set(DEFAULT_PAGER "${LESS_PATH}" CACHE FILEPATH "Sensible pager command")

find_program(VI_PATH vi)
set(DEFAULT_EDITOR "${VI_PATH}" CACHE FILEPATH "Sensible editor command")

if(WIN32 OR MINGW)
  set(NATIVE_CRLF ON)
endif()
print_bool(NATIVE_CRLF)

set(GIT_USER_AGENT "git/${PROJECT_VERSION}" CACHE STRING
    "User-agent used for network interactions")
message(STATUS "GIT_USER_AGENT: ${GIT_USER_AGENT}")

set(help_formats man info html)
set(DEFAULT_HELP_FORMAT "man" CACHE FILEPATH "\"git help\" format")
set_property(CACHE DEFAULT_HELP_FORMAT PROPERTY STRINGS "${help_formats}")
message(STATUS "DEFAULT_HELP_FORMAT: ${DEFAULT_HELP_FORMAT}")

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

check_symbol_exists(CLOCK_MONOTONIC "time.h" HAVE_CLOCK_MONOTONIC)
print_bool(HAVE_CLOCK_MONOTONIC)

try_compile(USE_PARENS_AROUND_GETTEXT_N
  "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/CMakeTmp"
  SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/cmake/parens_test.c")
print_bool(USE_PARENS_AROUND_GETTEXT_N)
if(USE_PARENS_AROUND_GETTEXT_N)
  list(APPEND defs "-DUSE_PARENS_AROUND_GETTEXT_N=1")
else()
  list(APPEND defs "-DUSE_PARENS_AROUND_GETTEXT_N=0")
endif()

try_compile(HAVE_BSD_SYSCTL
  "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/CMakeTmp"
  SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/cmake/sysctl_test.c")
print_bool(HAVE_BSD_SYSCTL)

check_function_exists(getdelim HAVE_GETDELIM)
print_bool(HAVE_GETDELIM)

set(doc_string "SP separated VAR=VAL pairs to define default environment")
set(doc_string "${doc_string} variables to be passed when a pager is spawned")
set(PAGER_ENV "LESS=FRX LV=-c" CACHE STRING "${doc_string}")
message(STATUS "PAGER_ENV: ${PAGER_ENV}")

find_program(SHELL_PATH sh)
message(STATUS "SHELL_PATH: ${SHELL_PATH}")

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
