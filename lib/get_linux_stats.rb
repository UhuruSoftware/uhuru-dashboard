require 'net/ssh'
require 'yaml'



config = YAML.load File.open(File.expand_path("../../config/uhuru-dashboard.yml", __FILE__))

case metric
  when "physical_ram" then { :min => 0, :max => 100, :value => 5 }

end

File.open(File.expand_path("../../data/199.16.201.75.yml", __FILE__), "w") do |file|

  Net::SSH.start("199.16.201.75", "uhurusa", :password => "Trump3t" ) do |ssh|
    config['linux']['base'].each { |script_name, script|
      value = ssh.exec!(script)
      file.write(<<SCRIPT
------UHURUMON-#{script_name}
#{value}
SCRIPT
)
    }


    config['linux'].each{|component, scripts|
      unless component == 'base'
        component_type = ssh.exec!(scripts['CHECK'])
        puts "#{component} #{component_type}"
        if component_type =~ /^\s*$/
          scripts.each{|script_name, script|
            unless script_name == 'CHECK'
              #ssh.exec!(script)
            end
          }
        end
      end
    }
  end
end
