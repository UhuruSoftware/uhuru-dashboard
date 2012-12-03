#!/usr/bin/env ruby
require "rubygems"
require 'bundler/setup'
require 'net/ssh'
require 'yaml'

config = YAML.load File.open(File.expand_path("../../config/uhuru-dashboard.yml", __FILE__))

os =          ARGV[0] # linux
ip =          ARGV[1] #"199.16.201.151"
component =   ARGV[2] # dea
metric =      ARGV[3] # cpu
warn =        ARGV[4].to_f # 80
critical =    ARGV[5].to_f # 90
user =        ARGV[6] # root
password =    ARGV[7] # password1234!
ip =
outfile =     "../../data/#{ip}.yml"

data = nil
unless metric == 'status'
  data = YAML.load File.open(File.expand_path(outfile, __FILE__))
end


base = case metric
  when "cpu"
    {
        :mu => '%',
        :min => 0,
        :max => 100,
        :value => /:.*us/.match(data['cpu_time'])[0].gsub(/(:)|(%us)/, '').strip!.to_f
    }
  when "physical_ram"
    {
        :mu => 'MB',
        :min => 0,
        :max => /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f,
        :value => /Mem:\s*\d*\s*\d*\s*\d*/.match(data['system_info'])[0].split(/\s+/)[2].to_f
    }
  when "cached_ram"
    {
        :mu => 'MB',
        :min => 0,
        :max => /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f,
        :value => /Mem:\s*\d*\s*\d*\s*\d*\s*\d*\s*\d*\s*\d*/.match(data['system_info'])[0].split(/\s+/)[6].to_f
    }
  when "swap_ram"
    {
        :mu => 'MB',
        :min => 0,
        :max => /Swap:\s*\d*/.match(data['system_info'])[0]/gsub(/Swap:/, '').strip!.to_f,
        :value => /Swap:\s*\d*\s*\d*\s*\d*/.match(data['system_info'])[0].split(/\s+/)[2].to_f
    }
  when "system_disk"
    {
        :mu => 'GB',
        :min => 0,
        :max => /\/dev\/sda1\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f,
        :value => /\/dev\/sda1\s*\S*\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[2].to_f
    }
  when "ephemeral_disk"
    {
        :mu => 'GB',
        :min => 0,
        :max => /\/dev\/sdb2\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f,
        :value => /\/dev\/sdb2\s*\S*\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[2].to_f
    }
  when "persistent_disk"
    {
        :mu => 'GB',
        :min => 0,
        :max => /\/dev\/sdc1\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f,
        :value => /\/dev\/sdc1\s*\S*\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[2].to_f
    }
  when "component" then {
      :value => data['component_info'].strip!}
  when 'status'
    File.open(File.expand_path(outfile, __FILE__), "w") do |file|
      Net::SSH.start(ip, user, {:password => password, :port => 60778 }) do |ssh|

        ['base', component].each { |group|
          config['linux'][group].each { |script_name, script|
            value = ssh.exec!(script)
            file.write "#{script_name}: |\n  ---\n"
            value.lines.each {|line| file.write "  #{line}"}
          }
        }
      end
    end
    {:value => "OK"}
end

if base == nil
  base = case component
           when 'dea'
             case metric
               when "droplets_on_disk"
                 {
                     :value => data['dropletcountfolder'].scan(/vcap-user/).size
                 }
               when "worker_processes_count"
                 {
                     :value => data['workerprocessesiiscount'].scan(/\/var\/vcap\/data\/dea\/apps/).size
                 }
               when "worker_processes_memory"
                 {
                     :mu => 'KB',
                     :min => 0,
                     :max => data['system_info'].scan(/Mem:\s*\d*/)[0].gsub(/(Mem:)/, '').strip!.to_f,
                     :value => data['workerprocessesmemory'].scan(/\d*\s*\d*\s*\?[^(\r|\n)]+\/var\/vcap\/data\/dea\/apps/).map {|x| x.split(/\s+/)[0].to_i }.inject {|sum, x| sum += x}
                 }
               when "dea_service_memory"
                 {
                     :mu => 'KB',
                     :min => 0,
                     :max => data['system_info'].scan(/Mem:\s*\d*/)[0].gsub(/(Mem:)/, '').strip!.to_f,
                     :value => data['deaprocessmemory'].scan(/\d*\s*\d*\s*\?[^(\r|\n)]+dea.yml/)[0].split(/\s+/)[0].to_f
                 }
               when "dea_provisionable_memory"
                 {
                     :min => 0,
                     :max => data['config'].scan(/max_memory:\s*\d*/)[0].split(/\s+/)[1].to_f,
                     :value => data['dropletdata'].scan(/"mem_quota":\s*\d*/).map {|x| x.split(/\s+/)[1].to_i }.inject {|sum, x| sum += x}
                 }
               when "dea_droplets"
                 {
                     :value => data['dropletdata'].scan(/"droplet_id"/).size
                 }
             end
           when 'mysql_node'
             case metric
               when "services_on_disk"
                 {
                     :value => data['databasesondrive'].scan(/\d*\s*d\w{32}/)[0].size
                 }
               when "provisioned_services"
                 {
                     :value => data['servicedb'].scan(/d\w{33}/)[0].size
                 }
               when "services_disk_size"
                 {
                     :mu => '%',
                     :min => 0,
                     :max => 100,
                     :value => val[0] = data['databasesondrive'].scan(/\d*\s*\d*-\d*-\d*\s*\d\d:\d\d\s*d\w{32}/).map {|x| x.split(/\s+/)[0].to_i}.inject {|sum, x| sum += x}

                 }
               when "mysql_server_memory"
                 {
                     :mu => '%',
                     :min => 0,
                     :max => 100,
                     :value => 12
                 }
               when "mysql_node_memory"
                 {
                     :value => data['databasesondrive'].scan(/\d\s+\d\w{5}/)[0].size
                 }
             end
           when 'postgresql_node'
             case metric
               when "services_on_disk"
                 {
                     :value => data['databasesondrive'].scan(/\w{4}-\w{2}-\w{2}/)[0].size
                 }
               when "provisioned_services"
                 {
                     :mu => '%',
                     :min => 0,
                     :max => 100,
                     :value => 12
                 }
               when "services_disk_size"
                 {
                     :mu => '%',
                     :min => 0,
                     :max => 100,
                     :value => val[0] = data['databasesondrive'].scan(/\d*\s*\d*-\d*-\d*\s*\d\d:\d\d\s*\w{8}\-\w{4}/).map {|x| x.split(/\s+/)[0].to_i}.inject {|sum, x| sum += x}
                 }
               when "postgresql_server_memory"
                 {
                     :mu => '%',
                     :min => 0,
                     :max => 100,
                     :value => 12
                 }
               when "postgresql_node_memory"
                 {
                     :mu => '%',
                     :min => 0,
                     :max => 100,
                     :value => 12
                 }
             end
           when 'mongodb_node'
             case metric
               when "services_on_disk"
                 {
                     :value => data['databasesondrive'].scan(/\w{8}-\w{4}-\w{4}/)[0].size
                 }
               when "provisioned_services"
                 {
                     :value => data['servicedb'].scan(/d\w{33}/)[0].size
                 }
               when "services_disk_size"
                 {
                     :mu => '%',
                     :min => 0,
                     :max => 100,
                     :value => val[0] = data['databasesondrive'].scan(/\d*\s*\d*-\d*-\d*\s*\d\d:\d\d\s*\w{8}\-\w{4}/).map {|x| x.split(/\s+/)[0].to_i}.inject {|sum, x| sum += x}
                 }
               when "mongodb_server_memory"
                 {
                     :mu => '%',
                     :min => 0,
                     :max => 100,
                     :value => 12
                 }
               when "mongodb_node_memory"
                 {
                     :mu => '%',
                     :min => 0,
                     :max => 100,
                     :value => 12
                 }
             end
           when 'redis_node'
             case metric
               when "services_on_disk"
                 {
                     :value => data['databasesondrive'].scan(/\w{8}-\w{4}-\w{4}/)[0].size
                 }
               when "provisioned_services"
                 {
                     :value => data['servicedb'].scan(/d\w{33}/)[0].size
                 }
               when "services_disk_size"
                 {
                     :mu => '%',
                     :min => 0,
                     :max => 100,
                     :value => val[0] = data['databasesondrive'].scan(/\d*\s*\d*-\d*-\d*\s*\d\d:\d\d\s*\w{8}\-\w{4}/).map {|x| x.split(/\s+/)[0].to_i}.inject {|sum, x| sum += x}
                 }
               when "redis_server_memory"
                 {
                     :mu => '%',
                     :min => 0,
                     :max => 100,
                     :value => 12
                 }
               when "redis_node_memory"
                 {
                     :mu => '%',
                     :min => 0,
                     :max => 100,
                     :value => 12
                 }
             end
           when 'rabbitmq_node'
             case metric
               when "services_on_disk"
                 {
                     :value => data['databasesondrive'].scan(/\w{8}-\w{4}-\w{4}/)[0].size
                 }
               when "provisioned_services"
                 {
                     :value => data['servicedb'].scan(/d\w{33}/)[0].size
                 }
               when "services_disk_size"
                 {
                     :mu => '%',
                     :min => 0,
                     :max => 100,
                     :value => val[0] = data['databasesondrive'].scan(/\d*\s*\d*-\d*-\d*\s*\d\d:\d\d\s*\w{8}\-\w{4}/).map {|x| x.split(/\s+/)[0].to_i}.inject {|sum, x| sum += x}
                 }
               when "rabbitmq_server_memory"
                 {
                     :mu => '%',
                     :min => 0,
                     :max => 100,
                     :value => 12
                 }
               when "rabbitmq_node_memory"
                 {
                     :mu => '%',
                     :min => 0,
                     :max => 100,
                     :value => 12
                 }
             end
         end
end

if base == nil || base[:value] == nil
  exit 3
end

if base[:max] == nil
  puts "#{metric} is #{base[:value]}"
  exit 0
else
  pct = (base[:value] / base[:max]) * 100

  performance = "|#{metric}=#{base[:value]}#{base[:mu]}, max=#{base[:max]}#{base[:mu]}, pct=#{pct}%"

  if pct > critical
    puts "CRITICAL - Metric #{metric} is above #{critical}%#{performance}"
    exit 2
  elsif pct > warn
    puts "WARN - Metric #{metric} is above #{warn}%#{performance}"
    exit 1
  else
    puts   "Metric #{metric} is OK#{performance}"
    exit 0
  end

end
