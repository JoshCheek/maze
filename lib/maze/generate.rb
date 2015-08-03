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
        next unless maze.is? maze.cell_line(crnt, edge),
                             pathable_or_edge_attrs
        next unless no_problem_corners? edge
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

    # at least two sides of the block must be completely clear
    def causes_block?(cell)
      each_block_adjacent_to cell do |block|
        next unless all_wall? block
        return block if num_sides_walled(block) < 2
      end
      false
    end

    def num_sides_walled(block)
      xs, ys = block.transpose
      minx, maxx = xs.minmax
      miny, maxy = ys.minmax

      [ [[minx-1, miny  ], [minx-1, maxy  ]],
        [[maxx+1, miny  ], [maxx+1, maxy  ]],
        [[minx  , miny-1], [maxx  , maxy-1]],
        [[minx  , miny+1], [maxx  , maxy+1]],
      ].count { |adjacent| all_wall? adjacent }
    end

    def all_wall?(cells)
      cells.all? do |cell|
        maze.on_board?(cell) && maze.is?(cell, type: :wall)
      end
    end

    def each_block_adjacent_to((x, y))
      yield [[x-1, y-2], [x  , y-2], # upper left
             [x-1, y-1], [x  , y-1]]
      yield [[x  , y-2], [x+1, y-2], # upper right
             [x  , y-1], [x+1, y-1]]
      yield [[x+1, y-1], [x+2, y-1], # right upper
             [x+1, y  ], [x+2, y  ]]
      yield [[x+1, y  ], [x+2, y  ], # right lower
             [x+1, y+1], [x+2, y+1]]
      yield [[x  , y-1], [x+1, y-1], # lower right
             [x  , y-2], [x+1, y-2]]
      yield [[x-1, y-1], [x  , y-1], # lower left
             [x-1, y-2], [x  , y-2]]
      yield [[x-2, y  ], [x-1, y  ], # right lower
             [x-2, y-1], [x-1, y-1]]
      yield [[x-2, y+1], [x-1, y+1], # right upper
             [x-2, y  ], [x-1, y  ]]
    end
  end
end
