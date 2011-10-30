require 'securerandom'

class HighScore
  attr_accessor :key, :score, :name, :ip_address, :submitted_at

  def initialize(options = {})
    self.score        = options[:score]
    self.name         = options[:name]
    self.ip_address   = options[:ip_address]
    self.submitted_at = options[:submitted_at]  || Time.now.utc.to_i
    self.key          = options[:key]           || generate_key
  end

  def generate_key
    SecureRandom.urlsafe_base64(16)
  end

  def to_hash
    {score: score, name: name, ip_address: ip_address, submitted_at: submitted_at}
  end
end
