############################################################################################
# Name      m00nie::weather
#
# Description   Uses wunderground API to grab some weather...
#     Default below you need to +weather your chan then calls are:
#     !w  = Current conditions (Either pass location or try user default)
#     !fc = 3 day forecast (Either pass location or try user default)
#     !w -set location = Set user default location (this also adds a user to the bot)
#
# Version   1.1 (13/06/15)
# Website   https://www.m00nie.com
# Notes     Grab your own key @ http://www.wunderground.com/weather/api
############################################################################################
namespace eval m00nie {
  namespace eval weather {
  package require http
  package require tdom
  bind pub - !w m00nie::weather::current_call
  bind pub - !fc m00nie::weather::forecast_call
  variable version "1.1"
  setudef flag weather
  variable key ""
  ::http::config -useragent "Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:38.0) Gecko/20100101 Firefox/38.0"

proc current_call {nick uhost hand chan text} {
  if {[lindex $text 0] == "-set"} {
    if {[validuser $hand]} { 
      setuser $hand XTRA incith:weather.location "[lrange $text 1 end]"
      putserv "PRIVMSG $chan :Default weather location set to [lrange $text 1 end]."
      return
    } else {
      putserv "PRIVMSG $chan :Sorry, your bot handle was not found. Unable to set a default."
      return
    }
  } else {
    set location [verify $hand $chan $text]
  }
  current $location $chan
}

proc forecast_call {nick uhost hand chan text} {
  set location [verify $hand $chan $text]
  forecast $location $chan
}

proc location {nick uhost hand chan text} {
  if {![validuser $hand]} {
    set mask [maskhost [getchanhost $nick $chan]]
    adduser $nick $mask
    chattr $nick -hp
    putlog "m00nie::weather::location added user $nick with mask $mask"
  }  
  setuser $nick XTRA incith:weather.location $text
  puthelp "PRIVMSG $chan :Default weather location for $nick set to $text."
  putlog "m00nie::weather::location $nick set their default location to $text."
}

proc verify {hand chan text} {
  if {(![channel get $chan weather])} {
    putlog "m00nie::weather::search Trigger seen but channel doesnt have +weather set!"
    return 0
  }
  if {$text != ""} { 
    set location $text 
  } else { 
    set location [getuser $hand XTRA incith:weather.location] 
  }
  
  if {[string length $location] == 0 || [regexp {[^0-9a-zA-Z,. ]} $location match] == 1} { 
    putlog "m00nie::weather::search location b0rked or no location said/default? Argument: $location"
    puthelp "PRIVMSG $chan :Did you ask to search somewhere? Or use !wl to set a default location"
    return
  } else {
    return $location
  }
}

proc current {location chan} {
  putlog "m00nie::weather::current is running against location: $location"
  set rawpage [getinfo $location conditions]
  set doc [dom parse $rawpage]
  set root [$doc documentElement]
        set notfound [$root selectNodes /response/error/description/text()]
        if {[llength $notfound] > 0 } {
                set errormsg [$notfound nodeValue]
                putlog "m00nie::weather::current ran but could not find any info for $location or an API error occured: $errormsg"
                puthelp "PRIVMSG $chan :$errormsg"
    return
        } 
  set city [[$root selectNodes /response/current_observation/display_location/full/text()] nodeValue]
  foreach var { observation_time weather temperature_string wind_string feelslike_string precip_today_metric } { 
    set $var [[$root selectNodes /response/current_observation/$var/text()] nodeValue]
  }
  set spam "Current weather for \002$city\002 ($observation_time) Current conditions: $weather, Temperature: $temperature_string, Wind: $wind_string, Rain today: $precip_today_metric mm, Feels like: $feelslike_string"
  puthelp "PRIVMSG $chan :$spam"
}

proc forecast {location chan} {
  putlog "m00nie::weather::forecast is running against location: $location"
        set rawpage [getinfo $location forecast]
        set doc [dom parse $rawpage]
        set root [$doc documentElement]
        set notfound [$root selectNodes /response/error/description/text()]
        if {[llength $notfound] > 0 } {
                set errormsg [$notfound nodeValue]
                putlog "m00nie::weather::current ran but could not find any info for $location or an API error occured: $errormsg"
                puthelp "PRIVMSG $chan :$errormsg"
    return
        }
  set dayList [$root selectNodes /response/forecast/txt_forecast/forecastdays/forecastday/title/text()]
  set foreList [$root selectNodes /response/forecast/txt_forecast/forecastdays/forecastday/fcttext/text()]
  set forCombined "Three day forecast for \002$location\002 "
  set x 0 
        while { $x < 3 } {
    set dayname [[lindex $dayList $x] nodeValue]
    set fore [[lindex $foreList $x] nodeValue]
    set ret "\002$dayname:\002 $fore "
    append forCombined $ret
    incr x
        }
  puthelp "PRIVMSG $chan :$forCombined"
  set forCombined ""
  set x 3 
        while { $x < 6 } {
    set dayname [[lindex $dayList $x] nodeValue]
    set fore [[lindex $foreList $x] nodeValue]
    set ret "\002$dayname:\002 $fore "
    append forCombined $ret
    incr x
        }
    puthelp "PRIVMSG $chan :$forCombined"
}

proc getinfo {location type} {
  regsub -all -- { } $location {%20} location
        set url "http://api.wunderground.com/api/$m00nie::weather::key/$type/q/$location.xml"
        putlog "m00nie::weather::getinfo grabbing data from $url"
        for { set i 1 } { $i <= 5 } { incr i } {
                set xmlpage [::http::data [::http::geturl "$url" -timeout 10000]] 
                if {[string length xmlpage] > 0} { break } 
        }
        putlog "m00nie::weather::getinfo xmlpage length is: [string length $xmlpage]" 
        if { [string length $xmlpage] == 0 }  {  
                error "wunderground returned ZERO no data :( or we couldnt connect properly"
        }
  return $xmlpage
}
}
}
putlog "m00nie::weather $m00nie::weather::version - Modified by HackPat@Freenode loaded"