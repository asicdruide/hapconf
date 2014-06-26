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

#      sub RxWait {
#        my ($project , @exp_byte) = @_;
#        
#        unshift(@exp_byte , 0xAA);             # start
#        push   (@exp_byte , undef);            # CHKSUM
#        push   (@exp_byte , 0xA5);             # stop
#      
#        my $socket = $project->{"socket"};
#        my $select = $project->{"select"};
#        my $result;
#        my $timeout;
#      
#        do {
#          my @can_read = $select->can_read(10);
#          my $rx;
#          
#          if (scalar(@can_read)==0) {
#            $timeout = 1;
#            $result  = "FAIL";
#          }
#          else {
#            $timeout = 0;
#            $socket->read($rx , 15);
#            
#            my @rx_byte = map {ord(substr($rx , $_ , 1))} (0..14);
#      
#            my $log = "Rx :";
#      
#            $result = "pass";
#      
#            foreach my $i (0..14) {
#              $log .= sprintf(" %02X" , $rx_byte[$i]);
#      
#              if (defined($exp_byte[$i]) 
#                  &&
#                  $exp_byte[$i] != $rx_byte[$i]) {
#                # fail...
#                $result = "FAIL";
#              }
#            }
#            
#            printf "%s %s %s\n"
#                   ,$log
#                   ,$result
#                   ,$project->decode_message(@rx_byte);
#          }
#        } until ($result eq "pass" || $timeout==1);
#        
#        if ($timeout==1) {
#          printf "ERROR : timeout!\n";
#        }
#      } 

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
        printf "%s\n",$log;
      }
    }
  } until ($result eq "pass" || $result eq "timeout");
  
  return ($result , @rx_byte);
} 

#=======================================================================================================================

sub HWping {
  my ($project , $number , $group) = @_;
  
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
                        ,1                 # timeout 1sec
                        ,0x10    , 0x41    # hw type response
                        ,$number , $group  # responder
                        ,undef   , undef   # HARD1, HARD2
                        ,undef   , 0xFF    # HVER , don't care
                        ,undef   , undef   # ID0, ID1
                        ,undef   , undef   # ID2, ID2
                        );

  my %result;

  if ($msg eq "pass") {
    $result{"msg" } = $msg;
    $result{"HARD"} = $byte[5]<<8  | $byte[6];
    $result{"HVER"} = $byte[7];
    $result{"ID"  } = $byte[9]<<24 | $byte[10]<<16 | $byte[11]<<8 | $byte[12]; 
  }
  elsif ($msg eq "timeout") {
    $result{"msg"  } = "ERROR : no HWping response during timeout";
  }
  
  return %result;
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

sub FWping {
  my ($project , $number , $group) = @_;
  
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
                        ,0.1               # timeout
                        ,0x10    , 0x61    # hw type response
                        ,$number , $group  # responder
                        ,undef   , undef   # HARD1, HARD2
                        ,undef   , undef   # HVER , ATYPE
                        ,undef   , undef   # AVERS , FVERS
                        ,undef   , undef   # BVER1 , BVER2
                        );

  my %result;

  if ($msg eq "pass") {
    $result{"msg"  } = $msg;
    $result{"HARD" } = $byte[ 5]<<8 | $byte[6];
    $result{"HVER" } = $byte[ 7];
    $result{"ATYPE"} = $byte[ 8];
    $result{"AVERS"} = $byte[ 9];
    $result{"FVERS"} = $byte[10];
    $result{"BVER" } = $byte[11]<<8 | $byte[12];
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
    
    my ($Amsg) = Rx($project
                   ,10                       # timeout 10sec
                   ,0x03 , 0x01              # frame type
                   ,$number , $group         # responder
                   ,$ADRU   , $ADRH , $ADRL  # address
                   ,0x00 , 0x00              # don't care
                   ,0x03                     # 0x03=erase 
                   ,0x00 , 0x00              # don't care
                   );

    if ($Amsg ne "pass") {
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

    if ($Dmsg ne "pass") {
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
    push(@data , 0x00);
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
        return sprintf("ERROR : no or incorrect response after setting flash address 0x%06X\n", $address);
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
        return sprintf("ERROR : no or incorrect response after writing flash data\n");
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
