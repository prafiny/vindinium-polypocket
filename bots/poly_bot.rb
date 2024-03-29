class PolyBot < BaseBot
  include Automaton, Threshold, Volatile
  extend Volatile
  def initialize threshold_file, *mutate
    load_thresholds threshold_file
    @mutate = mutate.include? :mutate
    @pathf = Pathfinding::Floyd.new
    @objective = lambda do
      @me.gold.to_f / (@game.heroes.map{ |h| h.gold }.reduce(:+).to_f + 1.0)
    end
    @goal = nil
    @aim = nil
    @ready = false

    def_automaton do
      state :calculating do
        transition_to(:conqueror) { @ready }
        
        behaviour do
          DIRECTIONS.sample
        end
      end
          
      state :conqueror do
        transition_to(:coward) { thirst > t(5) && nearness_tavern < t(6) }
        transition_to(:coward) { thirst > t(4) }
        transition_to(:coward) { nearest_mine.nil? }

        transition_to(:warrior) { nearness_enemy < t(7) && violence > t(16) }        
        behaviour do
          select_goal nearest_mine if current_state(:obj).activated? || goal_needed && !nearest_mine.nil?
        end
      end

      state :coward do
        transition_to(:warrior) { thirst < t(8) && nearness_enemy < t(10) && violence > t(11) }
        transition_to(:conqueror) { thirst < t(12) && nearness_mine < t(13) }
        transition_to(:conqueror) { thirst < t(14) && greed > t(15) }

        behaviour do
          select_goal nearest(@game.taverns) if current_state(:obj).activated? || goal_needed
        end
      end

      state :warrior do
        transition_to(:coward) { thirst > t(1) && nearness_tavern < t(9) }
        transition_to(:coward) { thirst > t(2) }
        transition_to(:coward) { violence < t(3) }

        behaviour do
          @enemy_to = nearest_enemy if current_state(:obj).activated? || goal_needed
          @goal = @aim = nearest_enemy.pos
        end
      end
    end
  end

  def move state
    fade
    if @game.nil?
      Thread.new do
        @game = Game.new state
        set_thresholds @game.board.size
        @distance_max = Math.sqrt(2) * @game.board.size
        @pathf.board = @game.board
        @pathf.compute
        @me = @game.me
        @ready = true
      end
    else
      @game.update state
    end
    evaluate_state
    act
    follow_path
  end

  private
  def goal_needed
    @goal.nil?
  end

  def nearest(arr, *args)
    if args.include?(:distance)
      nearest_el = arr.map { |el| @pathf.search_length(@me.pos, nearest_neighbour(el)) }.min
    else
      nearest_el = arr.min_by { |el| @pathf.search_length(@me.pos, nearest_neighbour(el)) }
    end
    nearest_el
  end

  def nearest_neighbour(el)
    @game.board.passable_neighbours(el).min_by { |n| @pathf.search_length @me.pos, n }
  end

  def follow_path
    return "Stay" if @goal.nil?
    if @game.board.neighbours(@me.pos).include?(@aim)
      n = @aim
      @goal = nil
      @aim = nil
    else
      n = @pathf.search_next(@me.pos, @goal)
    end
    x, y = n
    if x == @me.x
      return "East" if @me.y < y
      return "West" if @me.y > y
    end
    if y == @me.y
      return "South" if @me.x < x
      return "North" if @me.x > x
    end
    "Stay"
  end

  def select_goal aim
    unless aim.nil?
      @aim = aim
      @goal = nearest_neighbour aim
    end
  end

  volatile :thirst, :violence, :greed, :nearest_enemy, :nearest_mine, :nearest_tavern, :nearness_enemy, :nearness_mine,
           :nearness_tavern
  
  # Feelings
  def thirst
    @thirst ||= (100.0 - @me.life) / 100.0
  end

  def violence
    @violence ||= @me.life.to_f / nearest_enemy.life * nearest_enemy.mine_count / @game.mines.count
  end

  def greed
    score_total = @game.heroes.map{ |h| h.gold }.reduce(:+).to_f
    nb_mines_me = @game.mines.select { |m| m.belongs_to? @me }.count.to_f
    nb_mines = @game.mines.count.to_f
    @greed ||= (score_total - @me.gold) / (score_total+1) * (nb_mines - nb_mines_me) / nb_mines
  end

  def nearest_enemy
    @nearest_enemy ||= @game.heroes.select{ |h| h != @me }.min_by { |el| nearest_neighbour [el.x, el.y] }
  end

  def nearness_enemy
    @nearness_enemy ||= @pathf.search_length(@me.pos, nearest_enemy.pos) / @distance_max
  end

  def nearest_mine
    if @nearest_mine.nil?
      n = @game.mines.select{ |m| !m.belongs_to? @me }
      unless n.nil?
        @nearest_mine = nearest(n.map{ |m| m.pos })
      else
        @nearest_mine = nil
      end
    end
    @nearest_mine
  end

  def nearness_mine
    @nearness_mine ||= (nearest_mine.nil? ? @distance_max : @pathf.search_length(@me.pos, nearest_mine)) / @distance_max
  end

  def nearest_tavern
    @nearest_tavern ||= nearest @game.taverns
  end

  def nearness_tavern
    @nearness_tavern ||= @pathf.search_length(@me.pos, nearest_tavern) / @distance_max
  end  
end

