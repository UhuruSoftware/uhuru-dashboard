require 'net/smtp'
require 'rfc822'
require 'config'

module Uhuru
  class Email

    def self.validate_email(email)
      RFC822::EmailFormat.match(email)
    end

    def self.send_email(subject, body)

      to_email = $config['alerts']['email_to']

      msg = <<END_OF_MESSAGE
From: #{$config['email']['from_alias']} <#{$config['email']['from']}>
To: <#{to_email}>
Subject: #{subject}
MIME-Version: 1.0
Content-type: text/plain

#{body}
END_OF_MESSAGE

      client = Net::SMTP.new(
          $config['email']['server'],
          $config['email']['port'])


      if $config['email']['enable_tls']
        client.enable_starttls
      end


      client.start(
          "localhost",
          $config['email']['user'],
          $config['email']['secret'],
          $config['email']['auth_method']) do

        client.send_message msg, $config['email']['from'], to_email
      end
    end
  end
end