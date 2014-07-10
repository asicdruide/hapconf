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

package HAPCONF::ethernet;

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
             ,"value"              => {"name"                  => $name
                                      ,"version"               => $version
                                      ,"node_number"           => undef
                                      ,"node_group"            => undef
                                      ,"node_type"             => "???"

                                      # indirect control table...
                                      ,"box"                   => []

                                      ,"notes"                 => []
                                      ,"schedule"              => []

                                      ,"box_group"             => {}

                                      }

             ,"legal"              => {# default port names...
                                      # symbolic indirect control commands...
                                       "box_command"        => {"ENABLE_BOX"          => 0xDD
                                                               ,"DISABLE_BOX"         => 0xDE
                                                               ,"TOGGLE_BOX"          => 0xDF
                                                               }

                                      ,"box_state"          => {"enabled"             => 0x01
                                                               ,"disabled"            => 0x00
                                                               }

                                      ,"version"            => {0x00                  => "ethernet interface"
                                                               }
                                      }
             };

  bless($self , $class);

  # register ourself...
  $project->add_node($name, $self);

  ## register our message-decoder...
  #$project->add_decoder(0x300 , \&decode_clock_message , $self);

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

sub url {
  my ($self , $url) = @_;

  $self->{"value"}->{"url"} = HAPCONF::util::check_url($url , "url");

  return $self;
}

#=======================================================================================================================

sub schedule {
  my ($self , $schedule) = @_;

  push(@{$self->{"schedule"}} , $schedule);

  return $self;
}

#=======================================================================================================================

sub get_id {
  my ($self) = @_;

  return ($self->{"node_number"} , $self->{"node_group"});
}

#=======================================================================================================================

sub get_url {
  my ($self) = @_;

  return $self->{"value"}->{"url"};
}

# ======================================================================================================================

sub message_decoder {
  my ($self , @message) = @_;

  my $result = "";

  my ($frame_type , $response_flag , $number , $group) = HAPCONF::util::message_header(@message);

  # ethernet does not has an id...
  if ($frame_type == 0x300) {$result = $self->decode_clock_message(@message)}

  return $result;
}

# ======================================================================================================================

sub decode_clock_message {
  my ($self , @message) = @_;

  my $year    = sprintf("%s%s" , ($message[ 6] & 0xF0) >> 4 , $message[ 6] & 0x0F);
  my $month   = sprintf("%s%s" , ($message[ 7] & 0xF0) >> 4 , $message[ 7] & 0x0F);
  my $day     = sprintf("%s%s" , ($message[ 8] & 0xF0) >> 4 , $message[ 8] & 0x0F);
  my $hour    = sprintf("%s%s" , ($message[10] & 0xF0) >> 4 , $message[10] & 0x0F);
  my $minute  = sprintf("%s%s" , ($message[11] & 0xF0) >> 4 , $message[11] & 0x0F);
  my $second  = sprintf("%s%s" , ($message[12] & 0xF0) >> 4 , $message[12] & 0x0F);

  my $result = sprintf("RTC %s-%s-%s %s:%s:%s"
                      ,$year
                      ,$month
                      ,$day
                      ,$hour
                      ,$minute
                      ,$second
                      );

  return $result;
}

#=======================================================================================================================

#=======================================================================================================================

#=======================================================================================================================

#=======================================================================================================================

#=======================================================================================================================

#=======================================================================================================================

1;
