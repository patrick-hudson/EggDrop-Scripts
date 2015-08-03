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
# !xkcd
bind pub - !xkcd xkcd
package require http
package require json
proc xkcd {nick host hand chan arg} {
    set url "http://xkcd.com/"
    set page [http::data [http::geturl $url]]
    regsub -all {(?:\n|\t|\v|\r|\x01)} $page " " page
    if {[regexp -nocase {Permanent link to this comic: http://xkcd.com/(.*?)/} $page " " lastComic]} {
        regsub -nocase -- {Permanent link to this comic: http://xkcd.com/(.*?)/} $lastComic "\\1" comicMax
        set randomComic [myRand 1 $comicMax]
        getComicJSON $randomComic $chan
    }
}
proc getComicJSON { num chan} {
    set url "http://xkcd.com/$num/info.0.json"
    set page [http::data [http::geturl $url]]
    #regsub -all {(?:\n|\t|\v|\r|\x01)} $page " " page
    set xkcdDict [json::json2dict $page]
    set title [dict get $xkcdDict "safe_title"]
    set month [dict get $xkcdDict "month"]
    set day [dict get $xkcdDict "day"]
    set year [dict get $xkcdDict "year"]
    set month [dict get $xkcdDict "month"]
    set num [dict get $xkcdDict "num"]
    set alt_text [dict get $xkcdDict "alt"]
    set imageLink [dict get $xkcdDict "img"]
    putserv "PRIVMSG $chan :\002xkcd\002 #$num ($year-$month-$day) \002$title\002"
    putserv "PRIVMSG $chan :$imageLink"
    putserv "PRIVMSG $chan :\002Alt Text:\002 $alt_text"
}
proc myRand { min max } {
    set maxFactor [expr [expr $max + 1] - $min]
    set value [expr int([expr rand() * 100])]
    set value [expr [expr $value % $maxFactor] + $min]
    return $value
}
putlog "xkcd HackPat @ FreeNode"