package File::AddInc;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use File::Spec;
use File::Basename;
use Cwd ();
use lib ();
use Carp ();

use constant DEBUG => $ENV{DEBUG_MOP4IMPORT};

sub import {
  my ($pack) = @_;

  my ($callpack, $filename, $line) = caller;

  $pack->declare_file_inc($callpack, $filename);
}

sub declare_file_inc {
  my ($pack, $callpack, $filename) = @_;

  my $libdir = $pack->libdir($callpack, $filename);

  print STDERR "# use lib '$libdir'\n" if DEBUG;

  lib->import($libdir);
}

sub libdir {
  my ($pack, @caller) = @_;

  my ($callpack, $filename) = @caller ? @caller : caller;

  (my $packfn = $callpack) =~ s,::,/,g;
  $packfn .= ".pm";

  my $realFn = -l $filename
    ? resolve_symlink($pack, $filename)
    : $filename;

  my $absfn = File::Spec->rel2abs($realFn);

  $absfn =~ /\Q$packfn\E\z/
    or Carp::croak("Can't handle this case! absfn=$absfn; packfn=$packfn");

  substr($absfn, 0, length($absfn) - length($packfn) - 1);
}

sub resolve_symlink {
  my ($pack, $filePath) = @_;

  print STDERR "# resolve_symlink($filePath)...\n" if DEBUG;

  (undef, my ($realDir)) = fileparse($filePath);

  while (defined (my $linkText = readlink $filePath)) {
    ($filePath, $realDir) = resolve_symlink_1($pack, $linkText, $realDir);
    print STDERR "# => $filePath (realDir=$realDir)\n" if DEBUG;
  }

  return $filePath;
}

sub resolve_symlink_1 {
  my ($pack, $linkText, $realDir) = @_;

  my $filePath = do {
    if (File::Spec->file_name_is_absolute($linkText)) {
      $linkText;
    } else {
      File::Spec->catfile($realDir, $linkText);
    }
  };

  if (wantarray) {
    # purify x/../y to y
    my $realPath = Cwd::realpath($filePath);
    (undef, $realDir) = fileparse($realPath);
    ($realPath, $realDir);
  } else {
    $filePath;
  }
}

1;
__END__

=encoding utf-8

=head1 NAME

File::AddInc - find library directory of used file and add it to @INC

=head1 SYNOPSIS

    package MyApp::Deep::Module;
    use File::AddInc; # <-- This will add '../../' to @INC.
    use MyApp::Util;  # So perl can find MyApp/Util.pm correctly.

=head1 DESCRIPTION

File::AddInc finds library toplevel directory for given file and add it to @INC.
This is useful when you directly used/executed the module.

=head1 LICENSE

Copyright (C) Kobayasi, Hiroaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kobayasi, Hiroaki E<lt>buribullet@gmail.comE<gt>

=cut
