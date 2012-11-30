require 'net/ssh'
require 'yaml'

config = YAML.load File.open(File.expand_path("../../config/uhuru-dashboard.yml", __FILE__))

metric = ARGV[0] #'cpu'
component = 'dea'
ip = "199.16.201.151"
outfile = "../../data/#{ip}.yml"
user = 'root'
password = 'password1234!'

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
        :value => /:.*us/.match(data['cpu_time'])[0].gsub(/(:)|(%us)/, '').strip!
    }
  when "physical_ram"
    {
        :mu => 'MB',
        :min => 0,
        :max => /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!,
        :value => /Mem:\s*\d*\s*\d*\s*\d*/.match(data['system_info'])[0].split(/\s+/)[2]
    }
  when "cached_ram"
    {
        :mu => 'MB',
        :min => 0,
        :max => /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!,
        :value => /Mem:\s*\d*\s*\d*\s*\d*\s*\d*\s*\d*\s*\d*/.match(data['system_info'])[0].split(/\s+/)[6]
    }
  when "swap_ram"
    {
        :mu => 'MB',
        :min => 0,
        :max => /Swap:\s*\d*/.match(data['system_info'])[0]/gsub(/Swap:/, '').strip!,
        :value => /Swap:\s*\d*\s*\d*\s*\d*/.match(data['system_info'])[0].split(/\s+/)[2]
    }
  when "system_disk"
    {
        :mu => 'GB',
        :min => 0,
        :max => /\/dev\/sda1\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1],
        :value => /\/dev\/sda1\s*\S*\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[2]
    }
  when "ephemeral_disk"
    {
        :mu => 'GB',
        :min => 0,
        :max => /\/dev\/sdb2\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1],
        :value => /\/dev\/sdb2\s*\S*\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[2]
    }
  when "persistent_disk"
    {
        :mu => 'GB',
        :min => 0,
        :max => /\/dev\/sdc1\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1],
        :value => /\/dev\/sdc1\s*\S*\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[2]
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
end

puts base.inspect
specific = case component
  when 'dea'
    case metric
      when "droplets_on_disk"
        {
            :min => 0,
            :max => 100,
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
            :max => data['system_info'].scan(/Mem:\s*\d*/)[0].gsub(/(Mem:)/, '').strip!,
            :value => data['workerprocessesmemory'].scan(/\d*\s*\d*\s*\?[^(\r|\n)]+\/var\/vcap\/data\/dea\/apps/).map {|x| x.split(/\s+/)[0].to_i }.inject {|sum, x| sum += x}
        }
      when "dea_service_memory"
        {
            :mu => 'KB',
            :min => 0,
            :max => data['system_info'].scan(/Mem:\s*\d*/)[0].gsub(/(Mem:)/, '').strip!,
            :value => data['deaprocessmemory'].scan(/\d*\s*\d*\s*\?[^(\r|\n)]+dea.yml/)[0].split(/\s+/)[0]
        }
      when "dea_provisionable_memory"
        {
            :min => 0,
            :max => data['config'].scan(/max_memory:\s*\d*/)[0].split(/\s+/)[1],
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
            :mu => '%',
            :min => 0,
            :max => 100,
            :value => 12
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
            :value => 12
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
            :mu => '%',
            :min => 0,
            :max => 100,
            :value => 12
        }
    end
  when 'postgresql_node'
    case metric
      when "services_on_disk"
        {
            :mu => '%',
            :min => 0,
            :max => 100,
            :value => 12
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
            :value => 12
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
            :mu => '%',
            :min => 0,
            :max => 100,
            :value => 12
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
            :value => 12
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
            :mu => '%',
            :min => 0,
            :max => 100,
            :value => 12
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
            :value => 12
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
            :mu => '%',
            :min => 0,
            :max => 100,
            :value => 12
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
            :value => 12
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

puts specific