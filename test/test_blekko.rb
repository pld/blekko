require 'benchmark'
require 'test/unit'

require 'blekko'


class BlekkoTest < Test::Unit::TestCase

  def setup
    @obj = Blekko.new('example.com')
  end

  def test_set_referer
    e = Blekko.new('', 'ref')
    assert_equal 'ref', e.referer
  end

  # requires internet connectivity
  def test_get_search_response
    assert_equal false, @obj.search('nano fibers').empty?
  end

  # requires internet connectivity
  def test_get_num_search_response
    @obj.num_results = 10
    assert_equal 10, @obj.search('nano fibers').length
  end

  # requires internet connectivity
  def test_work_with_fewer_than_limit_returned
    # if 'helicoid' returns >= 100 results this test is trivial
    assert_equal false, @obj.search('helicoid').empty?
  end

  def test_set_start
    assert_equal false, @obj.search('helicoid', 10).empty?
  end

  def test_return_empty_if_not_results
    # if 'Ambiogenesis568' returns results this test is trivial
    assert_equal true, @obj.search('Ambiogenesis568').empty?
  end

  # benchmark
  def test_benchmark_no_asserts
    Benchmark.bm(4) do |x|
      (10..100).step(10) do |max|
        @obj.num_results = max
        x.report("web search #{max}:") { results = @obj.search('helioid') }
      end
    end
  end
end
