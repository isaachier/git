package Generators::CMake;
require Exporter;

use strict;
use vars qw($VERSION);
use Data::Dumper;

our $VERSION = '1.00';
our(@ISA, @EXPORT, @EXPORT_OK, @AVAILABLE);
@ISA = qw(Exporter);

BEGIN {
    push @EXPORT_OK, qw(generate);
}

sub makeOptions {
    return "COMPUTE_HEADER_DEPENDENCIES=no"
}

sub generate {
    my ($git_dir, $out_dir, $rel_dir, %build_structure) = @_;

    my @libs = @{$build_structure{LIBS}};
    foreach (@libs) {
        createLibProject($_, $git_dir, $out_dir, $rel_dir, %build_structure);
    }

    my @apps = @{$build_structure{APPS}};
    foreach (@apps) {
        createAppProject($_, $git_dir, $out_dir, $rel_dir, %build_structure);
    }

    createGlueProject($git_dir, $out_dir, $rel_dir, %build_structure);
    return 0;
}

sub createLibProject {
    my ($libname, $git_dir, $out_dir, $rel_dir, %build_structure) = @_;
    $rel_dir = "../$rel_dir";

    my $target = $libname;
    $target =~ s/lib//g;
    $target =~ s/\.a$//g;
    $target =~ s/\///g;
    if ("$target" eq "git") {
        $target = "libgit";
    }
    print "Generate $target library target\n";

    my @sources = @{$build_structure{"LIBS_${libname}_SOURCES"}};
    my @defines = @{$build_structure{"LIBS_${libname}_DEFINES"}};
    my @includes= @{$build_structure{"LIBS_${libname}_INCLUDES"}};
    my @cflags  = @{$build_structure{"LIBS_${libname}_CFLAGS"}};

    # TODO: open F, ">CMakeLists.txt" || die "Could not open CMakeLists.txt for writing!\n";
}

sub createAppProject {}

sub createGlueProject {}
