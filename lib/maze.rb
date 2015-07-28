require 'maze/display'
require 'maze/generate'

class Maze
  WALL       = '#'.freeze
  PATH       = ' '.freeze
  START      = 'S'.freeze
  FINISH     = 'F'.freeze
  PATH_CELLS = [PATH, START, FINISH].freeze

  attr_reader :width, :height, :start, :finish

  def initialize(width:, height:)
    @width, @height = width, height
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

    loop do
      cell = [x_min + rand(1+x_max-x_min),
              y_min + rand(1+y_max-y_min)]
      return cell if is? cell, type: type
    end
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

  def is?(cell, criteria)
    raise IndexError, "#{cell.inspect} is not on the board!" unless on_board? cell
    x, y = cell
    criteria.all? do |name, value|
      case name
      when :type        then value == :any || type(cell) == value
      when :x_min       then value <= x
      when :x_max       then x <= value
      when :y_min       then value <= y
      when :y_max       then y <= value
      when :traversable then value == PATH_CELLS.include?(maze[y][x])
      else raise ArgumentError, "WTF IS CRITERIA #{name.inspect}"
      end
    end
  end

  def traversible?((x, y))
    PATH_CELLS.include? maze[y][x]
  end

  def breadth_first_search(start, finish, display)
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
    else raise ArgumentError, "WTF IS TYPE #{type}"
    end
  end
end
