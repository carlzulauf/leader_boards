require 'redis/native_hash'

class VisitLogger < Redis::NativeHash
  LOG_RETENTION_SECONDS = 2592000  # 30 days
  CREATED_INDEX = "index:visits:created"
  attr_persist :ip_address, :activity, :created

  def initialize(*args)
    super
    self.created = Time.now.to_i
  end

  def namespace; :visits; end

  def created
    self['created'].to_i
  end

  def save
    super
    #redis.expire( redis_key, LOG_RETENTION_SECONDS )
    redis.lpush( CREATED_INDEX, key )
    self.class.purge_oldest
  end

  def generate_key
    unless ip_address.nil?
      t = Time.now
      t.strftime('%Y%m%d%H%M%S.') + t.usec.to_s.rjust(6,'0') + "-#{ip_address}"
    else
      super
    end
  end

  def self.latest
    latest = []; last = count - 1
    (0..last).each do |i|
      key = redis.lindex(CREATED_INDEX, i)
      log = find(key)
      latest << log
      yield(i, log) if block_given?
    end
    latest
  end

  def self.oldest
    oldest = []; last = count - 1
    (0..last).reverse_each do |i|
      key = redis.lindex(CREATED_INDEX, i)
      log = find(key)
      oldest << log
      yield(i, log) if block_given?
    end
    oldest
  end

  def self.purge_oldest
    now = Time.now.to_i
    trim_to = nil
    oldest do |i,visit|
      puts "Looking at visit ##{i}"
      break if visit.created > (now - LOG_RETENTION_SECONDS)
      visit.destroy
      trim_to = i
    end
    redis.ltrim(CREATED_INDEX, 0, trim_to - 1) unless trim_to.nil?
  end

  def self.count
    redis.llen( CREATED_INDEX )
  end
end

