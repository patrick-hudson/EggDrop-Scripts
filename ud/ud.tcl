##############################################################################################
##  ##  urbandictionary.tcl for eggdrop by Ford_Lawnmower irc.geekshed.net #Script-Help ##  ##
##############################################################################################
## To use this script you must set channel flag +ud (ie .chanset #chan +ud)                 ##
##############################################################################################
##############################################################################################
##  ##                             Start Setup.                                         ##  ##
##############################################################################################
namespace eval urbandictionary {
## Edit logo to change the logo displayed at the start of the line                      ##  ##
  variable logo "\017\00308,07\002UD\017"
  #variable logo ""
## Edit textf to change the color/state of the text shown                               ##  ##
  variable textf "\017\00304"
## Edit linkf to change the color/state of the links                                    ##  ##
  variable linkf "\017\037\00304"
## Edit tagf to change the color/state of the Tags:                                     ##  ##
  ## variable tagf "\017\002"
    variable tagf ""
## Edit line1, line2, line3, line4 to change what is displayed on each line             ##  ##
## Valid items are: word, definition, example, author, link                             ##  ##
## Do not remove any variables here! Just change them to "" to suppress display         ##  ##
  variable line1 ""
  variable line2 "definition"
  variable line3 ""
  variable line4 ""
## Edit cmdchar to change the !trigger used to for this script                          ##  ##
  variable cmdchar "!"
  variable gpage ""
##############################################################################################
##  ##                           End Setup.                                              ## ##
##############################################################################################
  setudef flag ud
  bind pub -|- [string trimleft $urbandictionary::cmdchar]ud urbandictionary::main
  bind pub -|- [string trimleft $urbandictionary::cmdchar]slang urbandictionary::main
}
proc urbandictionary::main {nick host hand chan text} {
  if {[lsearch -exact [channel info $chan] +ud] != -1} {
    set text [strip $text]
    set number ""
    set author ""
    set definition ""
    set example ""
    set word ""
    set term ""
    set class ""
    set udurl ""
    set page ""
    set link ""
    set count 1
    set item 1
    
    if {[regexp {^(?:[\d]{1,}\s)(.*)} $text match term]} {
      set term [urlencode $term]
      #set item [expr {[lindex $text 0] % 7}]
      set item [lindex $text 0]
      if {$item == 0} { set item 7 }
      set page [expr {int(ceil(double([lindex $text 0]) / double(7)))}]
      set page "&page=${page}"
      set udurl "/define.php?term=${term}${page}"
    } elseif {[lindex $text 0] == "redirect"} {
      set term [lindex $text 1]
      set udurl "/define.php?term=${term}"
    } elseif {[lindex $text 0] != "${urbandictionary::cmdchar}ud"} {
      set term [urlencode $text]
      set udurl [iif $term "/define.php?term=${term}" "/random.php"]
      set class "" 
    }
    set udsite "www.urbandictionary.com"
    if {[catch {set udsock [socket -async $udsite 80]} sockerr] && $udurl != ""} {
      return 0
    } else {
      puts $udsock "GET $udurl HTTP/1.0"
      puts $udsock "Host: $udsite"
      puts $udsock ""
      flush $udsock
      while {![eof $udsock]} {
        set udvar " [string map {<![CDATA[ "" ]]> "" \} "" \{ "" \[ "" \] "" \$ ""} [gets $udsock]] "
        regexp -nocase {<div\sclass="([^"]*)">} $udvar match class
        if {[regexp -nocase {class="index"[^>]*>(.*)\.<\/a>} $udvar match count]} {
        } elseif {[string match -nocase "*class='greenery'*" $udvar]} {
          set class "greenery"
        } elseif {[string match -nocase "*class='zazzle_links'*" $udvar]} {
          set class "zazzle"
        } elseif {[string match -nocase "*class=?meaning?*" $udvar]} {
          set class "definition"
        } elseif {[string match -nocase "*class=?example?*" $udvar]} {
          set class "example"
        } elseif {[string match -nocase "*class=?small?*" $udvar]} {
          set class "small"
        } elseif {$class == "small"} {
          regexp -nocase {(\d+)\.} $udvar match count
          set class ""
        } elseif {$class == "definition" && $count == $item} {
          if {[regexp -nocase {<div\sclass=["']meaning["']>(.*?)<\/div>} $udvar match definition]} {
            set definition [striphtml $definition]
            if {[regexp -nocase {<div class=["']example["']>(.*)} $udvar match example]} {
              set example [striphtml $example]
              set class "example"
            }
          } else {
            set definition "$definition [striphtml $udvar]"
            if {[string match -nocase "*</div>*" $udvar]} {
              set class ""
            }
          }
        } elseif {[string match -nocase "*class='word'*" $udvar]} {
          set class "word"
        } elseif {$class == "word" && [striphtml $udvar] != "" && ![string match "*<a class=\"index\"*" $udvar]} {
          set word [striphtml $udvar]
          set class ""
        } elseif {$class == "example" && $count == $item} {
          if {[regexp -nocase {<div class=["']example["']>(.*)(?:<\/div>)?} $udvar match example]} {
            regexp -nocase {(.*)<div class=["']example["']>} $udvar match definitionend
            set definition "$definition [striphtml $definitionend]"
            set example [striphtml $example]
          } else {
            set example "$example [striphtml $udvar]"
            if {[string match "*</div>*" $udvar]} { set class "" }
          }
        } elseif {[regexp -nocase {class=["']author["'][^>]*>(.*)<\/a>} $udvar match author] || [regexp -nocase {^\s?by\s([\w]*)} $udvar match author]} {
          if {$count == $item && $term != ""} {
            set wordfix [string map {" " +} [string trimleft [string trimright $word " "] " "]]
            set word "${urbandictionary::tagf}Word: ${urbandictionary::textf}[striphtml $word]"
            set link "${urbandictionary::tagf}Link: ${urbandictionary::linkf}http://www.urbandictionary.com/define.php?term=$term"
            set author "${urbandictionary::tagf}Author: ${urbandictionary::textf}[striphtml $author]"
            set definition "${urbandictionary::tagf}Definition: ${urbandictionary::textf}[striphtml $definition]"
            set example "${urbandictionary::tagf}Example: ${urbandictionary::textf}[striphtml $example]"
            if {$urbandictionary::line1 != ""} {
              msg $chan $urbandictionary::logo $urbandictionary::textf [subst [regsub -all -nocase {(\S+)} $urbandictionary::line1 {$\1}]] 
            }
            if {$urbandictionary::line2 != ""} {
              msg $chan $urbandictionary::logo $urbandictionary::textf [subst [regsub -all -nocase {(\S+)} $urbandictionary::line2 {$\1}]] $link
            }
            if {$urbandictionary::line3 != ""} {
              msg $chan $urbandictionary::logo $urbandictionary::textf [subst [regsub -all -nocase {(\S+)} $urbandictionary::line3 {$\1}]]
            }
            if {$urbandictionary::line4 != ""} {
              msg $chan $urbandictionary::logo $urbandictionary::textf [subst [regsub -all -nocase {(\S+)} $urbandictionary::line4 {$\1}]]
            }
            close $udsock
            return 0
          } else {
            #incr count
          }
        } elseif {[regexp -nocase {Location:\s(.*)} $udvar match redirect]} {
          set udredir ""
          regexp {term\=(.*)} $redirect match udredir
          urbandictionary::main $nick $host $hand $chan "redirect $udredir"
          break
          return 0
        } elseif {[string match -nocase "*<div id='not_defined_yet'>*" $udvar] || [string match -nocase "*</body>*" $udvar]} {
          putserv "PRIVMSG $chan :Nothing found!"
          close $udsock
          return
        }
      }
    }
  }
}
proc urbandictionary::striphtml {string} {
  return [string trimright [string trimleft [dehex [string map {&quot; \" &lt; < &rt; >} [regsub -all {(<[^<^>]*>)} $string ""]]]]]
}
proc urbandictionary::replacestring {string found replace} {
  set found [escape $found]
  putlog "found: $found"
  return [regsub -all $found $string $replace]
  
}
proc urbandictionary::escape {string} {
  return [subst [regsub -all {([\[\]\(\)\{\}\.\?\:\^])} $string "\\1"]]
}
proc urbandictionary::iif {test do elsedo} {
   if {$test != 0 && $test != ""} {
     return $do
   } else {
     return "$elsedo"
   }
}
proc urbandictionary::urlencode {string} {
  set string [string trimleft [string trimright $string]]
  return [subst [regsub -nocase -all {([^a-z0-9])} $string {%[format %x [scan "\\&" %c]]}]]
}
proc urbandictionary::strip {text} {
  regsub -all {\002|\031|\015|\037|\017|\003(\d{1,2})?(,\d{1,2})?} $text "" text
    return $text
}
proc urbandictionary::msg {chan logo textf text term} {
  set text [textsplit $text 100]
  set counter 0
  set linecount 1
  while {$counter <= [llength $text]} {
    if {[lindex $text $counter] != "" && $counter < 2} {
      putserv "PRIVMSG $chan :${logo} ${textf} ($linecount/[llength $text]) [string map {\\\" \"} [lindex $text $counter]]"
    } elseif {$counter > 1} {
      putserv "PRIVMSG $chan :${logo} Output Truncated - Read more $term"
      break
    }
    incr counter
    incr linecount
  }
}
proc urbandictionary::textsplit {text limit} {
  set text [split $text " "]
  set tokens [llength $text]
  set start 0
  set return ""
  while {[llength [lrange $text $start $tokens]] > $limit} {
    incr tokens -1
    if {[llength [lrange $text $start $tokens]] <= $limit} {
      lappend return [join [lrange $text $start $tokens]]
      set start [expr $tokens + 1]
      set tokens [llength $text]
    }
  }
  lappend return [join [lrange $text $start $tokens]]
  return $return
}
proc urbandictionary::hex {decimal} { return [format %x $decimal] }
proc urbandictionary::decimal {hex} { return [expr 0x$hex] }
proc urbandictionary::dehex {string} {
  regsub -all {^\{|\}$} $string "" string
  set string [subst [regsub -nocase -all {\\u([a-f0-9]{4})} $string {[format %c [decimal \1]]}]]
  set string [subst [regsub -nocase -all {\%([a-f0-9]{2})} $string {[format %c [decimal \1]]}]]
  set string [subst [regsub -nocase -all {\&#([0-9]{2});} $string {[format %c \1]}]]
  set string [subst [regsub -nocase -all {\&#x([0-9]{2});} $string {[format %c [decimal \1]]}]]
  set string [string map {&quot; \" &middot; · &amp; & <b> \002 </b> \002} $string]
  return $string
}
putlog "\002*Loaded* \00308,07\002UrbanDictionary\002\003 v1.01 \002by Ford_Lawnmower irc.GeekShed.net #Script-Help"