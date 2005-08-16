package My::Build::Utility;

use strict;
use base qw(Exporter);
use Config;

our @EXPORT_OK = qw(awx_arch_file awx_install_arch_file
                    awx_install_arch_auto_file);

sub awx_arch_file {
    my( $vol, $dir, $file ) = File::Spec->splitpath( $_[0] || '' );
    File::Spec->catfile( 'blib', 'arch', 'Alien', 'wxWidgets',
                         File::Spec->splitdir( $dir ), $file );
}

sub awx_install_arch_file {
    my( $vol, $dir, $file ) = File::Spec->splitpath( $_[0] || '' );
    File::Spec->catfile( $Config{sitearchexp}, 'Alien', 'wxWidgets',
                         File::Spec->splitdir( $dir ), $file );
}

sub awx_install_arch_auto_file {
    my( $vol, $dir, $file ) = File::Spec->splitpath( $_[0] || '' );
    File::Spec->catfile( $Config{sitearchexp}, 'auto', 'Alien', 'wxWidgets',
                         File::Spec->splitdir( $dir ), $file );
}

1;
