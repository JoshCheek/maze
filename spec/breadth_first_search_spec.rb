require 'spec_helper'
require 'maze/breadth_first_search'

RSpec.describe Maze::BreadthFirstSearch do
  include SpecHelpers

  it 'searches nodes it finds in the order it finds them until it hits the end, then traces the path back' do
    events        = []
    on_search     = lambda { |cell, bfs| events << [:search,     cell] }
    on_build_path = lambda { |cell, bfs| events << [:build_path, cell] }
    maze          = maze_for <<-MAZE
    #######
    #S    #
    ### ###
    #F  ###
    #######
    MAZE
    described_class.call maze: maze, start: maze.start, finish: maze.finish, on_search: on_search, on_build_path: on_build_path
    expect(events).to eq [
      [:search,     [1, 1]],
      [:search,     [2, 1]],
      [:search,     [3, 1]],
      [:search,     [4, 1]],
      [:search,     [3, 2]],
      [:search,     [5, 1]],
      [:search,     [3, 3]],
      [:search,     [2, 3]],
      [:build_path, [2, 3]],
      [:build_path, [3, 3]],
      [:build_path, [3, 2]],
      [:build_path, [3, 1]],
      [:build_path, [2, 1]],
      [:build_path, [1, 1]]
    ]
  end

  it 'keeps track of which cells it has already expored' do
    seens = [
      [[1,1]],
      [[1,1],[2,1]],
      [[1,1],[2,1],[3,1]],
    ]

    on_search = lambda { |cell, bfs| expect(bfs.explored).to eq seens.shift }
    maze      = maze_for <<-MAZE
    #####
    #S F#
    #####
    MAZE
    bfs = described_class.new maze: maze, start: maze.start, finish: maze.finish, on_search: on_search
    bfs.call
    expect(bfs.explored).to eq seens.shift
  end

  it 'returns the path from the start to the finish' do
    maze = maze_for <<-MAZE
    #######
    #S    #
    ### ###
    #F  ###
    #######
    MAZE
    path = described_class.call maze: maze, start: maze.start, finish: maze.finish
    expect(path).to eq [[1,1], [2,1], [3,1], [3,2], [3,3], [2,3], [1,3]]
  end
end
