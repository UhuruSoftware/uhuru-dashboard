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
                :max => lambda{ |data|  /\/dev\/sda1\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f },
                :value => lambda{ |data|  /\/dev\/sda1\s*\S*\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[2].to_f / 1024 }
            },
            "ephemeral_disk" => {
                :mu => 'GB',
                :max => lambda{ |data|  /\/dev\/sdb2\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f },
                :value => lambda{ |data|  /\/dev\/sdb2\s*\S*\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[2].to_f / 1024 }
            },
            "persistent_disk" => {
                :mu => 'GB',
                :max => lambda{ |data|  /\/dev\/sdc1\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f },
                :value => lambda{ |data|  /\/dev\/sdc1\s*\S*\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[2].to_f }
            },
            "component" => {
                :value => lambda{ |data|  data['check'].gsub(/---/, "").strip! }
            }
        },
        "dea" => {
            "droplets_on_disk" =>
                {
                    :mu => 'QT',
                    :value => lambda{ |data|  data['dropletcountfolder'].scan(/vcap-user/).size }
                },
            "worker_processes_count" =>
                {
                    :mu => 'QT',
                    :value => lambda{ |data|  data['workerprocessesiiscount'].scan(/\/var\/vcap\/data\/dea\/apps/).size }
                },
            "worker_processes_memory" =>
                {
                    :mu => 'KB',
                    :max => lambda{ |data|  data['system_info'].scan(/Mem:\s*\d*/)[0].gsub(/(Mem:)/, '').strip!.to_f },
                    :value => lambda{ |data|  data['workerprocessesmemory'].scan(/\d*\s*\d*\s*\?[^(\r|\n)]+\/var\/vcap\/data\/dea\/apps/).map {|x| x.split(/\s+/)[0].to_i }.inject {|sum, x| sum += x} }
                },
            "dea_service_memory" =>
                {
                    :mu => 'KB',
                    :max => lambda{ |data|  data['system_info'].scan(/Mem:\s*\d*/)[0].gsub(/(Mem:)/, '').strip!.to_f },
                    :value => lambda{ |data|  data['deaprocessmemory'].scan(/\d*\s*\d*\s*\?[^(\r|\n)]+dea.yml/)[0].split(/\s+/)[0].to_f }
                },
            "dea_provisionable_memory" =>
                {
                    :mu => 'GB',
                    :max => lambda{ |data|  data['config'].scan(/max_memory:\s*\d*/)[0].split(/\s+/)[1].to_f },
                    :value => lambda{ |data|  data['dropletdata'].scan(/"mem_quota":\s*\d*/).map {|x| x.split(/\s+/)[1].to_i }.inject {|sum, x| sum += x} }
                },
            "dea_droplets" =>
                {
                    :mu => 'QT',
                    :value => lambda{ |data|  data['dropletdata'].scan(/"droplet_id"/).size }
                }
        },

        "mysql_node" => {
            "services_on_disk" =>
                {
                    :mu => 'QT',
                    :value => lambda{ |data|  data['databasesondrive'].scan(/\d*\s*d\w{32}/).size }
                },
            "provisioned_services" =>
                {
                    :mu => 'QT',
                    :max => lambda{ |data|  data['config'].scan(/capacity:\s+\d*/)[0].split(/\s+/)[1].to_f },
                    :value => lambda{ |data|  data['servicedb'].scan(/\w{33}/).size }
                },
            "services_disk_size" =>
                {
                    :mu => 'GB',
                    :max => lambda{ |data|  /\/dev\/sdc1\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f },
                    :value => lambda{ |data|  val[0] = data['databasesondrive'].scan(/\d*\s*\d*-\d*-\d*\s*\d\d:\d\d\s*d\w{32}/).map {|x| x.split(/\s+/)[0].to_i}.inject {|sum, x| sum += x} }

                },
            "mysql_server_memory" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f },
                    :value => lambda{ |data|  data['servermemory'].scan(/vcap[^\r]*\?/).size }
                },
            "mysql_node_memory" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f },
                    :value => lambda{ |data|  data['nodeprocessmemory'].scan(/\d*\s*\d*\s*\?[^\r]*ruby/).size }
                },
        },
        "postgresql_node" => {
            "services_on_disk" =>
                {
                    :mu => 'QT',
                    :value => lambda{ |data|  data['databasesondrive'].scan(/\w{4}-\w{2}-\w{2}/).size }
                },
            "provisioned_services" =>
                {
                    :mu => 'QT',
                    :max => lambda{ |data|  data['config'].scan(/capacity:\s+\d*/)[0].split(/\s+/)[1].to_f },
                    :value => lambda{ |data|  data['servicedb'].scan(/\w{33}/).size }
                },
            "services_disk_size" =>
                {
                    :mu => 'GB',
                    :max => lambda{ |data|  /\/dev\/sdc1\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f },
                    :value => lambda{ |data|  val[0] = data['databasesondrive'].scan(/\d*\s*\d*-\d*-\d*\s*\d\d:\d\d\s*\w{8}\-\w{4}/).map {|x| x.split(/\s+/)[0].to_i}.inject {|sum, x| sum += x} }
                },
            "postgresql_server_memory" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f },
                    :value => lambda{ |data|  data['servermemory'].scan(/vcap[^\r]*\?/).size }
                },
            "postgresql_node_memory" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f },
                    :value => lambda{ |data|  data['nodeprocessmemory'].scan(/\d*\s*\d*\s*\?[^\r]*ruby/).size }
                }
        },
        "mongodb_node" => {
            "services_on_disk" =>
                {
                    :mu => 'QT',
                    :value => lambda{ |data|  data['databasesondrive'].scan(/\w{8}-\w{4}-\w{4}/).size }
                },
            "provisioned_services" =>
                {
                    :mu => 'QT',
                    :max => lambda{ |data|  data['config'].scan(/capacity:\s+\d*/)[0].split(/\s+/)[1].to_f },
                    :value => lambda{ |data|  data['servicedb'].scan(/\w{33}/).size }
                },
            "services_disk_size" =>
                {
                    :mu => 'GB',
                    :max => lambda{ |data|  /\/dev\/sdc1\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f },
                    :value => lambda{ |data|  val[0] = data['databasesondrive'].scan(/\d*\s*\d*-\d*-\d*\s*\d\d:\d\d\s*\w{8}\-\w{4}/).map {|x| x.split(/\s+/)[0].to_i}.inject {|sum, x| sum += x} }
                },
            "mongodb_server_memory" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f },
                    :value => lambda{ |data|  data['servermemory'].scan(/vcap[^\r]*\?/).size }
                },
            "mongodb_node_memory" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f },
                    :value => lambda{ |data|  data['nodeprocessmemory'].scan(/\d*\s*\d*\s*\?[^\r]*ruby/).size }
                }
        },
        "redis_node" => {
            "services_on_disk" =>
                {
                    :mu => 'QT',
                    :value => lambda{ |data|  data['databasesondrive'].scan(/\w{8}-\w{4}-\w{4}/).size }
                },
            "provisioned_services" =>
                {
                    :mu => 'QT',
                    :max => lambda{ |data|  data['config'].scan(/capacity:\s+\d*/)[0].split(/\s+/)[1].to_f },
                    :value => lambda{ |data|  data['servicedb'].scan(/\w{33}/).size }
                },
            "services_disk_size" =>
                {
                    :mu => 'GB',
                    :max => lambda{ |data|  /\/dev\/sdc1\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f },
                    :value => lambda{ |data|  val[0] = data['databasesondrive'].scan(/\d*\s*\d*-\d*-\d*\s*\d\d:\d\d\s*\w{8}\-\w{4}/).map {|x| x.split(/\s+/)[0].to_i}.inject {|sum, x| sum += x} }
                },
            "redis_server_memory" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f },
                    :value => lambda{ |data|  data['servermemory'].scan(/vcap[^\r]*\?/).size }
                },
            "redis_node_memory" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f },
                    :value => lambda{ |data|  data['nodeprocessmemory'].scan(/\d*\s*\d*\s*\?[^\r]*ruby/).size }
                }
        },
        "rabbit_node" => {
            "services_on_disk" =>
                {
                    :mu => 'QT',
                    :value => lambda{ |data|  data['databasesondrive'].scan(/\w{8}-\w{4}-\w{4}/).size }
                },
            "provisioned_services" =>
                {
                    :mu => 'QT',
                    :max => lambda{ |data|  data['config'].scan(/capacity:\s+\d*/)[0].split(/\s+/)[1].to_f },
                    :value => lambda{ |data|  data['servicedb'].scan(/\w{33}/).size }
                },
            "services_disk_size" =>
                {
                    :mu => 'GB',
                    :max => lambda{ |data|  /\/dev\/sdc1\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f },
                    :value => lambda{ |data|  val[0] = data['databasesondrive'].scan(/\d*\s*\d*-\d*-\d*\s*\d\d:\d\d\s*\w{8}\-\w{4}/).map {|x| x.split(/\s+/)[0].to_i}.inject {|sum, x| sum += x} }
                },
            "rabbitmq_server_memory" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f },
                    :value => lambda{ |data|  data['servermemory'].scan(/vcap[^\r]*\?/).size }
                },
            "rabbitmq_node_memory" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f },
                    :value => lambda{ |data|  data['nodeprocessmemory'].scan(/\d*\s*\d*\s*\?[^\r]*ruby/).size }
                }
        }
    },
    "windows" => {
        "base" => {
            "cpu" => {
                :mu => '%',
                :max => 100,
                :value => lambda{ |data|  (data['cpu_time']).scan(/'*[0-9].[0-9]*'\s*Exiting,/).map {|x| x.split(/\s+/)[0]} }
            },
            "physical_ram" => {
                :mu => 'MB',
                :max => lambda{ |data|  (data['system_info']).scan(/Total Physical Memory:\s*\d,\d*/).map {|x| x.split(/\s+/)[3]} },
                :value => lambda{ |data|  (data['system_info']).scan(/Total Physical Memory:\s*\d,\d*/).map {|x| x.split(/\s+/)[3]} }
            },
            "cached_ram" => {
                :mu => 'MB',
                :max => lambda{ |data|  (data['system_info']).scan(/Virtual Memory: Available:\s*\d,\d*/).map {|x| x.split(/\s+/)[4]} },
                :value => lambda{ |data|  (data['system_info']).scan(/Virtual Memory: In Use:\s*\d,\d*/).map {|x| x.split(/\s+/)[4]} }
            },
            "swap_ram" => {
                :mu => 'MB',
                #:max => /Swap:\s*\d*/.match(data['system_info'])[0]/gsub(/Swap:/, '').strip!.to_f,
                #:value => /Swap:\s*\d*\s*\d*\s*\d*/.match(data['system_info'])[0].split(/\s+/)[2].to_f
            },
            "system_disk" => {
                :mu => 'GB',
                #:max => /\/dev\/sda1\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f,
                #:value => /\/dev\/sda1\s*\S*\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[2].to_f
            },
            "ephemeral_disk" => {
                :mu => 'GB',
                #:max => /\/dev\/sdb2\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f,
                #:value => /\/dev\/sdb2\s*\S*\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[2].to_f
            },
            "persistent_disk" => {
                :mu => 'GB',
                #:max => /\/dev\/sdc1\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f,
                #:value => /\/dev\/sdc1\s*\S*\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[2].to_f
            },
            "component" => {
                :value => lambda{ |data|  data['component_info'].strip!}
            },
            "dea" => {
                "droplets_on_disk" => {
                    :value => lambda{ |data|  data['dropletcountfolder'].scan(/<DIR>\s+\w{25}/).size }
                },
                "worker_processes_count" => {
                    #:value => data['workerprocessesiiscount'].scan(/\/var\/vcap\/data\/dea\/apps/).size
                },
                "worker_processes_memory" => {
                    :mu => 'KB',
                    :max => lambda{ |data|  data['system_info'].scan(/Available Physical Memory:\s*\d*/)[0].gsub(/(Available Physical Memory:)/, '').strip!.to_f },
                    #:value => data['workerprocessesmemory'].scan(/\d*\s*\d*\s*\?[^(\r|\n)]+\/var\/vcap\/data\/dea\/apps/).map {|x| x.split(/\s+/)[0].to_i }.inject {|sum, x| sum += x}
                },
                "dea_service_memory" => {
                    :mu => 'KB',
                    :max => lambda{ |data|  data['system_info'].scan(/Available Physical Memory:\s*\d*/)[0].gsub(/(Available Physical Memory:)/, '').strip!.to_f },
                    :value => lambda{ |data|  data['deaprocessmemory'].scan(/\d*\s*\d*\s*\?[^(\r|\n)]+dea.yml/)[0].split(/\s+/)[0].to_f }
                },
                "dea_provisionable_memory" => {
                    :max => lambda{ |data|  data['config'].scan(/Total Physical Memory:\s*\d*/)[0].split(/\s+/)[1].to_f },
                    :value => lambda{ |data|  data['dropletdata'].scan(/"mem_quota":\s*\d*/).map {|x| x.split(/\s+/)[1].to_i }.inject {|sum, x| sum += x} }
                },
                "dea_droplets" => {
                    #:value => data['dropletdata'].scan(/"droplet_id"/).size
                }
            },
            "mssql_node" => {
                "services_on_disk" => {
                    :value => lambda{ |data|  data['databasesondrive'].scan(/D4Ta\w{20}/).size }
                },
                "provisioned_services" => {
                    :mu => 'QT',
                    :max => lambda{ |data|  data['config'].scan(/capacity="\d*"/) },
                    #:value => data['servicedb'].scan(/\w{33}/).size
                },
                "services_disk_size" => {
                    :mu => 'GB',
                    :max => lambda{ |data|  /\/dev\/sdc1\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f },
                    #:value => val[0] = data['databasesondrive'].scan(/\d*\s*\d*-\d*-\d*\s*\d\d:\d\d\s*d\w{32}/).map {|x| x.split(/\s+/)[0].to_i}.inject {|sum, x| sum += x}
                },
                "mssql_server_memory" => {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f },
                    #:value => data['servermemory'].scan(/vcap[^\r]*\?/).size
                },
                "mssql_node_memory" => {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f },
                    #:value => data['nodeprocessmemory'].scan(/\d*\s*\d*\s*\?[^\r]*ruby/).size
                },
            },
            "filesystem_node" => {
                "services_on_disk" => {
                    :value => lambda{ |data|  data['databasesondrive'].scan(/APP\s+/).size }
                },
                "provisioned_services" => {
                    :mu => 'QT',
                    :max => lambda{ |data|  data['config'].scan(/capacity:\s+\d*/) },
                    #:value => data['servicedb'].scan(/\w{33}/).size
                },
                "services_disk_size" => {
                    :mu => 'GB',
                    :max => lambda{ |data|  /\/dev\/sdc1\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f },
                    #:value => val[0] = data['databasesondrive'].scan(/\d*\s*\d*-\d*-\d*\s*\d\d:\d\d\s*\w{8}\-\w{4}/).map {|x| x.split(/\s+/)[0].to_i}.inject {|sum, x| sum += x}
                },
                "filesystem_server_memory" => {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f },
                    #:value => data['servermemory'].scan(/vcap[^\r]*\?/).size
                },
                "filesystem_node_memory" => {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f },
                    #:value => data['nodeprocessmemory'].scan(/\d*\s*\d*\s*\?[^\r]*ruby/).size
                }
            }
        }
    }
}