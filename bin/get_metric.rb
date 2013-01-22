#!/usr/bin/env ruby
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../Gemfile", __FILE__)
$:.unshift(File.expand_path("../../lib", __FILE__))

require "rubygems"
require 'bundler/setup'
require 'bosh_helper'
require 'net/ssh'
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
    user = rand(36**9).to_s(36)
    password = rand(36**9).to_s(36)
    sshkey = File.open(File.expand_path("../../config/sshkey.pub", __FILE__)).read

    if os == 'windows' && $config['legacy']['enabled'] == true
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
    else
      begin
        Uhuru::BOSHHelper.open_ssh(deployment, job, index, sshkey, user, password )
      rescue Exception => e
        raise "Cannot open SSH\n#{e.message}"
      end


      begin
        filemode = ARGV[5] == '--onscreen' ? "r" : "w"

        File.open(File.expand_path(datafile, __FILE__), filemode) do |file|
          Net::SSH.start(ip, "bosh_#{user}", :password => password, :keys => [File.expand_path("../../config/sshkey", __FILE__)] ) do |ssh|
            ['base', job].each { |group|
              value = ssh.exec!("echo #{password} | sudo -S ps")
              unless $config[os][group] == nil
                $config[os][group].each { |script_name, script|
                  value = ssh.exec!("sudo bash -c \"#{script}\"")
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
        raise "SSH Connection Failed\n#{e.message}"
      end

      begin
        Uhuru::BOSHHelper.stop_ssh(deployment, job, index, user)
      rescue Exception => e
        raise "Cannot close SSH\n#{e.Message}"
      end
    end
    output = "Status is OK"
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
        output = "#{metric} is #{metric_value}|#{metric}=#{metric_value}#{metric_mu}"
        exitcode = 0
      else

        if metric_max.is_a? Proc
          metric_max = metric_max[data]
        end

        critical = (metric_max / 100) * metric_critical
        warning = (metric_max / 100) * metric_warn

        pct = (metric_value / metric_max) * 100

        if metric_mu == '%'
          performance = "|#{metric}=#{metric_value}#{metric_mu};#{warning};#{critical}"
        else
          performance = "|#{metric}=#{metric_value}#{metric_mu};#{warning};#{critical};0;#{metric_max}"
        end

        if pct > metric_critical
          output = "CRITICAL - Metric #{metric} is above #{metric_critical}%#{performance}"
          exitcode = 2
        elsif pct > metric_warn
          output = "WARN - Metric #{metric} is above #{metric_warn}%#{performance}"
          exitcode = 1
        else
          output = "Metric #{metric} is OK#{performance}"
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