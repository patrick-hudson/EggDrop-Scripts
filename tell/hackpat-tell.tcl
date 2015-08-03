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