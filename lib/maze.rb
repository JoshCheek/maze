class Maze
  WALL        = :wall
  INVISI_WALL = :invisible_wall
  PATH        = :path
  START       = :start
  FINISH      = :finish
  ALL         = [WALL, PATH, INVISI_WALL, START, FINISH].freeze
  PATH_CELLS  = (ALL - [WALL, INVISI_WALL]).freeze

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
    maze[y][x]
  end

  def set(type, cell)
    ALL.include? type or raise ArgumentError, "Unknown type: #{type.inspect}"
    if    type == :start  then self.start  = cell
    elsif type == :finish then self.finish = cell
    end
    maze[cell[1]][cell[0]] = type
    self
  end

  def edges_of((x, y))
    [[x, y-1], [x-1, y], [x+1, y], [x, y+1]].select { |e| on_board? e }
  end

  def corners_of((x,y))
    [[x-1, y-1], [x+1, y-1], [x-1, y+1], [x+1, y+1]].select { |e| on_board? e }
  end

  def neighbours_of(cell)
    edges_of(cell) + corners_of(cell)
  end

  def on_board?((x, y))
    0 <= x && 0 <= y && y < height && x < width
  end

  def is?(cell, criteria)
    on_board? cell or raise IndexError, "#{cell.inspect} is not on the board!"
    x, y = cell
    criteria.all? do |name, value|
      case name
      when :type        then value == :any || type(cell) == value
      when :x_min       then value <= x
      when :x_max       then x <= value
      when :y_min       then value <= y
      when :y_max       then y <= value
      when :traversable then value == PATH_CELLS.include?(type cell)
      else raise ArgumentError, "WTF IS CRITERIA #{name.inspect}"
      end
    end
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

  def each_cell
    maze.each_with_index do |row, y|
      row.each_index do |x|
        yield [x, y]
      end
    end
  end

  private

  attr_writer :start, :finish
  attr_accessor :maze
end
