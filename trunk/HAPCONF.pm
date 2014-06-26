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
package HAPCONF;

use strict;
use warnings;

use Exporter;
use Time::HiRes;

use vars qw(@ISA @EXPORT);

@ISA    = "Exporter";

@EXPORT = ("ethernet"
          ,"button_DIN_rail8"
          ,"button_back_box13"
          ,"button_back_box14"
          ,"button_back_box6touch"
          ,"relay_monostable_CO"
          ,"relay_monostable_NO"
          ,"relay_bistable_CO"
          ,"relay_bistable_NO"
          ,"ir_rx_tx"
          ,"led_rgb"
          ,"check"
          ,"node"
          ,"flash_fast"
          ,"flash_full"
          ,"go_online"
          ,"trace_CAN"
          ,"go_offline"
          ,"scan_network"
          ,"new_scan_network"
          ,"begin_log"
          ,"end_log"
          );


use Carp;
use Data::Dumper;
use IO::Socket::INET;
use IO::Select;

use HAPCONF::ethernet;
use HAPCONF::button;
#use HAPCONF::ir_rx_tx;
#use HAPCONF::led_rgb;
use HAPCONF::relay;
use HAPCONF::util;

$| = 1;


my $project;              # class-variable...

#=======================================================================================================================

sub new {
  my ($class , $name) = @_;

  if (defined($project)) {
    printf STDERR "ERROR : Multiple project per file by convention not allowed...\n";
    Carp:confess();
  }

  my $self = {"name"           => $name
             ,"node_id"        => {}
             ,"node_name"      => {}
             ,"message"        => {}
             ,"if"             => undef
             ,"socket"         => undef
             ,"select"         => undef
             ,"log"            => {"TxCAN" => 0
                                  ,"RxCAN" => 0
                                  ,"Box"   => 0
                                  }

             ,"node_type"      => {0x01 => {0x00 => "button, DIN rail"
                                           ,0x01 => "button, back box13"
                                           ,0x02 => "button, back box6touch"
                                           ,0x03 => "button, back box14"
                                           }
                                  ,0x02 => {0x01 => "relay, monostable, CO"
                                           ,0x02 => "relay, bistable, CO"
                                           ,0x03 => "relay, monostable, NO"
                                           ,0x04 => "relay, bistable, NO"
                                           }
                                  }
             };
  bless($self , $class);

  $project = $self;  # store in global class variable...
  
  return $self;
}

#=======================================================================================================================

sub ethernet {
  my ($name) = @_;

  my $ethernet = HAPCONF::ethernet->new($project , $name);
  
  return $ethernet;
}

#=======================================================================================================================

sub button_DIN_rail8 {
  my ($name) = @_;
  
  my $back_box_button = HAPCONF::button->new($project , $name , 0);
  
  return $back_box_button;
}

#=======================================================================================================================

sub button_back_box13 {
  my ($name) = @_;
  
  my $back_box_button = HAPCONF::button->new($project , $name , 1);
  
  return $back_box_button;
}

#=======================================================================================================================

sub button_back_box6touch {
  my ($name) = @_;
  
  my $back_box_button = HAPCONF::button->new($project , $name , 2);
  
  return $back_box_button;
}

#=======================================================================================================================

sub button_back_box14 {
  my ($name) = @_;
  
  my $back_box_button = HAPCONF::button->new($project , $name , 3);
  
  return $back_box_button;
}

#=======================================================================================================================

sub relay_monostable_CO {
  my ($name) = @_;

  my $bistable_relay = HAPCONF::relay->new($project , $name , 1);
  
  return $bistable_relay;
}

#=======================================================================================================================

sub relay_bistable_CO {
  my ($name) = @_;

  my $bistable_relay = HAPCONF::relay->new($project , $name , 2);
  
  return $bistable_relay;
}

#=======================================================================================================================

sub relay_monostable_NO {
  my ($name) = @_;

  my $bistable_relay = HAPCONF::relay->new($project , $name , 3);
  
  return $bistable_relay;
}

#=======================================================================================================================

sub relay_bistable_NO {
  my ($name) = @_;

  my $bistable_relay = HAPCONF::relay->new($project , $name , 4);
  
  return $bistable_relay;
}

#=======================================================================================================================

sub ir_rx_tx {
  my ($name , $version) = @_;
  
  my $ir_rx_tx = HAPCONF::ir_rx_tx->new($project , $name , $version);
  
  return $ir_rx_tx;
}

#=======================================================================================================================

sub led_rgb {
  my ($name , $version) = @_;
  
  my $led_rgb = HAPCONF::led_rgb->new($project , $name , $version);
  
  return $led_rgb;
}

#=======================================================================================================================

sub node {
  my ($name) = @_;
  
  if (!exists($project->{"node_name"}->{$name})) {
    printf STDERR "ERROR : unknown node '%s'.\n", $name;
    Carp::confess();
  }
  else {
    return $project->{"node_name"}->{$name}
  }
}

#=======================================================================================================================

sub begin_log {
  my (@flag) = @_;
  
  foreach my $flag (@flag) {
    if (exists($project->{"log"}->{$flag})) {
               $project->{"log"}->{$flag} = 1;
    }
    else {
      printf STDERR "ERROR : unknown log flag '%s'.\n", $flag;
    }
  }
  
  return undef;
}

#=======================================================================================================================

sub end_log {
  my (@flag) = @_;
  
  foreach my $flag (@flag) {
    if (exists($project->{"log"}->{$flag})) {
               $project->{"log"}->{$flag} = 0;
    }
    else {
      printf STDERR "ERROR : unknown log flag '%s'.\n", $flag;
    }
  }
  
  return undef;
}

#=======================================================================================================================

sub flash_fast {
  my (@name) = @_;
  
  foreach my $name (@name) {
    if (!exists($project->{"node_name"}->{$name})) {
      printf STDERR "ERROR : unknown node '%s'.\n", $name;
      Carp::confess();
    }
    else {
      $project->{"node_name"}->{$name}->flash("fast");
    }
  }
  
  return undef;
}

#=======================================================================================================================

sub flash_full {
  my (@name) = @_;
  
  foreach my $name (@name) {
    if (!exists($project->{"node_name"}->{$name})) {
      printf STDERR "ERROR : unknown node '%s'.\n", $name;
      Carp::confess();
    }
    else {
      $project->{"node_name"}->{$name}->flash("full");
    }
  }
  
  return undef;
}

#=======================================================================================================================

sub dump {
   print Dumper($project);
}

#=======================================================================================================================

sub add_node {
  my ($project , $node_name , $node_ref) = @_;
  
  if (exists($project->{"node_name"}->{$node_name})) {
    printf STDERR "ERROR : node name '%s' is not unique\n", $node_name;
    Carp::confess();
  }
  else {
    $project->{"node_name"}->{$node_name} = $node_ref;
    
    if (ref($node_ref) eq "HAPCONF::ethernet") {
      $project->{"if"} = $node_ref;
    }
  }
  
  return undef;
}

#=======================================================================================================================

sub set_node_id {
  my ($project , $node_name , $node_number , $node_group) = @_;
  
  my $node_id = $node_number.",".$node_group;

  if (!exists($project->{"node_name"}->{$node_name})) {
    printf STDERR "ERROR : a node named '%s' does not exist\n", $node_name;
    Carp::confess();
  }
  elsif (exists($project->{"node_id"}->{$node_id})) {
    printf STDERR "ERROR : node id '%s' is not unique\n", $node_id;
    Carp::confess();
  }
  else {
    $project->{"node_id"}->{$node_id} = $project->{"node_name"}->{$node_name};
  }
  
  return undef;
}

#=======================================================================================================================

sub add_message {
  my ($project , $name , @message) = @_;
  
  if (exists($project->{"message"}->{$name})) {
    printf STDERR "ERROR : message '%s' is not unique\n", $name;
    Carp::confess();
  }
  else {
    $project->{"message"}->{$name} = [@message];
  }
  
  return undef;
}

#=======================================================================================================================

sub get_message {
  my ($project , $name) = @_;
  
  if (!exists($project->{"message"}->{$name})) {
    printf STDERR "ERROR : unknown message '%s'.\n", $name;
    Carp::confess();
  }

  return @{$project->{"message"}->{$name}};
}

#=======================================================================================================================

sub go_online {
  if (!defined($project->{"if"})) {
    printf STDERR "ERROR : no ethernet interface defined, yet.\n";
    Carp::confess();
  }
  
  my  $if_url = $project->{"if"}->get_url();
  
  my $socket;
  
  if ($socket = IO::Socket::INET->new(PeerAddr    => $if_url
                                     ,Proto       => 'tcp'
                                     ,Type        => SOCK_STREAM
                                     ,Timeout     => 2.0
                                     ,Blocking    => 1
                                     )
     ) {
    printf STDERR "INFO : connected\n";
    $socket->autoflush(1);
  }
  else {
    printf STDERR "ERROR : can't connect to '%s', %s\n", $if_url , $@;
    Carp::confess();
  }

  my $select = IO::Select->new();

  $select->add($socket);
  
  $project->{"socket"} = $socket;
  $project->{"select"} = $select;
  
  return undef;
}

#=======================================================================================================================

sub scan_network {
  my ($n_min , $n_max , $g_min , $g_max) = @_;
  
  my $n = 0;
  
  my $sep = "";
  
  foreach   my $group  (($g_min & 0xFF)..($g_max & 0xFF)) {
    foreach my $number (($n_min & 0xFF)..($n_max & 0xFF)) {
      my %HWping = HAPCONF::util::HWping($project ,$number , $group);

      if ($HWping{"msg"} eq "pass") {
        my %FWping = HAPCONF::util::FWping($project ,$number , $group);

        printf "%sfound node at (%s,%s)\n"
               ,$sep
               ,$number
               ,$group
        ;
        printf "  HARD=0x%04X HVER=0x%02X ID=0x%08X\n"
               ,$HWping{"HARD"}
               ,$HWping{"HVER"}
               ,$HWping{"ID"}
        ;
        
        if ($FWping{"msg"} eq "pass") {
          printf "  ATYPE=0x%02X AVERS=0x%02X FVERS=0x%02X BVER=0x%04X\n  %s\n"
                 ,$FWping{"ATYPE"}
                 ,$FWping{"AVERS"}
                 ,$FWping{"FVERS"}
                 ,$FWping{"BVER"}
                 ,$project->decode_type($FWping{"ATYPE"} , $FWping{"AVERS"})
          ;
        }

        $sep = "";
        
        $n += 1;
      }
      else {
        print ".";
        $sep = "\n";
      }
    }
  }

  printf "\n%d nodes found\n",$n;
  
  return undef;
}

#=======================================================================================================================

sub new_scan_network {
  my ($n_min , $n_max , $g_min , $g_max) = @_;
  
  my @ping;
  my $n = 0;
  
  foreach   my $group  (($g_min & 0xFF)..($g_max & 0xFF)) {
    foreach my $number (($n_min & 0xFF)..($n_max & 0xFF)) {
      push(@ping , [$number , $group]);
    }
  }

  my $socket = $project->{"socket"};
  my $select = $project->{"select"};
  my $timeout = 1;

  while (scalar(@ping) > 0) {
    my $pinged = 0;
    
    while (scalar(@ping) > 0 && $pinged < 1) {
      my ($number , $group) = @{shift(@ping)};
      
      HAPCONF::util::Tx($project
        ,"ping"
        ,0x10    , 0x40    # hw type request
        ,0x00    , 0x00    # sender (might not know, yet)
        ,0x00    , 0x00    # don't care
        ,$number , $group  # receiver
        ,0x00    , 0x00    # don't care
        ,0x00    , 0x00    # don't care
      );
      #Time::HiRes::usleep(50000);
      $pinged += 1;
    }
    
    # check answers...
    my @can_read = $select->can_read($timeout);
    my $rx;

    while (scalar(@can_read) > 0) {
      foreach my $can_read (@can_read) {
        $can_read->read($rx , 15);
        
        my @rx_byte = map {ord(substr($rx , $_ , 1))} (0..14);

        # tbd: check CHKSUM...
        if ($rx_byte[1] == 0x10
            &&
            $rx_byte[2] == 0x41) {
          # somebody sent a hw type response...
          my $number = $rx_byte[3];
          my $group  = $rx_byte[4];
          my $HARD   = $rx_byte[5]<<8  | $rx_byte[6];
          my $HVER   = $rx_byte[7];
          my $ID     = $rx_byte[9]<<24 | $rx_byte[10]<<16 | $rx_byte[11]<<8 | $rx_byte[12]; 
      
          printf "found node at (%s,%s) : HARD=0x%04X HVER=0x%02X ID=0x%08X\n"
                 ,$number
                 ,$group
                 ,$HARD
                 ,$HVER
                 ,$ID
          ;
          $n += 1;
        } 
      }

      @can_read = $select->can_read($timeout);
    }
  }

  printf "\n%d nodes found\n",$n;
  
  return undef;
}

#=======================================================================================================================

sub trace_CAN {
  my ($timeout) = @_;
  
  if (!defined($timeout)) {
    $timeout = 30;
  }
  
  if (defined($project->{"socket"})) {
    printf STDERR "INFO : stop tracing after %d seconds of inactivity\n", $timeout;
    HAPCONF::util::RxFlush($project , $timeout);
  }
  else {
    printf STDERR "ERROR : not online.\n";
  }
  
  return undef;
}

#=======================================================================================================================

sub go_offline {
  if (defined($project->{"socket"})) {
    $project->{"select"}->remove($project->{"socket"});
    $project->{"socket"}->close();
    
    $project->{"select"} = undef;
    $project->{"socket"} = undef;
    
    printf STDERR "INFO : disconnected.\n";

  }
  else {
    printf STDERR "ERROR : not online.\n";
  }
  
  return undef;
}

#=======================================================================================================================

sub decode_type {
  my ($project , $ATYPE , $AVERS) = @_;
  my $result = "";
  
  if (exists( $project->{"node_type"}->{$ATYPE})
      &&
      exists( $project->{"node_type"}->{$ATYPE}->{$AVERS})) {
    $result = $project->{"node_type"}->{$ATYPE}->{$AVERS};
  }
  else {
    $result = sprintf("unknown module 0x%02X 0x%02X" , $ATYPE , $AVERS);
  }

  return $result;
}

#=======================================================================================================================

sub decode_message {
  my ($project , @message) = @_;
  
  if (scalar(@message)!=15) {
    return sprintf("Error : wrong frame length, '%s' is not 15\n",scalar(@message));
  }
  
  if ($message[0] != 0xAA) {
    return sprintf("Error : wrong start byte, '0x%02X' is not 0xAA\n",$message[0]);
  }

  if ($message[14] != 0xA5) {
    return sprintf("Error : wrong stop byte, '0x%02X' is not 0xA5\n",$message[14]);
  }

  my $chksum = 0;

  map {$chksum += $_} @message[1..12];
  
  $chksum = $chksum & 0xFF;
  
  if ($message[13] != $chksum) {
    return sprintf("Error : wrong chksum, '0x%02X' is not 0x%02X\n",$message[13] , $chksum);
  }

  my ($frame_type
     ,$response_flag
     ,$number
     ,$group) = HAPCONF::util::message_header(@message);

  my $result;

  if ($response_flag == 0) {
    $result = " req ";
  }
  else {
    $result = " rsp ";
  }
  
  $result .= sprintf("(%02X,%02X) ", $number , $group);
  
  foreach my $name (keys %{$project->{"node_name"}}) {
    my $part = $project->{"node_name"}->{$name}->message_decoder(@message);
    $result .= $part;
  }

  return $result;
}

# ======================================================================================================================

sub message_decoder {
  my ($self , $frame_type , $response_flag , @byte) = @_;
  
  my $result = "";
  
  if    ($frame_type == 0x104) {$result = $self->decode_hw_type_message(@byte)}

  return $result;
}

# ======================================================================================================================

sub decode_hw_type_message {
  my ($self, @byte) = @_;
  my $result = "";

  $result = sprintf("(%02X,%02X) HW type ", $byte[3] , $byte[4]);
  
  my $HARD = $byte[5]<<8 | $byte[6];
  my $HVER = $byte[7];
  my $ID   = $byte[9]<<24 | $byte[10]<<16 | $byte[11]<<8 | $byte[12]; 
  
  my %id_map = (0x000005F7 => "Bistable Relay"
               ,0x000005E9 => "RGB LED Controller"
               ,0x00000608 => "Back Box Button"
               ,0x000005D4 => "IR RxTx"
               );
            
  my $desc = "";
  
  if (exists($id_map{$ID})) {
    $desc =  "(".$id_map{$ID}.")";
  }
  
  $result .= sprintf(" HARD=0x%04X HVER=0x%02X ID=0x%08X %s"
                    ,$HARD
                    ,$HVER
                    ,$ID
                    ,$desc);
  
  return $result;
}

#=======================================================================================================================

1;
