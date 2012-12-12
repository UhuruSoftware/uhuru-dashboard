#!/usr/bin/env ruby

$:.unshift(File.expand_path("../../lib", __FILE__))

require "rubygems"
require 'bundler/setup'

require 'bosh_helper'
require 'string_helper'
require 'erb'

require 'config'


@vms = Uhuru::BOSHHelper.get_vms


@deployments = @vms.map { |vm| { :name => vm['deployment'].gsub(' ', '_').downcase , :description => vm['deployment'] } }.uniq!

# cache IPs and intersect with Database information

@hosts = []

@vms.each do |vm|
  host = {}
  host[:deployment] = vm['deployment']
  host[:name] = vm['job_name'] != nil ? "#{vm['deployment']}_#{vm['job_name']}_#{vm['index']}" : "#{vm['deployment']}_#{vm['ips'][0]}"
  host[:alias] = "#{Uhuru::StringHelper.humanize(host[:name].gsub(/-/, "_")).split(' ').map {|w| w.capitalize }.join(' ') }"
  host[:address] = vm['ips'][0]
  host[:component] = vm['job_name']
  host[:index] = vm['index']
  host[:os] = ['mssql_node', 'windea', 'uhurufs_node'].include?(host[:component]) ? "windows" : "linux"
  if host[:address] != nil && host[:address].size > 0
    @hosts << host
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
        #service[:servicegroups] = ["Cloud Foundry Metrics"]
        service[:os] = os
        service[:component] = component
        service[:warn] = 80
        service[:critical] = 90
        service[:metric] = metric
        service[:mu] = metric_data[:mu]
        service
        @services << service
      end
    end
  end
end


@command_path = File.expand_path("bin/get_metric.sh")

template = ERB.new File.open(File.expand_path("../../config/uhuru-hosts.cfg.erb", __FILE__)).read

File.open(File.expand_path("../../config/uhuru-hosts.cfg", __FILE__), "w") do |file|
  file.write(template.result(binding))
end

template = ERB.new File.open(File.expand_path("../../config/uhuru-ngraph.ncfg.erb", __FILE__)).read

File.open(File.expand_path("../../config/uhuru-ngraph.ncfg", __FILE__), "w") do |file|
  file.write(template.result(binding))
end


