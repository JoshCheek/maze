require 'set'
require 'maze'

class Maze
  class Generate
    def self.call(attrs, &on_pave)
      new(attrs, &on_pave).call
    end

    attr_accessor :width, :height, :maze, :explored, :on_pave

    def initialize(width:, height:, &on_pave)
      self.width    = width
      self.height   = height
      self.on_pave  = on_pave || Proc.new { }
      self.explored = Set.new
      self.maze     = Maze.new width: width, height: height
    end

    def call
      start = maze.random_cell pathable_attrs
      pave(start)
      finish = explored.select { |cell| cell != start }.shuffle.first
      maze.set(:start, start).set(:finish, finish)
    end

    private

    def pave(crnt)
      explored << crnt
      maze.set :path, crnt
      on_pave.call crnt, self
      maze.edges_of(crnt).shuffle.each do |edge|
        next if     explored.include? edge
        next unless maze.is? edge, pathable_attrs
        next unless no_problem_corners? edge
        next unless maze.is? maze.cell_line(crnt, edge), pathable_or_edge_attrs
        pave edge
      end
    end

    def pathable_or_edge_attrs
      { type:  :wall,
        x_min: 0,
        x_max: width-1,
        y_min: 0,
        y_max: height-1,
      }
    end

    def pathable_attrs
      { type:  :wall,
        x_min: 1,
        x_max: width-2,
        y_min: 1,
        y_max: height-2,
      }
    end

    # we can move here if all the corners are either walls,
    # or if they are paths, they share exactly 1 path with our cell
    # eg 1 is allowed, 2 and 3 are not
    #
    #  1####  2####  3####  x = cell we're considering making a path
    #   #xs#   #xs#   #x##  c = corner cell that is a path
    #   ##c#   #sc#   ##c#  s = shared path cell
    #   ####   ####   ####  # = wall
    def no_problem_corners?(cell)
      maze.corners_of(cell).all? do |corner|
        num_shared = maze.shared_edges(cell, corner).count { |edge| maze.is? edge, type: :path }
        maze.is?(corner, type: :wall) || 1 == num_shared
      end
    end
  end
end
