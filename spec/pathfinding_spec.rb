# pathfinding_spec.rb
require_relative '../lib/pathfinding'

class Board
  attr_reader :size
  def initialize size
    @passable = {}
    @size = size
  end
  
  def set_not_passable pos
    @passable[pos] = false
  end
  
  def passable_neighbours pos
    neighbours(pos).find_all { |e| passable?(e) }
  end

  def passable? pos
    @passable[pos].nil?
  end

  def neighbours pos
    x, y = pos
    Enumerator.new do |e|
      e << [x+1, y] if x < @size-1
      e << [x-1, y] if x > 0 
      e << [x, y+1] if y < @size-1 
      e << [x, y-1] if y > 0
    end
  end
end

describe Pathfinding::AStar, "#search_path" do
  astar = Pathfinding::AStar.new
  it "should fetch path to neighbours properly" do
    astar.board = Board.new 10
    expect(astar.search_path([1, 1], [0, 1]).first).to eq([[1, 1], [0, 1]])
    expect(astar.search_path([1, 1], [1, 0]).first).to eq([[1, 1], [1, 0]])
    expect(astar.search_path([1, 1], [1, 2]).first).to eq([[1, 1], [1, 2]])
    expect(astar.search_path([1, 1], [2, 1]).first).to eq([[1, 1], [2, 1]])
  end

  it "should return nil if there's no path" do
    board = Board.new 20
    board.set_not_passable([0, 10])
    astar.board = board
    expect(astar.search_path([1, 1], [0, 10]).first).to eq(nil)
    board = Board.new 20
    board.set_not_passable([0, 10])
    board.set_not_passable([1, 10])
    board.set_not_passable([2, 10])
    board.set_not_passable([3, 10])
    board.set_not_passable([3, 9])
    board.set_not_passable([3, 8])
    board.set_not_passable([3, 7])
    board.set_not_passable([3, 6])
    board.set_not_passable([3, 5])
    board.set_not_passable([3, 4])
    board.set_not_passable([3, 3])
    board.set_not_passable([3, 2])    
    board.set_not_passable([3, 1])
    board.set_not_passable([3, 0])
    astar.board = board
    expect(astar.search_path([1, 1], [0, 10]).first).to eq(nil)
  end

  it "should return the right score" do
    board = Board.new 20
    astar.board = board
    expect(astar.search_path([1, 1], [0, 10])[1]).to eq(10) # 1 + 9 = 10
    (0..10).each do |y|
      board.set_not_passable([5, y])
    end
    expect(astar.search_path([0, 5], [10, 5])[1]).to eq(22)
  end
end

describe Pathfinding::Floyd do
  floyd = Pathfinding::Floyd.new
  it "should fetch path to neighbours properly" do
    floyd.board = Board.new 10
    floyd.compute
    expect(astar.search_path([1, 1], [0, 1]).first).to eq([[1, 1], [0, 1]])
    expect(astar.search_path([1, 1], [1, 0]).first).to eq([[1, 1], [1, 0]])
    expect(astar.search_path([1, 1], [1, 2]).first).to eq([[1, 1], [1, 2]])
    expect(astar.search_path([1, 1], [2, 1]).first).to eq([[1, 1], [2, 1]])
  end

  it "should return nil if there's no path" do
    board = Board.new 20
    board.set_not_passable([0, 10])
    floyd.board = board
    floyd.compute
    expect(astar.search_path([1, 1], [0, 10]).first).to eq(nil)
    board = Board.new 20
    board.set_not_passable([0, 10])
    board.set_not_passable([1, 10])
    board.set_not_passable([2, 10])
    board.set_not_passable([3, 10])
    board.set_not_passable([3, 9])
    board.set_not_passable([3, 8])
    board.set_not_passable([3, 7])
    board.set_not_passable([3, 6])
    board.set_not_passable([3, 5])
    board.set_not_passable([3, 4])
    board.set_not_passable([3, 3])
    board.set_not_passable([3, 2])    
    board.set_not_passable([3, 1])
    board.set_not_passable([3, 0])
    floyd.board = board
    floyd.compute
    expect(astar.search_path([1, 1], [0, 10]).first).to eq(nil)
  end

  it "should return the right score" do
    board = Board.new 20
    floyd.board = board
    floyd.compute
    expect(astar.search_path([1, 1], [0, 10])[1]).to eq(10) # 1 + 9 = 10
    (0..10).each do |y|
      board.set_not_passable([5, y])
    end
    floyd.compute
    expect(astar.search_path([0, 5], [10, 5])[1]).to eq(22)
  end
end

