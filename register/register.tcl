# Copyright (c) 2014 Patrick Hudson
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# Commands: 
# ---------
# Public: !register
#         !unregister
# OP:     !unregister

# The trigger - set this to anything you'd like
set pubtrig "!"

# ---- STOP EDITING HERE. When this code was created, and only myself and god knew how it worked. Now only god knows ---- #
proc getTrigger {} {
  global pubtrig
  return $pubtrig
}
bind pub - ${pubtrig}unregister deluser:pub
bind pub n ${pubtrig}purge purge:users
bind pub - ${pubtrig}register adduser:pub
bind join - "#* *!*@*" join:add

proc join:add {nick host handle chan} {
    foreach user [userlist] {
        set handle [string range "$nick" 0 8]
        if {$user == $handle} {
          setuser $handle HOSTS [maskhost $host]
          putlog "Register: <${nick}/${chan}> succesfully updated host to $host"
        }
    }
}

proc adduser:pub {nick uhost handle chan arg} {
  set handle $nick
  set hostmask [lindex $arg 1]
  putlog "$handle $nick"
    if {[validuser $handle]} {
      puthelp "privmsg $chan :$nick: Are you retarded? You already exist, go bother someone else."
      putlog "Register: <${nick}/${chan}> already exists in user file, ignoring"
      return 0
    }
    if {$hostmask == ""} {
      set host [getchanhost $handle]

      if {$host == ""} {
        puthelp "privmsg $chan :$nick: I can't get $handle's host."
        return 0
      }
    }

    if {![validuser $handle]}  {
      adduser $handle [maskhost $uhost]
      puthelp "privmsg $chan :$handle added to the user list."
      putlog "Register: <${nick}/${chan}> added to the user list via !register"
    }

}
proc purge:users {nick uhost hand chan arg} {
  foreach user [userlist] { 
  if {![matchattr $user n]} { deluser $user } 
  } 
}


proc deluser:pub {nick uhost handle chan arg} {
  set handle [string range "$nick" 0 8]
  set hostmask [lindex $arg 1]
    if {[validuser $handle] && $arg == ""} {
      deluser $handle 
      puthelp "privmsg $chan :$handle has been deleted!"
      putlog "Register: <${nick}/${chan}> removed from the user list via !unregister"
      return 0
    }
    if {$arg != ""} {
      puthelp "privmsg $chan : You must seriously think I'm that stupid huh? Like I'd let you unregister someone elses nick. Fuck off."
      putlog "Register: <${nick}/${chan}> tried to delete someone elses nick. What a dumb fuck"
      return 0
    }
    if {![validuser $handle]} {
      puthelp "privmsg $chan : Huh, I don't seem to have you in my database. Contacting N.S.A. for backup database..........Connection Terminated. Oh well."
      putlog "Register: <${nick}/${chan}> tried to unregister a non-existant nick. Dumbass."
      return 0
    }
}
putlog ".:Loaded:. register.tcl - HackPat@freenode"