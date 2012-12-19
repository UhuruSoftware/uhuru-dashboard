require 'net/http'
require 'uri'

class SystemStats

  def self.get(host, port, stat)
    tsdStat = Net::HTTP.get_response(URI.parse("http://#{host}:#{port}/stats"))
    curTsdTime = tsdStat.body.split(/ /)[1]
    curTsdTime = curTsdTime.to_i

    # last 5 minutes
    startTime = curTsdTime -  10 * 60
    endTime = curTsdTime


    res = {}
    # http://10.0.5.179:4242/q?start=1352472151&end=1352472152&m=avg:system.mem.percent{index=*,job=*}&ascii
    # http://10.0.5.179:4242/q?start=32s-ago&m=avg:system.mem.percent{index=*,job=*}&ascii
    response = Net::HTTP.get_response(URI.parse(URI.encode("http://#{host}:#{port}/q?start=#{10*60}s-ago&m=avg:#{stat}{index=*,job=*}&ascii")))
    response.body.split("\n").each {|line|
      values = line.split(/ /)
      sampleTimestamp = values[1].to_i
      if values[1].to_i >= startTime
        indexValue = values.select{|e| e =~ /\Aindex=/}.first.gsub(/\Aindex=/, "")
        jobValue = values.select{|e| e =~ /\Ajob=/}.first.gsub(/\Ajob=/, "")
        res[jobValue] ||= {}
        sample = res[jobValue][indexValue]

        if !sample || sampleTimestamp > sample["timestamp"]
          res[jobValue][indexValue] = {"timestamp" => sampleTimestamp, "value" => values[2]}
        end

      end
    }

    res
  end

  def self.getHistory(host, port, stat, duration, end_time = nil, aggregator = "avg", job_name = "*", job_index = "*", max_samples = 100)
    tsdStat = Net::HTTP.get_response(URI.parse("http://#{host}:#{port}/stats"))
    curTsdTime = tsdStat.body.split(/ /)[1]
    curTsdTime = curTsdTime.to_i


    endTime = end_time || curTsdTime
    startTime = curTsdTime - (duration || 15 * 60)

    interval = ((endTime - startTime) / max_samples).to_i

    res = {}
    # http://10.0.5.179:4242/q?start=1352472151&end=1352472152&m=avg:system.mem.percent{index=*,job=*}&ascii
    # http://10.0.5.179:4242/q?start=32s-ago&m=min:100s-min:system.healthy{index=*,job=*}&ascii
    response = Net::HTTP.get_response(URI.parse(URI.encode("http://#{host}:#{port}/q?start=#{startTime}&end=#{endTime}&m=#{aggregator}:#{interval}s-#{aggregator}:#{stat}{index=#{job_index},job=#{job_name}}&ascii")))
    response.body.split("\n").each {|line|
      values = line.split(/ /)
      sampleTimestamp = values[1].to_i
      if values[1].to_i >= startTime
        indexValue = values.select{|e| e =~ /\Aindex=/}.first.gsub(/\Aindex=/, "")
        jobValue = values.select{|e| e =~ /\Ajob=/}.first.gsub(/\Ajob=/, "")
        res[jobValue] ||= {}
        res[jobValue][indexValue] ||= []

        if (sampleTimestamp >= startTime && sampleTimestamp <= endTime)
          res[jobValue][indexValue] << {"timestamp" => sampleTimestamp, "value" => values[2]}
        end

      end
    }

    res
  end

end

#tsdStat = Net::HTTP.get_response(URI.parse("http://#{"10.0.5.179"}:#{"4242"}/stats"))

#res = SystemStats.get("10.0.5.179", "4242", "system.mem.percent")
#puts res

#res = SystemStats.getHistory("10.0.5.179", "4242", "system.mem.percent", 60 * 15, nil, "avg", "dashboard", 0, 3)
#puts res