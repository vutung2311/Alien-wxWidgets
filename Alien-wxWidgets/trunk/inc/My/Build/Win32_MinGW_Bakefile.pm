package My::Build::Win32_MinGW_Bakefile;

use strict;
use base qw(My::Build::Win32_MinGW My::Build::Win32_Bakefile);
use My::Build::Utility qw(awx_install_arch_file awx_install_arch_auto_file);
use Config;
use Fatal qw(chdir);

sub awx_wx_config_data {
    My::Build::Win32::_init();

    my $self = shift;
    return $self->{awx_data} if $self->{awx_data};

    my %data = ( %{$self->SUPER::awx_wx_config_data},
                 'cxx'     => 'g++',
                 'ld'      => 'g++',
               );

    my $cflags = 'CXXFLAGS=" -Os -DNO_GCC_PRAGMA "';
        
    my $final = $self->awx_debug ? 'BUILD=debug'
                                 : 'BUILD=release';
                                 
    if( my $xbuildflags = $self->awx_w32_extra_buildflags ) {
		$final .= ' ' . $xbuildflags;
	}
    
    my $unicode = $self->awx_unicode ? 'UNICODE=1' : 'UNICODE=0';
    $unicode .= ' MSLU=1' if $self->awx_mslu;

    my $dir = Cwd::cwd;
    my $make = $self->_find_make;
    chdir File::Spec->catdir( $ENV{WXDIR}, 'samples', 'minimal' );
    
    # help xcomp tools
    local $ENV{GNUTARGET} = ( $Config{ptrsize} == 8  ) ? 'pe-x86-64' : 'pe-i386';
    
    my @t = qx($make -n -B -f makefile.gcc $final $unicode $cflags SHARED=1);

    my( $orig_libdir, $libdir, $digits );
    foreach ( @t ) {
        chomp;

        if( m/\s-l\w+/ ) {
            m/-lwxbase(\d+)/ and $digits = $1;
            s/^[cg]\+\+//;
            s/(?:\s|^)-[co]//g;
            s/\s+\S+\.(exe|o)/ /gi;
            s{-L(\S+)}
             {$orig_libdir = File::Spec->canonpath
                                 ( File::Spec->rel2abs( $1 ) );
              '-L' . ( $libdir = awx_install_arch_file( $self, 'rEpLaCe/lib' ) )}eg;
            $data{libs} = $_;
        } elsif( s/^\s*g\+\+\s+// ) {
            s/\s+\S+\.(cpp|o|d)/ /g;
            s/\s+-M[DP]\b/ /g;
            s/(?:\s|^)-[co]//g;
            s{[-/]I(\S+)}{'-I' . File::Spec->canonpath
                                     ( File::Spec->rel2abs( $1 ) )}egi;
            s{[-/]I(\S+)[\\/]samples[\\/]minimal(\s|$)}{-I$1\\contrib\\include }i;
            s{[-/]I(\S+)[\\/]samples(\s|$)}{ }i;
            $data{cxxflags} = $_;
        }
    }

    chdir $dir;
    die 'Could not find wxWidgets lib directory' unless $libdir;

    $self->awx_w32_find_setup_dir( $data{cxxflags} ); # for awx_grep_dlls

    $data{dlls} = $self->awx_grep_dlls( $orig_libdir, $digits, $self->awx_is_monolithic );
    $data{version} = $digits;

    $self->{awx_data} = \%data;
}

sub _make_command {
    my $make = $_[0]->_find_make;
    "$make -f makefile.gcc all "
}

sub build_wxwidgets {
    my( $self ) = shift;

    $self->My::Build::Win32_Bakefile::build_wxwidgets( @_ );
}

sub awx_w32_ldflags {
	my $self = shift;
	# MinGW.org gcc 4.5.2 links shared libstdc++ by default.
	# gcc 4.4.x and below doesn't understand -static-libstdc++
	# (MinGW.org 3.4.5 compiler and many versions of mingw-w64 compiler)
	# TDM mingw bundles do understand so no harm in specifying even
	# though static is the defautl there
	my $cmdout = qx(g++ -static-libstdc++ 2>&1);
	my $ldflags = ($cmdout =~ /unrecognized option/) ? '' : '-static-libstdc++';
	# add -m32 / -m64  flags for mingw-w64 builds that combine 32bit / 64bit
	# The mingw bundle from TDM requires this
	$ldflags .= ( $Config{ptrsize} == 8 ) ? ' -m64' : ' -m32';
	return $ldflags;
}

sub awx_w32_cppflags {
	my $self = shift;
	# see awx_w32_ldflags
	my $cppflags = ( $Config{ptrsize} == 8 ) ? '-m64' : '-m32';
	
	return $cppflags;
}


1;
