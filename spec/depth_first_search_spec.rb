require 'spec_helper'
require 'maze/depth_first_search'

RSpec.describe Maze::DepthFirstSearch do
  include SpecHelpers

  def dfs_for(maze, &block)
    described_class.call maze: maze, start: maze.start, finish: maze.finish, &block
  end

  let(:maze) { maze_for <<-MAZE }
    ########
    #S     #
    ### # ##
    #  F####
    ########
  MAZE

  it 'searches each path completely before backtracking and trying the next one' do
    path = []
    dfs_for(maze) { |cell, dfs| path << cell }
    expect(path).to eq [
      [1, 1], [2, 1], [3, 1], [4, 1], [5, 1], [6, 1], # all the way to the right
                      [5, 2],                         # then backtrack to another dead end
                      [3, 2], [3, 3],                 # then backtrack to successful path
    ]
  end

  it 'keeps track of which cells it has already expored' do
    seens = [ [[0,0]],
              [[0,0],[1,0]],
              [[0,0],[1,0],[2,0]],
            ]
    maze = maze_for "S F"
    dfs_for(maze) { |cell, dfs| expect(dfs.explored).to eq seens.shift }
    expect(seens).to be_empty
  end

  it 'keeps track of all its failed paths, successful, and all paths' do
    failed_paths = [ [[1,1], [2,1], [3,1], [4,1], [5,1], [6,1]], # right wall
                     [[1,1], [2,1], [3,1], [4,1], [5,1], [5,2]], # 2nd turn
                   ]
    success_path = [[1, 1], [2, 1], [3, 1], [3, 2], [3, 3]]
    all_paths    = [*failed_paths, success_path]
    dfs          = dfs_for maze

    expect(dfs.failed_paths).to eq failed_paths
    expect(dfs.success_path).to eq success_path
    expect(dfs.all_paths   ).to eq all_paths
  end
end
