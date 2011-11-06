require 'rubygems'
require 'rack'
require 'rack/jsonp'
require 'sinatra'
require 'redis_hash'

require './leader_boards'

begin
  Redis::Client.default.inspect
rescue
  Redis::Client.default = Redis.new(path: '/tmp/redis.sock')
end

use Rack::JSONP

run LeaderBoards::API
