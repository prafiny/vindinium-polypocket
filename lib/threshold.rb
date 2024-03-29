require 'yaml'

module Threshold
  class ThresholdCore
    MaxExploration = 0.1
    def initialize file, *opts
      @file = file
      @config = YAML.load(File.read(file))
      if @config['best'].nil?
        @config['best'] = {'score' => {}, 'known' => {}}
      end

      if @config['stats'].nil?
        @config['stats'] = {}
      end
    end

    def set_thresholds map_size
      @map_size = classify map_size
      @param = (@mutate ? mutate(@config['best']['known'][@map_size]) : @config['best']['known'][@map_size]) || @config['initial_solution']
    end

    def save
      File.open(@file, 'w') { |file| file.write @config.to_yaml }
    end

    def refine score
      if !@config['best']['score'].include?(@map_size) || score >= (@config['best']['score'][@map_size] || 0.0)
        puts "New solution for #{@map_size} : #{@param.inspect}"
        @config['best']['score'][@map_size] = score
        @config['best']['known'][@map_size] = @param
      end
    end

    def stat score
      if @config['stats'].include? @map_size
        @config['stats'][@map_size]['mean'] = (@config['stats'][@map_size]['mean'] * @config['stats'][@map_size]['nb'] + score) / (@config['stats'][@map_size]['nb'] + 1)
        @config['stats'][@map_size]['nb'] += 1
      else
        @config['stats'][@map_size] = {'mean' => score, 'nb' => 1}
      end
    end

    def classify size
      case size
        when 0..14 then 'xs'
        when 15..18 then 's'
        when 19..22 then 'm'
        when 23..26 then 'l'
        when 27..30 then 'xl'
      end
    end

    def [] el
      @param[el]
    end

  private
    def mutate thresholds
      return nil if thresholds.nil?
      return thresholds.map do |n|
        n += rand(-MaxExploration..MaxExploration)
        n = 1.0 if n > 1.0
        n = 0.0 if n < 0.0
        n
      end
    end
  end
  
  public
  def set_thresholds *args
    @thresholds.set_thresholds(*args)
  end

  def load_thresholds *args
    @thresholds = ThresholdCore.new(*args)
  end

  def finished
    score = @objective.call
    @thresholds.refine score if @mutate
    @thresholds.stat score
    @thresholds.save
  end

  module_function

  def threshold i
    @thresholds[i-1]
  end

  def t *args
    threshold *args
  end

end
