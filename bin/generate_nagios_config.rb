#!/usr/bin/env ruby
$:.unshift(File.expand_path("../../lib", __FILE__))

require "rubygems"
require 'bosh_helper'
require 'string_helper'
require 'erb'
require 'config'
require 'optparse'
require 'json'

@vms = Uhuru::BOSHHelper.get_vms


@deployments = @vms.map { |vm| { :name => vm['deployment'].gsub(' ', '_').downcase , :description => vm['deployment'] } }.uniq!

# cache IPs and intersect with Database information

@hosts = []

@vms.each do |vm|
  if !vm['job_name'].nil?
    host = {}
    host[:deployment] = vm['deployment']
    host[:name] = vm['job_name'] != nil ? "#{vm['deployment']}_#{vm['job_name']}_#{vm['index']}" : "#{vm['deployment']}_#{vm['ips'][0]}"
    host[:alias] = "#{Uhuru::StringHelper.humanize(host[:name].gsub(/-/, "_")).split(' ').map {|w| w.capitalize }.join(' ') }"
    host[:address] = vm['ips'][0]
    host[:component] = vm['job_name']
    host[:index] = vm['index']
    host[:os] = ['mssql_node', 'win_dea', 'uhurufs_node', 'uhuru_tunnel'].include?(host[:component]) ? "windows" : "linux"
    if host[:address] != nil && host[:address].size > 0
      @hosts << host
    end
  end
end

if $config['legacy']['enabled'] == true
  $config['legacy']['machines'].each {|machine|
    host = {}
    host[:deployment] = machine['deployment']
    host[:name] = machine['name']
    host[:alias] = machine['alias']
    host[:address] = machine['address']
    host[:component] = machine['component']
    host[:index] = machine['index']
    host[:os] = machine['os']
    if host[:address] != nil && host[:address].size > 0
      @hosts << host
    end
  }
end

@services = []

$states.each do |os, components|
  components.each do |component, metrics|
    if @hosts.any? {|host| host[:component] == component } || (component ==  "base" && @hosts.any? {|host| host[:os] == os })
      metrics.each do |metric, metric_data|
        service = {}
        service[:name] = "#{os}_#{component}_#{metric}"
        service[:hostgroup] = component == 'base' ? os : component
        service[:description] = Uhuru::StringHelper.humanize("#{os}_#{component}_#{metric}").split(' ').map {|w| w.capitalize}.join(' ')
        service[:os] = os
        service[:component] = component
        service[:warn] = 80
        service[:critical] = 90
        service[:metric] = metric
        service[:mu] = metric_data[:mu]
        if(metric_data[:max] != nil)
          service[:has_max] = true
        else
          service[:has_max] = false
        end
        service
        @services << service
      end
    end
  end
end


@command_path = File.expand_path("../../bin/get_metric.sh", __FILE__)
@check_host_path = File.expand_path("../../bin/check_host.sh", __FILE__)
@send_mail_path = File.expand_path("../../bin/send_mail.sh", __FILE__)

old_hosts = []
if File.exist? File.expand_path("../../config/hosts", __FILE__)
  buffer = File.open(File.expand_path("../../config/hosts", __FILE__)).read
  old_hosts = JSON.parse(buffer, :symbolize_names => true)
end

old_services = []
if File.exist? File.expand_path("../../config/services", __FILE__)
 buffer = File.open(File.expand_path("../../config/services", __FILE__)).read
 old_services = JSON.parse(buffer, :symbolize_names => true)
end

FileUtils.cp(File.expand_path("../../config/uhuru-hosts.cfg", __FILE__), File.expand_path("../../config/uhuru-hosts.cfg.old", __FILE__))

if (@hosts - old_hosts != []) or (old_hosts - @hosts != []) or (old_services - @services != []) or (@services - old_services != [])
  template = ERB.new File.open(File.expand_path("../../config/uhuru-hosts.cfg.erb", __FILE__)).read

  File.open(File.expand_path("../../config/uhuru-hosts.cfg", __FILE__), "w") do |file|
    file.write(template.result(binding))
  end
  File.open(File.expand_path("../../config/hosts", __FILE__), "w") do |file|
    file.write(@hosts.to_json)
  end
  File.open(File.expand_path("../../config/services", __FILE__), "w") do |file|
    file.write(@services.to_json)
  end

end