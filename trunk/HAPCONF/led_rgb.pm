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

package HAPCONF::led_rgb;

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
                                      
                                      ,"powerup_value" => {"1"   =>    0
                                                          ,"2"   =>    0
                                                          ,"3"   =>    0
                                                          ,"4"   =>  255
                                                          }
                                      ,"powerup_last"  => {"1"   => 0x01
                                                          ,"2"   => 0x02
                                                          ,"3"   => 0x04
                                                          ,"4"   => 0x00
                                                          }
                                      ,"dimming_time"  => {"1"   =>    8
                                                          ,"2"   =>    8
                                                          ,"3"   =>    8
                                                          ,"4"   =>    8
                                                          }            
                                      ,"min_value"     => {"1"   =>    0
                                                          ,"2"   =>    0
                                                          ,"3"   =>    0
                                                          ,"4"   =>    0
                                                          }
                                      ,"max_value"     => {"1"   =>  255
                                                          ,"2"   =>  255
                                                          ,"3"   =>  255
                                                          ,"4"   =>  255
                                                          }
                                      ,"state_memory"  => {"1"   =>  0x01
                                                          ,"2"   =>  0x01
                                                          ,"3"   =>  0x01
                                                          ,"4"   =>  0x01
                                                          }

                                      # indirect control table...
                                      ,"box"                => []
                                      
                                      # long description...
                                      ,"notes"              => []

                                      ,"box_group"          => {}
                                      }
                                      
             ,"legal"              => {# legal port names...
                                       "ports"              => [1..4]

                                      ,"port"               => {"r"   =>  1
                                                               ,"g"   =>  2
                                                               ,"b"   =>  3
                                                               ,"m"   =>  4
                                                                      
                                                               ,"1"   =>  1
                                                               ,"2"   =>  2
                                                               ,"3"   =>  3
                                                               ,"4"   =>  4
                                                               }
                                      
                                      # symbolic relay events...
                                      ,"relay_event"        => {"->on"        => 0xFF
                                                               ,"->off"       => 0x00
                                                               }
                                      
                                      # symbolic indirect control commands...
                                      ,"cmd_value_timer"   => {# set to commands...
                                                                "R="          => 0x00
                                                               ,"G="          => 0x01
                                                               ,"B="          => 0x02
                                                               ,"M="          => 0x03
                                                               # step down commands...
                                                               ,"R-="         => 0x08
                                                               ,"G-="         => 0x09
                                                               ,"B-="         => 0x0A
                                                               ,"M-="         => 0x0B
                                                               # step up commands...
                                                               ,"R+="         => 0x0C
                                                               ,"G+="         => 0x0D
                                                               ,"B+="         => 0x0E
                                                               ,"M+="         => 0x0F
                                                               # set softly to commands...
                                                               ,"R~"          => 0x10
                                                               ,"G~"          => 0x11
                                                               ,"B~"          => 0x12
                                                               ,"M~"          => 0x13
                                                               }
                                                               
                                      ,"cmd_timer"          => {"toggle_R"    => 0x04
                                                               ,"toggle_G"    => 0x05
                                                               ,"toggle_B"    => 0x06
                                                               ,"toggle_M"    => 0x07
                                                               }
                                                               
                                      ,"cmd_plain"          => {"stop_R"      => 0x14
                                                               ,"stop_G"      => 0x15
                                                               ,"stop_B"      => 0x16
                                                               ,"stop_M"      => 0x17
                                                               
                                                               ,"start_R"     => 0x18
                                                               ,"start_G"     => 0x19
                                                               ,"start_B"     => 0x1A
                                                               ,"start_M"     => 0x1B
                                                               
                                                               ,"RGBspeed+"   => 0x23
                                                               ,"RGBspeed-"   => 0x24
                                                               }
                                                               
                                      ,"cmd_value"          => {"Rspeed="     => 0x1C
                                                               ,"Gspeed="     => 0x1D
                                                               ,"Bspeed="     => 0x1E
                                                               ,"Mspeed="     => 0x1F
                                                               ,"RGBspeed="   => 0x22
                                                               }
                                                               
                                      ,"cmd_3value_timer"   => {# set to commands...
                                                                "RGB="        => 0x20
                                                               ,"RGB~"        => 0x21
                                                               }
                                                                
                                      ,"prg"                => {"PRGstop"     => [0x25 , 0x00]
                                                               ,"PRG1"        => [0x25 , 0x01]
                                                               ,"PRG2"        => [0x25 , 0x02]
                                                               }
 
                                      ,"box_command"        => {"ENABLE_BOX"  => 0xDD
                                                               ,"DISABLE_BOX" => 0xDE
                                                               ,"TOGGLE_BOX"  => 0xDF
                                                               }
                                      
                                      ,"box_state"          => {"enabled"     => 0x01
                                                               ,"disabled"    => 0x00
                                                               }
                                      
                                      ,"version"            => {0x00          => "rev0"
                                                               }
                                      
                                      ,"state_memory"       => {"yes"         => 0x01
                                                               ,"no"          => 0x00
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

sub powerup_value {
  my ($self , $port , $value_spec) = @_;
  
  if (!exists($self->{"legal"}->{"port"}->{$port})) {
    printf STDERR "ERROR : unknown port '%s'.\n", $port;
    Carp::confess();
  }
  else  {
    $port = $self->{"legal"}->{"port"}->{$port};

    if ($value_spec =~ m/^(\d+)$/) {
      $self->{"value"}->{"powerup_value"}->{$port} = $value_spec;
      $self->{"value"}->{"powerup_last" }->{$port} = 0x00;
    }
    elsif ($value_spec eq "last") {
      $self->{"value"}->{"powerup_value"}->{$port} = 0x00;
      $self->{"value"}->{"powerup_last" }->{$port} = 0x01 << ($port-1);
    }
    else {
      printf STDERR "ERROR : illegal powerup value specification '%s'.\n", $value_spec;
      Carp::confess();
    }
  }
  
  return $self;
}

#=======================================================================================================================

sub dimming_time {
  my ($self , $port , $time_spec) = @_;
  
  if (!exists($self->{"legal"}->{"port"}->{$port})) {
    printf STDERR "ERROR : unknown port '%s'.\n", $port;
    Carp::confess();
  }
  elsif ($time_spec !~ m/^(\d+)$/) {
    printf STDERR "ERROR : illegal time specification '%s'.\n", $time_spec;
    Carp::confess();
  }
  else {
    $port = $self->{"legal"}->{"port"}->{$port};
    
    $self->{"value"}->{"dimming_time"}->{$port} = $time_spec;
  }
  
  return $self;
}

#=======================================================================================================================

sub min_value {
  my ($self , $port , $value_spec) = @_;
  
  if (!exists($self->{"legal"}->{"port"}->{$port})) {
    printf STDERR "ERROR : unknown port '%s'.\n", $port;
    Carp::confess();
  }
  elsif ($value_spec !~ m/^(\d+)$/) {
    printf STDERR "ERROR : illegal min-value specification '%s'.\n", $value_spec;
    Carp::confess();
  }
  else {
    $port = $self->{"legal"}->{"port"}->{$port};
    
    $self->{"value"}->{"min_value"}->{$port} = $value_spec;
  }
  
  return $self;
}

#=======================================================================================================================

sub max_value {
  my ($self , $port , $value_spec) = @_;
  
  if (!exists($self->{"legal"}->{"port"}->{$port})) {
    printf STDERR "ERROR : unknown port '%s'.\n", $port;
    Carp::confess();
  }
  elsif ($value_spec !~ m/^(\d+)$/) {
    printf STDERR "ERROR : illegal max-value specification '%s'.\n", $value_spec;
    Carp::confess();
  }
  else {
    $port = $self->{"legal"}->{"port"}->{$port};
    
    $self->{"value"}->{"max_value"}->{$port} = $value_spec;
  }
  
  return $self;
}

#=======================================================================================================================

sub state_memory {
  my ($self , $port , $state_spec) = @_;
  
  if (!exists($self->{"legal"}->{"port"}->{$port})) {
    printf STDERR "ERROR : unknown port '%s'.\n", $port;
    Carp::confess();
  }
  elsif (!exists($self->{"legal"}->{"state_memory"}->{$state_spec})) {
    printf STDERR "ERROR : illegal state-memory specification '%s'.\n", $state_spec;
    Carp::confess();
  }
  else {
    $port = $self->{"legal"}->{"port"}->{$port};
    
    $self->{"value"}->{"state_memory"}->{$port} = $self->{"legal"}->{"state_memory"}->{$state_spec} << ($port-1);
  }
  
  return $self;
}

#=======================================================================================================================

sub message {
  my ($self , $name , $event_spec , $opt) = @_;
  
  if (exists(    $self->{"legal"}->{"relay_event"}->{$event_spec})) {
    if (exists(  $self->{"legal"}->{"port"       }->{$opt       })) {

      # format relay frame and register centrally that other can refer to it...
      my @message = (0x30,0x80
                    ,$self->{"value"}->{"node_number"}
                    ,$self->{"value"}->{"node_group"}
                    ,0xFF
                    ,0xFF
                    ,0x04                  # master
                    ,undef
                    ,$self->{"legal"}->{"relay_event"}->{$event_spec}
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
  # tbd...
  
  return $self;
}

#=======================================================================================================================

sub box {
  my ($self 
     ,$state        # enabled/disabled
     ,$command      # one of many
     ,@opt
     ) = @_;
     
  my $box_group;
  my $trigger;
  my $group_list;

  my $box_state;
  my $INSTR1 = 0x00;
  my $INSTR2 = 0x00;
  my $INSTR3 = 0x00;
  my $INSTR4 = 0x00;
  my $INSTR5 = 0x00;
  my $INSTR6 = 0x00;
  my $INSTR7 = 0x00;
  my $INSTR8 = 0x00;

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

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
  
  my @value;
  
  if ($command =~ m/^(.+?)(\=|\~|\+\=|\-\=)(.+)$/) {
    $command = $1.$2;
    @value   = split(/\s,\s/ , $3);
  }
  
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  if (exists( $self->{"legal"}->{"cmd_value_timer"}->{$command})) {
    $INSTR1 = $self->{"legal"}->{"cmd_value_timer"}->{$command};
    $INSTR2 = $value[0];
    $INSTR3 = $timer;

    ($trigger , $group_list) = @opt;
  }
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  elsif (exists($self->{"legal"}->{"cmd_timer"}->{$command})) {
    $INSTR1 =   $self->{"legal"}->{"cmd_timer"}->{$command};
    $INSTR3 = $timer; 

    ($trigger , $group_list) = @opt;
  }
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  elsif (exists($self->{"legal"}->{"cmd_plain"}->{$command})) {
    $INSTR1 =   $self->{"legal"}->{"cmd_plain"}->{$command};

    ($trigger , $group_list) = @opt;
  }
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  elsif (exists($self->{"legal"}->{"cmd_value"}->{$command})) {
    $INSTR1 =   $self->{"legal"}->{"cmd_value"}->{$command};
    $INSTR2 = $value[0];

    ($trigger , $group_list) = @opt;
  }
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  elsif (exists($self->{"legal"}->{"cmd_3value_timer"}->{$command})) {
    $INSTR1 =   $self->{"legal"}->{"cmd_3value_timer"}->{$command};
    $INSTR2 = $value[0];
    $INSTR3 = $value[1];
    $INSTR4 = $value[2];
    $INSTR5 = $timer; 

    ($trigger , $group_list) = @opt;
  }
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  elsif (exists           ($self->{"legal"}->{"prg"}->{$command})) {
    ($INSTR1, $INSTR2) = @{$self->{"legal"}->{"prg"}->{$command}};

    ($trigger , $group_list) = @opt;
  }
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  elsif (exists($self->{"legal"}->{"box_command"}->{$command})) {
    $INSTR1 =   $self->{"legal"}->{"box_command"}->{$command};

    ($box_group , $trigger , $group_list) = @opt;

    if (!exists($self->{"value"}->{"box_group"}->{$box_group})) {
      printf STDERR "ERROR : unknown box_group '%s'.\n", $box_group;
      Carp::confess();
    }
    
    # check that group is continuous...
    my @box_group = @{$self->{"value"}->{"box_group"}->{$box_group}};
    {
      my $x = $box_group[0];
      
      foreach my $i (0..scalar(@box_group)-1) {
        if ($x+$i != $box_group[$i]) {
          printf STDERR "ERROR : box_group '%s' is not continuous (%s).\n", $box_group, join("," , @box_group);
          Carp::confess();
        }
      }
    }

    $INSTR2 = $box_group[ 0]         & 0x7F;   # BoxX...
    $INSTR3 = (scalar(@box_group)-1) & 0x7F;   # BoxY...
  }
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  else {
    printf STDERR "ERROR : illegal command '%s'.\n", $command;
    Carp::confess();
  }
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  
  # fetch trigger message...
  my @trigger = $self->{"project"}->get_message($trigger);

  # store group membership...
  if (defined($group_list)) {
    foreach my $box_group (split(/\s*,\s*/ , $group_list)) {
      my $this_box = scalar(@{$self->{"value"}->{"box"}});
      
      push(@{$self->{"value"}->{"box_group"}->{$box_group}} , $this_box);
    }
  }

  my $doc = sprintf("%s %-15s %-20s %s"
                   ,$state
                   ,$command
                   ,join(" , " , @opt)
                   ,join(" " , map {if (defined($_)) {
                                      sprintf("=%02X",$_);
                                    } 
                                    else {
                                      "x00";
                                    }
                               } 
                               @trigger
                    )
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
      if ($FWping{"ATYPE"} != 0x08) {
        $msg .= sprintf("ERROR : Node(%s,%s) is not a led controller module\n"
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
  # collect data...
  if ($msg eq "pass") {
    my @data;

    printf STDERR "INFO : writing setup info to EEPROM...\n";
    push(@data , $self->{"value"}->{"min_value"}->{1}); # R.min
    push(@data , $self->{"value"}->{"max_value"}->{1}); # R.max
    push(@data , $self->{"value"}->{"min_value"}->{2}); # R.min
    push(@data , $self->{"value"}->{"max_value"}->{2}); # R.max
    push(@data , $self->{"value"}->{"min_value"}->{3}); # R.min
    push(@data , $self->{"value"}->{"max_value"}->{3}); # R.max
    push(@data , $self->{"value"}->{"min_value"}->{4}); # R.min
    push(@data , $self->{"value"}->{"max_value"}->{4}); # R.max

    push(@data , $self->{"value"}->{"powerup_value"}->{1}); # R - channel 1 set power up state
    push(@data , 0x00                                    ); # R - channel 1 last saved in eeprom state
    push(@data , $self->{"value"}->{"powerup_value"}->{2}); # G - channel 2 set power up state
    push(@data , 0x00                                    ); # G - channel 2 last saved in eeprom state
    push(@data , $self->{"value"}->{"powerup_value"}->{3}); # B - channel 3 set power up state
    push(@data , 0x00                                    ); # B - channel 3 last saved in eeprom state
    push(@data , $self->{"value"}->{"powerup_value"}->{4}); # M - channel 4 set power up state
    push(@data , 0x00                                    ); # M - channel 4 last saved in eeprom state

    # Bits<4:7> - state memory    (channel 1 - channel 4); possible values: 
    #  * '1' - channel value sets to previous state when turning channel on
    #  * '0' - no memory of last state; (works with START & TOGGLE instructions)
    # Bits<0:3> - power up source (channel 1 - channel 4), possible values: 
    #  * '1' - power up from last saved
    #  * '0' - from set power up values
    my $state_memory_byte = 0;
    my $powerup_src_byte  = 0;
    
    map {$state_memory_byte |= $self->{"value"}->{"state_memory"}->{$_}} @ports;
    map {$powerup_src_byte  |= $self->{"value"}->{"powerup_last"}->{$_}} @ports;

    push(@data , $state_memory_byte<<4
                 |
                 $powerup_src_byte <<0); 

    push(@data , $self->{"value"}->{"dimming_time"}->{1}); # R.dimming time
    push(@data , $self->{"value"}->{"dimming_time"}->{2}); # R.dimming time
    push(@data , $self->{"value"}->{"dimming_time"}->{3}); # G.dimming time
    push(@data , $self->{"value"}->{"dimming_time"}->{4}); # M.dimming time
                        
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
    printf "INFO : node %s,%s (led_rgb) flashed\n",$number , $group;
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

  if ($number == $self->{"value"}->{"node_number"}
      &&
      $group  == $self->{"value"}->{"node_group" }) {
    # it's one of our message...
    if ($frame_type == 0x308) {$result = $self->decode_led_reg_message(@message)}
  }
    
  return $result;
}

# ======================================================================================================================

sub decode_led_reg_message {
  my ($self , @message) = @_;
  
  my %map1 = (1 => "R"
             ,2 => "G"
             ,3 => "B"
             ,4 => "M"
             );
            
  my %map2 = (0x00 => "off"
             ,0xFF => "on"
             );
            
            
  my $channel    = $message[7];
  my $status     = $message[8];
  my $relay      = $message[9];
  my $result;
  
  if ($channel == 4) {
    $result     = sprintf ("LEDs are %s" , $map2{$relay});
  }
  else {
    $result     = sprintf ("LED %s->%s" , $map1{$channel} , $status);
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
