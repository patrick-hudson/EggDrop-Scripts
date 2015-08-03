#Looks up random insults
bind pub - !insult insult
proc insult {nick host hand chan arg} {
  package require http
  set url "http://www.insultgenerator.org/"
  set page [http::data [http::geturl $url]]
  regsub -all {(?:\n|\t|\v|\r|\x01)} $page " " page
 	if {[regexp -nocase {<div class="wrap">(.*?)</div>} $page " " insult]} {
		regsub -nocase -- {<br><br>(.*?)} $insult "\\1" insult
		regsub {^[\ ]*} $insult "" insult
		regsub {[\ ]*$} $insult "" insult
		regsub {^[\ ]*} $arg "" arg
		regsub {[\ ]*$} $arg "" arg
			if {$arg == ""} {
		  		putserv "PRIVMSG $chan :$nick, $insult"
			} else {
				putserv "PRIVMSG $chan :$arg, $insult"
			}
	}
}

putlog "Insulterrrrrrr HackPat @ FreeNode"