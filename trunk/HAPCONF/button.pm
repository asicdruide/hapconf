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

package HAPCONF::button;

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
  elsif ($version !~ m/^[0123]$/) {
    printf STDERR "ERROR : illegal version '%s'.\n" , $version;
    Carp::confess();
  }

  my $self = {"project"            => $project
             ,"value"              => {"name"                  => $name
                                      ,"version"               => $version
                                      ,"node_number"           => undef
                                      ,"node_group"            => undef
                                      ,"node_type"             => "???"
                                                               
                                      # user defined symbolic name...
                                      ,"port_name"             => {}
                                                                  
                                      # enabled events...                            
                                      ,"event_enable"          => {}                         
                                                               
                                      # indirect control table...
                                      ,"box"                   => [] 
                                                               
                                      ,"notes"                 => []
                                                               
                                      ,"box_group"             => {}
                                      
                                      ,"thermostat_threshold"  => [0x00 , 0x00]
                                      ,"thermostat_hysteresis" => 0x00
                                      ,"temperature_offset"    => [0x00 , 0x00]
                                      }
                                      
             ,"legal"              => {# default port names...
                                       "ports"              => []
                                       
                                      ,"port"               => {}
                                                              
                                      # symbolic events...                        
                                      ,"button_event"       => {#           code   LED     bit<0>- on 
                                                                #                             <1>- 400ms 
                                                                #                             <2>- 4s 
                                                                #                             <3>- off 
                                                                #                             <4>- <400ms
                                                                #                             <5>- <4s  
                                                                #                             <6>- >4s
                                                                "v"     => [0xFF , undef     , 0x01]  # "closed"
                                                               ,"v="    => [0xFE , undef     , 0x02]  # "closed and held for 400ms"
                                                               ,"v=="   => [0xFD , undef     , 0x04]  # "closed and held for 4s"
                                                               ,"v^"    => [0xFC , undef     , 0x10]  # "closed and open within 400ms"
                                                               ,"v=^"   => [0xFB , undef     , 0x20]  # "closed and open between 400ms and 4s"
                                                               ,"v==^"  => [0xFA , undef     , 0x40]  # "closed and open after 4s"
                                                               ,"^"     => [0x00 , undef     , 0x08]  # "open"

                                                               ,"0v"    => [0xFF , 0x00      , 0x01]  # "closed"
                                                               ,"0v="   => [0xFE , 0x00      , 0x02]  # "closed and held for 400ms"
                                                               ,"0v=="  => [0xFD , 0x00      , 0x04]  # "closed and held for 4s"
                                                               ,"0v^"   => [0xFC , 0x00      , 0x10]  # "closed and open within 400ms"
                                                               ,"0v=^"  => [0xFB , 0x00      , 0x20]  # "closed and open between 400ms and 4s"
                                                               ,"0v==^" => [0xFA , 0x00      , 0x40]  # "closed and open after 4s"
                                                               ,"0^"    => [0x00 , 0x00      , 0x08]  # "open"

                                                               ,"1v"    => [0xFF , 0xFF      , 0x01]  # "closed"
                                                               ,"1v="   => [0xFE , 0xFF      , 0x02]  # "closed and held for 400ms"
                                                               ,"1v=="  => [0xFD , 0xFF      , 0x04]  # "closed and held for 4s"
                                                               ,"1v^"   => [0xFC , 0xFF      , 0x10]  # "closed and open within 400ms"
                                                               ,"1v=^"  => [0xFB , 0xFF      , 0x20]  # "closed and open between 400ms and 4s"
                                                               ,"1v==^" => [0xFA , 0xFF      , 0x40]  # "closed and open after 4s"
                                                               ,"1^"    => [0x00 , 0xFF      , 0x08]  # "open"
                                                               }
                                      
                                      ,"thermostat_event"   => {# events without LED dependency
                                                                "T^"     => 0xFF  # over temperature
                                                               ,"Tv"     => 0x00  # under temperature
                                                               }
                                      
                                      # symbolic indirect control commands...
                                      ,"led_command"        => {"led_on"              => 0x01
                                                               ,"led_off"             => 0x00
                                                               ,"led_toggle"          => 0x02
                                                               }
                                                               
                                      ,"thermostat_command" => {"set_thermostat_to"   => 0x03
                                                               ,"dec_thermostat_by"   => 0x04                        
                                                               ,"inc_thermostat_by"   => 0x05                        
                                                               }                        
                                                                                       
                                      ,"box_command"        => {"ENABLE_BOX"          => 0xDD                        
                                                               ,"DISABLE_BOX"         => 0xDE                        
                                                               ,"TOGGLE_BOX"          => 0xDF                        
                                                               }                        
                                                              
                                      ,"box_state"          => {"enabled"             => 0x01                        
                                                               ,"disabled"            => 0x00                        
                                                               }   

                                      ,"version"            => {0x00                  => "button, DIN rail"
                                                               ,0x01                  => "button, back box13"
                                                               ,0x02                  => "button, back box6touch"
                                                               ,0x03                  => "button, back box14"
                                                               }
                                      }
             };
  
  bless($self , $class);
  
  # resolve version dependencies...
  if (exists(                         $self->{"legal"}->{"version"}->{$version})) {
    $self->{"value"}->{"node_type"} = $self->{"legal"}->{"version"}->{$version};

    my @ports;
  
    if ($version eq "0") {
      # DIN rail button
      @ports = (1..8);
      $self->{"legal"}->{"thermostat_event"  } = {}; # no temperature sensor supported...
      $self->{"legal"}->{"led_command"       } = {}; # no leds...
      $self->{"legal"}->{"thermostat_command"} = {}; # no temperature sensor supported...
    }
    elsif ($version eq "1") {
      # back box button 13
      @ports = (1..13);
    }
    elsif ($version eq "2") {
      # back box button 6 touch
      @ports = (1..6);
    }
    elsif ($version eq "3") {
      # back box button 14
      @ports = (1..14);
    }

    foreach my $i (@ports) {
      $self->{"legal"}->{"port"}->{$i} = $i;
    }
    
    $self->{"legal"}->{"ports"} = [@ports];

    # register ourself...
    $project->add_node($name , $self);
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
  
  if (exists($self->{"legal"}->{"button_event"}->{$event_spec})) {
    if (exists(  $self->{"legal"}->{"port"}->{$opt})) {
      my $port = $self->{"legal"}->{"port"}->{$opt};
      
      # format button frame and register centrally that other can refer to it...
      my @message = (0x30,0x10     # universal module frame, button, 0,0,0,RE
                    ,$self->{"value"}->{"node_number"}
                    ,$self->{"value"}->{"node_group"}
                    ,0xFF
                    ,0xFF
                    ,$port
                    ,$self->{"legal"}->{"button_event"}->{$event_spec}->[0]
                    ,$self->{"legal"}->{"button_event"}->{$event_spec}->[1]   # might be undef...
                    ,0xFF
                    ,0xFF
                    ,0xFF
                    );
                    
      $self->{"value"}->{"event_enable"}->{$port}->{$event_spec} = 1;
                    
      $self->{"project"}->add_message($name , @message);
    }
    else {
      printf STDERR "ERROR : unknown port '%s'.\n", $opt;
      Carp::confess();
    }
  }
  elsif (exists($self->{"legal"}->{"thermostat_event"}->{$event_spec})) {
    # format thermostat frame and register centrally that other can refer to it...
    my @message = (0x30,0x40
                  ,$self->{"value"}->{"node_number"}
                  ,$self->{"value"}->{"node_group"}
                  ,0xFF
                  ,0xFF
                  ,0x12
                  ,$self->{"legal"}->{"thermostat_event"}->{$event_spec}
                  ,0xFF
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

sub box {
  my ($self 
     ,$state        # enabled/disabled
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
  if (exists( $self->{"legal"}->{"led_command"}->{$command})) {
    $INSTR1 = $self->{"legal"}->{"led_command"}->{$command};
    $INSTR2 = 0;
    $INSTR3 = 0;

    my @port_list;

    # translate port list into bit masks...
    foreach my $port (split(/\s*,\s*/ , $opt)) {
      if (exists($self->{"legal"}->{"port"}->{$port})) {
        my $i =  $self->{"legal"}->{"port"}->{$port};
        
        if ($i <= 8) {
          $INSTR2 |= 2**($i-1);
        }
        else {
          $INSTR3 |= 2**($i-9);
        }
        
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
  }
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  elsif (exists($self->{"legal"}->{"thermostat_command"}->{$command})) {
    $INSTR1 =   $self->{"legal"}->{"thermostat_command"}->{$command};

    if ($INSTR1 == 0x03) {
      # set thermostat
      $INSTR2 = 0; # translate opt-value into MSB
      $INSTR3 = 0; # translate opt-value into LSB
    }
    else {
      # inc/dec thermostat
      $INSTR2 = 0; # translate opt-value into step
    }
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

sub thermostat_threshold {
  my ($self , $temperature) = @_;
  
  if (!defined($temperature)) {
    printf STDERR "ERROR : undefined thermostat temperature.\n";
    Carp::confess();
  }
  
  if ($temperature < -38.8125      # -55.0 
      ||
      $temperature > 124.5625 ){   # 125.0
    printf STDERR "ERROR : illegal thermostat temperature '%s'.\n", $temperature;
    Carp::confess();
  }
  
  my $temp_int = int($temperature / 0.0625);
  my $temp_msb = ($temp_int % 0xFF00)>>8;
  my $temp_lsb = ($temp_int % 0x00FF)>>0;
  
  #printf "DEBUG : thermostat temperature:%f(%d)  MSB=0x%02X   LSB=0x%02X\n"
  #      ,$temperature
  #      ,$temp_int
  #      ,$temp_msb
  #      ,$temp_lsb
  #      ;
  
  $self->{"value"}->{"thermostat_threshold"} = [$temp_msb , $temp_lsb];
  
  
  return $self;
}

#=======================================================================================================================

sub thermostat_hysteresis {
  my ($self , $temperature) = @_;
  
  if (!defined($temperature)) {
    printf STDERR "ERROR : undefined thermostat hysteresis.\n";
    Carp::confess();
  }
  
  if ($temperature <   0*0.25
      ||
      $temperature > 255*0.25){
    printf STDERR "ERROR : illegal thermostat hysteresis '%s'.\n", $temperature;
    Carp::confess();
  }
  
  my $temp_int = int($temperature / 0.25);
  
  
  #printf "DEBUG : thermostat hysteresis:%f(%d) 0x%02X\n"
  #       ,$temperature
  #       ,$temp_int
  #       ,$temp_int
  #       ;
  
  $self->{"value"}->{"thermostat_hysteresis"} = $temp_int;
  
  return $self;
}

#=======================================================================================================================

sub temperature_offset {
  my ($self , $temperature) = @_;
  
  if (!defined($temperature)) {
    printf STDERR "ERROR : undefined offset temperature.\n";
    Carp::confess();
  }
  
  if ($temperature < -20.0
      ||
      $temperature >  20.0){
    printf STDERR "ERROR : illegal offset temperature '%s'.\n", $temperature;
    Carp::confess();
  }
  
  my $temp_int = int($temperature / 0.0625);
  my $temp_msb = ($temp_int % 0xFF00)>>8;
  my $temp_lsb = ($temp_int % 0x00FF)>>0;
  
  
  #printf "DEBUG : offset temperature:%f(%d)  MSB=0x%02X   LSB=0x%02X\n"
  #       ,$temperature
  #       ,$temp_int
  #       ,$temp_msb
  #       ,$temp_lsb
  #       ;
  
  $self->{"value"}->{"temperature_offset"} = [$temp_msb , $temp_lsb];
  
  
  return $self;
}

# ======================================================================================================================

sub flash {
  my ($self , $cmd) = @_;
  
  my $project          =               $self->{"project"};
  my $number           =               $self->{"value"  }->{"node_number"          };
  my $group            =               $self->{"value"  }->{"node_group"           };
  my $version          =               $self->{"value"  }->{"version"              };
  my @box              =             @{$self->{"value"  }->{"box"                  }};
  my $name             =               $self->{"value"  }->{"name"                 };
  my @ports            =             @{$self->{"legal"  }->{"ports"                }};
  my @port_name        =          map {$self->{"value"  }->{"port_name"            }->{$_}} @ports;
  my $notes            = join("\n" , @{$self->{"value"  }->{"notes"                }});
  my @therm_threshold  =             @{$self->{"value"  }->{"thermostat_threshold" }};
  my $therm_hysteresis =               $self->{"value"  }->{"thermostat_hysteresis"};
  my @temp_offset      =             @{$self->{"value"  }->{"temperature_offset"   }};
  
  my $msg = "";
  
  ######################################################################################################################
  # check that we are what we expect to be...
  { 
    my %FWping = HAPCONF::util::FWping($project ,$number , $group);
    
    if ($FWping{"msg"} eq "pass") {
      if ($FWping{"ATYPE"} != 0x01) {
        $msg .= sprintf("ERROR : Node(%s,%s) is not a button module\n"
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

    printf STDERR "INFO : writing event enables to EEPROM...\n";
    
    foreach my $i (@ports) {
      my $event_enable = 0;
      
      if (exists(                      $self->{"value"}->{"event_enable"}->{$i})) {
        foreach my $event_spec (keys %{$self->{"value"}->{"event_enable"}->{$i}}) {
          $event_enable |=             $self->{"legal"}->{"button_event"}->{$event_spec}->[2];
        }
      }
      
      push(@data , $event_enable);
    }
      
    if ($version > 0) {
      # back box button modules have a temperature sensor...
      push(@data , $therm_threshold[0]); # ThermMSB
      push(@data , $therm_threshold[1]); # ThermLSB
      push(@data , $therm_threshold[0]); # ThermMSB last saved
      push(@data , $therm_threshold[1]); # ThermLSB last saved
      push(@data , $therm_hysteresis  ); # Hysteresis
      push(@data , $temp_offset    [0]); # OffsetMSB
      push(@data , $temp_offset    [1]); # OffsetLSB
    }

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

  if ($number == $self->{"value"}->{"node_number"}
      &&
      $group  == $self->{"value"}->{"node_group" }) {
    # it's one of our messages...
    if    ($frame_type == 0x301) {$result = $self->decode_button_message     (@message)}
    elsif ($frame_type == 0x304) {$result = $self->decode_temperature_message(@message)}
  }
    
  return $result;
}

# ======================================================================================================================

sub decode_button_message {
  my ($self , @message) = @_;

  my %map;

  foreach my $event_spec (keys       %{$self->{"legal"}->{"button_event"}}) {
    my ($event_code , $led_status) = @{$self->{"legal"}->{"button_event"}->{$event_spec}};

    if (defined($led_status)) {
      $map{$led_status*256 + $event_code} = $event_spec;
    }
  }

  my $channel    = $message[7];
  my $button     = $message[8];
  my $led        = $message[9];
  my $event_code = $led*256 + $button;
  my $event      = exists($map{$event_code}) ? $map{$event_code} : "??";

  my $result     = sprintf ("Button B%d %s" , $channel , $event);

  return $result;
}

# ======================================================================================================================

sub decode_temperature_message {
  my ($self, @message) = @_;
  
  my $temperature = (unpack "s" ,  pack "s", $message[ 8]<<8 + $message[ 9]) * 0.0625;
  my $threshold   = (unpack "s" ,  pack "s", $message[10]<<8 + $message[11]) * 0.0625;
  my $hysteresis  =                          $message[12]                    * 0.25;


  my $result = sprintf("Temperature:%8.3f  Threshold:%8.3f  Hysteresis:%5.2f"
                      ,$temperature
                      ,$threshold
                      ,$hysteresis
                      );
  
  return $result;
}

#=======================================================================================================================

1;
