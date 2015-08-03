require 'maze'
class Maze
  class GenerateLsystem
    def self.call(attrs)
      new(attrs).call
    end

    attr_accessor :times, :axiom, :rules

    def initialize(times:, axiom:, rules:)
      self.times     = times
      self.axiom     = axiom
      self.rules     = rules
    end

    def call
      production = production_for(times, axiom, rules)
      path       = normalize traverse production
      maze       = maze_for path
      add_start_and_finish maze
    end

    def production_for(times, axiom, rules)
      times.times.inject axiom.chars do |production, _|
        production.flat_map do |char|
          rules.fetch(char, char).chars
        end
      end
    end

    def traverse(production)
      x = y = 0
      direction = [ [1,  0], # east
                    [0, -1], # south
                    [-1, 0], # west
                    [0,  1], # north
                  ]
      traversal = [[x, y]]

      production.each do |char|
        case char
        when '-'
          direction.rotate!(1)
        when '+'
          direction.rotate!(-1)
        when 'F' then
          xdelta, ydelta = direction[0]
          traversal << [x+=xdelta, y+=ydelta]
          traversal << [x+=xdelta, y+=ydelta]
        when *rules.keys # noop
        else raise "WAT: #{char.inspect}"
        end
      end

      traversal
    end

    # moves the path over so that its xmin and ymin are 0
    def normalize(path)
      xdelta, ydelta = path.transpose.map { |positions| 0 - positions.min }
      path.map { |x, y| [x+xdelta, y+ydelta] }
    end

    def maze_for(path)
      xmax, ymax = path.transpose.map(&:max)
      maze = Maze.new width: xmax+3, height: ymax+3
      path.each { |(x, y)| maze.set(:path, [x+1, y+1]) }
      maze
    end

    def add_start_and_finish(maze)
      start  = maze.random_cell type: :path
      finish = maze.random_cell type: :path
      finish = maze.random_cell type: :path while start == finish
      maze.set :start,  start
      maze.set :finish, finish
      maze
    end
  end
end
