require 'spec_helper'

RSpec.describe Maze::Display do
  specify '.null returns an unenabled display' do
    expect(described_class.null).to be_a_kind_of described_class
    expect(described_class.null).to_not be_enabled
  end

  let(:stream)           { MockIO.new }

  let(:display)          { described_class.new enable: true, stream: stream }
  let(:enabled)          { display }
  let(:disabled)         { described_class.new enable: false, stream: stream }
  let(:ansi_clear)       { "\e[H\e[2J" }
  let(:ansi_hide_cursor) { "\e[?25l" }
  let(:ansi_show_cursor) { "\e[?25h" }

  it 'blows up if not told whether to be enabled' do
    expect { described_class.new stream: stream }.to raise_error ArgumentError, /enable/
  end

  it 'blows up if enabled and not given a stream' do
    described_class.new enable: false
    expect { described_class.new enable: true }.to raise_error ArgumentError, /enable/
  end

  describe '#clear' do
    it 'prints the clear escape sequence' do
      stream.will_print!(ansi_clear) { display.clear }
    end

    it 'prints nothing when disabled' do
      stream.prints_something! { enabled.clear }
      stream.prints_nothing!   { disabled.clear }
    end
  end

  describe '#hide_cursor' do
    it 'prints the hide_cursor escape sequence' do
      stream.will_print!(ansi_hide_cursor) { display.hide_cursor }
    end

    it 'prints nothing when disabled' do
      stream.prints_something! { enabled.hide_cursor }
      stream.prints_nothing!   { disabled.hide_cursor }
    end
  end

  describe '#show_cursor' do
    it 'prints the show_cursor escape sequence' do
      stream.will_print!(ansi_show_cursor) { display.show_cursor }
    end

    it 'prints nothing when disabled' do
      stream.prints_something! { enabled.show_cursor }
      stream.prints_nothing!   { disabled.show_cursor }
    end
  end

  describe '#without_cursor' do
    it 'hides the cursor for the duration of the block, ensuring it gets turned back on' do
      expect do
        display.without_cursor do
          stream.was_printed!     ansi_hide_cursor
          stream.was_not_printed! ansi_show_cursor
          raise 'omg'
        end
      end.to raise_error 'omg'
      stream.was_printed! ansi_show_cursor
    end
  end

  describe '#call' do
    let(:maze) { Maze.new width: 2, height: 2 }

    it 'prints the heading, and maze' do
      display.call heading: {text: "SOME HEADER", colour: :red}, maze: maze
      stream.was_printed! "SOME HEADER"
      stream.was_printed! "####\n"*2 # what it should print for 2 rows of walls
    end

    it 'defaults the heading to "Debugging"' do
      stream.will_not_print!("Debugging") do
        display.call maze: maze, heading: {text: "SOME HEADER", colour: :red}
      end

      stream.will_print!("Debugging") do
        display.call maze: maze
      end
    end

    it 'doesn\'t blow up when given the various colours (going to not bother testing their escape sequences)' do
      colours    = Maze::Display::DEFAULT_COLOURS.keys
      attributes = colours.map { |colour| [colour, [0, 0]] }.to_h
      display.call maze: maze, **attributes
    end

    it 'respects the provided duration'
    it 'defaults the duration to 0'

    it 'prints nothing when disabled' do
      stream.prints_something! { enabled.call maze: maze }
      stream.prints_nothing!   { disabled.call maze: maze }
    end

    context 'when printing the maze' do
      it 'prints "##" for a wall' do
        stream.will_print!('##') { display.call maze: maze }
        maze.set :path, [0, 0]
        maze.set :path, [1, 0]
        maze.set :path, [0, 1]
        maze.set :path, [1, 1]
        stream.will_not_print!('##') { display.call maze: maze }
      end

      it 'prints "  " for a path' do
        # have to include the wall that comes after it, b/c two spaces is too generic, it unintentionally matches
        stream.will_not_print!('  ##') { display.call maze: maze }
        maze.set :path, [0, 0]
        stream.will_print!('  ##') { display.call maze: maze }
      end

      it 'prints " S" for the start' do
        stream.will_not_print!(' S') { display.call maze: maze }
        maze.set :start, [0, 0]
        stream.will_print!(' S') { display.call maze: maze }
      end

      it 'prints " F" for the finish' do
        stream.will_not_print!(' F') { display.call maze: maze }
        maze.set :finish, [0, 0]
        stream.will_print!(' F') { display.call maze: maze }
      end
    end
  end
end
