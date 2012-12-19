require './system_stats.rb'
require 'sinatra'
require 'yajl'

def generateHtmlTable(data, headers=nil)

  if headers.nil?
    headers ||= []
    data.first.each {|key, value|
      headers << key
    }

  end

  htmlTable =
<<table
  <table border="">
  <tr>
table

  if headers
    headers.each {|h| htmlTable += "<th>#{h}</th>\n"}
  end

  htmlTable += "</tr>\n"

  data.each {|instance|
    htmlTable += "<tr>\n"

    headers.each{|h|
      htmlTable += "<td>#{instance[h]}</td>\n"
    }

    htmlTable += "</tr>\n"
  }

  htmlTable +=
<<table
  </table>
table

end

use Rack::Auth::Basic, "Access restricted to authorized users only" do |username, password|
  [username, password] == ['uhuru', 'v1ewstat3']
end

get '/test' do
  generateHtmlTable([{"cpu" => "0.4", "mem" => "300"}, {"cpu" => "0.6", "mem" => "500"}])
end

STATS = [
    {"tsdbKey" => "system.cpu.sys", "headerName" => "CPU Sys %"},
    {"tsdbKey" => "system.cpu.user", "headerName" => "CPU User %"},
    {"tsdbKey" => "system.cpu.wait", "headerName" => "CPU Wait %"},
    {"tsdbKey" => "system.load.1m", "headerName" => "Load 1-min"},
    {"tsdbKey" => "system.disk.system.percent", "headerName" => "System Disk %"},
    {"tsdbKey" => "system.disk.ephemeral.percent", "headerName" => "Ephemeral Disk %"},
    {"tsdbKey" => "system.disk.persistent.percent", "headerName" => "Persistent Disk %"},
    {"tsdbKey" => "system.healthy", "headerName" => "Healthy"},
    {"tsdbKey" => "system.mem.percent", "headerName" => "Memory %"},
    {"tsdbKey" => "system.mem.kb", "headerName" => "Memory MB"},
    {"tsdbKey" => "system.swap.percent", "headerName" => "Swap %"},
    {"tsdbKey" => "system.swap.kb", "headerName" => "Swap MB"}
]

get '/' do
  (table = []) << ["Job", "Index"] + STATS.collect{|s| s["headerName"]} + ["Charts"]

  statsData = {}
  open_tsdb_host = ENV["OPENTSDB_HOST"] || "10.0.5.179"
  open_tsdb_port = ENV["OPENTSDB_PORT"] || "4242"

  STATS.each {|stat|
    tsdbStat = SystemStats.get(open_tsdb_host, open_tsdb_port, stat["tsdbKey"])

    # puts tsdbStat.inspect
    tsdbStat.each {|jobName, value|
      statsData[jobName] ||= {}
      value.each {|jobIndex, tsdbStat|
        statsData[jobName][jobIndex] ||= {}
        statsData[jobName][jobIndex][stat["tsdbKey"]] = tsdbStat["value"].to_f.round(1)
      }
    }
  }

  table_stats_data = statsData.collect{|jobName, statsValues| {"Job" => jobName}.merge(statsValues)}

  statsData.each do |job, h|
    h.each do |index, stat|
      row = [job, index]

      row << stat["system.cpu.sys"]
      row << stat["system.cpu.user"]
      row << stat["system.cpu.wait"]
      row << stat["system.load.1m"]
      row << stat["system.disk.system.percent"]
      row << stat["system.disk.ephemeral.percent"]
      row << stat["system.disk.persistent.percent"]
      row << (stat["system.healthy"] && stat["system.healthy"].to_i > 0) ? true : false
      row << stat["system.mem.percent"]
      row << (stat["system.mem.kb"] / 1024).to_f.round(2)
      row << stat["system.swap.percent"]
      row << (stat["system.swap.kb"] / 1024).to_f.round(2)
      row <<
<<ROW
      <a href="/charts/#{job}/#{index}?duration_time=#{15 * 60}">15m</a>
      <a href="/charts/#{job}/#{index}?duration_time=#{60 * 60 - 10}">hour</a>
      <a href="/charts/#{job}/#{index}?duration_time=#{24 * 60 * 60 - 10}">day</a>
      <a href="/charts/#{job}/#{index}?duration_time=#{7 * 24 * 60 * 60 - 10 }">week</a>
      <a href="/charts/#{job}/#{index}?duration_time=#{30 * 24 * 60 * 60 - 10 }">month</a>
      <a href="/charts/#{job}/#{index}?duration_time=#{12 * 30 * 24 * 60 * 60 - 10 }">year</a>
ROW

      table << row
    end
  end

  # table_headers = ["Job"] + STATS.collect{|s| s["headerName"]}

  erb :'vms', :locals => {:table => table}
end

get '/charts/:job/:index' do
  open_tsdb_host = ENV["OPENTSDB_HOST"] || "10.0.5.179"
  open_tsdb_port = ENV["OPENTSDB_PORT"] || "4242"

  job = params[:job]
  index = params[:index]
  end_time = params[:end_time] || nil
  duration_time = params[:duration_time].to_i || 60 * 15 # 15 min

  readable_timestamp_converter = ->(timestamp) {Time.at(timestamp).strftime("%Ss")}

  if (duration_time > 60)
    readable_timestamp_converter = ->(timestamp) {Time.at(timestamp).strftime("%Mm:%Ss")}
  end
  if (duration_time > 60*60)
    readable_timestamp_converter = ->(timestamp) {Time.at(timestamp).strftime("%Hh:%Mm")}
  end
  if (duration_time > 60*60*24)
    readable_timestamp_converter = ->(timestamp) {Time.at(timestamp).strftime("%dd-%Hh")}
  end
  if (duration_time > 60*60*24 * 30)
    readable_timestamp_converter = ->(timestamp) {Time.at(timestamp).strftime("%mmon-%dd")}
  end

  # cpu stats
  cpuStats = {}
  tsdbStatCpuSys = SystemStats.getHistory(open_tsdb_host, open_tsdb_port, "system.cpu.sys", duration_time, end_time, "avg", job, index, 100)[job][index]
  tsdbStatCpuSys.each {|stat| (cpuStats[stat["timestamp"]] ||= {})["system.cpu.sys"] = stat["value"] }

  tsdbStatCpuUser = SystemStats.getHistory(open_tsdb_host, open_tsdb_port, "system.cpu.user", duration_time, end_time, "avg", job, index, 100)[job][index]
  tsdbStatCpuUser.each {|stat| (cpuStats[stat["timestamp"]] ||= {})["system.cpu.user"] = stat["value"] }

  tsdbStatCpuWait = SystemStats.getHistory(open_tsdb_host, open_tsdb_port, "system.cpu.wait", duration_time, end_time, "avg", job, index, 100)[job][index]
  tsdbStatCpuWait.each {|stat| (cpuStats[stat["timestamp"]] ||= {})["system.cpu.wait"] = stat["value"] }

  (cpu_chart_data = []) << ['Date', "Cpu User", "Cpu System", "Cpu Wait"]
  cpuStats.each {|timestamp, stat| cpu_chart_data << [readable_timestamp_converter.call(timestamp), stat["system.cpu.user"].to_f.round(1), stat["system.cpu.sys"].to_f.round(1), stat["system.cpu.wait"].to_f.round(1)]}

  # caluculate cpu load
  loadStats = {}
  tsdbStatLoad = SystemStats.getHistory(open_tsdb_host, open_tsdb_port, "system.load.1m", duration_time, end_time, "avg", job, index, 100)[job][index]
  tsdbStatLoad.each {|stat| (loadStats[stat["timestamp"]] ||= {})["system.load.1m"] = stat["value"] }

  (load_chart_data = []) << ['Date', "Cpu load avg"]
  loadStats.each {|timestamp, stat| load_chart_data  << [readable_timestamp_converter.call(timestamp), stat["system.load.1m"].to_f.round(3)]}

  # caluculate health
  healthStats = {}
  tsdbStatHealth = SystemStats.getHistory(open_tsdb_host, open_tsdb_port, "system.healthy", duration_time, end_time, "min", job, index, 100)[job][index]
  tsdbStatHealth.each {|stat| (healthStats[stat["timestamp"]] ||= {})["system.healthy"] = stat["value"] }

  (health_chart_data = []) << ['Date', "Health"]
  healthStats.each {|timestamp, stat| health_chart_data  << [readable_timestamp_converter.call(timestamp), stat["system.healthy"].to_f.round(0)]}

  # memory stats
  memStats = {}
  tsdbStatMem = SystemStats.getHistory(open_tsdb_host, open_tsdb_port, "system.mem.percent", duration_time, end_time, "avg", job, index, 100)[job][index]
  tsdbStatMem.each {|stat| (memStats[stat["timestamp"]] ||= {})["system.mem.percent"] = stat["value"] }

  tsdbStatSwap = SystemStats.getHistory(open_tsdb_host, open_tsdb_port, "system.swap.percent", duration_time, end_time, "avg", job, index, 100)[job][index]
  tsdbStatSwap.each {|stat| (memStats[stat["timestamp"]] ||= {})["system.swap.percent"] = stat["value"] }

  (mem_chart_data = []) << ['Date', "Mem", "Swap"]
  memStats.each {|timestamp, stat| mem_chart_data  << [readable_timestamp_converter.call(timestamp), stat["system.mem.percent"].to_f.round(1), stat["system.swap.percent"].to_f.round(1)]}

  # Disk stats
  diskStats = {}
  tsdbStatDiskSys = SystemStats.getHistory(open_tsdb_host, open_tsdb_port, "system.disk.system.percent", duration_time, end_time, "avg", job, index, 100)[job][index]
  tsdbStatDiskSys.each {|stat| (diskStats[stat["timestamp"]] ||= {})["system.disk.system.percent"] = stat["value"] }

  tsdbStatDiskEph = SystemStats.getHistory(open_tsdb_host, open_tsdb_port, "system.disk.ephemeral.percent", duration_time, end_time, "avg", job, index, 100)[job][index]
  tsdbStatDiskEph.each {|stat| (diskStats[stat["timestamp"]] ||= {})["system.disk.ephemeral.percent"] = stat["value"] }

  tsdbStatDiskPers = SystemStats.getHistory(open_tsdb_host, open_tsdb_port, "system.disk.persistent.percent", duration_time, end_time, "avg", job, index, 100)
  tsdbStatDiskPers = tsdbStatDiskPers[job] ? tsdbStatDiskPers[job][index] : []
  tsdbStatDiskPers.each {|stat| (diskStats[stat["timestamp"]] ||= {})["system.disk.persistent.percent"] = stat["value"].to_f.round(1) }

  (disk_chart_data = []) << ['Date', "System Disk", "Ephemeral System", "Persistent Disk"]
  diskStats.each {|timestamp, stat| disk_chart_data << [readable_timestamp_converter.call(timestamp), stat["system.disk.system.percent"].to_f.round(1), stat["system.disk.ephemeral.percent"].to_f.round(1), stat["system.disk.persistent.percent"] || 0]}

  erb :'area_chart', :locals => {:cpu_chart_data => cpu_chart_data, :load_chart_data => load_chart_data, :health_chart_data => health_chart_data, :mem_chart_data => mem_chart_data, :disk_chart_data => disk_chart_data  }
end



get '/htmltable' do


  statsData = {}
  open_tsdb_host = ENV["OPENTSDB_HOST"] || "10.0.5.179"
  open_tsdb_port = ENV["OPENTSDB_PORT"] || "4242"

  STATS.each {|stat|
    tsdbStat = SystemStats.get(open_tsdb_host, open_tsdb_port, stat["tsdbKey"])

    # puts tsdbStat.inspect
    tsdbStat.each {|jobName, value|
      value.each {|jobIndex, tsdbStat|
        (statsData["#{jobName}-#{jobIndex}"] ||= {})[stat["headerName"]] = tsdbStat["value"].to_f.round(1)
      }
    }
  }

  table_stats_data = statsData.collect{|jobName, statsValues| {"Job" => jobName}.merge(statsValues)}

  table_headers = ["Job"] + STATS.collect{|s| s["headerName"]}

  generateHtmlTable(table_stats_data ,table_headers)

  # SystemStats.get("10.0.5.179", "4242", "system.mem.percent")
  # generateHtmlTable([{"cpu" => "0.4", "mem" => "300"}, {"cpu" => "0.6", "mem" => "500"}])
end
