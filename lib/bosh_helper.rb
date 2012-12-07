require 'pg'
require 'bcrypt'
require 'config'
require 'net/http'
require 'json'
require "digest/sha1"

module Uhuru
  class BOSHHelper

    def self.open_ssh(deployment, job, index, public_key, user, password)
      ensure_bosh_user_exists

      uri = URI("http://#{$config['director']['address']}:#{$config['director']['port']}/deployments/#{deployment}/ssh")

      req = Net::HTTP::Post.new(uri.request_uri)
      req.basic_auth $config['director']['user'], $config['director']['password']

      payload = {
          "command" => "setup",
          "deployment_name" => deployment,
          "target" => {
              "job" => job,
              "indexes" => [index].compact
          },
          "params" => {
              "user" => "bosh_#{user}",
              "public_key" => public_key,
              "password" => encrypt_password(password)
          }
      }

      req.body = payload.to_json
      req.add_field("Content-Type", "application/json")

      res = Net::HTTP.start(uri.host, uri.port) {|http|
        http.request(req)
      }

      case res
        when Net::HTTPSuccess then res.body
        when Net::HTTPRedirection
          uri = URI(res['location'])
          req = Net::HTTP::Get.new(uri.request_uri)
          req.basic_auth $config['director']['user'], $config['director']['password']
          res = Net::HTTP.start(uri.host, uri.port) {|http|
            http.request(req)
          }
      end

      response = JSON.parse(res.body)

      while !['done', 'finished', 'canceled', 'error'].include? response['state']
        response = JSON.parse(get_bosh_response("tasks/#{response['id']}"))
        sleep 0.5
      end
    end

    def self.stop_ssh(deployment, job, index, user)
      ensure_bosh_user_exists

      uri = URI("http://#{$config['director']['address']}:#{$config['director']['port']}/deployments/#{deployment}/ssh")

      req = Net::HTTP::Post.new(uri.request_uri)
      req.basic_auth $config['director']['user'], $config['director']['password']

      payload = {
          "command" => "cleanup",
          "deployment_name" => deployment,
          "target" => {
              "job" => job,
              "indexes" => [index].compact
          },
          "params" => {
              "user_regex" => "^bosh_#{user}$"
          }
      }

      req.body = payload.to_json
      req.add_field("Content-Type", "application/json")

      res = Net::HTTP.start(uri.host, uri.port) {|http|
        http.request(req)
      }

      case res
        when Net::HTTPSuccess then res.body
        when Net::HTTPRedirection
          uri = URI(res['location'])
          req = Net::HTTP::Get.new(uri.request_uri)
          req.basic_auth $config['director']['user'], $config['director']['password']
          res = Net::HTTP.start(uri.host, uri.port) {|http|
            http.request(req)
          }
      end

      response = JSON.parse(res.body)

      while !['done', 'finished', 'canceled', 'error'].include? response['state']
        response = JSON.parse(get_bosh_response("tasks/#{response['id']}"))
        sleep 0.5
      end

      response['id']
    end

    def self.get_vms
      # get deployments
      deployments = JSON.parse(get_bosh_response('deployments'))

      vms = []

      # get vms
      deployments.each{|deployment|
        response = JSON.parse(get_bosh_response("deployments/#{deployment['name']}/vms?format=full"))

        while !['done', 'finished', 'canceled', 'error'].include? response['state']
          response = JSON.parse(get_bosh_response("tasks/#{response['id']}"))
          sleep 0.5
        end

        result = get_bosh_response("tasks/#{response['id']}/output?type=result")

        result.to_s.split("\n").each do |vm_state|
          vm = JSON.parse(vm_state)
          vm['deployment'] = deployment['name']
          vms << vm
        end
      }

      vms
    end

    :private

    def self.ensure_bosh_user_exists
      conn = PG::Connection.new(
          :host => $config['bosh_db']['address'],
          :port => $config['bosh_db']['port'],
          :dbname => $config['bosh_db']['database'],
          :user => $config['bosh_db']['user'],
          :password => $config['bosh_db']['password'])

      user = conn.exec("select * from users where username='#{$config['director']['user']}'")

      if user.values.size == 0
        conn.exec("insert into users (username, password) values ('#{$config['director']['user']}', '#{BCrypt::Password.create($config['director']['password'])}')")
      end

      conn.close
    end

    def self.get_bosh_response(action)
      ensure_bosh_user_exists

      uri = URI("http://#{$config['director']['address']}:#{$config['director']['port']}/#{action}")

      req = Net::HTTP::Get.new(uri.request_uri)
      req.basic_auth $config['director']['user'], $config['director']['password']

      res = Net::HTTP.start(uri.host, uri.port) {|http|
        http.request(req)
      }

      case res
        when Net::HTTPSuccess then res.body
        when Net::HTTPRedirection
          uri = URI(res['location'])
          req = Net::HTTP::Get.new(uri.request_uri)
          req.basic_auth $config['director']['user'], $config['director']['password']
          res = Net::HTTP.start(uri.host, uri.port) {|http|
            http.request(req)
          }
          res.body

      end
    end

    def self.encrypt_password(plain_text)
      return unless plain_text
      @salt_charset ||= get_salt_charset
      salt = ""
      8.times do
        salt << @salt_charset[rand(@salt_charset.size)]
      end
      plain_text.crypt(salt)
    end

    def self.get_salt_charset
      charset = []
      charset.concat(("a".."z").to_a)
      charset.concat(("A".."Z").to_a)
      charset.concat(("0".."9").to_a)
      charset << "."
      charset << "/"
      charset
    end
  end
end