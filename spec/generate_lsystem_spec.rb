require 'spec_helper'
require 'maze/generate_lsystem'

RSpec.describe Maze::GenerateLsystem do
  def hilbert(n)
    described_class.call times: n,
                         axiom: "A",
                         rules: {
                           "A" => "-BF+AFA+FB-",
                           "B" => "+AF-BFB-FA+",
                         }
  end

  it 'generates a hilbert curve from the lsystem' do
    maze_str = hilbert(2).to_raw_arrays.map { |row|
      row.map { |c| c == :wall ? '#' : " " } << "\n"
    }.join

    expect(maze_str).to eq "#########\n" +
                           "#   #   #\n" +
                           "# # # # #\n" +
                           "# #   # #\n" +
                           "# ##### #\n" +
                           "#   #   #\n" +
                           "### # ###\n" +
                           "#   #   #\n" +
                           "#########\n"
  end

  it 'picks a random start' do
    starts = 10.times.map { hilbert(2).start }.uniq
    expect(starts.uniq.length).to be > 1
  end

  it 'picks a random finish' do
    finishes = 10.times.map { hilbert(2).finish }.uniq
    expect(finishes.uniq.length).to be > 1
  end
end


__END__
  * Hilbert
    - Axiom: A
    - A -> - B F + A F A + F B -
    - B -> + A F - B F B - F A +
  * Dragon Curve L-System:
    - Axiom: FX
    - X -> X+YF
    - Y -> FX-Y
    - Use 90 degree turns
  * Quadratic Fractal:
    - Axiom: F+F+F+F
    - F -> F+F-F
    - Use 90 degree turns
  * Koch Curve Variant:
    - Axiom = F
    - F -> F+F-F-F+F
    - Use 90 degree turns
