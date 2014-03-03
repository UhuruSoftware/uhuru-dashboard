require 'yaml'

$config = YAML.load File.open(File.expand_path("../../config/uhuru-dashboard.yml", __FILE__))


$states = {
    "linux" => {
        "base" =>  {
            "cpu" => {
                :mu => '%',
                :max => 100,
                :value => lambda{ |data|  data['cpu_time'].scan(/:.*us/)[1].gsub(/(:)|(%us)/, '').strip!.to_f },
                :graph => true
            },
            "physical_ram" => {
                :mu => 'MB',
                :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f },
                :value => lambda{ |data|  /buffers.cache:\s*\d*\s*\d*\s*\d*/.match(data['system_info'])[0].split(/\s+/)[1].to_f },
                :graph => true
            },
            "cached_ram" => {
                :mu => 'MB',
                :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f },
                :value => lambda{ |data|  /Mem:\s*\d*\s*\d*\s*\d*\s*\d*\s*\d*\s*\d*/.match(data['system_info'])[0].split(/\s+/)[6].to_f },
                :graph => true
            },
            "swap_ram" => {
                :mu => 'MB',
                :max => lambda{ |data|  /Swap:\s*\d*/.match(data['system_info'])[0].gsub(/Swap:/, '').strip!.to_f },
                :value => lambda{ |data|  /Swap:\s*\d*\s*\d*\s*\d*/.match(data['system_info'])[0].split(/\s+/)[2].to_f },
                :graph => true
            },
            "system_disk" => {
                :mu => 'GB',
                :warn => 90,
                :critical => 95,
                :max => lambda{ |data|  /\/dev\/sda1\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f / (1024.0 * 1024.0) },
                :value => lambda{ |data|  /\/dev\/sda1\s*\S*\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[2].to_f / (1024.0 * 1024.0) },
                :graph => true
            },
            "ephemeral_disk" => {
                :mu => 'GB',
                :max => lambda{ |data|  /\/dev\/sdb2\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f / (1024.0 * 1024.0) },
                :value => lambda{ |data|  /\/dev\/sdb2\s*\S*\s*[0-9|.]*/.match(data['disk_usage'])[0].split(/\s+/)[2].to_f / (1024.0 * 1024.0) },
                :graph => true
            }
        },
        "ccdb" => {
            "persistent_disk" => {
              :mu => 'GB',
              :max => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[0].to_f  / (1024.0 * 1024.0)},
              :value => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f  / (1024.0 * 1024.0)},
              :graph => true
            }
        },
        "uhuru_webui" => {
            "persistent_disk" => {
                :mu => 'GB',
                :max => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[0].to_f  / (1024.0 * 1024.0)},
                :value => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f  / (1024.0 * 1024.0)},
                :graph => true
            }
        },
        "vcap_postgres" => {
            "persistent_disk" => {
                :mu => 'GB',
                :max => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[0].to_f  / (1024.0 * 1024.0)},
                :value => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f  / (1024.0 * 1024.0)},
                :graph => true
            }
        },
        "debian_nfs_server" => {
            "persistent_disk" => {
              :mu => 'GB',
              :max => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[0].to_f  / (1024.0 * 1024.0)},
              :value => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f  / (1024.0 * 1024.0)},
              :graph => true
            }
        },
        "syslog_aggregator" => {
            "persistent_disk" => {
              :mu => 'GB',
              :max => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[0].to_f  / (1024.0 * 1024.0)},
              :value => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f  / (1024.0 * 1024.0)},
              :graph => true
            }
        },
        "dea" => {
            "droplets_on_disk" =>
                {
                    :mu => '',
                    :value => lambda{ |data|  data['dropletcountfolder'].scan(/vcap-user/).size },
                    :graph => true
                },
            "worker_processes_count" =>
                {
                    :mu => '',
                    :value => lambda{ |data|  data['workerprocesses'].scan(/\/var\/vcap\/data\/dea\/apps/).size },
                    :graph => true
                },
            "worker_processes_memory" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  data['system_info'].scan(/Mem:\s*\d*/)[0].gsub(/(Mem:)/, '').strip!.to_f - 256.0 },
                    :value => lambda{ |data|  data['workerprocesses'].scan(/\d*\s*\d*\s*\?[^(\r|\n)]+\/var\/vcap\/data\/dea\/apps/).map {|x| x.split(/\s+/)[1].to_i }.inject(0) {|sum, x| sum += x} / 1024.0 },
                    :graph => true
                },
            "dea_service_memory" =>
                {
                    :mu => 'MB',
                    :max => 200,
                    :value => lambda{ |data|  data['deaprocessmemory'].scan(/\d*\s*\d*\s*\?[^(\r|\n)]+dea.yml/)[0].split(/\s+/)[1].to_f / 1024.0 },
                    :graph => true
                },
            "dea_provisionable_memory" =>
                {
                    :mu => 'GB',
                    :min => 0,
                    :max => lambda{ |data|  data['config'].scan(/max_memory:\s*\d*/)[0].split(/\s+/)[1].to_f / 1024.0 },
                    :value => lambda{ |data|  data['dropletdata'].scan(/"mem_quota":\s*\d*/).map {|x| x.split(/\s+/)[1].to_i }.inject(0){|sum, x| sum += x}.to_f / ( 1024.0 * 1024.0 * 1024.0) },
                    :graph => true
                },
            "dea_droplets" =>
                {
                    :mu => '',
                    :value => lambda{ |data|  data['dropletdata'].scan(/"droplet_id"/).size },
                    :graph => true
                }
        },

        "dea_next" => {
            "droplets_on_disk" =>
                {
                    :mu => '',
                    :value => lambda{ |data|  data['dropletcountfolder'].scan(/\d{3}\D{8}/).size },
                    :graph => true
                },
            "worker_processes_count" =>
                {
                    :mu => '',
                    :value => lambda{ |data|  data['workerprocesses'].scan(/\/var\/vcap\/data\/warden\/depot/).size },
                    :graph => true
                },
            "worker_processes_memory" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  data['system_info'].scan(/Mem:\s*\d*/)[0].gsub(/(Mem:)/, '').strip!.to_f - 256.0 },
                    :value => lambda{ |data|  data['workerprocesses'].scan(/\d*\s*\d*\s*\?[^(\r|\n)]+\/var\/vcap\/data\/warden\/depot/).map {|x| x.split(/\s+/)[1].to_i }.inject(0) {|sum, x| sum += x} / 1024.0 },
                    :graph => true
                },
            "dea_service_memory" =>
                {
                    :mu => 'MB',
                    :max => 200,
                    :value => lambda{ |data|  data['deaprocessmemory'].scan(/\d*\s*\d*\s*\?[^(\r|\n)]+dea.yml/)[0].split(/\s+/)[1].to_f / 1024.0 },
                    :graph => true
                },
            "dea_provisionable_memory" =>
                {
                    :mu => 'GB',
                    :min => 0,
                    :max => lambda{ |data|  data['config'].scan(/memory_mb:\s*\d*/)[0].split(/\s+/)[1].to_f / 1024.0 },
                    :value => lambda{ |data|  data['dropletdata'].scan(/"mem":\s*\d*/).map {|x| x.split(/\s+/)[1].to_i }.inject(0){|sum, x| sum += x}.to_f / 1024.0 },
                    :graph => true
                },
            "dea_droplets" =>
                {
                    :mu => '',
                    :value => lambda{ |data|  data['dropletdata'].scan(/"droplet_id"/).size },
                    :graph => true
                }
        },

        "mysql_node" => {
            "services_on_disk" =>
                {
                    :mu => '',
                    :value => lambda{ |data|  data['databasesondrive'].scan(/\d*\s*d\w{32}/).size },
                    :graph => true
                },
            "provisioned_services" =>
                {
                    :mu => '',
                    :max => lambda{ |data|  data['config'].scan(/capacity:\s+\d*/)[0].split(/\s+/)[1].to_f },
                    :value => lambda{ |data|  data['servicedb'].scan(/\w{33}/).size },
                    :graph => true
                },
            "services_disk_size" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[0].to_f / 1024.0 },
                    :value => lambda{ |data|  data['servicesdisksize'].scan(/\d+\w\s+/).map {|x| x.split(/\s+/)[0].gsub(/\D/,'').to_i}.inject(0){|sum, x| sum += x}.to_f / 1024.0 },
                    :graph => true
                },
            "persistent_disk" => {
                    :mu => 'GB',
                    :max => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[0].to_f  / (1024.0 * 1024.0)},
                    :value => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f  / (1024.0 * 1024.0)},
                    :graph => true
                },
            "mysql_server_memory" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f - 256.0 },
                    :value => lambda{ |data|  data['servermemory'].scan(/\d*\s*\d*\s*\?[^\r]*mysqld\s--defaults/)[0].split(/\s+/)[1].to_f / 1024.0 },
                    :graph => true
                },
            "mysql_node_memory" =>
                {
                    :mu => 'MB',
                    :max => 200,
                    :value => lambda{ |data|  data['nodeprocessmemory'].scan(/\d*\s*\d*\s*\?[^\r]*ruby/)[0].split(/\s+/)[1].to_f / 1024.0 },
                    :graph => true
                }
        },

        "mysql_node_free" => {
            "services_on_disk" =>
                {
                    :mu => '',
                    :value => lambda{ |data|  data['databasesondrive'].scan(/\d*\s*d\w{32}/).size },
                    :graph => true
                },
            "provisioned_services" =>
                {
                    :mu => '',
                    :max => lambda{ |data|  data['config'].scan(/capacity:\s+\d*/)[0].split(/\s+/)[1].to_f },
                    :value => lambda{ |data|  data['servicedb'].scan(/\w{33}/).size },
                    :graph => true
                },
            "services_disk_size" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[0].to_f / 1024.0 },
                    :value => lambda{ |data|  data['servicesdisksize'].scan(/\d+\w\s+/).map {|x| x.split(/\s+/)[0].gsub(/\D/,'').to_i}.inject(0){|sum, x| sum += x}.to_f / 1024.0 },
                    :graph => true
                },
            "persistent_disk" => {
                :mu => 'GB',
                :max => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[0].to_f  / (1024.0 * 1024.0)},
                :value => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f  / (1024.0 * 1024.0)},
                :graph => true
            },
            "mysql_server_memory" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f - 256.0 },
                    :value => lambda{ |data|  data['servermemory'].scan(/\d*\s*\d*\s*\?[^\r]*mysqld\s--defaults/)[0].split(/\s+/)[1].to_f / 1024.0 },
                    :graph => true
                },
            "mysql_node_memory" =>
                {
                    :mu => 'MB',
                    :max => 200,
                    :value => lambda{ |data|  data['nodeprocessmemory'].scan(/\d*\s*\d*\s*\?[^\r]*ruby/)[0].split(/\s+/)[1].to_f / 1024.0 },
                    :graph => true
                }
        },

        "postgresql_node" => {
            "services_on_disk" =>
                {
                    :mu => '',
                    :value => lambda{ |data|  data['databasesondrive'].scan(/\d{2}:\d{2}\s\d{5}/).size - 2 },
                    :graph => true
                },
            "provisioned_services" =>
                {
                    :mu => '',
                    :max => lambda{ |data|  data['config'].scan(/capacity:\s+\d*/)[0].split(/\s+/)[1].to_f },
                    :value => lambda{ |data|  data['servicedb'].scan(/\w{33}/).size },
                    :graph => true
                },
            "persistent_disk" => {
                    :mu => 'GB',
                    :max => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[0].to_f  / (1024.0 * 1024.0)},
                    :value => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f  / (1024.0 * 1024.0)},
                    :graph => true
                },
            "services_disk_size" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[0].to_f / 1024.0 },
                    :value => lambda{ |data|  data['servicesdisksize'].scan(/\d+\w\s+/).map {|x| x.split(/\s+/)[0].gsub(/\D/,'').to_i}.inject(0){|sum, x| sum += x}.to_f / 1024.0 },
                    :graph => true
                },
            "postgresql_server_memory" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f - 256.0 },
                    :value => lambda{ |data|  data['servermemory'].scan(/\d*\s*\d*\s*\?[^\r]*postgres\s-D/)[0].split(/\s+/)[1].to_f / 1024.0 },
                    :graph => true
                },
            "postgresql_node_memory" =>
                {
                    :mu => 'MB',
                    :max => 200,
                    :value => lambda{ |data|  data['nodeprocessmemory'].scan(/\d*\s*\d*\s*\?[^\r]*ruby/)[0].split(/\s+/)[1].to_f / 1024.0 },
                    :graph => true
                }
        },
        "postgresql_service_node_free" => {
            "services_on_disk" =>
                {
                    :mu => '',
                    :value => lambda{ |data|  data['databasesondrive'].scan(/\d{2}:\d{2}\s\d{5}/).size - 2 },
                    :graph => true
                },
            "provisioned_services" =>
                {
                    :mu => '',
                    :max => lambda{ |data|  data['config'].scan(/capacity:\s+\d*/)[0].split(/\s+/)[1].to_f },
                    :value => lambda{ |data|  data['servicedb'].scan(/\w{33}/).size },
                    :graph => true
                },
            "persistent_disk" => {
                :mu => 'GB',
                :max => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[0].to_f  / (1024.0 * 1024.0)},
                :value => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f  / (1024.0 * 1024.0)},
                :graph => true
            },
            "services_disk_size" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[0].to_f / 1024.0 },
                    :value => lambda{ |data|  data['servicesdisksize'].scan(/\d+\w\s+/).map {|x| x.split(/\s+/)[0].gsub(/\D/,'').to_i}.inject(0){|sum, x| sum += x}.to_f / 1024.0 },
                    :graph => true
                },
            "postgresql_server_memory" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f - 256.0 },
                    :value => lambda{ |data|  data['servermemory'].scan(/\d*\s*\d*\s*\?[^\r]*postgres\s-D/)[0].split(/\s+/)[1].to_f / 1024.0 },
                    :graph => true
                },
            "postgresql_node_memory" =>
                {
                    :mu => 'MB',
                    :max => 200,
                    :value => lambda{ |data|  data['nodeprocessmemory'].scan(/\d*\s*\d*\s*\?[^\r]*ruby/)[0].split(/\s+/)[1].to_f / 1024.0 },
                    :graph => true
                }
        },
        "mongodb_node" => {
            "services_on_disk" =>
                {
                    :mu => '',
                    :value => lambda{ |data|  data['databasesondrive'].scan(/\w{8}-\w{4}-\w{4}/).size },
                    :graph => true
                },
            "provisioned_services" =>
                {
                    :mu => '',
                    :max => lambda{ |data|  data['config'].scan(/capacity:\s+\d*/)[0].split(/\s+/)[1].to_f },
                    :value => lambda{ |data|  data['servicedb'].scan(/\w{8}-\w{4}-\w{4}/).size },
                    :graph => true
                },
            "persistent_disk" => {
                    :mu => 'GB',
                    :max => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[0].to_f  / (1024.0 * 1024.0)},
                    :value => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f  / (1024.0 * 1024.0)},
                    :graph => true
                },
            "services_disk_size" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[0].to_f / 1024.0 },
                    :value => lambda{ |data|  data['servicesdisksize'].scan(/\d+\w\s+/).map {|x| x.split(/\s+/)[0].gsub(/\D/,'').to_i}.inject(0){|sum, x| sum += x}.to_f / 1024.0 },
                    :graph => true
                },
            "mongodb_server_memory" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f - 256.0 },
                    :value => lambda{ |data|  data['servermemory'].scan(/\d+\s+\S+\s+\S+\s+\d+\s+\d+:\d+\s+\S+mongod/).map {|x| x.split(/\s+/)[0].to_i }.inject(0){|sum, x| sum += x}.to_f / 1024.0 },
                    :graph => true
                },
            "mongodb_node_memory" =>
                {
                    :mu => 'MB',
                    :max => 200,
                    :value => lambda{ |data|  data['nodeprocessmemory'].scan(/\d+\s+\S+\s+\S+\s+\S+\s+\d+:\d+\s+ruby/)[0].split(/\s+/)[0].to_f / 1024.0 },
                    :graph => true
                }
        },

        "mongodb_service_node_free" => {
            "services_on_disk" =>
                {
                    :mu => '',
                    :value => lambda{ |data|  data['databasesondrive'].scan(/\w{8}-\w{4}-\w{4}/).size },
                    :graph => true
                },
            "provisioned_services" =>
                {
                    :mu => '',
                    :max => lambda{ |data|  data['config'].scan(/capacity:\s+\d*/)[0].split(/\s+/)[1].to_f },
                    :value => lambda{ |data|  data['servicedb'].scan(/\w{8}-\w{4}-\w{4}/).size },
                    :graph => true
                },
            "persistent_disk" => {
                :mu => 'GB',
                :max => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[0].to_f  / (1024.0 * 1024.0)},
                :value => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f  / (1024.0 * 1024.0)},
                :graph => true
            },
            "services_disk_size" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[0].to_f / 1024.0 },
                    :value => lambda{ |data|  data['servicesdisksize'].scan(/\d+\w\s+/).map {|x| x.split(/\s+/)[0].gsub(/\D/,'').to_i}.inject(0){|sum, x| sum += x}.to_f / 1024.0 },
                    :graph => true
                },
            "mongodb_server_memory" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f - 256.0 },
                    :value => lambda{ |data|  data['servermemory'].scan(/\d+\s+\S+\s+\S+\s+\d+\s+\d+:\d+\s+\S+mongod/).map {|x| x.split(/\s+/)[0].to_i }.inject(0){|sum, x| sum += x}.to_f / 1024.0 },
                    :graph => true
                },
            "mongodb_node_memory" =>
                {
                    :mu => 'MB',
                    :max => 200,
                    :value => lambda{ |data|  data['nodeprocessmemory'].scan(/\d+\s+\S+\s+\S+\s+\S+\s+\d+:\d+\s+ruby/)[0].split(/\s+/)[0].to_f / 1024.0 },
                    :graph => true
                }
        },

        "redis_node" => {
            "services_on_disk" =>
                {
                    :mu => '',
                    :value => lambda{ |data|  data['databasesondrive'].scan(/\w{8}-\w{4}-\w{4}/).size },
                    :graph => true
                },
            "persistent_disk" => {
                    :mu => 'GB',
                    :max => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[0].to_f  / (1024.0 * 1024.0)},
                    :value => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f  / (1024.0 * 1024.0)},
                    :graph => true
                },
            "provisioned_services" =>
                {
                    :mu => '',
                    :max => lambda{ |data|  data['config'].scan(/capacity:\s+\d*/)[0].split(/\s+/)[1].to_f },
                    :value => lambda{ |data|  data['servicedb'].scan(/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}/).size },
                    :graph => true
                },
            "services_disk_size" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[0].to_f / 1024.0 },
                    :value => lambda{ |data|  data['servicesdisksize'].scan(/\d+\w\s+/).map {|x| x.split(/\s+/)[0].gsub(/\D/,'').to_i}.inject(0){|sum, x| sum += x}.to_f / 1024.0 },
                    :graph => true
                },
            "redis_server_memory" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f - 256.0 },
                    :value => lambda{ |data|  data['servermemory'].scan(/\d+\s+\S+\s+\S+\s+\d+\s+\d+:\d+\s+\S+redis-server/).map {|x| x.split(/\s+/)[0].to_i }.inject(0){|sum, x| sum += x}.to_f / 1024.0 },
                    :graph => true
                },
            "redis_node_memory" =>
                {
                    :mu => 'MB',
                    :max => 200,
                    :value => lambda{ |data|  data['nodeprocessmemory'].scan(/\d*\s*\d*\s*\?[^\r]*ruby/)[0].split(/\s+/)[1].to_f / 1024.0 },
                    :graph => true
                }
        },

        "redis_service_node_free" => {
            "services_on_disk" =>
                {
                    :mu => '',
                    :value => lambda{ |data|  data['databasesondrive'].scan(/\w{8}-\w{4}-\w{4}/).size },
                    :graph => true
                },
            "persistent_disk" => {
                :mu => 'GB',
                :max => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[0].to_f  / (1024.0 * 1024.0)},
                :value => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f  / (1024.0 * 1024.0)},
                :graph => true
            },
            "provisioned_services" =>
                {
                    :mu => '',
                    :max => lambda{ |data|  data['config'].scan(/capacity:\s+\d*/)[0].split(/\s+/)[1].to_f },
                    :value => lambda{ |data|  data['servicedb'].scan(/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}/).size },
                    :graph => true
                },
            "services_disk_size" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[0].to_f / 1024.0 },
                    :value => lambda{ |data|  data['servicesdisksize'].scan(/\d+\w\s+/).map {|x| x.split(/\s+/)[0].gsub(/\D/,'').to_i}.inject(0){|sum, x| sum += x}.to_f / 1024.0 },
                    :graph => true
                },
            "redis_server_memory" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f - 256.0 },
                    :value => lambda{ |data|  data['servermemory'].scan(/\d+\s+\S+\s+\S+\s+\d+\s+\d+:\d+\s+\S+redis-server/).map {|x| x.split(/\s+/)[0].to_i }.inject(0){|sum, x| sum += x}.to_f / 1024.0 },
                    :graph => true
                },
            "redis_node_memory" =>
                {
                    :mu => 'MB',
                    :max => 200,
                    :value => lambda{ |data|  data['nodeprocessmemory'].scan(/\d*\s*\d*\s*\?[^\r]*ruby/)[0].split(/\s+/)[1].to_f / 1024.0 },
                    :graph => true
                }
        },
        "rabbit_node" => {
            "services_on_disk" =>
                {
                    :mu => '',
                    :value => lambda{ |data|  data['databasesondrive'].scan(/\w{8}-\w{4}-\w{4}/).size },
                    :graph => true
                },
            "persistent_disk" => {
                    :mu => 'GB',
                    :max => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[0].to_f  / (1024.0 * 1024.0)},
                    :value => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f  / (1024.0 * 1024.0)},
                    :graph => true
                },
            "provisioned_services" =>
                {
                    :mu => '',
                    :max => lambda{ |data|  data['config'].scan(/capacity:\s+\d*/)[0].split(/\s+/)[1].to_f },
                    :value => lambda{ |data|  data['servicedb'].scan(/\w{8}-\w{4}-\w{4}/).size },
                    :graph => true
                },
            "services_disk_size" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[0].to_f / 1024.0 },
                    :value => lambda{ |data|  data['servicesdisksize'].scan(/\d+\w\s+/).map {|x| x.split(/\s+/)[0].gsub(/\D/,'').to_i}.inject(0){|sum, x| sum += x}.to_f / 1024.0 },
                    :graph => true
                },
            "rabbitmq_server_memory" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f - 256.0 },
                    :value => lambda{ |data|  data['servermemory'].scan(/\d+\s+\S+\s+\S+\s+\d+\s+\d+:\d+\s+.var.vcap.data/).map {|x| x.split(/\s+/)[0].to_i }.inject(0){|sum, x| sum += x}.to_f / 1024.0 },
                    :graph => true
                },
            "rabbitmq_node_memory" =>
                {
                    :mu => 'MB',
                    :max => 200,
                    :value => lambda{ |data|  data['nodeprocessmemory'].scan(/\d*\s*\d*\s*\?[^\r]*ruby/)[0].split(/\s+/)[1].to_f / 1024.0 },
                    :graph => true
                }
        },
        "rabbit_service_node_free" => {
            "services_on_disk" =>
                {
                    :mu => '',
                    :value => lambda{ |data|  data['databasesondrive'].scan(/\w{8}-\w{4}-\w{4}/).size },
                    :graph => true
                },
            "persistent_disk" => {
                :mu => 'GB',
                :max => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[0].to_f  / (1024.0 * 1024.0)},
                :value => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[1].to_f  / (1024.0 * 1024.0)},
                :graph => true
            },
            "provisioned_services" =>
                {
                    :mu => '',
                    :max => lambda{ |data|  data['config'].scan(/capacity:\s+\d*/)[0].split(/\s+/)[1].to_f },
                    :value => lambda{ |data|  data['servicedb'].scan(/\w{8}-\w{4}-\w{4}/).size },
                    :graph => true
                },
            "services_disk_size" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /\d*\s*\d*\s*\d*\s*\d+.\s*\/var\/vcap\/store/.match(data['disk_usage'])[0].split(/\s+/)[0].to_f / 1024.0 },
                    :value => lambda{ |data|  data['servicesdisksize'].scan(/\d+\w\s+/).map {|x| x.split(/\s+/)[0].gsub(/\D/,'').to_i}.inject(0){|sum, x| sum += x}.to_f / 1024.0 },
                    :graph => true
                },
            "rabbitmq_server_memory" =>
                {
                    :mu => 'MB',
                    :max => lambda{ |data|  /Mem:\s*\d*/.match(data['system_info'])[0].gsub(/(Mem:)/, '').strip!.to_f - 256.0 },
                    :value => lambda{ |data|  data['servermemory'].scan(/\d+\s+\S+\s+\S+\s+\d+\s+\d+:\d+\s+.var.vcap.data/).map {|x| x.split(/\s+/)[0].to_i }.inject(0){|sum, x| sum += x}.to_f / 1024.0 },
                    :graph => true
                },
            "rabbitmq_node_memory" =>
                {
                    :mu => 'MB',
                    :max => 200,
                    :value => lambda{ |data|  data['nodeprocessmemory'].scan(/\d*\s*\d*\s*\?[^\r]*ruby/)[0].split(/\s+/)[1].to_f / 1024.0 },
                    :graph => true
                }
        }
    },
    "windows" => {
        "base" => {
            "cpu" => {
                :mu => '%',
                :max => 100,
                :value => lambda{ |data|  (data['cpu_time']).scan(/"*[0-9].[0-9]*"\s*Exiting,/)[0].split(/\s+/)[0].gsub('"', '').to_f },
                :graph => true
            },
            "physical_ram" => {
                :mu => 'MB',
                :max => lambda{ |data|  (data['system_info']).scan(/Total Physical Memory:\s+\d+?,?\d+/)[0].split(/\s+/)[3].gsub(/\D/, '').to_f },
                :value => lambda{ |data|  (data['system_info']).scan(/Total Physical Memory:\s+\d+?,?\d+/)[0].split(/\s+/)[3].gsub(/\D/, '').to_f - (data['system_info']).scan(/Available Physical Memory:\s+\d+?,?\d+/)[0].split(/\s+/)[3].gsub(/\D/, '').to_f },
                :graph => true
            },
            "virtual_ram" => {
                :mu => 'MB',
                :max => lambda{ |data|  (data['system_info']).scan(/Virtual Memory: Max Size:\s+\d+?,?\d+/)[0].split(/\s+/)[4].gsub(/\D/, '').to_f },
                :value => lambda{ |data|  (data['system_info']).scan(/Virtual Memory: In Use:\s+\d+?,?\d+/)[0].split(/\s+/)[4].gsub(/\D/, '').to_f },
                :graph => true
            },
            "system_disk" => {
                :mu => 'GB',
                :max => lambda{ |data|  (data['disk_usage_c']).scan(/of bytes\D+\d+/)[0].split(/\s+/)[3].gsub(/\D/, '').to_f / (1024 * 1024 * 1024) },
                :value => lambda{ |data|  ((data['disk_usage_c']).scan(/of bytes\D+\d+/)[0].split(/\s+/)[3].gsub(/\D/, '').to_f - (data['disk_usage_c']).scan(/avail free bytes\D+\d+/)[0].split(/\s+/)[4].gsub(/\D/, '').to_f) / (1024 * 1024 * 1024) },
                :graph => true
            },
            "ephemeral_disk" => {
                :mu => 'GB',
                :max => lambda{ |data|  (data['disk_usage_data']).scan(/of bytes\D+\d+/)[0].split(/\s+/)[3].gsub(/\D/, '').to_f / (1024 * 1024 * 1024) },
                :value => lambda{ |data|  ((data['disk_usage_data']).scan(/of bytes\D+\d+/)[0].split(/\s+/)[3].gsub(/\D/, '').to_f - (data['disk_usage_data']).scan(/avail free bytes\D+\d+/)[0].split(/\s+/)[4].gsub(/\D/, '').to_f) / (1024 * 1024 * 1024) },
                :graph => true
            },
            "license_info" => {
                :mu => 'state',
                :accepted_values => ["Licensed"],
                :value => lambda{ |data| data['license_info'].scan(/^License\sStatus:\s(.*)$/)[0][0].to_s },
                :graph => false
            }
        },
        "uhuru_tunnel" => {
            "tunnels_on_disk" => {
                :mu => '',
                :value => lambda{ |data|  data['dropletcountfolder'].scan(/<DIR>\s+\S+-\d+-\S{14}/).size },
                :graph => true
            },
            "tunnel_processes_count" => {
                :mu => '',
                :value => lambda{ |data| data['workerprocesses'].scan(/w3wp.exe/).size },
                :graph => true
            },
            "tunnel_processes_memory" => {
                :mu => 'MB',
                :max => lambda{ |data|  data['system_info'].scan(/Total Physical Memory:\s+\d+?,?\d+/)[0].split(/\s+/)[3].gsub(/\D/, '').to_f - 512.0 },
                :value => lambda{ |data|  data['workerprocesses'].scan(/w3wp.exe\s+\d+\s\w+\s+\d+\s+\S+/).map {|x| x.split(/\s+/)[4].gsub(/\D/, '').to_f }.inject(0){|sum, x| sum += x}.to_f / 1024.0 },
                :graph => true
            },
            "dea_service_memory" => {
                :mu => 'MB',
                :max => 256.0,
                :value => lambda{ |data|  data['deaprocessmemory'].scan(/\d+.\d{6}/)[0].split(/\s+/)[0].to_f / (1024.0 * 1024.0) },
                :graph => true
            },
            "dea_provisionable_memory" => {
                :mu => 'GB',
                :max => lambda{ |data|  data['config'].scan(/maxMemoryMB="\d*"/)[0].split('"')[1].to_f / 1024.0 },
                :value => lambda{ |data|  data['dropletdata'].scan(/"mem_quota":\s*\d*/).map {|x| x.split(':')[1].to_i }.inject(0){|sum, x| sum += x}.to_f / (1024.0 * 1024.0 * 1024.0) },
                :graph => true
            },
            "tunnels" => {
                :mu => '',
                :value => lambda{ |data|  data['dropletdata'].scan(/"droplet_id"/).size },
                :graph => true
            }
        },
        "win_dea" => {
            "droplets_on_disk" => {
                :mu => '',
                :value => lambda{ |data|  data['dropletcountfolder'].scan(/<DIR>\s+\S+-\d+-\S{14}/).size },
                :graph => true
            },
            "worker_processes_count" => {
                :mu => '',
                :value => lambda{ |data| data['workerprocesses'].scan(/w3wp.exe/).size },
                :graph => true
            },
            "worker_processes_memory" => {
                :mu => 'MB',
                :max => lambda{ |data|  data['system_info'].scan(/Total Physical Memory:\s+\d+?,?\d+/)[0].split(/\s+/)[3].gsub(/\D/, '').to_f - 512.0 },
                :value => lambda{ |data|  data['workerprocesses'].scan(/w3wp.exe\s+\d+\s\w+\s+\d+\s+\S+/).map {|x| x.split(/\s+/)[4].gsub(/\D/, '').to_f }.inject(0){|sum, x| sum += x}.to_f / 1024.0 },
                :graph => true
            },
            "dea_service_memory" => {
                :mu => 'MB',
                :max => 256.0,
                :value => lambda{ |data|  data['deaprocessmemory'].scan(/\d+.\d{6}/)[0].split(/\s+/)[0].to_f / (1024.0 * 1024.0) },
                :graph => true
            },
            "dea_provisionable_memory" => {
                :mu => 'GB',
                :max => lambda{ |data|  data['config'].scan(/maxMemoryMB="\d*"/)[0].split('"')[1].to_f / 1024.0 },
                :value => lambda{ |data|  data['dropletdata'].scan(/"mem_quota":\s*\d*/).map {|x| x.split(':')[1].to_i }.inject(0){|sum, x| sum += x}.to_f / (1024.0 * 1024.0 * 1024.0) },
                :graph => true
            },
            "dea_droplets" => {
                :mu => '',
                :value => lambda{ |data|  data['dropletdata'].scan(/"droplet_id"/).size },
                :graph => true
            }
        },
        "mssql_node" => {
            "services_on_disk" => {
                :mu => '',
                :value => lambda{ |data|  data['databasesondrive'].scan(/PriData.mdf/).size },
                :graph => true
            },
            "provisioned_services" => {
                :mu => '',
                :max => lambda{ |data|  data['config'].scan(/capacity="\d*"/)[0].split('"')[1].to_i },
                :value => lambda { |data| data['servicedb'].scan(/D4Ta\w{32}/).size },
                :graph => true
            },
            "services_disk_size" => {
                :mu => 'MB',
                :max => lambda{ |data|  (data['disk_usage_store']).scan(/of bytes\D+\d+/)[0].split(/\s+/)[3].gsub(/\D/, '').to_f / (1024 * 1024) },
                :value => lambda{ |data|  data['databasesondrive'].scan(/\d*,?\d*,?\d*\sD4Ta/).map {|x| x.split(/\s+/)[0].gsub(/\D/,'').to_i}.inject{|sum, x| sum += x }.to_f / (1024.0 * 1024.0) },
                :graph => true
            },
            "mssql_server_memory" => {
                :mu => 'MB',
                :max => lambda{ |data|  data['system_info'].scan(/Total Physical Memory:\s+\d+?,?\d+/)[0].split(/\s+/)[3].gsub(/\D/, '').to_f - 512.0 },
                :value => lambda{ |data| data['sqlservermemory'].scan(/\d+.\d{6}/)[0].split(/\s+/)[0].to_f / (1024.0 * 1024.0) },
                :graph => true
            },
            "mssql_node_memory" => {
                :mu => 'MB',
                :max => 256.0,
                :value => lambda{ |data| data['nodeprocessmemory'].scan(/\d+.\d{6}/)[0].split(/\s+/)[0].to_f / (1024.0 * 1024.0) },
                :graph => true
            },
        },
        "mssql_node_free" => {
            "services_on_disk" => {
                :mu => '',
                :value => lambda{ |data|  data['databasesondrive'].scan(/PriData.mdf/).size },
                :graph => true
            },
            "provisioned_services" => {
                :mu => '',
                :max => lambda{ |data|  data['config'].scan(/capacity="\d*"/)[0].split('"')[1].to_i },
                :value => lambda { |data| data['servicedb'].scan(/D4Ta\w{32}/).size },
                :graph => true
            },
            "services_disk_size" => {
                :mu => 'MB',
                :max => lambda{ |data|  (data['disk_usage_store']).scan(/of bytes\D+\d+/)[0].split(/\s+/)[3].gsub(/\D/, '').to_f / (1024 * 1024) },
                :value => lambda{ |data|  data['databasesondrive'].scan(/\d*,?\d*,?\d*\sD4Ta/).map {|x| x.split(/\s+/)[0].gsub(/\D/,'').to_i}.inject{|sum, x| sum += x }.to_f / (1024.0 * 1024.0) },
                :graph => true
            },
            "mssql_server_memory" => {
                :mu => 'MB',
                :max => lambda{ |data|  data['system_info'].scan(/Total Physical Memory:\s+\d+?,?\d+/)[0].split(/\s+/)[3].gsub(/\D/, '').to_f - 512.0 },
                :value => lambda{ |data| data['sqlservermemory'].scan(/\d+.\d{6}/)[0].split(/\s+/)[0].to_f / (1024.0 * 1024.0) },
                :graph => true
            },
            "mssql_node_memory" => {
                :mu => 'MB',
                :max => 256.0,
                :value => lambda{ |data| data['nodeprocessmemory'].scan(/\d+.\d{6}/)[0].split(/\s+/)[0].to_f / (1024.0 * 1024.0) },
                :graph => true
            },
        },
        "uhurufs_node" => {
            "services_on_disk" => {
                :mu => '',
                :value => lambda{ |data|  data['datafolders'].scan(/D4Ta\w{32}/).size },
                :graph => true
            },
            "provisioned_services" => {
                :mu => '',
                :max => lambda{ |data|  data['config'].scan(/capacity="\d*"/)[0].split('"')[1].to_i },
                :value => lambda { |data| data['servicedb'].scan(/D4Ta\w{32}/).size },
                :graph => true
            },
            "filesystem_node_memory" => {
                :mu => 'MB',
                :max => 256.0,
                :value => lambda{ |data| data['nodeprocessmemory'].scan(/\d+.\d{6}/)[0].split(/\s+/)[0].to_f / (1024.0 * 1024.0) },
                :graph => true
            },
            "iis_apps" => {
                :mu => '',
                :value => lambda{ |data|  data['iiswebsitecount'].scan(/APP\s+/).size },
                :graph => true
            },
            "services_disk_size" => {
                :mu => 'GB',
                :max => lambda{ |data|  (data['disk_usage_store']).scan(/of bytes\D+\d+/)[0].split(/\s+/)[3].gsub(/\D/, '').to_f / (1024 * 1024 * 1024) },
                :value => lambda{ |data|  ((data['disk_usage_store']).scan(/of bytes\D+\d+/)[0].split(/\s+/)[3].gsub(/\D/, '').to_f - (data['disk_usage_store']).scan(/avail free bytes\D+\d+/)[0].split(/\s+/)[4].gsub(/\D/, '').to_f) / (1024 * 1024 * 1024) },
                :graph => true
            }
        }
    }
}