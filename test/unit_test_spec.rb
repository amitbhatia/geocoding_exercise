require 'geocode_spec'

class TestApi < MiniTest::Test

  public
  def test_longitude #Test Correct Values for Longitude

    geo = GeocodeGoogle.new
    request = geo.rest_call("230 5th avenue New York")
    assert_equal(request.code.to_i, 200)

    hash = geo.geocode("230 5th avenue New York")
    assert_equal(-73.9883779, hash.first[:longitude])

  end


  def test_latitude #Test Correct Values for Latitude

    geo = GeocodeGoogle.new
    hash = geo.geocode("230 5th avenue New York")
    assert_equal(40.7441554, hash.first[:latitude])

  end


  def test_bad_inputs #Test For Invalid Inputs

    geo = GeocodeGoogle.new
    hash = geo.geocode("0000 Pokerety") # Wrong Addresses or the ones that don't exist
    refute_equal(hash["status"], "OK")
    assert_equal(hash["status"], "ZERO_RESULTS")

    geo = GeocodeGoogle.new
    hash = geo.geocode("South Pole Antarctica") # Partial Address/ Ambiguous
    assert_equal(hash.first[:status], "OK")
    assert_equal(hash.first[:country], "Antarctica")
    assert_equal(hash.first[:location_type], "APPROXIMATE")
    assert_equal(hash.first[:types], "natural_feature")
    assert(hash.first[:partial_match])

    hash = geo.geocode("1 South Pole Antarctica") #Wrong Address again
    assert_empty(hash["results"])
    assert_equal(hash["status"], "ZERO_RESULTS")

    hash = geo.geocode(" ")                       # Empty Strings
    assert_equal(hash["status"], "ZERO_RESULTS")

    # Bug1: When given multiple inputs of the same address, it gives different results
    hash = geo.geocode("230 5th avenue New York 230 5th avenue New York") # Repeated address Twice
    refute_equal(40.7441554, hash.first[:latitude])
    refute_equal(-73.9883779, hash.first[:longitude])

    hash = geo.geocode("230 5th avenue New York 230 5th avenue New York 230 5th avenue New York") # Repeated address Thrice
    assert_equal(40.7441554, hash.first[:latitude])
    assert_equal(-73.9883779, hash.first[:longitude])

  end


  def test_valid_inputs # Test Some Valid Inputs, Airports, Valid Addresses

    geo = GeocodeGoogle.new
    hash = geo.geocode("One Kings Lane San Francisco")
    assert_equal(37.6816738, hash.first[:latitude])

    geo = GeocodeGoogle.new
    hash = geo.geocode("San Francisco International Airport")
    assert_equal(hash.first[:types], "airport")

  end


  def test_geocoding_request #Test all the fields of a valid address; Ensure all the values for the API response are correct

    geo = GeocodeGoogle.new
    hash = geo.geocode("88 Colin P Kelly Jr St, San Francisco, CA 94107")

    assert_equal(hash.first[:street_number], "88")
    assert_equal(hash.first[:route], "Colin P Kelly Junior Street")
    assert_equal(hash.first[:neighborhood], "South Beach")
    assert_equal(hash.first[:locality], "San Francisco")
    assert_equal(hash.first[:administrative_area_level_2], "San Francisco County")
    assert_equal(hash.first[:administrative_area_level_1], "California")
    assert_equal(hash.first[:country], "United States")
    assert_equal(hash.first[:postal_code], "94107")
    assert_match("88 Colin P Kelly Jr St", hash.first[:formatted_address], "City Match")
    assert_equal(hash.first[:latitude], 37.78226710000001)
    assert_equal(hash.first[:longitude], -122.3912479)
    assert_equal(hash.first[:location_type], "ROOFTOP")
    assert_equal(hash.first[:types], "street_address")


    hash = geo.geocode("1600 Pennsylvania Ave NW, Washington, DC 20500")

    assert_equal(hash.first[:premise], "The White House")
    assert_equal(hash.first[:street_number], "1600")
    assert_equal(hash.first[:route], "Pennsylvania Avenue Northwest")
    assert_equal(hash.first[:neighborhood], "Northwest Washington")
    assert_equal(hash.first[:locality], "Washington")
    assert_equal(hash.first[:administrative_area_level_1], "District of Columbia")
    assert_equal(hash.first[:country], "United States")
    assert_equal(hash.first[:postal_code], "20500")
    assert_match("The White House", hash.first[:formatted_address], "Premise Match")
    assert_equal(hash.first[:latitude], 38.8976094)
    assert_equal(hash.first[:longitude], -77.0367349)
    assert_equal(hash.first[:location_type], "ROOFTOP")
    assert_equal(hash.first[:types], "premise")

  end


  def test_bounds

    geo = GeocodeGoogle.new
    hash = geo.geocode("address=Disney Anaheim", {:bounds =>"33.8815471,-117.674604|33.788916,-118.017595"})
    assert_equal(hash.first[:locality], "Anaheim")
    assert_equal(hash.first[:administrative_area_level_2], "Orange County")
    assert_equal(hash.first[:administrative_area_level_1], "California")
    assert_equal(hash.first[:country], "United States")
    assert_equal(hash.first[:formatted_address], "Anaheim, CA, USA")
    assert_equal(hash.first[:latitude], 33.8352932)
    assert_equal(hash.first[:longitude], -117.9145036)
    assert_equal(hash.first[:location_type], "APPROXIMATE")
    assert_equal(hash.first[:partial_match], true)

  end

  def test_region_bias # Test the Region API and ensure different results with extra parameters like country

    geo = GeocodeGoogle.new
    hash1 = geo.geocode("Toledo")
    hash2 = geo.region_biasing("Toledo", "es")
    refute_equal(hash1.first[:country], hash2.first[:country])
    assert_equal(hash2.first[:country], "Spain")
    assert_equal(hash1.first[:country], "United States")

  end


  def test_reverse_geocoding_request # Test reverse geocoding where you get different addresses for given Lat/Longitude Values

    geo = GeocodeGoogle.new
    hash = geo.reverse_geocode("40.714224", "-73.961452")
    assert_equal(hash[0][:formatted_address], "277 Bedford Ave, Brooklyn, NY 11211, USA")
    assert_equal(hash[1][:formatted_address], "Grand St/Bedford Av, Brooklyn, NY 11211, USA")
    assert_equal(hash[2][:formatted_address], "Williamsburg, Brooklyn, NY, USA")
    assert_equal(hash[3][:formatted_address], "Brooklyn, NY, USA")
    assert_equal(hash[4][:formatted_address], "New York, NY, USA")
    assert_equal(hash[5][:formatted_address], "Brooklyn, NY 11211, USA")
    assert_equal(hash[6][:formatted_address], "Kings County, NY, USA")
    assert_equal(hash[7][:formatted_address], "New York, USA")
    assert_equal(hash[8][:formatted_address], "United States")
    assert_match("Brooklyn", hash.first[:formatted_address], "City Match")
    assert_equal("United States", hash.first[:country])

  end


  def test_reverse_geocoding_request_without_key #Test Reverse Geocode with location type without an API Key

    geo = GeocodeGoogle.new
    hash = geo.reverse_geocode("40.714224", "-73.961452", {:location_type => "ROOFTOP"})
    refute_equal(hash["status"], "OK")
    assert_equal(hash["status"], "REQUEST_DENIED")

  end


  def test_reverse_geocoding_combined #Test rev_geocode after geocoding a location

    geo = GeocodeGoogle.new

    hash = geo.geocode("88 Colin P Kelly Jr St, San Francisco, CA 94107")
    assert_equal(hash.first[:latitude], 37.78226710000001)
    assert_equal(hash.first[:longitude], -122.3912479)

    hash = geo.reverse_geocode(hash.first[:latitude], hash.first[:longitude])
    assert_match("88 Colin P Kelly Jr St", hash[1][:formatted_address], "GH HQ Address Matched")

  end


  def test_reverse_geocoding_request_diff_languages # Return reverse geocoded results in different languages

    geo = GeocodeGoogle.new
    hash = geo.geocode("Eiffel Tower, Paris, France")
    assert_equal(hash.first[:status], "OK")

    hash1 = geo.reverse_geocode(hash.first[:latitude], hash.first[:longitude], {:language => "es"}) #Spanish
    hash2 = geo.reverse_geocode(hash.first[:latitude], hash.first[:longitude], {:language => "pl"}) #Poland
    hash3 = geo.reverse_geocode(hash.first[:latitude], hash.first[:longitude], {:language => "pt"}) #Portuguese
    hash4 = geo.reverse_geocode(hash.first[:latitude], hash.first[:longitude], {:language => "nl"}) #Dutch

    assert_equal(hash1.first[:country], "Francia")
    assert_equal(hash2.first[:country], "Francja")
    assert_equal(hash3.first[:country], "France")
    assert_equal(hash4.first[:country], "Frankrijk")

  end


  def test_components_filter #Test the components Filter with multiple inputs

    geo = GeocodeGoogle.new
    comp_list = "locality:delhi,country:india"
    hash = geo.components_filter("New Delhi", comp_list)
    assert_equal(hash.first[:locality], "New Delhi")

    hash1 = geo.components_filter("Santa Cruz", "country:ES") #Components Filter with different countries returns different results
    hash2 = geo.components_filter("Santa Cruz", "country:US")
    assert_equal(hash1.first[:country], "Spain")
    assert_equal(hash2.first[:country], "United States")
    refute_equal(hash1.first[:country], hash2.first[:country])

  end

end