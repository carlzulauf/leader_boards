class ScoreBoard
  attr_accessor :game, :name, :duration
  def initialize(game, name, duration)
    self.game     = game
    self.name     = name
    self.duration = duration
    @scores = Redis::BigHash.new(:scores, game.namespace)
    @redis  = Redis::BigHash.redis
  end

  def save_score(score)
    @scores[score.key] = score.to_hash
    @redis.zadd("#{game.namespace}:#{name}",      score.score,        score.key)
    @redis.zadd("#{game.namespace}:#{name}:ages", score.submitted_at, score.key)
  end

  def prune
    return if duration == 0  # don't prune if no expiration
    max_age = Time.now.utc.to_i - duration
    too_old = @redis.zrangebyscore("#{game.namespace}:#{name}:ages", 0, max_age)
    return if too_old.empty?
    @redis.pipelined do
      @redis.zrem("#{game.namespace}:#{name}",      *too_old)
      @redis.zrem("#{game.namespace}:#{name}:ages", *too_old)
    end
  end

  def rebuild
    @redis.del "#{game.namespace}:#{name}"
    @redis.del "#{game.namespace}:#{name}:ages"
    t = Time.now.utc.to_i
    @scores.keys.each do |k|
      score = HighScore.new(@scores[k].merge(key: k))
      save_score(score) if duration == 0 or score.submitted_at > (t - duration)
    end
  end

  def top(limit = 100, page = 1)
    top_keys = @redis.send(
      game.order == :desc ? :zrevrange : :zrange,
      "#{game.namespace}:#{name}",
      (page - 1) * limit,
      limit * page
    )
    list = []
    return list if top_keys.empty?
    top_scores = @scores[*top_keys]
    top_scores = [top_scores] unless top_scores.kind_of?(Array)
    top_scores.each_with_index do |data,i|
      list << HighScore.new(data.merge(key: top_keys[i]))
    end
    list
  end
end
