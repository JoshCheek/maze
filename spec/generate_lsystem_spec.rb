require 'spec_helper'
require 'maze/generate_lsystem'

RSpec.describe Maze::GenerateLsystem do
  def hilbert(n)
    described_class.hilbert(n)
  end

  def dragon(n)
    described_class.dragon(n)
  end

  it 'generates a hilbert curve from the lsystem' do
    maze_str = hilbert(2).to_raw_arrays.map { |row|
      row.map { |c| c == :wall ? '#' : " " } << "\n"
    }.join

    expect(maze_str).to eq "###########\n" +
                           "#         #\n" +
                           "# ### ### #\n" +
                           "# # # # # #\n" +
                           "# # ### # #\n" +
                           "# #     # #\n" +
                           "# ### ### #\n" +
                           "#   # #   #\n" +
                           "# ### ### #\n" +
                           "#         #\n" +
                           "###########\n"
  end

  it 'generates a dragon curve lsystem' do
    maze_str = dragon(3).to_raw_arrays.map { |row|
      row.map { |c| c == :wall ? '#' : " " } << "\n"
    }.join

    expect(maze_str).to eq "###########\n" +
                           "#         #\n" +
                           "#     ### #\n" +
                           "#       # #\n" +
                           "# ### ### #\n" +
                           "# # # #   #\n" +
                           "# # ###   #\n" +
                           "#         #\n" +
                           "###########\n"
  end

  it 'picks a random start' do
    starts = 10.times.map { hilbert(2).start }.uniq
    expect(starts.uniq.length).to be > 1
  end

  it 'picks a random finish' do
    finishes = 10.times.map { hilbert(2).finish }.uniq
    expect(finishes.uniq.length).to be > 1
  end

  it 'gives padding around the edge to prevent islands' do
    path_cells = Set.new
    maze       = hilbert(2)
    maze.each_cell { |cell| path_cells << cell if maze.is? cell, traversable: true }
    connected = Set.new << path_cells.first

    loop do
      break if path_cells.empty?
      to_reject = path_cells.select do |(x, y)|
        connected.include?([x-1, y  ]) ||
        connected.include?([x+1, y  ]) ||
        connected.include?([x  , y-1]) ||
        connected.include?([x  , y+1])
      end

      break if to_reject.empty?
      path_cells -= to_reject
      connected += to_reject
    end

    expect(path_cells).to be_empty
  end

end


__END__
  * Quadratic Fractal:
    - Axiom: F+F+F+F
    - F -> F+F-F
    - Use 90 degree turns
  * Koch Curve Variant:
    - Axiom = F
    - F -> F+F-F-F+F
    - Use 90 degree turns
