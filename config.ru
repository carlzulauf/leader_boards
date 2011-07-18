require 'rubygems'
require 'rack'
require 'rack/jsonp'
require 'sinatra'
require 'redis/native_hash'

require './lib/visit_logger'
require './apitest'

$redis = Redis.new
Redis::NativeHash.redis = $redis

use Rack::JSONP

run LeaderBoards::ApiTest

