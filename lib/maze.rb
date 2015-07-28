require 'maze/display'

class GenerateMaze
  def self.call(attrs)
    new(attrs).call
  end

  def initialize(width:, height:, display:)
    self.width    = width
    self.height   = height
    self.explored = []
    self.display  = display
    self.maze     = Maze.new width: width, height: height, display: display
  end

  def call
    start = maze.random_cell pathable_attrs
    pave(start)
    finish = explored.select { |cell| cell != start }.shuffle.first
    maze.set(:start, start).set(:finish, finish)
  end

  private

  attr_accessor :width, :height, :maze, :explored, :display

  def pave(crnt)
    explored << crnt
    maze.set :path, crnt
    # display.call heading: {text: "Paving", colour: :red}, maze: maze, green: crnt
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



class Maze
  WALL       = '#'.freeze
  PATH       = ' '.freeze
  START      = 'S'.freeze
  FINISH     = 'F'.freeze
  PATH_CELLS = [PATH, START, FINISH].freeze

  attr_reader :width, :height, :start, :finish
  attr_accessor :display

  def initialize(width:, height:, display: Display.new)
    @width, @height = width, height
    self.display = display
    self.maze = Array.new height do
      Array.new(width) { WALL }
    end
  end

  def random_cell(criteria={})
    type  = criteria.fetch :type,  :any
    x_min = criteria.fetch :x_min, 0
    x_max = criteria.fetch :x_max, width-1
    y_min = criteria.fetch :y_min, 0
    y_max = criteria.fetch :y_max, height-1

    100.times do
      cell = [
        x_min + rand(x_max-x_min),
        y_min + rand(y_max-y_min)
      ]
      return cell if type == type(cell)
    end
    raise "100 iterations in, we couldn't find one good enough for #{criteria.inspect}"
  end

  def type((x, y))
    case maze[y][x]
    when '#' then :wall
    when ' ' then :path
    when 'S' then :start
    when 'F' then :finish
    else raise "WTF IS #{maze[y][x].inspect}, at y=#{y}, x=#{x}"
    end
  end

  def set(type, cell)
    if type == :start
      self.start = cell
    elsif type == :finish
      self.finish = cell
    end
    x, y = cell
    maze[y][x] = char_for(type)
    self
  end

  def edges_of((x, y))
    [[x, y-1], [x-1, y], [x+1, y], [x, y+1]].select { |e| on_board? e }
  end

  def corners_of((x,y))
    [[x-1, y-1], [x+1, y-1], [x-1, y+1], [x+1, y+1]].select { |e| on_board? e }
  end

  def on_board?((x, y))
    0 <= x && 0 <= y && y < height && x < width
  end

  # FIXME
  def is?(cell, criteria)
    x, y = cell
    criteria.all? do |name, value|
      case name
      when :type  then type(cell) == value
      when :x_min then value <= x
      when :x_max then x <= value
      when :y_min then value <= y
      when :y_max then y <= value
      else raise "WTF IS CRITERIA #{name.inspect}"
      end
    end
  end

  def traversible?((x, y))
    PATH_CELLS.include? maze[y][x]
  end

  def breadth_first_search(start, finish)
    came_from  = {start => start}  # record the how we got to each cell so we can reconstruct the path
    to_explore = [start]           # a queue of where to search next

    # search until we run out of places to look, or find the target
    while finish != (current = to_explore.shift)
      display.call heading: {text: 'Searching', colour: :blue},
                   maze:    self,
                   green:   [start, current],
                   blue:    came_from.keys,
                   magenta: to_explore,
                   red:     finish

      edges_of(current).each do |edge|
        next unless traversible? edge
        next if     came_from.key? edge
        came_from[edge] = current
        to_explore << edge
      end
    end

    path = []
    while current != came_from[current]
      path << current
      current = came_from[current]
      display.call maze:    self,
                   heading: {text: 'Building Path', colour: :green},
                   magenta: [start, finish],
                   green:   current,
                   blue:    path,
                   orange:  came_from.keys
    end
    path
  end

  def to_raw_arrays
    maze.map(&:dup)
  end

  def shared_edges(cell1, cell2)
    edges_of(cell1) & edges_of(cell2)
  end

  def cell_line(from, to)
    [ from[0] + 2*(to[0] - from[0]),
      from[1] + 2*(to[1] - from[1])
    ]
  end

  private

  attr_writer :start, :finish
  attr_accessor :maze

  def char_for((type))
    case type
    when :wall   then '#'
    when :path   then ' '
    when :start  then 'S'
    when :finish then 'F'
    else raise "WTF IS TYPE #{type}"
    end
  end
end