# Copyright (C) 2006-2007 Kurt Stephens <ruby-currency(at)umleta.com>
# See LICENSE.txt for details.

require File.dirname(__FILE__) + '/../source'

# Base class for rate data providers.
# Assumes that rate sources provide more than one rate per query.
class Currency::Exchange::Rate::Source::Provider < Currency::Exchange::Rate::Source::Base

  # Error during parsing of rates.
  class ParserError < ::Currency::Exception::RateSourceError; end

  # The URI used to access the rate source.
  attr_accessor :uri
  
  # The URI path relative to uri used to access the rate source.
  attr_accessor :uri_path
  
  # The Time used to query the rate source.
  # Typically set by #load_rates.
  attr_accessor :date

  # The name is the same as its #uri.
  alias :name :uri 
  
  def initialize(*args)
    super
    @rates = { }
  end

  # Returns the date to query for rates.
  # Defaults to yesterday.
  # TODO: use ActiveSupport here?
  def date
    @date || (Time.now - 24 * 60 * 60) # yesterday.
  end


  # Returns year of query date.
  def date_YYYY
    '%04d' % date.year
  end


  # Return month of query date.
  def date_MM
    '%02d' % date.month
  end


  # Returns day of query date.
  def date_DD
    '%02d' % date.day
  end


  # Returns the URI string as evaluated with this object.
  def get_uri
    uri = instance_eval("\"#{self.uri}\"")
    $stderr.puts "#{self}: uri = #{uri.inspect}" if @verbose
    uri
  end

  # Returns the URI content.
  def get_page_content
    open(get_uri) { |data| data.read }
  end


  # Clear cached rates from this source.
  def clear_rates
    @rates.clear
    super
  end


  # Returns current base Rates or calls load_rates to load them from the source.
  def rates(time = nil)
    time = time && normalize_time(time)
    @rates["#{time}"] ||= load_rates(time)
  end
  

  # Returns an array of base Rates from the rate source.
  #
  # Subclasses must define this method.
  def load_rates(time = nil)
    raise Currency::Exception::SubclassResponsibility, :load_rates
  end


  # Return a matching base rate.
  def get_rate(c1, c2, time)
    # puts "Getting rates for c1: #{c1} and c2: #{c2} at #{time}\n rates: #{rates.map{|r| "#{r.c1}->#{r.c2}"}.inspect}"
    rates.each do | rate |
      # puts " >#{rate.c1} == #{c1} && #{rate.c2} == #{c2} #{rate.c1 == c1} && #{rate.c2.to_s == c2.to_s}< "
      return rate if 
        rate.c1 == c1 &&
        rate.c2.to_s == c2.to_s && # FIXME: understand why this second param needs to be cast to String for specs to pass
        (! time || normalize_time(rate.date) == time)
    end

    nil
  end

  alias :get_rate_base :get_rate


  # Returns true if a rate provider is available.
  def available?(time = nil)
    true
  end

end # class



