require 'simplecov'
SimpleCov.start
require 'maze'


class MockIO
  # =====  IO methods  =====

  def print(*strings)
    printed.concat strings
    nil
  end

  def puts(*strings)
    strings.map! { |string| string.end_with?("\n") ? string : string + "\n" }
    printed.concat strings
    nil
  end

  # ===== Assertions  =====

  include RSpec::Matchers

  def will_print!(str)
    pristine do
      was_not_printed! str
      yield
      was_printed! str
    end
  end

  def will_not_print!(str)
    pristine do
      was_not_printed! str
      yield
      was_not_printed! str
    end
  end

  def prints_something!
    pristine do
      yield
      expect(printed).to_not be_empty
    end
  end

  def prints_nothing!
    pristine do
      yield
      expect(printed).to be_empty
    end
  end

  def was_printed!(text)
    expect(printed).to be_any { |string| string.include? text }
  end

  def was_not_printed!(text)
    expect(printed).to be_none { |string| string.include? text }
  end

  private

  def printed
    @printed ||= []
  end

  def pristine
    previously_printed = printed
    @printed = []
    yield
  ensure
    @printed = previously_printed
  end
end
