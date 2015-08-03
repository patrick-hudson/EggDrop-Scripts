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
# Public:   !ass - Returns a random ass picture from /r/ass
#       	!pussy - Returns a random ass picture from /r/pussy
#       	!tits - Returns a random ass picture from /r/Boobies
#       	!gif - Returns a random gif picture from /r/NSFW_GIF
#       	!nsfw [number] - Returns a list of random pictures from /r/nsfw
#       	!nsfw [subreddit] [number] - Returns a list of random pictures from /r/[subreddit]
package require http
package require tls
package require json
# The trigger

set pubtrig "!"

# ---- EDIT END ----
proc getTrigger {} {
	global pubtrig
	return $pubtrig
}
bind pub - ${pubtrig}tits tits:pub
bind pub - ${pubtrig}ass ass:pub
bind pub - ${pubtrig}pussy pussy:pub
bind pub - ${pubtrig}nsfw nsfw:pub
bind pub - ${pubtrig}gif gif:pub

proc tits:pub {nick host hand chan arg} {
	set page [myRand 0 50]
	set theurl "https://api.imgur.com/3/gallery/r/Boobies/time/$page"
	dict set hdr Authorization "Client-ID cefb2e6ae32f74f"
	http::register https 443 [list ::tls::socket -tls1 1]
	set token [http::geturl $theurl -headers $hdr -query]
	set responseBody [::json::json2dict [http::data $token]]
	set i 0
	array set idlist {}
	array set titlelist {}
	foreach link [dict get $responseBody data] {
		set idlist($i) [dict get $link link]
		set titlelist($i) [dict get $link title]
		incr i
	}
	array set completelist {}
	set forran [myRand 0 [array size idlist]]
	set completelist(0) "$idlist($forran) - $titlelist($forran)"
	putserv "PRIVMSG $chan :\002NSFW\002 Your random tits! $completelist(0)"
	http::cleanup $token
}
proc ass:pub {nick host hand chan arg} {
	set page [myRand 0 50]
	set theurl "https://api.imgur.com/3/gallery/r/ass/time/$page"
	dict set hdr Authorization "Client-ID cefb2e6ae32f74f"
	http::register https 443 [list ::tls::socket -tls1 1]
	set token [http::geturl $theurl -headers $hdr -query]
	set responseBody [::json::json2dict [http::data $token]]
	set i 0
	array set idlist {}
	array set titlelist {}
	foreach link [dict get $responseBody data] {
		set idlist($i) [dict get $link link]
		set titlelist($i) [dict get $link title]
		incr i
	}
	array set completelist {}
	set forran [myRand 0 [array size idlist]]
	set completelist(0) "$idlist($forran) - $titlelist($forran)"
	putserv "PRIVMSG $chan :\002NSFW\002 Your random ass! $completelist(0)"
	http::cleanup $token
}
proc pussy:pub {nick host hand chan arg} {
	set page [myRand 0 50]
	set theurl "https://api.imgur.com/3/gallery/r/pussy/time/$page"
	dict set hdr Authorization "Client-ID cefb2e6ae32f74f"
	http::register https 443 [list ::tls::socket -tls1 1]
	set token [http::geturl $theurl -headers $hdr -query]
	set responseBody [::json::json2dict [http::data $token]]
	set i 0
	array set idlist {}
	array set titlelist {}
	foreach link [dict get $responseBody data] {
		set idlist($i) [dict get $link link]
		set titlelist($i) [dict get $link title]
		incr i
	}
	array set completelist {}
	set forran [myRand 0 [array size idlist]]
	set completelist(0) "$idlist($forran) - $titlelist($forran)"
	putserv "PRIVMSG $chan :\002NSFW\002 Your random pussy! $completelist(0)"
	http::cleanup $token
}
proc gif:pub {nick host hand chan arg} {
	set page [myRand 0 50]
	set theurl "https://api.imgur.com/3/gallery/r/NSFW_GIF/time/$page"
	dict set hdr Authorization "Client-ID cefb2e6ae32f74f"
	http::register https 443 [list ::tls::socket -tls1 1]
	set token [http::geturl $theurl -headers $hdr -query]
	set responseBody [::json::json2dict [http::data $token]]
	set i 0
	array set idlist {}
	array set titlelist {}
	foreach link [dict get $responseBody data] {
		set idlist($i) [dict get $link link]
		set titlelist($i) [dict get $link title]
		incr i
	}
	array set completelist {}
	set forran [myRand 0 [array size idlist]]
	set completelist(0) "$idlist($forran) - $titlelist($forran)"
	putserv "PRIVMSG $chan :\002NSFW\002 Your random gif! $completelist(0)"
	http::cleanup $token
}
proc nsfw:pub {nick host hand chan arg} {
	set arg1 [lindex $arg 0]
	set arg2 [lindex $arg 1]
	if {$arg1 == "help"} {
		putserv "PRIVMSG $chan :\002NSFW\002 !ass - Returns a random ass picture from /r/ass"
		putserv "PRIVMSG $chan :\002NSFW\002 !pussy - Returns a random ass picture from /r/pussy"
		putserv "PRIVMSG $chan :\002NSFW\002 !tits - Returns a random ass picture from /r/Boobies"
		putserv "PRIVMSG $chan :\002NSFW\002 !gif - Returns a random gif picture from /r/NSFW_GIF"
		putserv "PRIVMSG $chan :\002NSFW\002 !nsfw \[number\] - Returns a list of random pictures from /r/nsfw"
		putserv "PRIVMSG $chan :\002NSFW\002 !nsfw \[subreddit\] \[number\] - Returns a list of random pictures from /r/\[subreddit\]"
		return ""
	}
	set page [myRand 0 50]
	set theurl "https://api.imgur.com/3/gallery/r/nsfw/time/$page"
	dict set hdr Authorization "Client-ID cefb2e6ae32f74f"
	http::register https 443 [list ::tls::socket -tls1 1]
	set token [http::geturl $theurl -headers $hdr -query]
	set responseBody [::json::json2dict [http::data $token]]
	set data [dict filter $responseBody key "data"]
	set i 0
	array set idlist {}
	array set titlelist {}
	foreach link [dict get $responseBody data] {
		set idlist($i) [dict get $link link]
		set titlelist($i) [dict get $link title]
		incr i
	}
	if {[regexp {^([0-9]+)$} $arg1]} {
		if {$arg1 > 4 && ![matchattr $hand +o]} {
			set arg1 4
		}
		array set completelist {}
		for {set i 0} {$i < $arg1} {incr i} {
			set forran [myRand 0 [array size idlist]]
			set completelist($i) "$idlist($forran) - $titlelist($forran)"
		}
		set linkid [myRand 0 [array size idlist]]
		for {set i 0} {$i < $arg1} {incr i} {
			putserv "PRIVMSG $chan :\002NSFW\002 Random $completelist($i)"
		}
	} elseif {[regexp {^([a-zA-Z_0-9]+)$} $arg1]} {
			set page [myRand 1 20]
			set theurl "https://api.imgur.com/3/gallery/r/$arg1/time/"
			dict set hdr Authorization "Client-ID cefb2e6ae32f74f"
			http::register https 443 [list ::tls::socket -tls1 1]
			set token [http::geturl $theurl -headers $hdr -query]
			set responseBody [::json::json2dict [http::data $token]]
			set data [dict filter $responseBody key "data"]
			set i 0
			array set idlistsubreddit {}
			array set titlelistsubreddit {}
			foreach link [dict get $responseBody data] {
				set idlistsubreddit($i) [dict get $link link]
				set titlelistsubreddit($i) [dict get $link title]
				incr i
			}
			if {[array size idlistsubreddit] == 0} {
				set i 0
				array set idlist {}
				array set titlelist {}
				foreach link [dict get $responseBody data] {
					set idlist($i) [dict get $link link]
					set titlelist($i) [dict get $link title]
					incr i
				}
				array set completelist {}
				set forran [myRand 0 [array size idlist]]
				set completelist(0) "$idlist($forran) - $titlelist($forran)"
				putserv "PRIVMSG $chan :\002NSFW\002 Opps! Imgur subreddit doesn't exist, don't worry here's something to look at!: $completelist(0)"
				putserv "PRIVMSG $chan :\002NSFW\002 Use http://redditlist.com/nsfw/ for a list of subreddits to search"
				return ""
			}
			set linkid [myRand 0 [array size idlistsubreddit]]
			set listnsfw ""
			set listtitle ""
			if {$arg2 == "" || $arg2 == 0} {
				set arg2 1
			}
			if {$arg2 > 4 && ![matchattr $hand +o]} {
				set arg2 4
			}
			array set completelist {}
			for {set i 0} {$i < $arg2} {incr i} {
				set forran [myRand 0 [array size idlistsubreddit]]
				set completelist($i) "$idlistsubreddit($forran) - $titlelistsubreddit($forran)"

			}
			unset i
			if {$arg2 == 1} {
				putserv "PRIVMSG $chan :\002NSFW\002 Random $arg1 $completelist(0)"
				} else {
					for {set i 0} {$i < $arg2} {incr i} {
						putserv "PRIVMSG $chan :\002NSFW\002 Random $arg1 $completelist($i)"
					}
				}

		} else {
					set i 0
					array set idlist {}
					array set titlelist {}
					foreach link [dict get $responseBody data] {
						set idlist($i) [dict get $link link]
						set titlelist($i) [dict get $link title]
						incr i
					}
					array set completelist {}
					set forran [myRand 0 [array size idlist]]
					set completelist(0) "$idlist($forran) - $titlelist($forran)"
					putserv "PRIVMSG $chan :\002NSFW\002 Random NSFW $completelist(0)"
				}

				http::cleanup $token
		}
proc myRand { min max } {
	set maxFactor [expr [expr $max + 1] - $min]
	set value [expr int([expr rand() * 100])]
	set value [expr [expr $value % $maxFactor] + $min]
	return $value
}

putlog ".:Loaded:. rannsfw.tcl - HackPat@Freenode"
