require 'set'
require 'maze'

class Maze
  class GenerateLsystem
    def self.hilbert(n)
      GenerateLsystem.call invert: true,
                           times:  n,
                           axiom:  "A",
                           rules:  {
                             "A" => "-BF+AFA+FB-",
                             "B" => "+AF-BFB-FA+",
                           }
    end

    def self.dragon(n)
      GenerateLsystem.call invert: false,
                           times:  n,
                           axiom:  'FX',
                           rules:  {
                             "X" => "X+YF",
                             "Y" => "FX-Y",
                           }
    end

    def self.quadratic_fractal(n)
      GenerateLsystem.call invert: false,
                           times:  n,
                           axiom:  'F+F+F+F',
                           rules:  {
                             "F" => "F+F-F",
                           }
    end

    def self.koch(n)
      GenerateLsystem.call invert: false,
                           times:  n,
                           axiom:  'F',
                           rules:  {
                             "F" => "F+F-F-F+F",
                           }
    end

    def self.hilbert2(n)
      GenerateLsystem.call invert: true,
                           times:  n,
                           axiom:  'X',
                           rules:  {
                             "X" => "XFYFX+F+YFXFY-F-XFYFX",
                             "Y" => "YFXFY-F-XFYFX+F+YFXFY",
                           }
    end

    def self.call(attrs)
      new(attrs).call
    end

    attr_accessor :times, :axiom, :rules, :invert

    def initialize(times:, axiom:, rules:, invert:)
      self.times  = times
      self.axiom  = axiom
      self.rules  = rules
      self.invert = invert
    end

    def call
      production = production_for(times, axiom, rules)
      path       = traverse production
      path       = normalize path
      maze       = maze_for path, invert: invert
      maze       = add_start_and_finish maze
      maze       = trim_wall_masses     maze
      maze
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

    def maze_for(path, invert:)
      if invert
        inverted_generate path
      else
        normal_generate path
      end
    end

    def inverted_generate(path)
      walls = Set.new path.map { |x, y| [x+2, y+2] }
      xmax, ymax = walls.to_a.transpose.map(&:max)
      maze = Maze.new width: xmax+3, height: ymax+3
      1.upto ymax+1 do |y|
        1.upto xmax+1 do |x|
          cell = [x, y]
          maze.set :path, cell unless walls.include? cell
        end
      end
      maze
    end

    def normal_generate(path)
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

    def trim_wall_masses(maze)
      maze.each_cell do |cell|
        next if maze.neighbours_of(cell).any? { |n| maze.is? n, traversable: true }
        maze.set :invisible_wall, cell
      end
      maze
    end
  end
end
