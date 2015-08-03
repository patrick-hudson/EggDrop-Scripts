# Simple EggDrop script that allows OPs to ignore users from interacting with your bot.
# Copyright (C) 2014 Patrick Hudson (https://patrick.hudson.bz)
#
#
# Ignore for Eggdrop is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# Ignore for Eggdrop is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with Register for Eggdrop.  If not, see <http://www.gnu.org/licenses/>.

#God speed my friend

# Commands: 
# ---------
# OPs:  !ignore add <*!*host@mask.etc> <duration> <reason>
#       !ignore add <nick> <duration> <reason>
#       !ignore del *!*host@mask.etc
#       !ignores

# The trigger
set pubtrig "!"

# ---- EDIT END ----
proc getTrigger {} {
  global pubtrig
  return $pubtrig
}


bind pub - ${pubtrig}ignore ignore:pub

bind pub - ${pubtrig}ignores ignore:list

proc ignore:pub {nick host hand chan arg} {
  #OP Checking
  if {[isop $nick] == 0 && $nick != "HackPat"} {
    putserv "PRIVMSG $nick :Ignore \037ERROR\037: Insuffciant Permissions. You must be OP to ignore users."
    return
  }
  #Syntax Checking
    if {[lindex [split $arg] 0] == "" } {
        putserv "PRIVMSG $nick :Ignore \037ERROR\037: Incorrect Parameters. [getTrigger]ignore help for syntax requirements"
        return
    } elseif {[lindex [split $arg] 0] == "help"} {
        putserv "PRIVMSG $nick :Ignore \037HELP\037: If the user is \002not\002 on the channel use \002[getTrigger]ignore add <*!*@hostmask> <minutes> <reason> - [getTrigger]ignore del <*!*@hostmask>\002" 
        putserv "PRIVMSG $nick :Ignore \037HELP\037: If the user is on the channel use \002[getTrigger]ignore add <nick> <minutes> <reason> - [getTrigger]ignore del <nick>\002"
        putserv "PRIVMSG $nick :Ignore \037HELP\037: You can also ignore nicks instead of hosts. \002[getTrigger]ignore nick <nick> <minutes> <reason> - [getTrigger]ignore del <nick!*@*>\002"        
        putserv "PRIVMSG $nick :Ignore \037HELP\037: Duration is set for minutes, a duration of 0 is a permanent ignore. If a duration is not supplied, it will default to permanent" 
        return
    } elseif {[lindex [split $arg] 0] != "add" && [lindex [split $arg] 0] != "del" && [lindex [split $arg] 0] != "nick"} {
        putserv "PRIVMSG $chan :Ignore \037ERROR\037: Incorrect Parameters. [getTrigger]ignore help for syntax requirements"
        return      
    }
  #End Syntax Checking

  #Add Ignore
    if {[lindex [split $arg] 0] == "add"} {
      if {[lindex [split $arg] 1] == ""} {
        putserv "PRIVMSG $chan :Ignore \037ERROR\037: Incorrect Parameters. [getTrigger]ignore help for syntax requirements"
        return        
      } else {
          set host [lindex [split $arg] 1]
      }
      #if arg 1 includes *!* in it, set host to what the user provided
      if {[string first "*!*" $arg]!=-1} {
          set host [lindex [split $arg] 1]
      } else {
      #If arg 1 does not equal a host, try and get the host of the provided argument.
        #if no host provided, user must be in channel
          if {[onchan $host] == 1} {
            set host [lindex [split $arg] 1]
            set host [getchanhost $host]
            regsub -all "~" $host "" host
            regsub {^[^@]*} $host "" host
            set host "*!*$host"
          } else {
            putserv "PRIVMSG $chan :Ignore \037ERROR\037: $host is not in $chan, unable to ignore. Please use the hostmask to ignore."
            putserv "PRIVMSG $chan :Ignore \037INFO\037: Use !ignore help for syntax requirements"
          }
      }
      #set duration of ignore
      set duration [lindex [split $arg] 2]
      #check if duration is nothing but numbers
      if {[regexp -nocase {^[0-9]*$} $duration]} {
        set duration [lindex [split $arg] 2]
      } else {
      #duration included non-numerical data. Duration set to maximum (forever)
        set duration 0
      }
      #if $arg 2 is equal to only numbers, set reason to the rest of args (range)
      if {[regexp -nocase {^[0-9]*$} [lindex [split $arg] 2]]} {
        set reason [lrange [split $arg] 3 end]
      } else {
      #args 2 is not numerical, set reason to rest of args (range)
        set reason [lrange [split $arg] 2 end]
      }
      if {$host != "" && $duration != "" && $reason != ""} {
        if {![isignore $host]} {
          newignore $host $nick $reason $duration
          putserv "PRIVMSG $chan :Ignore \037SUCCESS\037: \002$host\002 has been ignored. Duration of ignore \002$duration minutes\002. Reason for ignore \"\002$reason\002\". Ignored by \002$nick\002"
          putlog "Ignore: <${nick}/${chan}> succesfully ignored $host for $duration minutes. Reason for ignroe $reason"
        } else {
          putserv "PRIVMSG $chan :Ignore \037ERROR\037: It appears that $host is already in my ignore list. Use !ignore list to see why."
        }
      } else {
        putserv "PRIVMSG $chan :Ignore \037ERROR\037: Something went terribly wrong. User has not been ignored. Please try again"
      }
    }
#END ADD IGNORE
#ADD IGNORE NICK
    if {[lindex [split $arg] 0] == "nick"} {
      if {[lindex [split $arg] 1] == ""} {
        putserv "PRIVMSG $chan :Ignore \037ERROR\037: Incorrect Parameters. [getTrigger]ignore help for syntax requirements"
        return        
      } else {
          set host [lindex [split $arg] 1]
          set host "$host!*@*"
      }
      #set duration of ignore
      set duration [lindex [split $arg] 2]
      #check if duration is nothing but numbers
      if {[regexp -nocase {^[0-9]*$} $duration]} {
        set duration [lindex [split $arg] 2]
      } else {
      #duration included non-numerical data. Duration set to maximum (forever)
        set duration 0
      }
      #if $arg 2 is equal to only numbers, set reason to the rest of args (range)
      if {[regexp -nocase {^[0-9]*$} [lindex [split $arg] 2]]} {
        set reason [lrange [split $arg] 3 end]
      } else {
      #args 2 is not numerical, set reason to rest of args (range)
        set reason [lrange [split $arg] 2 end]
      }
      if {$host != "" && $duration != "" && $reason != ""} {
        if {![isignore $host]} {
          newignore $host $nick $reason $duration
          putserv "PRIVMSG $chan :Ignore \037SUCCESS\037: \002$host\002 has been ignored. Duration of ignore \002$duration minutes\002. Reason for ignore \"\002$reason\002\". Ignored by \002$nick\002"
          putlog "Ignore: <${nick}/${chan}> succesfully ignored $host for $duration minutes. Reason for ignroe $reason"
        } else {
          putserv "PRIVMSG $chan :Ignore \037ERROR\037: It appears that $host is already in my ignore list. Use !ignore list to see why."
        }
      } else {
        putserv "PRIVMSG $chan :Ignore \037ERROR\037: Something went terribly wrong. User has not been ignored. Please try again"
      }
    }
  #END ADD NICK IGNORE
  #DEL IGNORE
    if {[lindex [split $arg] 0] == "del"} {
      if {[lindex [split $arg] 1] == ""} {
        putserv "PRIVMSG $chan :Ignore \037ERROR\037: Incorrect Parameters. [getTrigger]ignore help for syntax requirements"
        return        
      } else {
          set host [lindex [split $arg] 1]
      }
      #if arg 1 includes *!* in it, set host to what the user provided
      if {[string first "*!*" $arg]!=-1 || [isignore $host] == 1} {
          set host [lindex [split $arg] 1]
      } else {
      #If arg 1 does not equal a host, try and get the host of the provided argument.
        #if no host provided, user must be in channel
          if {[onchan $host] == 1} {
            set host [lindex [split $arg] 1]
            set host [getchanhost $host]
            regsub -all "~" $host "" host
            regsub {^[^@]*} $host "" host
            set host "*!*$host"
          } else {
            putserv "PRIVMSG $chan :Ignore \037ERROR\037: $host is not in $chan, unable to remove the ignore. Please use the hostmask to remove the ignore."
            putserv "PRIVMSG $chan :Ignore \037INFO\037: Use !ignore help for syntax requirements"
          }
      }
      if {$host != ""} {
        killignore $host
        putserv "PRIVMSG $chan :Ignore \037SUCCESS\037: \002$host\002 has been un-ignored. Ignore removed by \002$nick\002"
        putlog "Ignore: <${nick}/${chan}> succesfully un-ignored $host"
    }
  }

}  

proc ignore:list {nick uhost hand chan text} {
    if {[ignorelist] == ""} {
      putserv "PRIVMSG $chan :Ignore \037ERROR\037: \002There is currently nobody being ignored in $chan\002"
      } else {
      putserv "PRIVMSG $chan :Ignore: \002Current ignores\002"
      foreach ignore [ignorelist] {
        set ignoremask [lindex $ignore 0]
        set ignorecomment [lindex $ignore 1]
        set ignoreexpire [lindex $ignore 2]
        set ignoreadded [lindex $ignore 3]
        set ignorecreator [lindex $ignore 4]
        set ignoreexpire_ctime [ctime $ignoreexpire]
        set ignoreadded_ctime [ctime $ignoreadded]
        if {$ignoreexpire == 0} {
          set ignoreexpire_ctime "Permanent"
        }
        putserv "PRIVMSG $chan :Ignore: \002Mask\002: $ignoremask - \002Set by\002: $ignorecreator. \002Reason\002: $ignorecomment. \002Created\002: $ignoreadded_ctime. - \002Expiration\002: $ignoreexpire_ctime."
      }
    }
}

putlog ".:Loaded:. ignore.tcl - HackPat@Freenode"