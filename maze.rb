ENABLE_DRAWING = true

# =====  Maze functions  =====
# uhm, might be nice to have a class here :P
WALL       = '#'.freeze
PATH       = ' '.freeze
START      = 'S'.freeze
FINISH     = 'F'.freeze
PATH_CELLS = [PATH, START, FINISH]

def edges_of(maze, (x, y))
  [[x, y-1], [x-1, y], [x+1, y], [x, y+1]].select { |e| on_board? maze, e }
end

def corners_of(maze, (x,y))
  [[x-1, y-1], [x+1, y-1], [x-1, y+1], [x+1, y+1]].select { |e| on_board? maze, e }
end

def shared_edges(maze, cell1, cell2)
  edges_of(maze, cell1) & edges_of(maze, cell2)
end

def all_cells(maze)
  maze.flat_map.with_index do |row, y|
    row.each_index.map { |x| [x, y] }
  end
end

def path_cells(maze)
  all_cells(maze).select { |cell| path? maze, cell }
end

def no_problem_corners?(maze, cell)
  # we can move here if all the corners are either walls, or if they are paths, then they share exactly 1 path with our cell
  # eg 1 is allowed, 2 and 3 are not
  #
  #  1####  2####  3####  x = cell we're considering making a path
  #   #xs#   #xs#   #x##  c = corner cell that is a path
  #   ##c#   #sc#   ##c#  s = shared path cell
  #   ####   ####   ####  # = wall
  corners_of(maze, cell).all? do |corner|
    num_shared = shared_edges(maze, cell, corner).count { |edge| path? maze, edge }
    wall?(maze, corner) || 1 == num_shared
  end
end

def pathable?(maze, cell)
  x, y = cell
  x > 0                            &&
  y > 0                            &&
  y < maze.length.pred             &&
  x < maze[0].length.pred          &&
  wall?(maze, cell)                &&
  no_problem_corners?(maze, cell)
end

def path?(maze, (x, y))
  PATH_CELLS.include? maze[y][x]
end

def wall?(maze, (x, y))
  maze[y][x] == WALL
end

def on_board?(maze, (x, y))
  0 <= x && 0 <= y && y < maze.length && x < maze[0].length
end

def make_path(maze, (x, y))
  maze[y][x] = PATH
end

def make_start(maze, (x, y))
  maze[y][x] = START
end

def make_finish(maze, (x, y))
  maze[y][x] = FINISH
end

def colour(text, colour)
  colours = {
    black:   [7, 0],
    red:     [7, 1],
    green:   [0, 2],
    orange:  [7, 3],
    blue:    [7, 4],
    magenta: [7, 5],
    cyan:    [0, 6],
    white:   [0, 7],

    fg_black:   [0, 0],
    fg_red:     [1, 0],
    fg_green:   [2, 0],
    fg_orange:  [3, 0],
    fg_blue:    [4, 0],
    fg_magenta: [5, 0],
    fg_cyan:    [6, 0],
    fg_white:   [7, 0],
  }
  fg, bg = colours.fetch colour
  "\e[3#{fg}m\e[4#{bg}m#{text}\e[0m"
end

def colour_cell(maze, (x, y), colour)
  maze[y][x] = colour(maze[y][x], colour)
end

def display(maze, options={})
  return unless ENABLE_DRAWING
  heading  = options.delete :heading
  dup_maze = maze.map(&:dup)
  options.each do |colour, cells|
    cells = [cells] if cells[0].kind_of? Fixnum
    cells.each { |cell| colour_cell dup_maze, cell, colour }
  end

  print "\e[1;1H" # move to top-left
  if heading
    text   = heading.fetch :text
    colour = heading.fetch :colour
    puts colour("=====  #{text}  =====", :"fg_#{colour}")
  end
  puts dup_maze.map { |row| row.zip(row).join.sub(START*2, " #{START}").sub(FINISH*2, " #{FINISH}") }.join("\n")
  sleep 0.01
end

# =====  Building  =====

def pave(maze, crnt, explored)
  explored << crnt
  make_path maze, crnt
  edges_of(maze, crnt).shuffle.each do |edge|
    next if explored.include? edge
    next unless pathable? maze, edge
    one_further = [
      crnt[0] + 2*(edge[0] - crnt[0]),
      crnt[1] + 2*(edge[1] - crnt[1])
    ]
    next if path? maze, one_further
    display maze, heading: {text: "Paving", colour: :red}, green: edge
    pave maze, edge, explored
  end
end

def build_maze(width, height)
  maze = Array.new height do
    Array.new(width) { WALL }
  end
  crnt = [width/2, height/2]
  pave maze, crnt, []
  start, finish = path_cells(maze).shuffle.take(2)
  make_start  maze, start
  make_finish maze, finish
  [maze, start, finish]
end


# =====  The breadth first search  =====

def breadth_first_search(maze, start, finish)
  came_from = {start => start}

  to_explore = [start]

  while to_explore.any?
    current = to_explore.shift
    display maze, heading: {text: 'Searching', colour: :blue}, green: [start, current], blue: came_from.keys, magenta: to_explore, red: finish
    edges_of(maze, current)
      .select { |edge| path? maze, edge }
      .reject { |edge| came_from.key? edge }
      .each   { |edge| came_from[edge] = current
                       to_explore << edge
              }
    break if current == finish
  end

  path = []
  while current != came_from[current]
    path << current
    current = came_from[current]
    display maze, heading: {text: 'Building Path', colour: :green}, magenta: [start, finish], green: current, blue: path, orange: came_from.keys
  end

  path
end

def depth_first_search(maze, current, finish, visited=[])
  return [current] if current == finish

  visited << current
  display maze, heading: {text: 'Searching', colour: :blue},
                green:   current,
                blue:    visited,
                red:     finish

  edges_of(maze, current)
    .select { |edge| path? maze, edge }
    .reject { |edge| visited.include? edge }
    .each   { |edge|
      path = depth_first_search maze, edge, finish, visited
      return path.insert(0, current) if path
    }

  nil
end

def depth_first_search(maze, start, finish)
  visited     = []
  paths_taken = []
  stack       = [
    [start, [start]]
  ]

  loop do
    parent, children = stack.last

    if children.empty?
      stack.pop
      next
    end

    current = children.shift
    visited << current
    break if current == finish

    display maze, heading: {text: 'Searching', colour: :blue},
                  green:   current,
                  blue:    visited,
                  red:     finish

    edges = edges_of(maze, current).select do |edge|
      path?(maze, edge) && edge != parent
    end

    paths_taken << (stack.map(&:first) << current) if edges.empty?

    edges.reject! { |edge| visited.include? edge }
    stack.push [current, edges]
  end

  paths_taken << stack.map(&:first)
  paths_taken
end
