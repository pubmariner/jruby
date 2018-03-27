require 'test/unit'

class TestTime < Test::Unit::TestCase

  def test_add_many_under_ms
    t = Time.new(2000, 1, 1, 0, 0, 0)
    t += Rational(123456789, 1_000_000_000)
    assert_equal 123456789, t.nsec
    delta = Rational(999, 1000_000)
    1000.times do
      t += delta
    end
    # JRuby used to let NSec go above 10^6
    assert_equal [1, 122456789], [t.sec, t.nsec]
  end

  def test_tz_without_minutes
    begin
      old_tz, ENV['TZ'] = ENV['TZ'], 'JST-9'
      assert_nothing_raised {
        time = Time.at(86400)
        assert_equal '1970-01-02T09:00:00+0900', time.strftime('%FT%T%z')
      }
    ensure
      ENV['TZ'] = old_tz
    end
  end

  def test_tz_with_minutes
    begin
      old_tz, ENV['TZ'] = ENV['TZ'], 'UTC+5:45'
      assert_nothing_raised {
        time = Time.at(86400)
        assert_equal '1970-01-01T18:15:00-0545', time.strftime('%FT%T%z')
      }
    ensure
      ENV['TZ'] = old_tz
    end
  end

  def test_nsec_rounding # GH-843
    t1 = Time.utc(2013,6,30,14,56,14,263031.604)
    t2 = Time.utc(2013,6,30,14,56,14,263031.605)
    assert_equal t1.usec, t2.usec
    assert_not_equal t1.nsec, t2.nsec
    assert_false t1 == t2
  end

  def test_large_add # GH-1779
    t = Time.local(2000, 1, 1) + (400 * 366 * 24 * 60 * 60)
    assert_equal 2400, t.year
  end

  def test_far_future
    now = Time.now
    t1 = now + 80000000000
    t2 = now + 90000000000
    assert_false t1 == t2
  end

  def test_end_of_day
    time = time_change(Time.now,
        :hour => 23,
        :min => 59,
        :sec => 59,
        :usec => Rational(999_999_999, 1000)
    )

    assert_equal 23, time.hour
    assert_equal 59, time.min
    assert_equal 59, time.sec
    assert_equal Time.now.zone, time.zone
    assert_equal 999999999, time.nsec
  end

  def time_change(time, options) # from ActiveSupport
    new_year  = options.fetch(:year, time.year)
    new_month = options.fetch(:month, time.month)
    new_day   = options.fetch(:day, time.day)
    new_hour  = options.fetch(:hour, time.hour)
    new_min   = options.fetch(:min, options[:hour] ? 0 : time.min)
    new_sec   = options.fetch(:sec, (options[:hour] || options[:min]) ? 0 : time.sec)

    if new_nsec = options[:nsec]
      raise ArgumentError, "Can't change both :nsec and :usec at the same time: #{options.inspect}" if options[:usec]
      new_usec = Rational(new_nsec, 1000)
    else
      new_usec  = options.fetch(:usec, (options[:hour] || options[:min] || options[:sec]) ? 0 : Rational(time.nsec, 1000))
    end

    if time.utc?
      ::Time.utc(new_year, new_month, new_day, new_hour, new_min, new_sec, new_usec)
    elsif time.zone
      ::Time.local(new_year, new_month, new_day, new_hour, new_min, new_sec, new_usec)
    else
      raise ArgumentError, 'argument out of range' if new_usec >= 1000000
      ::Time.new(new_year, new_month, new_day, new_hour, new_min, new_sec + (new_usec.to_r / 1000000), time.utc_offset)
    end
  end
  private :time_change

end

class TestTimeNilOps < Test::Unit::TestCase
  def test_minus
    begin
      Time.now - ()
    rescue TypeError=>x
      assert x
      assert_equal "no implicit conversion to rational from nil", x.message
    end
  end
  def test_plus
    begin
      Time.now + ()
    rescue TypeError=>x
      assert x
      assert_equal "no implicit conversion to rational from nil", x.message
    end
  end
  def test_times
    t = Time.now
    begin
      _ = t * ()
      fail "bleh"
    rescue NoMethodError=>x
      assert x
      assert_equal "undefined method `*' for #{t}:Time", x.message
    end
  end
  def test_div
    t = Time.now
    begin
      _ = t / ()
      fail "bleh"
    rescue NoMethodError=>x
      assert x
      assert_equal "undefined method `/' for #{t}:Time", x.message
    end
  end

end
