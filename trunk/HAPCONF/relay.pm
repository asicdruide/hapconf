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

package HAPCONF::relay;

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
                                      ,"port_name"          => {}

                                      ,"powerup_state"      => {}

                                      # indirect control table...
                                      ,"box"                => []

                                      # indirect control table...
                                      ,"notes"              => []

                                      ,"box_group"          => {}
                                      }

             ,"legal"              => {# legal port names...
                                       "ports"              => [1..6]

                                      ,"port"               => {}

                                      # symbolic relay events...
                                      ,"relay_event"        => {"->on"        => 0xFF
                                                               ,"->off"       => 0x00
                                                               }

                                      # symbolic indirect control commands...
                                      ,"relay_command"      => {"turn_on"     => 0x01
                                                               ,"turn_off"    => 0x00
                                                               ,"toggle"      => 0x02
                                                               }

                                      ,"box_command"        => {"ENABLE_BOX"  => 0xDD
                                                               ,"DISABLE_BOX" => 0xDE
                                                               ,"TOGGLE_BOX"  => 0xDF
                                                               }

                                      ,"box_state"          => {"enabled"     => 0x01
                                                               ,"disabled"    => 0x00
                                                               }

                                      ,"powerup_state"      => {"on"          => 0x01
                                                               ,"off"         => 0x00
                                                               ,"last"        => 0x02
                                                               }

                                      ,"version"            => {0x01          => "relay, monostable, CO"
                                                               ,0x02          => "relay, bistable, CO"
                                                               ,0x03          => "relay, monostable, NO"
                                                               ,0x04          => "relay, bistable, NO"
                                                               }
                                      }
             };

  bless($self , $class);

  # resolve version dependencies...
  if (exists(                         $self->{"legal"}->{"version"}->{$version})) {
    $self->{"value"}->{"node_type"} = $self->{"legal"}->{"version"}->{$version};

    my @ports;

    if    ($version eq "1") {
      # monostable CO
    }
    elsif ($version eq "2") {
      # bistable   CO
    }
    elsif ($version eq "3") {
      # monostable NO
    }
    elsif ($version eq "4") {
      # bistable   NO
    }

    foreach my $i (@{$self->{"legal"}->{"ports"}}) {
      $self->{"legal"}->{"port"}->{$i} = $i;
    }

    # register ourself...
    $project->add_node($name, $self);
  }
  else {
    printf STDERR "ERROR : unknown version '%s'.\n", $version;
    Carp::confess();
  }

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

# assign symbolic name on port...
sub port_name {
  my ($self , $port , $port_name) = @_;

  if (!exists($self->{"legal"}->{"port"}->{$port})) {
    printf STDERR "ERROR : illegal port '%s'.\n", $port;
    Carp::confess();
  }
  elsif (exists($self->{"legal"}->{"port"}->{$port_name})) {
    printf STDERR "ERROR : port_name '%s' is not unique.\n", $port_name;
    Carp::confess();
  }
  else {
    my $port = $self->{"legal"}->{"port"}->{$port};

    $self->{"legal"}->{"port"     }->{$port_name} = $port;
    $self->{"value"}->{"port_name"}->{$port     } = $port_name;
  }

  return $self;
}

#=======================================================================================================================

sub notes {
  my ($self , $notes) = @_;

  push(@{$self->{"value"}->{"notes"}} , $notes);

  return $self;
}

#=======================================================================================================================

sub message {
  my ($self , $name , $event_spec , $opt) = @_;

  if (exists(    $self->{"legal"}->{"relay_event"}->{$event_spec})) {
    if (exists(  $self->{"legal"}->{"port"       }->{$opt       })) {
      my $port = $self->{"legal"}->{"port"       }->{$opt       };

      # format relay frame and register centrally that other can refer to it...
      my @message = (0x30,0x20
                    ,$self->{"value"}->{"node_number"}
                    ,$self->{"value"}->{"node_group"}
                    ,0xFF
                    ,0xFF
                    ,$port
                    ,$self->{"legal"}->{"relay_event"}->{$event_spec}
                    ,0xFF
                    ,undef
                    ,undef
                    ,undef
                    );

      $self->{"project"}->add_message($name , @message);
    }
    else {
      printf STDERR "ERROR : unknown port '%s'.\n", $opt;
      Carp::confess();
    }
  }
  else {
    printf STDERR "ERROR : illegal event specification '%s'.\n", $event_spec;
    Carp::confess();
  }

  return $self;
}

#=======================================================================================================================

# implements direct control...
sub send {
  my ($self
     ,$command
     ,$port_list
     ) = @_;
  my $timer           = 0;
  my $instruction;
  my $port_mask       = 0;
  my $receiver_number = $self->{"value"}->{"node_number"};
  my $receiver_group  = $self->{"value"}->{"node_group"};
  my $project         = $self->{"project"};

  if ($command =~ m/^(.+)#([0-9]+)$/) {
    $command = $1;
    $timer   = $2;
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  if (exists(      $self->{"legal"}->{"relay_command"}->{$command})) {
    $instruction = $self->{"legal"}->{"relay_command"}->{$command};

    # translate port list into bit masks...
    foreach my $port (split(/\s*,\s*/ , $port_list)) {
      if (exists($self->{"legal"}->{"port"}->{$port})) {
        my $i =  $self->{"legal"}->{"port"}->{$port};

        $port_mask |= 2**($i-1);
      }
      else {
        printf STDERR "ERROR : unknown port '%s'.\n", $port;
        Carp::confess();
      }
    }

    HAPCONF::util::Tx($project
                     ,"direct control"
                     ,0x10 , 0xA0    # direct control frame...
                     ,0x00 , 0x00    # sender ID
                     ,$instruction
                     ,$port_mask
                     ,$receiver_number , $receiver_group
                     ,$timer
                     ,0x00           # don't care
                     ,0x00           # don't care
                     ,0x00           # don't care
    );
  }
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  else {
    printf STDERR "ERROR : illegal command '%s'.\n", $command;
    Carp::confess();
  }
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  return $self;
}

#=======================================================================================================================

sub box {
  my ($self
     ,$state        # enabled/isabled
     ,$command      # one of many
     ,$opt          # depends on command: port_list, thermostat parameters,...
     ,$trigger      # trigger message
     ,$group_list   # optional box_group membership...
     ) = @_;

  if (!defined($group_list)) {
    $group_list = "";
  }

  my $box_state;
  my $INSTR1 = 0x00;
  my $INSTR2 = 0x00;
  my $INSTR3 = 0x00;
  my $INSTR4 = 0x00;
  my $INSTR5 = 0x00;
  my $INSTR6 = 0x00;
  my $INSTR7 = 0x00;
  my $INSTR8 = 0x00;
  # fetch trigger message...
  my @trigger = $self->{"project"}->get_message($trigger);

  if (exists($self->{"legal"}->{"box_state"}->{$state})) {
    $box_state = $state;
  }
  else {
    printf STDERR "ERROR : unknown box state '%s'.\n", $state;
    Carp::confess();
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  my $timer = 0;

  if ($command =~ m/^(.+)#([0-9]+)$/) {
    $command = $1;
    $timer   = $2;
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  if (exists( $self->{"legal"}->{"relay_command"}->{$command})) {
    $INSTR1 = $self->{"legal"}->{"relay_command"}->{$command};
    $INSTR2 = 0;

    my @port_list;

    # translate port list into bit masks...
    foreach my $port (split(/\s*,\s*/ , $opt)) {
      if (exists($self->{"legal"}->{"port"}->{$port})) {
        my $i =  $self->{"legal"}->{"port"}->{$port};

        $INSTR2 |= 2**($i-1);

        push(@port_list , $self->{"legal"}->{"port"}->{$port});
      }
      else {
        printf STDERR "ERROR : unknown port '%s'.\n", $port;
        Carp::confess();
      }
    }

    # store group membership...
    foreach my $box_group (split(/\s*,\s*/ , $group_list)) {
      my $this_box = scalar(@{$self->{"value"}->{"box"}});

      push(@{$self->{"value"}->{"box_group"}->{$box_group}} , $this_box);
    }

    $INSTR3 = $timer;
  }
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  elsif (exists($self->{"legal"}->{"box_command"}->{$command})) {
    $INSTR1 =   $self->{"legal"}->{"box_command"}->{$command};

    if (!exists($self->{"value"}->{"box_group"}->{$opt})) {
      printf STDERR "ERROR : unknown box_group '%s'.\n", $opt;
      Carp::confess();
    }

    # check that group is continuous...
    my @box_group = @{$self->{"value"}->{"box_group"}->{$opt}};
    {
      my $x = $box_group[0];

      foreach my $i (0..scalar(@box_group)-1) {
        if ($x+$i != $box_group[$i]) {
          printf STDERR "ERROR : box_group '%s' is not continuous (%s).\n", $opt, join("," , @box_group);
          Carp::confess();
        }
      }
    }

    $INSTR2 = $box_group[ 0]         & 0x7F;   # BoxX...
    $INSTR3 = (scalar(@box_group)-1) & 0x7F;   # BoxY...

    # store group membership...
    foreach my $box_group (split(/\s*,\s*/ , $group_list)) {
      my $this_box = scalar(@{$self->{"value"}->{"box"}});

      push(@{$self->{"value"}->{"box_group"}} , $this_box);
    }
  }
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  else {
    printf STDERR "ERROR : illegal command '%s'.\n", $command;
    Carp::confess();
  }
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  my $doc = sprintf("%s %-15s %-20s %s %s"
                   ,$state
                   ,$command
                   ,$opt
                   ,join(" " , map {if (defined($_)) {
                                      sprintf("=%02X",$_);
                                    }
                                    else {
                                      "x00";
                                    }
                               }
                               @trigger
                    )
                   ,$group_list
                   );

  push(@{$self->{"value"}->{"box"}} , [$box_state
                                      ,[$INSTR1
                                       ,$INSTR2
                                       ,$INSTR3
                                       ,$INSTR4
                                       ,$INSTR5
                                       ,$INSTR6
                                       ,$INSTR7
                                       ,$INSTR8
                                       ]
                                      ,[@trigger]
                                      ,$doc
                                      ]
  );

  return $self;
}

#=======================================================================================================================

sub powerup_state {
  my ($self , $port , $state_spec) = @_;

  if (!exists($self->{"legal"}->{"port"}->{$port})) {
    printf STDERR "ERROR : unknown port '%s'.\n", $port;
    Carp::confess();
  }
  elsif (!exists($self->{"legal"}->{"powerup_state"}->{$state_spec})) {
    printf STDERR "ERROR : illegal powerup state specification '%s'.\n", $state_spec;
    Carp::confess();
  }
  else {
    $port = $self->{"legal"}->{"port"}->{$port};

    $self->{"value"}->{"powerup_state"}->{$port} = $state_spec;
  }

  return $self;
}

# ======================================================================================================================

sub flash {
  my ($self , $cmd) = @_;

  my $project          =               $self->{"project"};
  my $number           =               $self->{"value"  }->{"node_number"};
  my $group            =               $self->{"value"  }->{"node_group" };
  my $version          =               $self->{"value"  }->{"version"    };
  my @box              =             @{$self->{"value"  }->{"box"        }};
  my $name             =               $self->{"value"  }->{"name"       };
  my @ports            =             @{$self->{"legal"  }->{"ports"      }};
  my @port_name        =          map {$self->{"value"  }->{"port_name"  }->{$_}} @ports;
  my $notes            = join("\n" , @{$self->{"value"  }->{"notes"      }});

  my $msg = "";

  ######################################################################################################################
  # check that we are what we expect to be...
  {
    my %FWping = HAPCONF::util::FWping($project ,$number , $group);

    if ($FWping{"msg"} eq "pass") {
      if ($FWping{"ATYPE"} != 0x02) {
        $msg .= sprintf("ERROR : Node(%s,%s) is not a relay module\n"
                       ,$number
                       ,$group
                       );
      }

      if ($FWping{"AVERS"} != $self->{"value"}->{"version"}) {
        $msg .= sprintf("ERROR : Node(%s,%s) has different version than configured (expected:%d found:%d)\n"
                       ,$number
                       ,$group
                       ,$self->{"value"}->{"version"}
                       ,$FWping{"AVERS"}
                       );
      }

      if ($msg eq "") {
        $msg = "pass";
      }
    }
    else {
      $msg = $FWping{"msg"};
    }
  }

  if ($msg eq "pass") {printf STDERR "INFO : verified that this module is a button module of correct version.\n"}
  else {printf STDERR $msg;$msg = ""}

  if ($msg eq "pass") {$msg = HAPCONF::util::one_node_enter_programming_mode($project , $number , $group)}

  if ($msg eq "pass") {printf STDERR "INFO : switched to programming mode\n"}
  else {printf STDERR $msg;$msg = ""}
  #
  ######################################################################################################################




  ######################################################################################################################
  # collect events to be enabled...
  if ($msg eq "pass") {
    my @data;

    printf STDERR "INFO : writing powerup info to EEPROM...\n";
    push(@data , 0x00); # Power up source: bit <0> - relay 1 … <5> - relay 6, value: '1' - power up from last saved, '0' - from set power up values
    push(@data , 0x00); # Set power up relay states: bit <0> - relay 1 … <5> - relay 6, value: '1' - relay on, '0' - relay off
    push(@data , 0x00); # Last saved relay states: bit <0> - relay 1 … <5> - relay 6, value: '1' - relay on, '0' - relay off

    $msg = HAPCONF::util::EEPROM_write($project , $number , $group , 0xF00008 , @data);

    if ($msg eq "pass") {printf STDERR "INFO : done.\n"}
    else {printf STDERR $msg;$msg = ""}
  }
  #
  ######################################################################################################################



  ######################################################################################################################
  # module name...
  if (defined($cmd) && $cmd eq "full") {
    if ($msg eq "pass") {printf STDERR "INFO : writing module name to EEPROM...\n"}

    my @data = HAPCONF::util::module_name_data($name);

    # write data...
    $msg = HAPCONF::util::EEPROM_write($project , $number , $group , 0xF00030 , @data);

    if ($msg eq "pass") {printf STDERR "INFO : done.\n"}
    else {printf STDERR $msg;$msg = ""}
  }
  #
  ######################################################################################################################



  ######################################################################################################################
  # collect boxes to be enabled...
  if ($msg eq "pass") {
    printf STDERR "INFO : writing box enables to EEPROM...\n";

    my @data = HAPCONF::util::box_enable_data(@box);

    # write data...
    $msg = HAPCONF::util::EEPROM_write($project , $number , $group , 0xF00040 , @data);

    if ($msg eq "pass") {printf STDERR "INFO : done.\n"}
    else {printf STDERR $msg;$msg = ""}
  }
  #
  ######################################################################################################################



  ######################################################################################################################
  # collect boxes...
  if ($msg eq "pass") {
    printf STDERR "INFO : writing box to Flash...\n";

    my @data = HAPCONF::util::box_data(@box);

    # erase data...
    $msg = HAPCONF::util::Flash_erase($project , $number , $group , 0x008800 , @data);

    if ($msg ne "pass") {printf STDERR $msg;$msg = ""}

    # write data...
    $msg = HAPCONF::util::Flash_write($project , $number , $group , 0x008800 , @data);

    if ($msg eq "pass") {printf STDERR "INFO : done.\n"}
    else {printf STDERR $msg;$msg = ""}
  }
  #
  ######################################################################################################################



  ######################################################################################################################
  # collect port names...
  if (defined($cmd) && $cmd eq "full") {
    if ($msg eq "pass") {printf STDERR "INFO : writing port names to Flash...\n"}

    my @data = HAPCONF::util::port_name_data(@port_name);

    # erase data...
    $msg = HAPCONF::util::Flash_erase($project , $number , $group , 0x008400 , @data);

    if ($msg ne "pass") {printf STDERR $msg;$msg = ""}

    # write data...
    $msg = HAPCONF::util::Flash_write($project , $number , $group , 0x008400 , @data);

    if ($msg eq "pass") {printf STDERR "INFO : done.\n"}
    else {printf STDERR $msg;$msg = ""}
  }
  #
  ######################################################################################################################



  ######################################################################################################################
  # collect notes...
  if (defined($cmd) && $cmd eq "full") {
    if ($msg eq "pass") {printf STDERR "INFO : writing notes to Flash...\n"}

    my @data = HAPCONF::util::notes_data($notes);

    # erase data...
    $msg = HAPCONF::util::Flash_erase($project , $number , $group , 0x008000 , @data);

    if ($msg ne "pass") {printf STDERR $msg;$msg = ""}

    # write data...
    $msg = HAPCONF::util::Flash_write($project , $number , $group , 0x008000 , @data);

    if ($msg eq "pass") {printf STDERR "INFO : done.\n"}
    else {printf STDERR $msg;$msg = ""}
  }
  #
  ######################################################################################################################



  if ($msg eq "pass") {
    printf "INFO : node %s,%s (button) flashed\n",$number , $group;
  }

  HAPCONF::util::one_node_exit_programming_mode($project , $number , $group);

  printf STDERR "INFO : switched to normal mode\n";

  return undef;
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
    if ($frame_type == 0x302) {$result = $self->decode_relay_message(@message)}
  }

  return $result;
}

# ======================================================================================================================

sub decode_relay_message {
  my ($self , @message) = @_;

  my %map = (0x00 => "->OFF"
            ,0xFF => "->ON"
            );

  my $channel    = $message[7];
  my $status     = $message[8];
  my $event      = exists($map{$status}) ? $map{$status} : "->??";

  my $result     = sprintf ("Relay K%d %s" , $channel , $event);

  return $result;
}

#=======================================================================================================================

1;
