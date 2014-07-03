########################################################################################################################
#   Copyright (C) 2014 Klaus Welch
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
########################################################################################################################
#   Revision History
#   Rev:  Date:     Details:
#   0     ??.????   ???????????????????
########################################################################################################################
use strict;
use warnings;
use Carp;
use HAPCONF::util;

$| = 1;

package HAPCONF::ir_rx_tx;

#=======================================================================================================================

sub new {
  my ($class
     ,$project
     ,$name
     ,$version
     ) = @_;

  $name = HAPCONF::util::check_name($name , "name");

  if (!defined($version)) {
    printf STDERR "ERROR : undefined version not allowed.\n";
    Carp::confess();
  }

  my $self = {"project"            => $project
             ,"value"              => {"name"               => $name
                                      ,"version"            => $version
                                      ,"node_number"        => undef
                                      ,"node_group"         => undef
                                      ,"node_type"          => "???"

                                      # user defined symbolic name...

                                      # indirect control table...
                                      ,"box"                => []

                                      # indirect control table...
                                      ,"program"            => {}

                                      # long description...
                                      ,"notes"              => []

                                      ,"box_group"          => {}
                                      }

             ,"legal"              => {# legal port names...

                                      # symbolic relay events...
                                       "relay_event"        => {"->on"        => 0xFF
                                                               ,"->off"       => 0x00
                                                               }

                                      ,"box_command"        => {"ENABLE_BOX"  => 0xDD
                                                               ,"DISABLE_BOX" => 0xDE
                                                               ,"TOGGLE_BOX"  => 0xDF
                                                               }

                                      ,"box_state"          => {"enabled"     => 0x01
                                                               ,"disabled"    => 0x00
                                                               }

                                      ,"version"            => {0x03          => "rev3"
                                                               }
                                      }
             };

  bless($self , $class);

  # register ourself...
  $project->add_node($name , $self);

  return $self;
}

#=======================================================================================================================

sub id {
  my ($self , $node_number , $node_group) = @_;

  $node_number = HAPCONF::util::check_number($node_number , "node_number");
  $node_group  = HAPCONF::util::check_number($node_group  , "node_group" );

  $self->{"value"}->{"node_number"} = $node_number;
  $self->{"value"}->{"node_group" } = $node_group;

  $self->{"project"}->set_node_id($self->{"value"}->{"name"} , $node_number , $node_group);

  return $self;
}

#=======================================================================================================================

sub get_id {
  my ($self) = @_;

  return ($self->{"value"}->{"node_number"} , $self->{"value"}->{"node_group"});
}

#=======================================================================================================================

sub message {
  my ($self , $name , $event_spec) = @_;

  if ($event_spec =~ m/^RC5-(\d{1,3})-(\d{1,3})-(begin|end)$/) {
    my $address = $1;
    my $command = $2;
    my $mode    = $3;

    my %code_type = ("begin" => 0x06
                    ,"end"   => 0x86
                    );

    # format message and register centrally that other can refer to it...
    my @message = (0x30,0x30
                  ,$self->{"value"}->{"node_number"}
                  ,$self->{"value"}->{"node_group" }
                  ,0xFF
                  ,0xFF
                  ,$code_type{$mode}
                  ,$address
                  ,$command
                  ,0xFF
                  ,0xFF
                  ,0xFF
                  );
    $self->{"project"}->add_message($name , @message);
  }
  else {
    printf STDERR "ERROR : illegal event specification '%s'.\n", $event_spec;
    Carp::confess();
  }

  return $self;
}

#=======================================================================================================================

sub notes {
  my ($self , $notes) = @_;

  push(@{$self->{"value"}->{"notes"}} , $notes);

  return $self;
}

# ======================================================================================================================

sub message_decoder {
  my ($self , @message) = @_;

  my $result = "";

  my ($frame_type , $response_flag , $number , $group) = HAPCONF::util::message_header(@message);

  if (defined(   $self->{"value"}->{"node_number"})
      &&
      defined(   $self->{"value"}->{"node_group"})
      &&
      $number == $self->{"value"}->{"node_number"}
      &&
      $group  == $self->{"value"}->{"node_group" }) {
    # it's one of our message...
    if ($frame_type == 0x303) {$result = $self->decode_ir_message(@message)}
  }

  return $result;
}

#=======================================================================================================================

sub decode_ir_message {
  my ($self , @message) = @_;

  my $code_type  = $message[ 7];
  my $code1      = $message[ 8];
  my $code2      = $message[ 9];
  my $code3      = $message[10];
  my $result;

  if ($code_type == 0x06) {
    $result     = sprintf ("IR start RC3-%d-%d" , $code1 , $code2);
  }
  elsif ($code_type == 0x86) {
    $result     = sprintf ("IR end   RC3-%d-%d" , $code1 , $code2);
  }
  else {
    $result     = sprintf ("IR code_type:%d code:%d-%d-%d" , $code_type , $code1 , $code2 , $code3);
  }

  return $result;
}

#=======================================================================================================================

#=======================================================================================================================

#=======================================================================================================================

#=======================================================================================================================

#=======================================================================================================================

#=======================================================================================================================

#=======================================================================================================================

1;
