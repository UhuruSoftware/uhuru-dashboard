require "net/ssh"
require "net/sftp"
require "uuidtools"

module Uhuru
  class SSHHelper
    def self.execute(host, user, password, commands)
      @out = ''
      @ran = false
      @mutex = Mutex.new
      @run_id = UUIDTools::UUID.random_create.to_s

      @regex_prompt = />\e\[\d+([mJ]|(;\d+f))\Z/
      @regex_ansi = /\e\[\d+([mJ]|(;\d+f))/

      @execute = ''

      commands.each do |key, command|
        command_before = "echo _____KEY:#{key}_____ >> #{@run_id} & "
        command_after = " >> #{@run_id} & "

        @execute << "#{command_before}#{command}#{command_after}"
      end

      @execute = "#{@execute}exit\r\n"

      @execute_delete = "del #{@run_id} & exit\r\n"

      Net::SSH.start( host, user, :password => password ) do |ssh|
        ssh.open_channel do |channel|
          channel.request_pty do |ch, success|
            if success
              ch.on_data do |ch2, data|
                @mutex.synchronize do
                  @out << data
                  if @out =~ @regex_prompt
                    unless @ran
                      @ran = true
                      ch2.send_data @execute
                    end
                  end
                end
              end
            else
              puts "could not obtain pty"
            end
          end
        end
      end

      @out = ''
      @ran = false

      include Net

      data = ''
      SFTP.start( host, user, :password => password ) do |sftp|
        data = sftp.download!(@run_id)
      end

      Net::SSH.start( host, user, :password => password ) do |ssh|
        ssh.open_channel do |channel|
          channel.request_pty do |ch, success|
            if success
              ch.on_data do |ch2, data|
                @mutex.synchronize do
                  @out << data
                 if @out =~ @regex_prompt
                    unless @ran
                      @ran = true
                      ch2.send_data @execute_delete
                    end
                  end
                end
              end
            else
              puts "could not obtain pty"
            end
          end
        end
      end

      data.gsub @regex_ansi, ""
    end
  end
end
