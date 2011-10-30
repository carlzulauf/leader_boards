require 'rubygems'
require 'rack'
require 'rack/jsonp'
require 'sinatra'
require 'redis/native_hash'

require './leader_boards'

use Rack::JSONP

run LeaderBoards::API
