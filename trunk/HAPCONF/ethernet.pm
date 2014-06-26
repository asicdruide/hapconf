use strict;
use warnings;
use Carp;
use HAPCONF::util;

$| = 1;

########################################################################################################################
#
# HAPCAN Ethernet Module
#
########################################################################################################################
package HAPCONF::ethernet;

#=======================================================================================================================

sub new {
  my ($class 
     ,$project
     ,$name
     ) = @_;
  
  $name = HAPCONF::util::check_name($name , "name");

  my $self = {"project"     => $project
             ,"name"        => $name
             ,"node_number" => undef
             ,"node_group"  => undef
             ,"url"         => undef
             ,"schedule"    => []               # 128 times enable/time_spec/CAN message
             ,"notes"       => undef
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
  
  $self->{"url"} = HAPCONF::util::check_url($url , "url");

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
  
  return $self->{"url"};
}

#=======================================================================================================================

sub check {
  my ($self) = @_;
  my $error=0;
  
  
  if (!defined($self->{"url"})) {
    printf STDERR "ERROR : Ethernet module '%s' has undefined url.\n"
                  ,$self->{"name"}
                  ;
    $error=1;
  }
  elsif ($self->{"url"} !~ m/^\d+\.\d+\.\d+\.\d+:\d+$/) {
    printf STDERR "ERROR : Ethernet module '%s' has malformed url '%s'.\n"
                  ,$self->{"name"}
                  ,$self->{"url"}
                  ;
    $error=1;
  }
  
  return $error;
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
