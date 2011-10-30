class Game

  DAY = 60*60*24

  attr_accessor :name, :boards, :order
  def initialize(name, options = {})
    self.name     = name
    self.order    = options[:order]  || :desc
    board_options = options[:boards] || { day:      DAY,
                                          week:     DAY*7, 
                                          month:    DAY*30,
                                          quarter:  DAY*90,
                                          year:     DAY*365,
                                          all_time: 0 }
    self.boards = []
    board_options.each_pair do |board, duration|
      self.boards << ScoreBoard.new(self, board, duration)
    end
  end

  def namespace
    "#{name}:leader_board"
  end

  def save_score(score)
    boards.each do |board|
      board.save_score(score)
    end
  end

  def prune_old_scores
    boards.each do |board|
      board.prune
    end
  end

  def rebuild
    boards.each do |board|
      board.rebuild
    end
  end
end