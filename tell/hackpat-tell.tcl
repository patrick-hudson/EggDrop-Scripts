# Copyright (c) 2015 Patrick Hudson
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
package require sqlite3
namespace eval hackpattell {
    sqlite3 db scripts/hackpat-tell.db
    #nick message time toldby
    proc tellSave {nick host user chan text} {
        set tellToNick [lindex $text 0]
        set tellMessage [lrange $text 1 end]
        set tellTimeDate [clock format [clock seconds] -format %D -timezone :America/Chicago]
        set tellTimeHours [clock format [clock seconds] -format %H:%M:%S -timezone :America/Chicago]
        set tellTimeZone [clock format [clock seconds] -format %z -timezone :America/Chicago]
        set message "Hey $tellToNick! $nick wanted me to tell you: \"$tellMessage\" at $tellTimeHours (GMT $tellTimeZone) on $tellTimeDate"
        db eval {INSERT INTO tells VALUES($tellToNick,$message,$nick)}
        putserv "PRIVMSG $chan :Alright! I will tell that person the next time I see them."
    }
    proc tellDropAll {nick host user chan text} {
        db eval {DELETE FROM tells}
    }
    proc tellCheck {nick host user chan text} {
        set count [db eval {SELECT COUNT(*) from tells WHERE nick=$nick}]
        #putserv "PRIVMSG $chan :$count"
        if {$count > 0} {
            for {set i 0} {$i < $count} {incr i} {
                 set message [db eval {SELECT message FROM tells WHERE nick=$nick ORDER BY toldby ASC LIMIT 1}]
                 regexp -nocase {\{(.*?)\}} $message "\\1" message
                 putserv "PRIVMSG $chan :$message"
                 db eval {DELETE FROM tells WHERE nick=$nick ORDER BY toldby ASC LIMIT 1}
            }
        }
        #putserv "PRIVMSG $chan :$count"
    }
}
bind pub -|- "!tell" hackpattell::tellSave
bind pub -|- "!telldrop" hackpattell::tellDropAll
bind pubm - "% *" hackpattell::tellCheck