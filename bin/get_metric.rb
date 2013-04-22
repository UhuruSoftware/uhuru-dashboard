#!/usr/bin/env ruby
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../Gemfile", __FILE__)
$:.unshift(File.expand_path("../../lib", __FILE__))

require 'config'

os =                ARGV[0] # linux
ip =                ARGV[1] # "199.16.201.151"
service_component = ARGV[2] # dea
metric =            ARGV[3] # cpu
hostname =          ARGV[4] # cloud_foundry_mongodb_gateway_0
deployment =        ARGV[5] # cloud_foundry
job =               ARGV[6] # mongodb_gateway
index =             ARGV[7] # 0

datafile =     File.expand_path(File.join($config['data_dir'],"#{ip}.yml"), __FILE__)

begin
  if metric == 'status'

    require 'bundler/setup'

    require 'net/ssh'

    if os == 'windows'
      if $config['legacy']['enabled'] == true
        if $config['legacy']['machines'].any? {|machine| machine["address"].include? ip}
          winexebin = File.expand_path('../../bin/winexe', __FILE__)

          filemode = ARGV[5] == '--onscreen' ? "r" : "w"

          File.open(File.expand_path(datafile, __FILE__), filemode) do |file|

            ['base', job].each { |group|
              unless $config[os][group] == nil
                $config[os][group].each { |script_name, script|
                  value = `#{winexebin} -U #{$config['legacy']['user']} --password="#{$config['legacy']['password']}" //#{ip} 'cmd /C #{script}'`
                  file.write "#{script_name}: |\n  ---\n"
                  if !value.nil?
                    value.lines.each {|line| file.write "  #{line}"}
                  end
                  file.write "\n"
                }
              end
            }
          end
        end
      else
        require "ssh_helper"
        require 'bosh_helper'

        user, password = Uhuru::BOSHHelper.setup_ssh_user(deployment, job, index, ip)

        begin
          regex = /_{5}KEY:(.+)_{5}/
          filemode = ARGV[5] == '--onscreen' ? "r" : "w"

          File.open(File.expand_path(datafile, __FILE__), filemode) do |file|

            ['base', job].each { |group|
              unless $config[os][group] == nil
                win_output = Uhuru::SSHHelper.execute(ip, "bosh_#{user}", password, $config[os][group])
                values = win_output.scan(regex)
                values.each_with_index do |key, index|
                  next_element = values[index+1]
                  if next_element.nil?
                    value = win_output.scan(/_{5}KEY:#{key[0]}_{5}(.*?)\z/m).flatten[0]
                  else
                    value = win_output.scan(/_{5}KEY:#{key[0]}_{5}(.*?)_{5}KEY:#{next_element[0]}_{5}/m).flatten[0]
                  end
                  file.write "#{key[0]}: |\n  ---\n"
                  if !value.nil?
                    value.lines.each {|line| file.write "  #{line}"}
                  end
                  file.write "\n"
                end
              end
            }
          end
        rescue Exception => e
          Uhuru::BOSHHelper.delete_user(user, deployment, job, index, ip)
          raise "SSH Connection Failed\n#{e.message}:#{e.backtrace}"
        end
      end

    else
      require 'bosh_helper'
      user, password = Uhuru::BOSHHelper.setup_ssh_user(deployment, job, index, ip)

      begin
        filemode = ARGV[5] == '--onscreen' ? "r" : "w"

        File.open(File.expand_path(datafile, __FILE__), filemode) do |file|
          Net::SSH.start(ip, "bosh_#{user}", :password => password, :keys => [File.expand_path("../../config/sshkey", __FILE__)] ) do |ssh|

            ['base', job].each { |group|
              value = ssh.exec!("echo #{password} | sudo -S ps")
              unless $config[os][group] == nil
                $config[os][group].each { |script_name, script|
                  value = ssh.exec!("sudo bash -c \'#{script}\'")
                  if ARGV[5] == '--onscreen'
                    puts "#{script_name}: |\n  ---\n"
                    if !value.nil?
                      value.lines.each {|line| puts "  #{line}"}
                    end
                    $stdout.flush
                  else
                    file.write "#{script_name}: |\n  ---\n"
                    if !value.nil?
                      value.lines.each {|line| file.write "  #{line}"}
                    end
                    file.write "\n"
                  end
                }
              end
            }
          end
        end

      rescue Exception => e
        Uhuru::BOSHHelper.delete_user(user, deployment, job, index, ip)
        raise "SSH Connection Failed\n#{e.message}:#{e.backtrace}"
      end
    end
    output = "[#{ip}] Status is OK"
    exitcode = 0
  else
    if File.exist?(datafile)
      component = service_component

      metrics = $states[os][component]
      if metrics == nil
        raise "No metrics defined for this component #{os}/#{component}"
      end

      metric_hash = metrics[metric]

      if metric_hash == nil
        raise "Metric definition does not exist #{os}/#{component}/#{metric}"
      end

      data = YAML.load File.open(File.expand_path(datafile, __FILE__))

      metric_value = metric_hash[:value]
      metric_max = metric_hash[:max]
      metric_mu = metric_hash[:mu]
      metric_warn = metric_hash[:warn]
      metric_critical = metric_hash[:critical]

      metric_warn ||= $config['default_warn_level']
      metric_critical ||= $config['default_critical_level']


      if metric_value == nil
        raise "Metric does not have a value definition"
      end

      if metric_value.is_a? Proc
        begin
          metric_value = metric_value[data]
        rescue Exception => e
          puts "Data not found\n#{e.message}\n#{e.backtrace}"
          $stdout.flush
          exit! 3
        end
      end

      if metric_max == nil
        output = "#{metric_value}|#{metric}=#{metric_value}#{metric_mu}"
        exitcode = 0

        if metric_mu == 'state'
          accepted_values = metric_hash[:accepted_values]
          output = metric_value
          if accepted_values.include? metric_value
            exitcode = 0
          else
            exitcode = 2
          end
        end
      else

        if metric_max.is_a? Proc
          begin
            metric_max = metric_max[data]
          rescue Exception => e
            puts "Data not found\n#{e.message}\n#{e.backtrace}"
            $stdout.flush
            exit! 3
          end
        end

        critical = (metric_max / 100) * metric_critical
        warning = (metric_max / 100) * metric_warn

        pct = (metric_value / metric_max) * 100

        if metric_mu == '%'
          performance = "|#{metric}=#{"%.3f" % metric_value}#{metric_mu};#{"%.3f" % warning};#{"%.3f" % critical}"
          info = "[#{metric_value}#{metric_mu}]"
        else
          performance = "|#{metric}=#{"%.3f" % metric_value}#{metric_mu};#{"%.3f" % warning};#{"%.3f" % critical};0;#{"%.3f" % metric_max}"
          info = "[#{"%.3f" % metric_value}#{metric_mu} / #{"%.3f" % metric_max}#{metric_mu}]"
        end

        if pct > metric_critical
          output = "#{info} Metric #{metric} is above #{metric_critical}%#{performance}"
          exitcode = 2
        elsif pct > metric_warn
          output = "#{info} Metric #{metric} is above #{metric_warn}%#{performance}"
          exitcode = 1
        else
          output = "#{info} Metric #{metric} is OK#{performance}"
          exitcode = 0
        end
      end
    else
      output = "Status data file not present"
      exitcode = 3
    end
  end
rescue Exception => e
  output = "#{e.message} \n #{e.backtrace} \n #{ ARGV.join(', ') }"
  exitcode = 2
end

puts output
$stdout.flush
exit! exitcode