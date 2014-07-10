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

package HAPCONF::util;

#=======================================================================================================================

sub check_name {
  my ($name , $msg) = @_;

  if (!defined($name)) {
    printf STDERR "ERROR : %s is not defined.\n", $msg;
    Carp::confess();
  }

  $name =~ s/^\s+//;
  $name =~ s/\s+$//;
  $name =~ s/\s*\.\s*$/./g;

  if ($name eq "") {
    printf STDERR "ERROR : %s is empty.\n", $msg;
    Carp::confess();
  }

  return $name;
}

#=======================================================================================================================

sub check_number {
  my ($number , $msg) = @_;

  if (!defined($number)) {
    printf STDERR "ERROR : undefined %s not allowed.\n", $msg;
    Carp::confess();
  }

  $number =~ s/\s//g;

  if ($number !~ m/\d+/) {
    printf STDERR "ERROR : illegal value '%s' for %s.\n", $number , $msg;
    Carp::confess();
  }

  return $number;
}

#=======================================================================================================================

sub check_description {
  my ($string) = @_;

  if (!defined($string)) {
    printf STDERR "ERROR : description is undefined.\n";
    Carp::confess();
  }

  $string =~ s/^\s+//;
  $string =~ s/\s+$//;

  if (length($string) > 32) {
    printf STDERR "ERROR : description '%s' is too long (%s > 32).\n", $string , length($string);
    Carp::confess();
  }

  return $string;
}

#=======================================================================================================================

sub check_string{
  my ($string , $regexp) = @_;

  if (!defined($string)) {
    printf STDERR "ERROR : direction is undefined.\n";
    Carp::confess();
  }

  $string =~ s/^\s+//;
  $string =~ s/\s+$//;

  if ($string !~ $regexp) {
    printf STDERR "ERROR : description '%s' is illegal (not matching %s).\n", $string, $regexp;
    Carp::confess();
  }

  return $string;
}

#=======================================================================================================================

sub check_url {
  my ($string) = @_;

  if (!defined($string)) {
    printf STDERR "ERROR : url is undefined.\n";
    Carp::confess();
  }

  $string =~ s/\s//g;

  if ($string !~ m/^\d+\.\d+\.\d+\.\d+:\d+$/) {
    printf STDERR "ERROR : url '%s' is illegal.\n", $string;
    Carp::confess();
  }

  return $string;
}

# ======================================================================================================================

sub Tx {
  my ($project , $msg , @tx_byte) = @_;

  _Tx($project , $msg , 0 , @tx_byte);

  return undef;
}

# ======================================================================================================================

sub Tx_raw {
  my ($project , $msg , @tx_byte) = @_;

  _Tx($project , $msg , 1 , @tx_byte);

  return undef;
}

# ======================================================================================================================

sub _Tx {
  my ($project , $msg , $raw_mode , @tx_byte) = @_;

  my $log = "\nTx :";


  if ($raw_mode==0) {
    my $chksum = 0;

    map {$chksum += $tx_byte[$_]} (0..scalar(@tx_byte)-1);

    unshift(@tx_byte , 0xAA);            # start
    push   (@tx_byte , $chksum & 0xFF);  # CHKSUM
    push   (@tx_byte , 0xA5);            # stop
  }


  my $tx = "";

  foreach my $tx_byte (@tx_byte) {
    $tx .= chr($tx_byte);
    $log .= sprintf(" %02X" , $tx_byte);
  }
  $log .= " ".$msg."\n";

  $project->{"socket"}->write($tx);

  if ($project->{"log"}->{"TxCAN"} == 1) {
    print $log;
  }

  return undef;
}

# ======================================================================================================================

sub RxLog {
  my ($project , $rx) = @_;

  my $result = "Rx :";
  my @rx_byte = map {ord(substr($rx , $_ , 1))} (0..14);

  foreach my $i (0..14) {
    $result .= sprintf(" %02X" , $rx_byte[$i]);
  }

  $result .= $project->decode_message(@rx_byte);

  return $result;
}

# ======================================================================================================================

sub RxFlush {
  my ($project , $timeout) = @_;
  my @can_read;
  my $rx;
  my $socket = $project->{"socket"};
  my $select = $project->{"select"};

  @can_read = $select->can_read($timeout);

  while (scalar(@can_read) > 0) {
    $socket->read($rx , 15);
    printf "%s\n", RxLog($project , $rx);
    @can_read = $select->can_read($timeout);
  }
}

# ======================================================================================================================

sub Rx {
  my ($project , $timeout , @exp_byte) = @_;

  unshift(@exp_byte , 0xAA);             # start
  push   (@exp_byte , undef);            # CHKSUM
  push   (@exp_byte , 0xA5);             # stop

  my $socket = $project->{"socket"};
  my $select = $project->{"select"};
  my $result = "";
  my @rx_byte;

  do {
    my @can_read = $select->can_read($timeout);
    my $rx;

    if (scalar(@can_read)==0) {
      $result = "timeout";
    }
    else {
      $socket->read($rx , 15);

      @rx_byte = map {ord(substr($rx , $_ , 1))} (0..14);

      $result = "pass";
      my $log = "Rx :";

      $result = "pass";


      foreach my $i (0..14) {
        $log .= sprintf(" %02X" , $rx_byte[$i]);

        if (defined($exp_byte[$i])
            &&
            $exp_byte[$i] != $rx_byte[$i]) {
          # fail...
          $result = "FAIL";
        }
      }

      if ($project->{"log"}->{"RxCAN"} == 1) {
        printf "%s %s\n",$log , $project->decode_message(@rx_byte);
      }
    }
  } until ($result eq "pass" || $result eq "timeout");

  return ($result , @rx_byte);
}

#=======================================================================================================================

sub box_enable_data {
  my (@box) = @_;
  my @data;
  my $mask;

  foreach my $i (0..127) {
    if ($i % 8 == 0) {
      $mask = 0;
    }

    my $box_state;

    if ($i < scalar(@box)) {
      $box_state = $box[$i]->[0];
    }
    else {
      $box_state = "";
    }

    if ($box_state eq "enabled") {
      $mask |= 2**($i % 8);
    }

    if ($i % 8 == 7) {
      push(@data , $mask);
    }
  }

  return @data;
}

#=======================================================================================================================

sub box_data {
  my (@box) = @_;
  my @data;

  foreach my $i (0..scalar(@box)-1) {
    my $box     =   $box[$i];
    my @INSTR   = @{$box->[1]};
    my @TRIGGER = @{$box->[2]};

    my @FIL;
    my @OPER;

    foreach my $byte (@TRIGGER) {
      if (defined($byte)) {
        push(@FIL  , $byte);
        push(@OPER , 0x01 );   # equal (non-equal not supported, yet)...
      }
      else {
        push(@FIL  , 0x00);
        push(@OPER , 0x00);   # don't care ...
      }
    }

    # 32 byte for each box...
    push(@data , @FIL  [0..11]);
    push(@data , @OPER [0..11]);
    push(@data , @INSTR[0.. 7]);
  }

  return @data;
}

#=======================================================================================================================

sub port_name_data {
  my (@name) = @_;
  my @data;

  foreach my $i (0..scalar(@name)-1) {
    my $name = $name[$i];

    if (!defined($name)) {
      $name = $i;
    }

    # 32 byte for each port...
    foreach my $j (0..31) {
      if ($j < length($name)) {
        push(@data , ord(substr($name , $j , 1)));
      }
      else {
        push(@data , 0x00);
      }
    }
  }

  return @data;
}

#=======================================================================================================================

sub notes_data {
  my ($notes) = @_;
  my @data;

  # 1024 bytes for notes...
  foreach my $i (0..1023) {
    if ($i < length($notes)) {
      push(@data , ord(substr($notes , $i , 1)));
    }
    else {
      push(@data , 0x00);
      last;
    }
  }

  return @data;
}

#=======================================================================================================================

sub module_name_data {
  my ($name) = @_;
  my @data;

  # 16 bytes for notes...
  foreach my $i (0..15) {
    if ($i < length($name)) {
      push(@data , ord(substr($name , $i , 1)));
    }
    else {
      push(@data , 0x00);
      last;
    }
  }

  return @data;
}

#=======================================================================================================================

sub HWping {
  my ($project , $number , $group , $timeout) = @_;

  if (!defined($timeout)) {
    $timeout = 1;
  }

  Tx($project
    ,"HWping"
    ,0x10    , 0x40    # hw type request
    ,0x00    , 0x00    # sender (might not know, yet)
    ,0x00    , 0x00    # don't care
    ,$number , $group  # receiver
    ,0x00    , 0x00    # don't care
    ,0x00    , 0x00    # don't care
  );

  my ($msg , @byte) = Rx($project
                        ,$timeout          # timeout 1sec
                        ,0x10    , 0x41    # hw type response
                        ,$number , $group  # responder
                        ,undef   , undef   # HARD1, HARD2
                        ,undef   , 0xFF    # HVER , don't care
                        ,undef   , undef   # ID0, ID1
                        ,undef   , undef   # ID2, ID2
                        );

  my %result;

  if ($msg eq "pass") {
    %result = decode_hardware_type_message(@byte);

    $result{"msg"} = $msg;
  }
  elsif ($msg eq "timeout") {
    $result{"msg"  } = "ERROR : no HWping response during timeout";
  }

  return %result;
}

#=======================================================================================================================

sub FWping {
  my ($project , $number , $group , $timeout) = @_;

  if (!defined($timeout)) {
    $timeout = 1;
  }

  Tx($project
    ,"FWping"
    ,0x10    , 0x60    # hw type request
    ,0x00    , 0x00    # sender (might not know, yet)
    ,0x00    , 0x00    # don't care
    ,$number , $group  # receiver
    ,0x00    , 0x00    # don't care
    ,0x00    , 0x00    # don't care
  );

  my ($msg , @byte) = Rx($project
                        ,$timeout          # timeout
                        ,0x10    , 0x61    # hw type response
                        ,$number , $group  # responder
                        ,undef   , undef   # HARD1, HARD2
                        ,undef   , undef   # HVER , ATYPE
                        ,undef   , undef   # AVERS , FVERS
                        ,undef   , undef   # BVER1 , BVER2
                        );

  my %result;

  if ($msg eq "pass") {
    %result = decode_firmware_type_message(@byte);

    $result{"msg"} = $msg;
  }
  elsif ($msg eq "timeout") {
    $result{"msg"  } = "ERROR : no FWping response during timeout";
  }

  return %result;
}

#=======================================================================================================================

sub one_node_enter_programming_mode {
  my ($project , $number , $group) = @_;

  Tx($project
    ,"one node enter programming mode"
    ,0x10    , 0x00           # frame type
    ,0x00    , 0x00           # sender
    ,0x00    , 0x00           # don't care
    ,$number , $group         # receiver
    ,0x00    , 0x00           # don't care
    ,0x00    , 0x00           # don't care
  );

  my ($msg , @byte) = Rx($project
                        ,10                # timeout 1sec
                        ,0x10    , 0x01    # frame type
                        ,$number , $group  # sender
                        ,0xFF    , 0xFF    # don't care
                        ,undef   , undef   # boot loader version
                        ,0xFF    , 0xFF    # don't care
                        ,0xFF    , 0xFF    # don't care
                        );

  if ($msg ne "pass") {
    $msg = "ERROR : no or incorrect response when entering programming mode\n";
  }

  return $msg;
}

#=======================================================================================================================

sub one_node_exit_programming_mode {
  my ($project , $number , $group) = @_;

  Tx($project
    ,"one node exit programming mode"
    ,0x02    , 0x00    # one node exit programming mode
    ,$number , $group  # receiver
    ,0x00    , 0x00    # don't care
    ,0x00    , 0x00    # don't care
    ,0x00    , 0x00    # don't care
    ,0x00    , 0x00    # don't care
    );

  return undef;
}

#=======================================================================================================================

sub one_node_reboot {
  my ($project , $number , $group) = @_;

  Tx($project
    ,"one node reboot"
    ,0x10    , 0x20    # one node reboot
    ,0x00    , 0x00    # sender
    ,0x00    , 0x00    # don't care
    ,$number , $group  # receiver
    ,0x00    , 0x00    # don't care
    ,0x00    , 0x00    # don't care
    );

  return undef;
}

#=======================================================================================================================

sub one_node_supply_voltage {
  my ($project , $number , $group) = @_;

  Tx($project
    ,"one node supply voltage"
    ,0x10    , 0xC0    # one node supply voltage
    ,0x00    , 0x00    # sender
    ,0x00    , 0x00    # don't care
    ,$number , $group  # receiver
    ,0x00    , 0x00    # don't care
    ,0x00    , 0x00    # don't care
    );

  my ($msg , @byte) = Rx($project
                        ,5.0               # timeout
                        ,0x10    , 0xC1    #
                        ,$number , $group  # responder
                        ,undef   , undef   # VOLBUS1, VOLBUS2
                        ,undef   , undef   # VOLCPU1, VOLCPU2
                        ,0xFF    , 0xFF    #
                        ,0xFF    , 0xFF    #
                        );

  my %result;

  if ($msg eq "pass") {
    %result = decode_supply_voltage_message(@byte);

    $result{"msg"} = $msg;
  }
  elsif ($msg eq "timeout") {
    $result{"msg"  } = "ERROR : no node supply voltage response during timeout";
  }

  return %result;
}

#=======================================================================================================================

sub one_node_status {
  my ($project , $number , $group) = @_;

  Tx($project
    ,"one node status request"
    ,0x10    , 0x90    # one node status request
    ,0x00    , 0x00    # sender
    ,0x00    , 0x00    # don't care
    ,$number , $group  # receiver
    ,0x00    , 0x00    # don't care
    ,0x00    , 0x00    # don't care
    );

  RxFlush($project , 3);

  return ();
}

#=======================================================================================================================

sub one_node_health_check {
  my ($project , $number , $group) = @_;

  Tx($project
    ,"one node health check request(1)"
    ,0x11    , 0x50    # one node exit programming mode
    ,0x00    , 0x00    # sender
    ,0x01    , 0x00    # status request, don't care
    ,$number , $group  # receiver
    ,0x00    , 0x00    # don't care
    ,0x00    , 0x00    # don't care
    );

  sleep(1);

  # don't know why i've to request twice. According to docu i'd guess that once is enough, but did not work.
  Tx($project
    ,"one node health check request(2)"
    ,0x11    , 0x50    # one node exit programming mode
    ,0x00    , 0x00    # sender
    ,0x01    , 0x00    # status request, don't care
    ,$number , $group  # receiver
    ,0x00    , 0x00    # don't care
    ,0x00    , 0x00    # don't care
    );

  my ($msg1 , @tmp1) = Rx($project
                         ,20                # timeout
                         ,0x11    , 0x51    #
                         ,$number , $group  # responder
                         ,undef   , undef   # frame1     , RXCNT
                         ,undef   , undef   # TXCNT      , RXCNTMX
                         ,undef   , undef   # TXCNTMX    , CANINTCNT
                         ,undef   , undef   # RXERRCNT   , TXERRCNT
                         );

  my ($msg2 , @tmp2) = Rx($project
                         ,20                # timeout
                         ,0x11    , 0x51    #
                         ,$number , $group  # responder
                         ,undef   , undef   # frame2     , don't care
                         ,undef   , undef   # don't care , RXCNTMXE
                         ,undef   , undef   # TXCNTMXE   , CANINTCNTE
                         ,undef   , undef   # RXERRCNTE  , TXERRCNTE
                         );

  my %result;

  if ($msg1 eq "pass" && $msg2 eq "pass") {

    %result = decode_health_check_message(@tmp1);

    my %result2 = decode_health_check_message(@tmp2);

    $result{"msg"} = "pass";

    foreach my $key (keys %result2) {
      $result{$key} = $result2{$key};
    }
  }
  elsif ($msg1 eq "timeout" || $msg2 eq "timeout") {
    $result{"msg"} = "ERROR : no node health check response during timeout";
  }

  return %result;
}

#=======================================================================================================================

sub one_node_device_id {
  my ($project , $number , $group) = @_;

  Tx($project
    ,"one node device id"
    ,0x11    , 0x10    # one node device id
    ,0x00    , 0x00    # sender
    ,0x00    , 0x00    # don't care
    ,$number , $group  # receiver
    ,0x00    , 0x00    # don't care
    ,0x00    , 0x00    # don't care
    );

  my ($msg , @byte) = Rx($project
                        ,1.0               # timeout
                        ,0x11    , 0x11    #
                        ,$number , $group  # responder
                        ,undef   , undef   # DEVID1, DEVID2
                        ,0xFF    , 0xFF    #
                        ,0xFF    , 0xFF    #
                        ,0xFF    , 0xFF    #
                        );

  my %result;

  if ($msg eq "pass") {
    %result = decode_device_id_message(@byte);

    $result{"msg"} = $msg;
  }
  elsif ($msg eq "timeout") {
    $result{"msg"  } = "ERROR : no node device id response during timeout";
  }

  return %result;
}

#=======================================================================================================================

sub one_node_uptime {
  my ($project , $number , $group) = @_;

  Tx($project
    ,"one node uptime"
    ,0x11    , 0x30    # one node uptime
    ,0x00    , 0x00    # sender
    ,0x00    , 0x00    # don't care
    ,$number , $group  # receiver
    ,0x00    , 0x00    # don't care
    ,0x00    , 0x00    # don't care
    );

  my ($msg , @byte) = Rx($project
                        ,1.0               # timeout
                        ,0x11    , 0x31    #
                        ,$number , $group  # responder
                        ,0xFF    , 0xFF    #
                        ,0xFF    , 0xFF    #
                        ,undef   , undef   # UPTIME3, UPTIME2
                        ,undef   , undef   # UPTIME1, UPTIME0
                        );

  my %result;

  if ($msg eq "pass") {
    %result = decode_uptime_message(@byte);

    $result{"msg"} = $msg;
  }
  elsif ($msg eq "timeout") {
    $result{"msg"} = "ERROR : no node uptime response during timeout";
  }

  return %result;
}

# ======================================================================================================================
# ======================================================================================================================

sub decode_device_id_message {
  my (@message) = @_;

  my %result;

  $result{"dev_id1"} = $message[5];
  $result{"dev_id2"} = $message[6];
  $result{"dev_id" } = $message[5]<<8 | $message[6];

  $result{"nice"   } = sprintf ("Device ID 0x%04X" , $result{"dev_id"});

  return %result;
}

# ======================================================================================================================

sub decode_uptime_message {
  my (@message) = @_;

  my %result;

  $result{"uptime3"} = $message[ 9];
  $result{"uptime2"} = $message[10];
  $result{"uptime1"} = $message[11];
  $result{"uptime0"} = $message[12];

  my $seconds =  $message[ 9]*256**3
                +$message[10]*256**2
                +$message[11]*256**1
                +$message[12]*256**0;

  $result{"uptime" } = $seconds;

  my $days     = int($seconds / (24*60*60));
  $seconds    -=     $days    * (24*60*60);

  my $hours    = int($seconds / (   60*60));
  $seconds    -=     $hours   * (   60*60);

  my $minutes  = int($seconds / (      60));
  $seconds    -=     $minutes * (      60);

  $result{"nice"} = sprintf("Uptime %d days %d hours %d minutes %d seconds"
                           ,$days
                           ,$hours
                           ,$minutes
                           ,$seconds
                           );

  return %result;
}

# ======================================================================================================================

sub decode_supply_voltage_message {
  my (@message) = @_;

  my %result;

  $result{"bus_voltage"} = ($message[5]*256+ $message[6])*30.5/65472;
  $result{"cpu_voltage"} = ($message[7]*256+ $message[8])* 5.0/65472;

  $result{"nice"       } = sprintf ("Supply Voltage bus:%5.2f   cpu:%5.2f"
                                   ,$result{"bus_voltage"}
                                   ,$result{"cpu_voltage"}
                                   );

  return %result;
}

# ======================================================================================================================

sub decode_hardware_type_message {
  my (@message) = @_;

  my %result;

  $result{"HARD"} = $message[5]<<8  | $message[6];
  $result{"HVER"} = $message[7];
  $result{"ID"  } = $message[9]<<24 | $message[10]<<16 | $message[11]<<8 | $message[12];

  return %result;
}

# ======================================================================================================================

sub decode_firmware_type_message {
  my (@message) = @_;

  my %result;

  $result{"HARD" } = $message[ 5]<<8 | $message[6];
  $result{"HVER" } = $message[ 7];
  $result{"ATYPE"} = $message[ 8];
  $result{"AVERS"} = $message[ 9];
  $result{"FVERS"} = $message[10];
  $result{"BVER" } = $message[11]<<8 | $message[12];

  return %result;
}

# ======================================================================================================================

sub decode_health_check_message {
  my (@message) = @_;

  my %result;

  if ($message[5] == 0x01) {
    $result{"RXCNT"    } = $message[ 6];
    $result{"TXCNT"    } = $message[ 7];
    $result{"RXCNTMX"  } = $message[ 8];
    $result{"TXCNTMX"  } = $message[ 9];
    $result{"CANINTCNT"} = $message[10];
    $result{"RXERRCNT" } = $message[11];
    $result{"TXERRCNT" } = $message[12];

    $result{"nice"     } = sprintf("RXCNT:%2d RXCNTMX:%2d TXCNT:%2d TXCNTMX:%2d CANINTCNT:%2d RXERRCNT:%2d TXERRCNT:%2d"
                                  ,$result{"RXCNT"    }
                                  ,$result{"RXCNTMX"  }
                                  ,$result{"TXCNT"    }
                                  ,$result{"TXCNTMX"  }
                                  ,$result{"CANINTCNT"}
                                  ,$result{"RXERRCNT" }
                                  ,$result{"TXERRCNT" }
                                  );
  }
  elsif ($message[5] == 0x02) {
    $result{"RXCNTMXE"  } = $message[ 8];
    $result{"TXCNTMXE"  } = $message[ 9];
    $result{"CANINTCNTE"} = $message[10];
    $result{"RXERRCNTE" } = $message[11];
    $result{"TXERRCNTE" } = $message[12];

    $result{"nice"      } = sprintf("RXCNTMXE:%2d TXCNTMXE:%2d CANINTCNTE:%2d RXERRCNTE:%2d TXERRCNTE:%2d "
                                   ,$result{"RXCNTMXE"  }
                                   ,$result{"TXCNTMXE"  }
                                   ,$result{"CANINTCNTE"}
                                   ,$result{"RXERRCNTE" }
                                   ,$result{"TXERRCNTE" }
                                   );
  }

  return %result;
}

#=======================================================================================================================
#=======================================================================================================================
#=======================================================================================================================
#=======================================================================================================================

sub EEPROM_write {
  my ($project , $number , $group , $base_address , @data) = @_;

  # pad data to fill a whole EEPROM-write...
  while ((scalar(@data) % 8) != 0) {
    push(@data , 0x00);
  }

  if ($base_address < 0xF00000) {
    return sprintf("ERROR : illegal EEPROM start address 0x%06X\n",$base_address);
  }

  if ($base_address+scalar(@data)-1 > 0xF003FF) {
    return sprintf("ERROR : illegal EEPROM address 0x%06X\n",$base_address);
  }

  if ($base_address & 0x07 != 0x00) {
    return sprintf("ERROR : illegal EEPROM address 0x%06X\n",$base_address);
  }

  my $data_ok = 1;

  foreach my $data (@data) {
    if (!defined($data)
        ||
        $data > 255
        ||
        $data < 0
       ) {
      $data_ok = 0;
    }
  }

  if ($data_ok == 0) {
    return "ERROR : illegal EEPROM data\n";
  }


  # write data...
  foreach my $row (0..(scalar(@data)/8)-1) {
    my $offset  = $row*8;
    my $address = $base_address + $offset;

    my $ADRU = ($address & 0xFF0000) >> 16;
    my $ADRH = ($address & 0x00FF00) >>  8;
    my $ADRL = ($address & 0x0000FF) >>  0;

    Tx($project
      ,sprintf("set eeprom address to 0x%06X" , $address)
      ,0x03    , 0x00           # frame type
      ,$number , $group         # receiver
      ,$ADRU   , $ADRH , $ADRL  # address
      ,0x00    , 0x00           # don't care
      ,0x02                     # cmd:0x02=write
      ,0x00    , 0x00           # don't care
    );

    my ($Amsg) = Rx($project
                   ,10                       # timeout 10sec
                   ,0x03 , 0x01              # frame type
                   ,$number , $group         # responder
                   ,$ADRU   , $ADRH , $ADRL  # address
                   ,0x00 , 0x00              # don't care
                   ,0x02                     # 0x02=write
                   ,0x00 , 0x00              # don't care
                   );

    if ($Amsg ne "pass") {
      return sprintf("ERROR : no or incorrect response after setting eeprom address 0x%06X\n", $address);
    }

    Tx($project
      ,"write eeprom data"
      ,0x04 , 0x00              # frame type
      ,$number , $group         # receiver
      ,$data[$offset+0]         # A+0
      ,$data[$offset+1]         # A+1
      ,$data[$offset+2]         # A+2
      ,$data[$offset+3]         # A+3
      ,$data[$offset+4]         # A+4
      ,$data[$offset+5]         # A+5
      ,$data[$offset+6]         # A+6
      ,$data[$offset+7]         # A+7
    );

    my ($Dmsg) = Rx($project
                   ,10                       # timeout 10sec
                   ,0x04 , 0x01              # frame type
                   ,$number , $group         # responder
                   ,$data[$offset+0]         # A+0
                   ,$data[$offset+1]         # A+1
                   ,$data[$offset+2]         # A+2
                   ,$data[$offset+3]         # A+3
                   ,$data[$offset+4]         # A+4
                   ,$data[$offset+5]         # A+5
                   ,$data[$offset+6]         # A+6
                   ,$data[$offset+7]         # A+7
                   );

    if ($Dmsg ne "pass") {
      return sprintf("ERROR : no or incorrect response after writing eeprom data\n");
    }
  }

  return "pass";
}

#=======================================================================================================================

sub Flash_erase {
  my ($project , $number , $group , $base_address , @data) = @_;

  # pad data to fill a whole flash-erase-block...
  while ((scalar(@data) % 64) != 0) {
    push(@data , 0x00);
  }

  if ($base_address < 0x008000) {
    return sprintf("ERROR : illegal Flash start address 0x%06X\n",$base_address);
  }

  if ($base_address+scalar(@data)-1 > 0x008FFF) {
    return sprintf("ERROR : illegal Flash address 0x%06X\n",$base_address);
  }

  if ($base_address & 0x3F != 0x00) {
    return sprintf("ERROR : illegal Flash address 0x%06X\n",$base_address);
  }

  # erase flash data...
  foreach my $block (0..(scalar(@data)/64)-1) {
    my $address = $base_address + $block*64;
    my $ADRU    = ($address & 0xFF0000) >> 16;
    my $ADRH    = ($address & 0x00FF00) >>  8;
    my $ADRL    = ($address & 0x0000FF) >>  0;

    Tx($project
      ,sprintf("set flash address to 0x%06X" , $address)
      ,0x03    , 0x00           # frame type
      ,$number , $group         # receiver
      ,$ADRU   , $ADRH , $ADRL  # address
      ,0x00    , 0x00           # don't care
      ,0x03                     # cmd:0x03=erase
      ,0x00    , 0x00           # don't care
    );
    printf "a";

    my ($Amsg) = Rx($project
                   ,10                       # timeout 10sec
                   ,0x03 , 0x01              # frame type
                   ,$number , $group         # responder
                   ,$ADRU   , $ADRH , $ADRL  # address
                   ,0x00 , 0x00              # don't care
                   ,0x03                     # 0x03=erase
                   ,0x00 , 0x00              # don't care
                   );

    if ($Amsg eq "pass") {
      printf "A";
    }
    else {
      return sprintf("ERROR : no or incorrect response after setting flash address 0x%06X\n", $address);
    }

    Tx($project
      ,"erase data"
      ,0x04 , 0x00              # frame type
      ,$number , $group         # receiver
      ,0x00                     # A+0
      ,0x00                     # A+1
      ,0x00                     # A+2
      ,0x00                     # A+3
      ,0x00                     # A+4
      ,0x00                     # A+5
      ,0x00                     # A+6
      ,0x00                     # A+7
    );
    printf "e";

    my ($Dmsg) = Rx($project
                   ,10                       # timeout 1sec
                   ,0x04 , 0x01              # frame type
                   ,$number , $group         # responder
                   ,0xFF                    # A+0
                   ,0xFF                    # A+1
                   ,0xFF                    # A+2
                   ,0xFF                    # A+3
                   ,0xFF                    # A+4
                   ,0xFF                    # A+5
                   ,0xFF                    # A+6
                   ,0xFF                    # A+7
                   );

    if ($Dmsg eq "pass") {
      printf "E";
    }
    else {
      return sprintf("ERROR : no or incorrect response after erasing data\n");
    }
  }

  return "pass";
}

#=======================================================================================================================

sub Flash_write {
  my ($project , $number , $group , $base_address , @data) = @_;

  # pad data to fill a whole flash-write-block...
  while ((scalar(@data) % 64) != 0) {
    push(@data , 0xFF);
  }

  if ($base_address < 0x008000) {
    return sprintf("ERROR : illegal Flash start address 0x%06X\n",$base_address);
  }

  if ($base_address+scalar(@data)-1 > 0x008FFF) {
    return sprintf("ERROR : illegal Flash address 0x%06X\n",$base_address);
  }

  if ($base_address & 0x07 != 0x00) {
    return sprintf("ERROR : illegal Flash address 0x%06X\n",$base_address);
  }

  my $data_ok = 1;

  foreach my $data (@data) {
    if (!defined($data)
        ||
        $data > 255
        ||
        $data < 0
       ) {
      $data_ok = 0;
    }
  }

  if ($data_ok == 0) {
    return "ERROR : illegal Flash data\n";
  }

  foreach my $block (0..(scalar(@data)/64)-1) {
    foreach my $row (0..7) {
      my $offset  = $block*64 + $row*8;
      my $address = $base_address + $offset;
      my $ADRU    = ($address & 0xFF0000) >> 16;
      my $ADRH    = ($address & 0x00FF00) >>  8;
      my $ADRL    = ($address & 0x0000FF) >>  0;

      Tx($project
        ,sprintf("set flash address to 0x%06X" , $address)
        ,0x03    , 0x00           # frame type
        ,$number , $group         # receiver
        ,$ADRU   , $ADRH , $ADRL  # address
        ,0x00    , 0x00           # don't care
        ,0x02                     # cmd:0x02=write
        ,0x00    , 0x00           # don't care
      );
      printf "a";

      my ($Amsg) = Rx($project
                     ,20                       # timeout
                     ,0x03 , 0x01              # frame type
                     ,$number , $group         # responder
                     ,$ADRU   , $ADRH , $ADRL  # address
                     ,0x00 , 0x00              # don't care
                     ,0x02                     # 0x02=write
                     ,0x00 , 0x00              # don't care
                     );

      if ($Amsg eq "pass") {
        printf "A";
      }
      else {
        return sprintf("\nERROR : no or incorrect response after setting flash address 0x%06X<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\n", $address);
      }

      Tx($project
        ,"write data"
        ,0x04 , 0x00              # frame type
        ,$number , $group         # receiver
        ,$data[$offset+0]         # A+0
        ,$data[$offset+1]         # A+1
        ,$data[$offset+2]         # A+2
        ,$data[$offset+3]         # A+3
        ,$data[$offset+4]         # A+4
        ,$data[$offset+5]         # A+5
        ,$data[$offset+6]         # A+6
        ,$data[$offset+7]         # A+7
      );
      printf "d";

      my ($Dmsg) = Rx($project
                     ,20                       # timeout
                     ,0x04 , 0x01              # frame type
                     ,$number , $group         # responder
                     ,$data[$offset+0]         # A+0
                     ,$data[$offset+1]         # A+1
                     ,$data[$offset+2]         # A+2
                     ,$data[$offset+3]         # A+3
                     ,$data[$offset+4]         # A+4
                     ,$data[$offset+5]         # A+5
                     ,$data[$offset+6]         # A+6
                     ,$data[$offset+7]         # A+7
                     );

      if ($Dmsg eq "pass") {
        printf "D";
      }
      else {
        return sprintf("\nERROR : no or incorrect response after writing flash data<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\n");
      }
    }

    if (($block % 4) == 3) {
      sleep(1);
    }
  }

  printf "\n";

  return "pass";
}

#=======================================================================================================================

sub Flash_read {
  my ($project , $number , $group , $address , $length) = @_;

  if (!defined($length)) {
    $length=1;
  }

  if ($address < 0x008000) {
    return sprintf("ERROR : illegal Flash start address 0x%06X\n",$address);
  }

  if ($address+$length-1 > 0x008FFF) {
    return sprintf("ERROR : illegal Flash address 0x%06X\n",$address);
  }

  my $base_address   = $address & 0xFFFFF8;
  my $offset_address = $address & 0x000007;


  foreach my $block (0..($length/64)-1) {
    foreach my $row (0..7) {
      my $offset  = $block*64 + $row*8;
      my $address = $base_address + $offset;
      my $ADRU    = ($address & 0xFF0000) >> 16;
      my $ADRH    = ($address & 0x00FF00) >>  8;
      my $ADRL    = ($address & 0x0000FF) >>  0;

      Tx($project
        ,sprintf("set flash read address to 0x%06X" , $address)
        ,0x03    , 0x00           # frame type
        ,$number , $group         # receiver
        ,$ADRU   , $ADRH , $ADRL  # address
        ,0x00    , 0x00           # don't care
        ,0x01                     # cmd:0x01=read
        ,0x00    , 0x00           # don't care
      );

      my ($Amsg) = Rx($project
                     ,10                       # timeout 10sec
                     ,0x03 , 0x01              # frame type
                     ,$number , $group         # responder
                     ,$ADRU   , $ADRH , $ADRL  # address
                     ,0x00 , 0x00              # don't care
                     ,0x01                     # 0x01=read
                     ,0x00 , 0x00              # don't care
                     );

      if ($Amsg ne "pass") {
        return sprintf("ERROR : no or incorrect response after setting flash address 0x%06X\n", $address);
      }

      Tx($project
        ,"read data"
        ,0x04 , 0x00              # frame type
        ,$number , $group         # receiver
        ,0x00                     # A+0
        ,0x00                     # A+1
        ,0x00                     # A+2
        ,0x00                     # A+3
        ,0x00                     # A+4
        ,0x00                     # A+5
        ,0x00                     # A+6
        ,0x00                     # A+7
      );

      my ($Dmsg) = Rx($project
                     ,10                       # timeout 10sec
                     ,0x04 , 0x01              # frame type
                     ,$number , $group         # responder
                     ,undef                    # A+0
                     ,undef                    # A+1
                     ,undef                    # A+2
                     ,undef                    # A+3
                     ,undef                    # A+4
                     ,undef                    # A+5
                     ,undef                    # A+6
                     ,undef                    # A+7
                     );

      if ($Dmsg ne "pass") {
        return sprintf("ERROR : no or incorrect response after reading flash data\n");
      }
    }
  }

  return "pass";
}

#=======================================================================================================================

sub message_header {
  my (@message) = @_;

  my $frame_type    = ($message[1] << 4) | ($message[2] & 0xF0)>>4;
  my $response_flag =  $message[2] & 0x01;
  my $number        =  $message[3];
  my $group         =  $message[4];

  return ($frame_type , $response_flag , $number , $group);
}

#=======================================================================================================================
#=======================================================================================================================
#=======================================================================================================================
#=======================================================================================================================
#=======================================================================================================================
#=======================================================================================================================
#=======================================================================================================================
#=======================================================================================================================
#=======================================================================================================================
#=======================================================================================================================
#=======================================================================================================================
#=======================================================================================================================
#=======================================================================================================================
#=======================================================================================================================
#=======================================================================================================================
#=======================================================================================================================
#=======================================================================================================================

1;
