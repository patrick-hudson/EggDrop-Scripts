###############################################################################
#  Name:                  Youtube Title V2
#  Author:                Jan Milants <viper@anope.org>
#  Version:               2.0     (28/08/2014)
#  Eggdrop Version:       1.6.x
#  Requires TCL version:  8.5
#  Package dependencies:  http, tls, json
#  Credits:               Based on original YouTube Script
#                             by jotham.read@gmail.com
#                         Design inspiration from
#                             youtube.tcl by Mookie.
# Modified heavily by HackPat @ FreeNode
###############################################################################
# Description
# -------------
# The script monitors text channels for links to Youtube.
# When found, it will query the google server for details such as video title
# and number of views of the youtube video and advertise the results in the channel.
# The script also supports searching youtube with the command "!youtube <search text>"
# or "!yt <search text>". In response, the search query will be passed on to the
# youtube API and the best ranking result will be linked in channel.
#
# This script will be active on any channel it resides in with the "youtube" flag.
# The flag can be set in the console with ".chanset #chan +youtube" or with the 
# in channel command "!youtube on". Both commands only work for users with flag mno.
#
# Getting your own Google API key
# ---------------------------------
# This script uses the Google Youtube Data API V3, which requires an API key to
# authorize access to the API and is used as basis for limiting request per day etc.
# Instructions can be found on 
#     https://developers.google.com/youtube/registering_an_application
# Required steps in short:
#     1. Go to the Google developers console https://console.developers.google.com
#     2. Create a new project. Give it a name like 'eggdrop', doesn't matter much.
#     3. When the project is loaded, select menu "APIs" under "APIs & auth"
#     4. In the list of APIs, enable the "YouTube Data API v3".
#     5. Select menu "Credentials" and click "Create new key".
#     6. Select key type "server".
#     7. Fill in the IP(s) or IP range from which the eggdrop bot will send
#        requests to google's servers. This is a whitelist, if the request
#        comes from a different IP, it will be rejected.
#        Note: If my-ip or my-hostname is configured in eggdrop.conf, they should
#              be entered here.
#     8. You now have an API KEY; copy it to the config section below.
#
# !!! IMPORTANT !!!
# When loading this script alongside other scripts which initiate web service calls,
# ensure this script is loaded last! The script creates a handler for HTTPS connection
# and sets the source IP to the my-ip or my-hostname from eggdrop.conf.
# Most other scripts will not correctly enforce the source IP of requests and 
# can overwrite this scripts HTTPS handler. This results in connections coming from another
# IP on the machine and may thus be rejected by the Google API Servers. 
# The typical error message logged would be "Error processing web service reply".
#
###############################################################################
#  Changes:
#  2.00 28/08/14
#    Started development (Jan).
#    Almost complete rewrite most notable changes:
#        * Use the YouTube Data API V3. (Requires TLS support!)
#        * Strip out flat_json_decoder and use json & dict packages instead.
#        * Strip out tinyurl support. Better to use youtu.be in the response.
#        * Many more data elements supported in response format (possible by new API).
#        * Added possiblity to turn the script on/off on a channel by channel basis.
#        * Added ability to search youtube and return the first result.
#  0.51 09/30/13
#    Small correction for caps in url (but not video id)
#  0.5 01/02/09
#    Added better error reporting for restricted youtube content.
#  0.4 10/11/09
#    Changed title scraping method to use the oembed api.
#    Added crude JSON decoder library.
#  0.3 02/03/09
#    Fixed entity decoding problems in return titles.
#    Added customisable response format.
#    Fixed rare query string bug.
###############################################################################
#
#  Configuration
#
###############################################################################

# API key assigned to your Google account.
# Sadly, everyone will have to register with Google and request their own API key.
# An API key is linked to an IP or mask, so you will need to register one for your own.
# Find detailed instructions above.
set youtube(api_key)           ""

# Base URI for links to youtube videos.
# Either use the normal youtube link or youtu.be for shorter URLs.
# I'd recommend keeping the HTTPS to avoid exposing user data.
set youtube(base_url)          "https://www.youtube.com/watch?v="
#set youtube(base_url)          "https://www.youtu.be/"

# Date/time format
# The format to be used when showing dates, for example in publish date.
# All times are in UTC.
#
# Available tokens:
#   %year%          4 digit year notation
#   %month%         2 digit month notation
#   %day%           2 digit day of the month notation
#   %hours%          2 digit hour notation on a 24hours basis
#   %minutes%       2 digit minutes notation
#   %seconds%       2 digit seconds notation
#
# Example:
#     "%day%/%month%/%year% %hours%:%minutes% UTC"
set youtube(date_format)   "%month%/%day%/%year%"


# Response Formats
# Template of the reply to be send to the channel showing the youtube video details.
# A separate response can be set for replies to a pasted URL or to a query.
#
# Available tokens in the response format:
#   %botnick%       Nickname of bot
#   %poster%        Nickname of person who posted the youtube link
#   %youtube_url%   URL to the youtube link (This may not be the exact same
#                   URL that was posted since it's rewritten based on the format
#                   above to ensure all links posted by the bot are HTTPS.)
#   %id%            ID of the linked youtube video.
#   %author%        Author/Uploader/channel of the video.
#   %title%         Title of youtube link
#   %description%   Description of the video.
#                   (Note that this is generally a VERY long text!)
#   %published%     Date & time the video was published.
#   %views%         The number of times the video has been viewed.
#   %likes%         The number of users who have "liked" the video.
#   %dislikes%      The number of users who have "disliked" the video.
#   %length%        Length of the video.
# Tokens only available in the response to searches (q_resp_format):
#   %query%         The original search string.
#
# Example:
#     "\002YouTube\002: %poster%: %youtube_url% - \"\002%title%\002\" (Uploaded by \"%author%\" on %published%) - Length: %length% - Views: %views%  - Likes / Dislikes: %likes% / %dislikes%"
# The template used when looking up a URL found in the channel
set youtube(response_format)   "\002\00301,00You\00300,04Tube\002\017 - \"\002%title%\002\" by \"%author%\" uploaded on %published% - Length: %length% - Views: %views%  - Likes - %likes% / Dislikes: %dislikes%"
# The template used when replying to a search query.
set youtube(q_resp_format)     "\002\00301,00You\00300,04Tube\002\017 - %youtube_url% - \"\002%title%\002\" by \"%author%\" - Length: %length% - Views: %views%  - Likes - %likes% / Dislikes:  %dislikes%"

# The maximum number of characters from a youtube title to print
set youtube(max_title_length)  64

# The maximum number of characters from a youtube description to print
set youtube(max_desc_length)   128

###############################################################################
#
#  Advanced Configuration
#  !!! DO NOT CHANGE UNLESS YOU KNOW WHAT YOU'RE DOING !!!
#
###############################################################################

# URLs of the youtube V3 API
set youtube(api_get)           "https://www.googleapis.com/youtube/v3/videos"
set youtube(api_search)        "https://www.googleapis.com/youtube/v3/search"

# The groups of properties to be fetched
set youtube(api_part)          "snippet,statistics,contentDetails"

# The fields from the selected property groups that are to be returned
set youtube(api_fields)        "items(id,snippet(publishedAt,title,description,channelTitle),statistics,contentDetails(duration))"

# Maximum time in milliseconds to wait for youtube to respond
set youtube(api_timeout)       "30000"

# Pattern used to patch youtube links in channel public text
set youtube(pattern)           {https{0,1}://.*youtu(?:\.be/|be\..*/watch\?(?:.*)v=)([A-Za-z0-9_\-]+)}

###############################################################################

package require Tcl 8.5
package require http 2.7
package require tls
package require json

# We need HTTPS support for the Google APIs..
# If local IP or host is configured in the main config, use it as the source
# of the outgoing connections.
if { [info exists {my-ip}] == 1 && [string length ${my-ip}] > 0} {
  http::register https 443 [list tls::socket -myaddr ${my-ip}]
} elseif { [info exists {my-hostname}] == 1 && [string length ${my-hostname}] > 0} {
  http::register https 443 [list tls::socket -myaddr ${my-hostname}]
} else {
  http::register https 443 tls::socket
}

set YoutubeTitleVersion "2.0"

setudef flag youtube
bind pubm - * public_youtube
bind pub - !youtube youtube_query
bind pub - !yt youtube_query

###############################################################################

proc note {msg} {
  putlog "% $msg"
}
proc commify {num {sep ,}} {
    while {[regsub {^([-+]?\d+)(\d\d\d)} $num "\\1$sep\\2" num]} {}
    return $num
}
# Ensure strings are no longer then given length. This will cutoff the string
# at the desired length and append '...'.
proc shorten {text maxlen} {
  if { [string length $text] > [expr $maxlen - 1] } {
    set text [string range $text 0 [expr $maxlen - 4]]"..."
  }
  return $text
}

# Convert an ISO8601 date into a more readable format..
proc conv_iso8601_date {orig_date} {
  global youtube
  set pattern {(\d{4})-(0[1-9]|1[0-2])-(0[1-9]|[12]\d{1}|3[012])[T\s](?:(?:([01]\d|2[0-3]):([0-5]\d))|(24):(00)):(?:([0-5]\d)(?:[\.,](\d+))?|(60)(?:[\.,](0+))?)Z}
  if { [regexp $pattern $orig_date match year month day hours minutes hours_2 minutes_2 seconds milliseconds seconds_2 milliseconds_2] } {
    # The hour and hour_2 variables are mutually exclusive, so we append the _2 variables to
    # the original ones to have fewer variables to work with.
    append hours $hours_2
    append minutes $minutes_2
    append seconds $seconds_2

    # Put everything in a dictionary so we can have a configurable time format.
    set tokens [dict create]
    dict set tokens %year% $year
    dict set tokens %month% $month
    dict set tokens %day% $day
    dict set tokens %hours% $hours
    dict set tokens %minutes% $minutes
    dict set tokens %seconds% $seconds

    return [string map $tokens $youtube(date_format)]
  } else {
    error "Unable to process date value ($orig_date) returned by web service."
  }
}

# Convert an ISO8601 duration into a more readable format..
proc conv_iso8601_duration {duration} {
  set length ""
  set pattern {P(?:(\d+)Y)?(?:(\d+)M)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+(?:\.\d+)?)S)?)}
  if { [regexp $pattern $duration match years months days hours minutes seconds] } {
    if { [string length $years] > 0 } {
      append length $years Y " "
    }
    if { [string length $months] > 0 } {
      append length $months M " "
    }
    if { [string length $days] > 0 } {
      append length $days D " "
    }
    if { [string length $hours] > 0 } {
      append length $hours h " "
    }
    if { [string length $minutes] > 0 } {
      append length $minutes m " "
    }
    if { [string length $seconds] > 0 } {
      append length $seconds s " "
    }
  } else {
    error "Unable to process duration value ($duration) returned by web service."
  }
  return [string trim $length]
}

###############################################################################

# Process the reply string of a video lookup from the Youtube API (JSON) and add the
# data to a dictionary containing all tokens the user will be able to use in the template.
proc read_props {json_blob} {
  global youtube
  # Create an empty dictionary for the variables supported in the response format.
  set properties [dict create]

  # Convert the JSON response to a dictionary.
  set reply [json::json2dict $json_blob]

  # The web service returns a list of results, even though our query will always get 1.
  # So we have to take the first element from the list..
  if { ![dict exists $reply items] } {
    error "Error processing web service reply."
  } else {
    set video [lindex [dict get $reply items] 0]

    # Check whether the variables we support in the response are present in the
    # reply from the web service. We check this one by one instead of assuming
    # they exist in case the API changes or someone messes with the requested fields.
    # Properties of the view we extract from reply..
    if { [dict exists $video id] } {
      dict set properties %id% [dict get $video id]
    } else {
      dict set properties %id% ""
    }
    if { [dict exists $video snippet channelTitle] } {
      dict set properties %author% [dict get $video snippet channelTitle]
    } else {
      dict set properties %author% ""
    }
    if { [dict exists $video snippet title] } {
      dict set properties %title% [shorten "[dict get $video snippet title]" $youtube(max_title_length)]
    } else {
      dict set properties %title% ""
    }
    if { [dict exists $video snippet description] } {
      dict set properties %description% [shorten "[dict get $video snippet description]" $youtube(max_desc_length)]]
    } else {
      dict set properties %description% ""
    }
    if { [dict exists $video snippet publishedAt] } {
      dict set properties %published% [conv_iso8601_date [dict get $video snippet publishedAt]]
    } else {
      dict set properties %published% ""
    }
    if { [dict exists $video statistics viewCount] } {
      dict set properties %views% [commify [dict get $video statistics viewCount]]
    } else {
      dict set properties %views% ""
    }
    if { [dict exists $video statistics likeCount] } {
      dict set properties %likes% [commify [dict get $video statistics likeCount]]
    } else {
      dict set properties %likes% ""
    }
    if { [dict exists $video statistics dislikeCount] } {
      dict set properties %dislikes% [commify [dict get $video statistics dislikeCount]]
    } else {
      dict set properties %dislikes% ""
    }
    if { [dict exists $video contentDetails duration] } {
      dict set properties %length% [conv_iso8601_duration [dict get $video contentDetails duration]]
    } else {
      dict set properties %length% ""
    }
  }

  return $properties
}

# Process the reply string of a search query to the Youtube API (JSON) and extract the 
# video id of the first result from the reply.
proc read_searchres {json_blob} {
  global youtube
  # Create an empty dictionary for the variables supported in the response format.
  set video_id ""

  # Convert the JSON response to a dictionary.
  set reply [json::json2dict $json_blob]

  # The web service returns a list of results, even though our query will always get 1.
  # So we have to take the first element from the list..
  if { ![dict exists $reply items] } {
    error "Error processing web service reply."
  } else {
    set res [lindex [dict get $reply items] 0]
    if { [dict exists $res id videoId] } {
      set video_id [dict get $res id videoId]
    }
  }

  return $video_id
}

# Send a request to the youtube API to fetch the video details for
# the video with the given ID.
proc fetch_props {youtube_id} {
  global youtube
  # Ensure an API key has been configured..
  if { [info exists youtube(api_key)] == 0 || [string length $youtube(api_key)] == 0 } {
    error "An API key must be configured to access the Google web API!"
  } else {
    set query [http::formatQuery id $youtube_id key $youtube(api_key) \
      part $youtube(api_part) fields $youtube(api_fields)]
    set response [http::geturl "$youtube(api_get)?$query" -timeout $youtube(api_timeout)]
    upvar #0 $response state
    if [expr [http::ncode $response] == 401] {
      error "Location contained restricted embed data."
    } else {
      set response_body [http::data $response]
      http::cleanup $response
      return [read_props $response_body]
    }
  }
}

# Find the video ID of the first match for the given search.
proc search_video {criteria} {
  global youtube
  # Ensure an API key has been configured..
  if { [info exists youtube(api_key)] == 0 || [string length $youtube(api_key)] == 0 } {
    error "An API key must be configured to access the Google web API!"
  } else {
    set query [http::formatQuery type "video" q $criteria key $youtube(api_key) \
      part "id" fields "items(id(videoId))" maxResults "1"]
    set response [http::geturl "$youtube(api_search)?$query" -timeout $youtube(api_timeout)]
    upvar #0 $response state
    if [expr [http::ncode $response] == 401] {
      error "Location contained restricted embed data."
    } else {
      set response_body [http::data $response]
      http::cleanup $response
      return [read_searchres $response_body]
    }
  }
}

###############################################################################

# This is triggered to analyse ever channel message for the presence of the youtube URL.
# When one is found, the ID is extracted and passed on to get a list of the video properties.
# Finally, this list is used to fill in the tokens in the user defined reply template.
proc public_youtube {nick userhost handle channel args} {
  global youtube botnick

  if { [channel get $channel youtube] && [regexp -nocase -- $youtube(pattern) $args match video_id] } {
    if { [catch {set tokens [fetch_props $video_id]} error] } {
      note "Failed to get video details: $error (querying '$video_id')"
    # If the reply contained an empty ID, we assume we found no video..
    } elseif { [string length [dict get $tokens %id%]] == 0 } {
      putserv "PRIVMSG $channel :Unable to find a youtube video with ID '$video_id'."
    } else {
      dict set tokens %botnick% $botnick
      dict set tokens %poster% $nick
      # Rebuild the URL so we use a url shortener or force SSL
      # in all messages coming from us
      dict set tokens %youtube_url% "$youtube(base_url)$video_id"

      set result [string map $tokens $youtube(response_format)]
      putserv "PRIVMSG $channel :$result" 
    }
  }
}

# This is triggered on !youtube commands.
# Allows turning monitoring on or off by admins.
# All other queries are interpreted as a youtube search.
proc youtube_query {nick userhost handle channel args} {
  global youtube botnick

  # We get a list of arguments, join it to get rid of the curly braces..
  set args [join $args]
  if  { [string length $args] == 0 } {
    if { [channel get $channel youtube] } {
      putserv "PRIVMSG $channel :Syntax: \002!youtube <search criteria>\002 - Search for a video."
    }
    if { [matchattr $handle +mno|+mno $channel] } {
      putserv "NOTICE $nick :Syntax: \002!youtube <on/off>\002 - Turn youtube link lookups on/off."
    }
  } elseif { [matchattr $handle +mno|+mno $channel] && ([string compare $args "on"] == 0 \
      || [string compare $args "off"] == 0) } {
    if { ![channel get $channel youtube] && [string compare $args "on"] == 0 } {
      channel set $channel +youtube
      putserv "NOTICE $nick :YoutubeTitleV2: enabled on $channel"
      note "YoutubeTitleV2: Monitoring enabled by $nick for $channel."
    } elseif { [channel get $channel youtube] && [string compare $args "off"] == 0 } {
      channel set $channel -youtube
      putserv "NOTICE $nick :YoutubeTitleV2: disabled on $channel"
      note "YoutubeTitleV2: Monitoring disabled by $nick for $channel."
    }
  # The magic number comes from the length of the string "cat".. ;)
  } elseif { [channel get $channel youtube] && [string length $args] < 3 } {
    putserv "PRIVMSG $channel :Search criteria must be at least 3 characters long."
  } elseif { [channel get $channel youtube] } {
    # Search a video...
    # Note that we have to do 2 requests: one to fetch search results (id)
    # and a second to get video details. This is caused by the youtube API 
    # not being capable of returning details in the search functions.
    if { [catch { set video_id [search_video $args] } error ] } {
      note "Failed to find a video: $error (searching for '$args')."
    # If the reply contained an empty ID, we assume we found no video..
    } elseif { [string length $video_id] == 0 } {
      putserv "PRIVMSG $channel :Unable to find a youtube video matching search '$args'" 
    # We have the video id, now find the properties..
    } elseif { [catch {set tokens [fetch_props $video_id]} error] } {
      note "Failed to get video details: $error (searching for '$args' and found '$video_id')."
    # If the reply contained an empty ID, we assume we found no video..
    } elseif { [string length [dict get $tokens %id%]] == 0 } {
      putserv "PRIVMSG $channel :Unable to fetch the video details of '$video_id' for the search result '$args'"
    } else {
      dict set tokens %botnick% $botnick
      dict set tokens %poster% $nick
      dict set tokens %query% $args
      # Rebuild the URL so we use a url shortener or force SSL
      # in all messages coming from us
      dict set tokens %youtube_url% "$youtube(base_url)$video_id"

      set result [string map $tokens $youtube(q_resp_format)]
      putserv "PRIVMSG $channel :$result" 
    }
  }
}

###############################################################################

note "YoutubeTitleV2 Version $YoutubeTitleVersion: loaded";
