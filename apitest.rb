require 'sinatra/base'
require 'yaml'
require 'haml'
require 'json'

module LeaderBoards
  class ApiTest < Sinatra::Base
    get "/" do
      log_visit
      haml :index
    end

    get "/latest" do
      @latest = VisitLogger.latest
      haml :latest
    end

    get "/visit/:visit_id" do |id|
      @visit = VisitLogger.find(id)
      haml :visit
    end

    get "/highscore" do
      log_visit
      content_type :json
      { :daily => 4, :weekly => 37, :monthly => 123, :all_time => 888 }.to_json
    end

    def log_visit(msg = nil)
      @logger = VisitLogger.new
      @logger.ip_address = env['REMOTE_ADDR']
      @logger.activity   = msg || "Test API access"
      @logger.update( env.select{ |k,v| k.start_with?('REMOTE_' ) }
              .merge( env.select{ |k,v| k.start_with?('REQUEST_') } )
              .merge( env.select{ |k,v| k.start_with?('HTTP_'   ) } )
              .merge(params) )
      @logger.save
    end
  end
end

