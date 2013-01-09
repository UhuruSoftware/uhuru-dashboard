require 'yaml'

$config = YAML.load File.open(File.expand_path("../../config/uhuru-dashboard.yml", __FILE__))


$states = {
    "linux" => {
        "base" =>  {
            "cpu" => {
                :mu => '%',
                :max => 100,
                :value => lambda{ |data|  /:.*us/.match(data['cpu_time'])[0].gsub(/(:)|(%us)/, '').strip!.to_f }
            },
            "physical_ram" => {
                :mu => 'MB',
                :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f },
                :value => lambda{ |data|  /Mem:\s*\d*\s*\d*\s*\d*/.match(data['system_info'])[0].split(/\s+/)[2].to_f }
            },
            "cached_ram" => {
                :mu => 'MB',
                :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f },
                :value => lambda{ |data|  /Mem:\s*\d*\s*\d*\s*\d*\s*\d*\s*\d*\s*\d*/.match(data['system_info'])[0].split(/\s+/)[6].to_f }
            },
            "swap_ram" => {
                :mu => 'MB',
                :max => lambda{ |data|  /Swap:\s*\d*/.match(data['system_info'])[0].gsub(/Swap:/, '').strip!.to_f },
                :value => lambda{ |data|  /Swap:\s*\d*\s*\d*\s*\d*/.match(data['system_info'])[0].split(/\s+/)[2].to_f }
            },
            "system_disk" => {
                :mu => 'GB',
                :warn => 90,
                :critical => 95,
                :max => lambda{ |data|  /\/dev\/sda1\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f / (1024.0 * 1024.0) },
                :value => lambda{ |data|  /\/dev\/sda1\s*\S*\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[2].to_f / (1024.0 * 1024.0)  }
            },
            "ephemeral_disk" => {
                :mu => 'GB',
                :max => lambda{ |data|  /\/dev\/sdb2\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f / (1024.0 * 1024.0) },
                :value => lambda{ |data|  /\/dev\/sdb2\s*\S*\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[2].to_f / (1024.0 * 1024.0) }
            },
            "component" => {
                :value => lambda{ |data|  data['check'].gsub(/---/, "").strip! }
            }
        },
        "dea" => {
            "droplets_on_disk" =>
                {
                    :mu => 'QTY',
                    :value => lambda{ |data|  data['dropletcountfolder'].scan(/vcap-user/).size }
                },
            "worker_processes_count" =>
                {
                    :mu => 'QTY',
                    :value => lambda{ |data|  data['workerprocesses'].scan(/\/var\/vcap\/data\/dea\/apps/).size }
                },
            "worker_processes_memory" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  data['system_info'].scan(/Mem:\s*\d*/)[0].gsub(/(Mem:)/, '').strip!.to_f - 256.0 },
                    :value => lambda{ |data|  data['workerprocesses'].scan(/\d*\s*\d*\s*\?[^(\r|\n)]+\/var\/vcap\/data\/dea\/apps/).map {|x| x.split(/\s+/)[0].to_i }.inject(0) {|sum, x| sum += x} / 1024.0 }
                },
            "dea_service_memory" =>
                {
                    :mu => 'MB',
                    :max => 256,
                    :value => lambda{ |data|  data['deaprocessmemory'].scan(/\d*\s*\d*\s*\?[^(\r|\n)]+dea.yml/)[0].split(/\s+/)[0].to_f / 1024.0 }
                },
            "dea_provisionable_memory" =>
                {
                    :mu => 'GB',
                    :min => 0,
                    :max => lambda{ |data|  data['config'].scan(/max_memory:\s*\d*/)[0].split(/\s+/)[1].to_f / 1024.0 },
                    :value => lambda{ |data|  data['dropletdata'].scan(/"mem_quota":\s*\d*/).map {|x| x.split(/\s+/)[1].to_i }.inject(0) {|sum, x| sum += x} }
                },
            "dea_droplets" =>
                {
                    :mu => 'QTY',
                    :value => lambda{ |data|  data['dropletdata'].scan(/"droplet_id"/).size }
                }
        },

        "mysql_node" => {
            "services_on_disk" =>
                {
                    :mu => 'QTY',
                    :value => lambda{ |data|  data['databasesondrive'].scan(/\d*\s*d\w{32}/).size }
                },
            "provisioned_services" =>
                {
                    :mu => 'QTY',
                    :max => lambda{ |data|  data['config'].scan(/capacity:\s+\d*/)[0].split(/\s+/)[1].to_f },
                    :value => lambda{ |data|  data['servicedb'].scan(/\w{33}/).size }
                },
            "services_disk_size" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /\/dev\/sdc1\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f / 1024.0 },
                    :value => lambda{ |data|  data['servicesdisksize'].scan(/\d+\w\s+/).map {|x| x.split(/\s+/)[0].gsub(/\D/,'').to_i}.inject(0){|sum, x| sum += x}.to_f / 1024.0 }
                },
            "persistent_disk" => {
                    :mu => 'GB',
                    :max => lambda{ |data|  /\/dev\/sdc1\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f  / (1024.0 * 1024.0)},
                    :value => lambda{ |data|  /\/dev\/sdc1\s*\S*\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[2].to_f  / (1024.0 * 1024.0)}
                },
            "mysql_server_memory" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f - 256.0 },
                    :value => lambda{ |data|  data['servermemory'].scan(/\d*\s*\d*\s*\?[^\r]*mysqld\s--defaults/)[0].split(/\s+/)[1].to_f / 1024.0 }
                },
            "mysql_node_memory" =>
                {
                    :mu => 'MB',
                    :max => 100,
                    :value => lambda{ |data|  data['nodeprocessmemory'].scan(/\d*\s*\d*\s*\?[^\r]*ruby/)[0].split(/\s+/)[1].to_f / 1024.0 }
                }
        },
        "postgresql_node" => {
            "services_on_disk" =>
                {
                    :mu => 'QTY',
                    :value => lambda{ |data|  data['databasesondrive'].scan(/\d{2}:\d{2}\s17\d{3}/).size }
                },
            "provisioned_services" =>
                {
                    :mu => 'QTY',
                    :max => lambda{ |data|  data['config'].scan(/capacity:\s+\d*/)[0].split(/\s+/)[1].to_f },
                    :value => lambda{ |data|  data['servicedb'].scan(/\w{33}/).size }
                },
            "persistent_disk" => {
                    :mu => 'GB',
                    :max => lambda{ |data|  /\/dev\/sdc1\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f  / (1024.0 * 1024.0)},
                    :value => lambda{ |data|  /\/dev\/sdc1\s*\S*\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[2].to_f  / (1024.0 * 1024.0)}
                },
            "services_disk_size" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /\/dev\/sdc1\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f / 1024.0 },
                    :value => lambda{ |data|  data['servicesdisksize'].scan(/\d+\w\s+/).map {|x| x.split(/\s+/)[0].gsub(/\D/,'').to_i}.inject(0){|sum, x| sum += x}.to_f / 1024.0 }
                },
            "postgresql_server_memory" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f - 256.0 },
                    :value => lambda{ |data|  data['servermemory'].scan(/\d*\s*\d*\s*\?[^\r]*postgres\s-D/)[0].split(/\s+/)[1].to_f / 1024.0 }
                },
            "postgresql_node_memory" =>
                {
                    :mu => 'MB',
                    :max => 100,
                    :value => lambda{ |data|  data['nodeprocessmemory'].scan(/\d*\s*\d*\s*\?[^\r]*ruby/)[0].split(/\s+/)[1].to_f / 1024.0 }
                }
        },
        "mongodb_node" => {
            "services_on_disk" =>
                {
                    :mu => 'QTY',
                    :value => lambda{ |data|  data['databasesondrive'].scan(/\w{8}-\w{4}-\w{4}/).size }
                },
            "provisioned_services" =>
                {
                    :mu => 'QTY',
                    :max => lambda{ |data|  data['config'].scan(/capacity:\s+\d*/)[0].split(/\s+/)[1].to_f },
                    :value => lambda{ |data|  data['servicedb'].scan(/\w{33}/).size }
                },
            "persistent_disk" => {
                    :mu => 'GB',
                    :max => lambda{ |data|  /\/dev\/sdc1\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f  / (1024.0 * 1024.0)},
                    :value => lambda{ |data|  /\/dev\/sdc1\s*\S*\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[2].to_f  / (1024.0 * 1024.0)}
                },
            "services_disk_size" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /\/dev\/sdc1\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f / 1024.0 },
                    :value => lambda{ |data|  data['servicesdisksize'].scan(/\d+\w\s+/).map {|x| x.split(/\s+/)[0].gsub(/\D/,'').to_i}.inject(0){|sum, x| sum += x}.to_f / 1024.0 }
                },
            "mongodb_server_memory" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f - 256.0 },
                    :value => lambda{ |data|  data['servermemory'].scan(/\d+\s+\S\s+\w+\s+\d\d:\d+\s+\d+:\d+\s+\S+mongod/).map {|x| x.split(/\s+/)[0].to_i }.inject(0){|sum, x| sum += x}.to_f / 1024.0 }
                },
            "mongodb_node_memory" =>
                {
                    :mu => 'MB',
                    :max => 256,
                    :value => lambda{ |data|  data['nodeprocessmemory'].scan(/\d*\s*\d*\s*\?[^\r]*ruby/)[0].split(/\s+/)[1].to_f / 1024.0 }
                }
        },
        "redis_node" => {
            "services_on_disk" =>
                {
                    :mu => 'QTY',
                    :value => lambda{ |data|  data['databasesondrive'].scan(/\w{8}-\w{4}-\w{4}/).size }
                },
            "persistent_disk" => {
                    :mu => 'GB',
                    :max => lambda{ |data|  /\/dev\/sdc1\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f  / (1024.0 * 1024.0)},
                    :value => lambda{ |data|  /\/dev\/sdc1\s*\S*\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[2].to_f  / (1024.0 * 1024.0)}
                },
            "provisioned_services" =>
                {
                    :mu => 'QTY',
                    :max => lambda{ |data|  data['config'].scan(/capacity:\s+\d*/)[0].split(/\s+/)[1].to_f },
                    :value => lambda{ |data|  data['servicedb'].scan(/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}/).size }
                },
            "services_disk_size" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /\/dev\/sdc1\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f / 1024.0 },
                    :value => lambda{ |data|  data['servicesdisksize'].scan(/\d+\w\s+/).map {|x| x.split(/\s+/)[0].gsub(/\D/,'').to_i}.inject(0){|sum, x| sum += x}.to_f / 1024.0 }
                },
            "redis_server_memory" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f - 256.0 },
                    :value => lambda{ |data|  data['servermemory'].scan(/\d+\s+\S\s+\w+\s+\d\d:\d+\s+\d+:\d+\s+\S+redis-server/).map {|x| x.split(/\s+/)[0].to_i }.inject(0){|sum, x| sum += x}.to_f / 1024.0 }
                },
            "redis_node_memory" =>
                {
                    :mu => 'MB',
                    :max => 100,
                    :value => lambda{ |data|  data['nodeprocessmemory'].scan(/\d*\s*\d*\s*\?[^\r]*ruby/)[0].split(/\s+/)[1].to_f / 1024.0 }
                }
        },
        "rabbit_node" => {
            "services_on_disk" =>
                {
                    :mu => 'QTY',
                    :value => lambda{ |data|  data['databasesondrive'].scan(/\w{8}-\w{4}-\w{4}/).size }
                },
            "persistent_disk" => {
                    :mu => 'GB',
                    :max => lambda{ |data|  /\/dev\/sdc1\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f  / (1024.0 * 1024.0)},
                    :value => lambda{ |data|  /\/dev\/sdc1\s*\S*\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[2].to_f  / (1024.0 * 1024.0)}
                },
            "provisioned_services" =>
                {
                    :mu => 'QTY',
                    :max => lambda{ |data|  data['config'].scan(/capacity:\s+\d*/)[0].split(/\s+/)[1].to_f },
                    :value => lambda{ |data|  data['servicedb'].scan(/\w{33}/).size }
                },
            "services_disk_size" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /\/dev\/sdc1\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f / 1024.0 },
                    :value => lambda{ |data|  data['servicesdisksize'].scan(/\d+\w\s+/).map {|x| x.split(/\s+/)[0].gsub(/\D/,'').to_i}.inject(0){|sum, x| sum += x}.to_f / 1024.0 }
                },
            "rabbitmq_server_memory" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f - 256.0 },
                    :value => lambda{ |data|  data['servermemory'].scan(/\d+\s+\S+\s+\w+\s+\d+:\d+\s+\d+:\d+\s.var.vcap.data/).map {|x| x.split(/\s+/)[0].to_i }.inject(0){|sum, x| sum += x}.to_f / 1024.0 }
                },
            "rabbitmq_node_memory" =>
                {
                    :mu => 'MB',
                    :max => 100,
                    :value => lambda{ |data|  data['nodeprocessmemory'].scan(/\d*\s*\d*\s*\?[^\r]*ruby/)[0].split(/\s+/)[1].to_f / 1024.0 }
                }
        }
    },
    "windows" => {
        "base" => {
            "cpu" => {
                :mu => '%',
                :max => 100,
                :value => lambda{ |data|  (data['cpu_time']).scan(/"*[0-9].[0-9]*"\s*Exiting,/)[0].split(/\s+/)[0].gsub('"', '').to_f }
            },
            "physical_ram" => {
                :mu => 'MB',
                :max => lambda{ |data|  (data['system_info']).scan(/Total Physical Memory:\s+\d+?,?\d+/)[0].split(/\s+/)[3].gsub(/\D/, '').to_f },
                :value => lambda{ |data|  (data['system_info']).scan(/Total Physical Memory:\s+\d+?,?\d+/)[0].split(/\s+/)[3].gsub(/\D/, '').to_f - (data['system_info']).scan(/Available Physical Memory:\s+\d+?,?\d+/)[0].split(/\s+/)[3].gsub(/\D/, '').to_f },
            },
            "virtual_ram" => {
                :mu => 'MB',
                :max => lambda{ |data|  (data['system_info']).scan(/Virtual Memory: Max Size:\s+\d+?,?\d+/)[0].split(/\s+/)[4].gsub(/\D/, '').to_f },
                :value => lambda{ |data|  (data['system_info']).scan(/Virtual Memory: In Use:\s+\d+?,?\d+/)[0].split(/\s+/)[4].gsub(/\D/, '').to_f },
            },
            "system_disk" => {
                :mu => 'GB',
                :max => lambda{ |data|  (data['diskusagec']).scan(/of bytes\D+\d+/)[0].split(/\s+/)[3].gsub(/\D/, '').to_f / (1024 * 1024 * 1024) },
                :value => lambda{ |data|  (data['diskusagec']).scan(/avail free bytes\D+\d+/)[0].split(/\s+/)[4].gsub(/\D/, '').to_f / (1024 * 1024 * 1024) },
            },
            "component" => {
                :value => lambda{ |data| data['check'].scan(/[^\r\n]+\Z/)[0] }
            }
        },
        "win_dea" => {
            "droplets_on_disk" => {
                :mu => 'QTY',
                :value => lambda{ |data|  data['dropletcountfolder'].scan(/<DIR>\s+\w{25}/).size }
            },
            "worker_processes_count" => {
                :mu => 'QTY',
                :value => data['workerprocesses'].scan(/w3wp.exe/).size
            },
            "worker_processes_memory" => {
                :mu => 'MB',
                :max => lambda{ |data|  data['system_info'].scan(/Total Physical Memory:\s+\d+?,?\d+/)[0].split(/\s+/)[3].gsub(/\D/, '').to_f - 512.0 },
                :value => lambda{ |data|  data['workerprocesses'].scan(/w3wp.exe\s+\d+\s\w+\s+\d+\s+\S+/).map {|x| x.split(/\s+/)[4].gsub(/\D/, '').to_f }.inject(0){|sum, x| sum += x}.to_f / 1024.0 }
            },
            "dea_service_memory" => {
                :mu => 'MB',
                :max => 256.0,
                :value => lambda{ |data|  data['deaprocessmemory'].scan(/\d+.\d{6}/)[0].split(/\s+/)[0].to_f / (1024.0 * 1024.0) }
            },
            "dea_provisionable_memory" => {
                :mu => 'GB',
                :max => lambda{ |data|  data['config'].scan(/maxMemory="\d*"/)[0].split('"')[1].to_f / 1024.0 },
                :value => lambda{ |data|  data['dropletdata'].scan(/"mem_quota":\s*\d*/).map {|x| x.split(':')[1].to_i }.inject{|sum, x| sum += x}.to_f / (1024.0 * 1024.0 * 1024.0) }
            },
            "dea_droplets" => {
                :mu => 'QTY',
                :value => lambda{ |data|  data['dropletdata'].scan(/"droplet_id"/).size }
            }
        },
        "mssql_node" => {
            "services_on_disk" => {
                :mu => 'QTY',
                :value => lambda{ |data|  data['databasesondrive'].scan(/PriData.mdf/).size }
            },
            "provisioned_services" => {
                :mu => 'QTY',
                :max => lambda{ |data|  data['config'].scan(/capacity="\d*"/)[0].split('"')[1].to_i },
                :value => lambda { |data| data['servicedb'].scan(/D4Ta\w{32}/).size }
            },
            "services_disk_size" => {
                :mu => 'MB',
                :max => lambda{ |data|  (data['disk_usage_c']).scan(/of bytes\D+\d+/)[0].split(/\s+/)[3].gsub(/\D/, '').to_f / (1024 * 1024) - 20480.0 },
                :value => lambda{ |data|  data['databasesondrive'].scan(/\d*,?\d*,?\d*\sD4Ta/).map {|x| x.split(/\s+/)[0].gsub(/\D/,'').to_i}.inject{|sum, x| sum += x }.to_f / (1024.0 * 1024.0) }
            },
            "mssql_server_memory" => {
                :mu => 'MB',
                :max => lambda{ |data|  data['system_info'].scan(/Total Physical Memory:\s+\d+?,?\d+/)[0].split(/\s+/)[3].gsub(/\D/, '').to_f - 512.0 },
                :value => lambda{ |data| data['sqlservermemory'].scan(/\d+.\d{6}/)[0].split(/\s+/)[0].to_f / (1024.0 * 1024.0) }
            },
            "mssql_node_memory" => {
                :mu => 'MB',
                :max => 256.0,
                :value => lambda{ |data| data['nodeprocessmemory'].scan(/\d+.\d{6}/)[0].split(/\s+/)[0].to_f / (1024.0 * 1024.0) }
            },
        },
        "uhurufs_node" => {
            "services_on_disk" => {
                :mu => 'QTY',
                :value => lambda{ |data|  data['datafolders'].scan(/D4Ta\w{32}/).size }
            },
            "provisioned_services" => {
                :mu => 'QTY',
                :max => lambda{ |data|  data['config'].scan(/capacity="\d*"/)[0].split('"')[1].to_i },
                :value => lambda { |data| data['servicedb'].scan(/D4Ta\w{32}/).size }
            },
            "filesystem_node_memory" => {
                :mu => 'MB',
                :max => 512.0,
                :value => lambda{ |data| data['nodeprocessmemory'].scan(/\d+.\d{6}/)[0].split(/\s+/)[0].to_f / (1024.0 * 1024.0) }
            },
            "iis_apps" => {
                :mu => 'QTY',
                :value => lambda{ |data|  data['iiswebsitecount'].scan(/APP\s+/).size }
            }
        }
    }
}