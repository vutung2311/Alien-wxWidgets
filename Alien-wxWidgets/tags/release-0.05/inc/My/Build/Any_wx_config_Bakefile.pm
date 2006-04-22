package My::Build::Any_wx_config_Bakefile;

use strict;
our @ISA = qw(My::Build::Any_wx_config::Base);
use Config;

sub awx_wx_config_data {
    my $self = shift;
    return $self->{awx_data} if $self->{awx_data};

    my %data;

    foreach my $item ( qw(cxx ld cxxflags version libs basename prefix) ) {
        $data{$item} = $self->_call_wx_config( $item );
    }
    $data{ld} =~ s/\-o\s*$/ /; # wxWidgets puts 'ld -o' into LD
    $data{libs} =~ s/\-lwx\S+//g;

    my $arg = 'libs' . $My::Build::Any_wx_config::WX_CONFIG_LIBSEP .
        join ',', grep { !m/base/ }
        @My::Build::Any_wx_config::LIBRARIES;
    my $libraries = $self->_call_wx_config( $arg );

    foreach my $lib ( grep { m/\-lwx/ } split ' ', $libraries ) {
        $lib =~ m/-l(.*_(\w+)-.*)/ or die $lib;
        my( $key, $name ) = ( $2, $1 );
        $key = 'base' if $key =~ m/^base[ud]{0,2}/;
        $key = 'base' if $key =~ m/^carbon/; # here for Mac
        $key = 'core' if $key =~ m/^mac[ud]{0,2}/;
        my $dll = "lib${name}." . $self->awx_dlext;

        $data{dlls}{$key} = { dll  => $dll,
                              link => $lib };
    }
    if( $self->awx_is_monolithic ) {
        $data{dlls}{mono} = delete $data{dlls}{core};
    }

    $self->{data} = \%data;
}

1;
