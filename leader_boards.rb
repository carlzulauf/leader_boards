require 'sinatra/base'
require 'yaml'
require 'haml'
require 'json'

require_relative 'lib/high_score'
require_relative 'lib/score_board'
require_relative 'lib/game'

module LeaderBoards
  class API < Sinatra::Base

    before do
      @game = Game.new('bug_sweeper', :order => :asc)
    end

    get '/' do
      haml :index
    end

    get '/new' do
      haml :new
    end

    get '/submit' do
      redirect to('/new') if params["name"].to_s.empty? and params["score"].to_i <= 0
      @score = HighScore.new(
        name:       params["name"],
        score:      params["score"].to_i,
        ip_address: env["REMOTE_ADDR"]
      )
      @game.save_score(@score)
      @game.prune_old_scores
      redirect to('/')
    end

    get '/rebuild' do
      @game.rebuild
      "Rebuilt all leader boards."
    end
  end
end
