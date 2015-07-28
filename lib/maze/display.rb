class Maze
  class Display
    def self.null
      new enable: false
    end

    DEFAULT_COLOURS = {
        black:      [7, 0],
        red:        [7, 1],
        green:      [0, 2],
        orange:     [7, 3],
        blue:       [7, 4],
        magenta:    [7, 5],
        cyan:       [0, 6],
        white:      [0, 7],

        fg_black:   [0, 0],
        fg_red:     [1, 0],
        fg_green:   [2, 0],
        fg_orange:  [3, 0],
        fg_blue:    [4, 0],
        fg_magenta: [5, 0],
        fg_cyan:    [6, 0],
        fg_white:   [7, 0],
    }.freeze
    DEFAULT_COLOURS.values.each(&:freeze)

    attr_accessor :enabled, :stream, :colours

    def initialize(enable:,
                   stream:  (raise "A stream must be provided when Display is enabled!" if enable),
                   colours: DEFAULT_COLOURS
                  )
      self.colours = colours
      self.enabled = enable
      self.stream  = stream
    end

    alias enabled? enabled

    def call(maze:, **options)
      return unless enabled?
      heading    = options.delete(:heading) || {text: "Debugging (#{caller[0]})", colour: :red}
      maze_array = maze.to_raw_arrays
      options.each do |colour, cells|
        cells = [cells] if cells[0].kind_of? Fixnum
        cells.each { |cell| colour_cell maze_array, cell, colour }
      end

      stream.print "\e[1;1H" # move to top-left
      text   = heading.fetch :text
      colour = heading.fetch :colour, :red
      stream.puts colour("=====  #{text}  =====", :"fg_#{colour}")
      stream.puts maze_array.map { |row| row.zip(row).join }
                            .join("\n")
                            .gsub(Maze::START*2, " #{Maze::START}")
                            .gsub(Maze::FINISH*2, " #{Maze::FINISH}")
      sleep 0.01
    end

    def clear
      stream.print "\e[H\e[2J"
    end

    def without_cursor(&block)
      hide_cursor
      block.call
    ensure
      show_cursor
    end

    def hide_cursor
      stream.print "\e[?25l"
    end

    def show_cursor
      stream.print "\e[?25h"
    end

    def colour(text, colour)
      fg, bg = colours.fetch colour
      "\e[3#{fg}m\e[4#{bg}m#{text}\e[0m"
    end

    def colour_cell(maze_array, (x, y), colour)
      maze_array[y][x] = colour(maze_array[y][x], colour)
    end
  end
end
