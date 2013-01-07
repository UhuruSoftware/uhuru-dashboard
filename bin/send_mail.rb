#!/usr/bin/env ruby
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../Gemfile", __FILE__)
$:.unshift(File.expand_path("../../lib", __FILE__))

require 'email'

type              = ARGV[0]    # host or service
notificationtype  = ARGV[1]    # NOTIFICATIONTYPE
name              = ARGV[2]    # HOSTNAME
state             = ARGV[3]    # HOSTSTATE / SERVICESTATE
hostaddress       = ARGV[4]    # HOSTADDRESS
output            = ARGV[5]    # HOSTOUTPUT / SERVICEOUTPUT
date              = ARGV[6]    # LONGDATETIME
email             = ARGV[7]    # CONTACTEMAIL
servicedesc       = ARGV[8]    # SERVICEDESC

if type == "host"
  body = <<END_OF_BODY
***** Nagios *****
Notification Type: #{notificationtype}
Host: #{name}
State: #{state}
Address: #{hostaddress}
Info: #{output}

Date/Time: #{date}
END_OF_BODY

  subject = "** #{notificationtype} Host Alert: #{name} is #{state} **"

elsif type == "service"
  body = <<END_OF_BODY
***** Nagios *****
Notification Type: #{notificationtype}
Service: #{servicedesc}
Host: #{name}
Address: #{hostaddress}
State: #{state}

Date/Time: #{date}

Additional Info:
#{output}
END_OF_BODY

  subject = "** #{notificationtype} Service Alert: #{name}/#{servicedesc} is #{state} **"
end


Uhuru::Email.send_email(email, subject, body)