require "eventmachine"
require "sinatra"
require "sinatra/base"
require "yajl"

class Endpoint < Sinatra::Base

  use Rack::Auth::Basic, "Access restricted to authorized users only" do |username, password|
    [username, password] == ['uhuru', 'v1ewstat3']
  end

  def initialize(app, collector)
    super app
    @collector = collector
  end

  get '/raw' do
    content_type 'application/json', :charset => 'utf-8'

    return Yajl.dump(@collector.components, :pretty => true)
  end

  get '/dump' do
    File.open("components.json", "w") do |jfile|
      Yajl.dump(@collector.components, jfile, :pretty => true)
    end

    return 'Dump completed in file components.json'
  end


  get '/component' do
    vcap_components = []

    # insert the headers
    vcap_components << ['Type', 'Id', 'Host', 'Cpu cores %', 'Mem', 'Uptime', 'EM latency', 'Healthz latency']

    @collector.components.each do |type, v|
      v.each do |id, comp|
        type = comp[:vcap_component]['type']
        uuid = comp[:vcap_component]['uuid'][0, 6] + "..."
        host =  comp[:vcap_component]['host']
        cpu = comp[:varz] && comp[:varz][:data] && comp[:varz][:data]['cpu'] ?
            "#{comp[:varz][:data]['cpu'].to_f} %" :
            "N/A"

        mem = comp[:varz] && comp[:varz][:data] && comp[:varz][:data]['mem'] ?
            "#{comp[:varz][:data]['mem'].to_i / 1024} MiB" :
            "N/A"
        uptime = comp[:vcap_component]['uptime'] || "N/A"

        announce_latency = "#{comp[:announce_latency] || "N/A"} ms"

        request_latency = comp[:healthz] && comp[:healthz][:request_latency] ?
            "#{comp[:healthz][:request_latency].to_i} ms" :
            "N/A"

        vcap_components <<
            [ type, uuid, host, cpu, mem, uptime, announce_latency, request_latency]

      end

    end

    erb :'components', :locals => {:vcap_components => vcap_components}
  end

  get '/router' do
    # insert the headers
    (table = []) << ['Url', 'RPS']

    # vcap_router = @collector['Router'].first
    components = @collector.components

    if components &&
        components['Router'] &&
        components['Router'].first &&
        components['Router'].first[1][:varz] &&
        components['Router'].first[1][:varz][:data] &&
        components['Router'].first[1][:varz][:data]['top10_app_requests']
      rtop = components['Router'].first[1][:varz][:data]['top10_app_requests']

      rtop.each do |v|
        table << [v['url'], v['rps']]
      end

   end

    erb :'router', :locals => {:table => table}
  end

  get '/apps' do
    # insert the headers
    (table = []) << ['Name', 'Uris', 'Cpu cores %', 'Mem MiB', 'Disk MiB', 'App Id', 'Dea Id', 'Host']

    # vcap_router = @collector['Router'].first
    components = @collector.components

    if components &&
        components['DEA']

      components['DEA'].each do |id, v|
        if v[:varz] && v[:varz][:data] && (apps = v[:varz][:data]['running_apps'])
          uuid = v[:vcap_component]['uuid'][0, 6] + ".."
          apps.each do |app|
            usage = app['usage'] || {}
            uris = ""; app['uris'].each{|url| uris = uris + " " + "http://#{url}" }
            table << [app['name'].to_s, uris, usage['cpu'], usage['mem'].to_i / 1024, usage['disk'].to_i / 1024 / 1024, app['droplet_id'].to_s, uuid, v[:vcap_component]['host'] ]
          end
        end

      end

    end

    erb :'apps', :locals => {:table => table}
  end

  get '/services' do


    # vcap_router = @collector['Router'].first
    components = @collector.components

    services = {}

    components.each do |type, v|
      if type =~ /-Node/
        v.each do |id, comp|
          node_id = comp[:vcap_component]['type'] + "-" + comp[:vcap_component]['uuid'][0, 6] + "..."
          host =  comp[:vcap_component]['host']


          if comp[:varz] && comp[:varz][:data] && comp[:varz][:data]['instances']
            instances = comp[:varz][:data]['instances'] || {}
            instances.each do |id, status|
              service = (services[id] ||= {})
              service['type'] = type.sub(/-Node/, "")
              service['healthy'] = status.strip.downcase == "ok" ? "Yes." : "No. Node checking failing."
              service['orphan'] = service['orphan'].nil? ? true : false
              service['fond_on'] = node_id
              service['stats'] ||= {}

            end

          end

          if type == "MyaaS-Node" && comp[:varz] && comp[:varz][:data] && comp[:varz][:data]['database_status']
              database_statuses = comp[:varz][:data]['database_status'] || []
              database_statuses.each do |db_stat|
                service = (services[db_stat['name']] ||= {})

                service['type'] ||= type.sub(/-Node/, "")
                service['healthy'] ||= "Db not tracked by node."
                service['orphan'] = service['orphan'].nil? ? true : false
                service['fond_on'] = node_id

                service['stats'] ||= {}
                service['stats']['used'] = (db_stat['size'] / 1024 / 1024).to_i.to_s + " MiB"
                service['stats']['used_percent'] = (100 * db_stat['size'] / db_stat['max_size'] ).to_i.to_s + " %"
              end
          end

          if type == "AuaaS-Node" && comp[:varz] && comp[:varz][:data] && comp[:varz][:data]['db_stat']
            database_statuses = comp[:varz][:data]['db_stat'] || []
            database_statuses.each do |db_stat|
              service = (services[db_stat['name']] ||= {})
              service['stats'] ||= {}
              service['stats']['used'] = (db_stat['size'] / 1024 / 1024).to_i.to_s + " MiB"
              service['stats']['used_percent'] = (100 * db_stat['size'] / db_stat['max_size'] ).to_i.to_s + " %"
              service['stats']['active_server_processes'] = db_stat['active_server_processes']
            end
          end

          if type == "RaaS-Node" && comp[:varz] && comp[:varz][:data] && comp[:varz][:data]['provisioned_instances']
            provisioned_instances = comp[:varz][:data]['provisioned_instances'] || []
            provisioned_instances.each do |instance|
              instance_usage = instance['usage'] || {}
              service = (services[instance['name']] ||= {})
              service['stats'] ||= {}
              service['stats']['used_memory'] = (instance_usage['used_memory'] / 1024).to_i.to_s + " MiB"
              service['stats']['used_memory_percent'] = (100 * instance_usage['used_memory'] / instance_usage['max_memory'] ).to_i.to_s + " %"
              service['stats']['connected_clients_num'] = instance_usage['connected_clients_num']
            end
          end

          if type == "RMQaaS-Node" && comp[:varz] && comp[:varz][:data] && comp[:varz][:data]['provisioned_instances']
            provisioned_instances = comp[:varz][:data]['provisioned_instances'] || []
            provisioned_instances.each do |instance|
              instance_usage = instance['usage'] || {}
              service = (services[instance['name']] ||= {})
              service['stats'] ||= {}
              service['stats']['queues_num'] = instance_usage['queues_num']
              service['stats']['exchanges_num'] = instance_usage['exchanges_num']
              service['stats']['bindings_num'] = instance_usage['bindings_num']
            end
          end

          if type == "MongoaaS-Node" && comp[:varz] && comp[:varz][:data] && comp[:varz][:data]['disk']
            disk = comp[:varz][:data]['disk'] || {}
            disk.each do |id, disk_size|
              if service = services[id]
                service['stats'] ||= {}
                service['stats']['disk_usage'] = (disk_size / 1024 / 1024).to_i.to_s + " MiB"
              end
            end
          end

          if type == "MongoaaS-Node" && comp[:varz] && comp[:varz][:data] && comp[:varz][:data]['running_services']
            provisioned_instances = comp[:varz][:data]['running_services'] || []
            provisioned_instances.each do |instance|
              instance_overall = instance['overall'] || {}
              service = (services[instance['name']] ||= {})
              service['stats'] ||= {}

              if  instance_overall['network']
                service['stats']['num_requests'] = instance_overall['network']['numRequests']
                service['stats']['network_in'] = (instance_overall['network']['bytesIn'] / 1024 / 1024).to_i.to_s + " MiB"
                service['stats']['network_out'] = (instance_overall['network']['bytesOut'] / 1024 / 1024).to_i.to_s + " MiB"
              end
            end
          end

          if type == "UhurufsaaS-Node" && comp[:varz] && comp[:varz][:data] && comp[:varz][:data]['provisioned_instances']
            provisioned_instances = comp[:varz][:data]['provisioned_instances'] || []
            provisioned_instances.each do |instance|
              instance_usage = instance['usage'] || {}
              service = (services[instance['name']] ||= {})
              service['stats'] ||= {}
              service['stats']['used_storage_size'] = (instance_usage['used_storage_size'] / 1024).to_i.to_s + " MiB"
              service['stats']['used_storage_size'] = (100 * instance_usage['used_storage_size'] / instance_usage['max_storage_size'] ).to_i.to_s + " %"
            end
          end

        end
      end
      if type =~ /-Provisioner/
        v.each do |id, comp|

          if comp[:varz] && comp[:varz][:data] && comp[:varz][:data]['prov_svcs']
            instances = comp[:varz][:data]['prov_svcs'] || {}
            instances.each do |id, confs|
              # else it's a binding
              if confs['credentials'] && confs['credentials']['node_id']

                service = (services[id] ||= {})
                service['type'] ||= type.sub(/-Provisioner/, "")
                service['healthy'] ||= "No. Node missing." # consider it not healthy if not seen by node
                service['orphan'] = false
                service['node_id'] = confs['credentials']['node_id']
                service['stats'] ||= {}
                service['bindings_count'] ||= 0
              elsif confs['credentials'] && confs['credentials']['name']
                service = (services[confs['credentials']['name']] ||= {})
                service['bindings_count'] ||= 0
                service['bindings_count'] += 1
                service['stats'] ||= {}
              end

            end

          end

        end
      end

    end

    # insert the headers for the table
    (table = []) << ['Service Id', 'Type', 'Node Id', 'Foud on node', 'Healthy', 'Orphan', 'Bindings count', 'Stats']

    services.each do |id, info|
      stats = ""
      info['stats'].each do |name, value|
        stats = stats + "<p>#{name}: #{value} </p>\n"
      end

      table << [id, info['type'] || "", info['node_id'] || "", info['fond_on'] || "N/A", info['healthy'], info['orphan'], info['bindings_count'], stats]
    end


    erb :'services', :locals => {:table => table}
  end

end
