require 'spec_helper'

$threshold = 12
$call_num = 0
$request = Hash.new
$cache = Array.new

# This is the main code for testing the Geocode API. Here we analyse the results, convert them to readable JSON,
# create the parameters for the said apis, create a cache for results where the queries get stored into a local cache,
# so that whenever a set of apis+param option is called, the results get stored into the cache and before we do an api call,
# we check the cache to ensure that the results are returned frim there. This helps the scalability of this solution.
# We also ensure that every 12 requests, we put a sleep time of 1 second to respect Google's API Query Limit


class GeocodeGoogle
  attr_accessor :service, :api

  public
  def initialize
    @service = "maps.googleapis.com/"
    @api = "maps/api/geocode/json"

  end

  def increment_call_count #Keeps track of the number of calls
    $call_num = $call_num + 1
    $call_num
  end

  def convert_address_to_query(str) #Converts San Francisco to San+Francisco for the API request
    str = str.gsub(' ', '+')
    str
  end

  def decode(resp) #Decodes the google API response to a localized normal response
    results = Hash.new
    resp = JSONify(resp)
    final_result = Array.new

    if resp["results"].empty?
      return resp
    end

    resp["results"].each do |address|
      address["address_components"].each {|val| results.merge!(:"#{val["types"][0]}"=>val["long_name"])}
      results.merge!(:"formatted_address"=>address["formatted_address"])
      if(address["geometry"].has_key?("bounds"))
        results.merge!(:"northeast_bounds"=>address["geometry"]["bounds"]["northeast"])
        results.merge!(:"southwest_bounds"=>address["geometry"]["bounds"]["southwest"])
      end
      results.merge!(:"latitude"=>address["geometry"]["location"]["lat"].to_f)
      results.merge!(:"longitude"=>address["geometry"]["location"]["lng"].to_f)
      results.merge!(:"location_type"=>address["geometry"]["location_type"])
      results.merge!(:"place_id"=>address["place_id"])
      if(address.has_key?("partial_match"))
        results.merge!(:"partial_match"=>true)
      end
      results.merge!(:"types"=>address["types"][0])
      results.merge!(:"status"=>resp["status"])
      final_result << results
      results = Hash.new
    end
    final_result #Returns an array of results when multiple results are expressed for an API call

  end

  def geocode(query, options = {})

    result = lookup_cache(query, "GEO") #Look Up Cache Request before returning a result
    return result if (!result.empty?)

    queryStr = convert_address_to_query(query)
    postparams = {address: queryStr}
    postparams.merge!(options) if (!options.empty?)
    sleep(1) if (increment_call_count() % $threshold == 0)
    return result if()

    uri = URI("http://#{@service}#{@api}")
    uri.query = URI.encode_www_form(postparams)
    res = Net::HTTP.get_response(uri)
    result = decode(res.body)
    populate_cache(query, postparams, result)
    result

  end

  def rest_call(query) #API Call to just get the response of an API so that we can look for Response Metrics

    queryStr = convert_address_to_query(query)
    postparams = {address: queryStr}
    sleep(1) if (increment_call_count() % $threshold == 0)
    uri = URI("http://#{@service}#{@api}")
    uri.query = URI.encode_www_form(postparams)
    res = Net::HTTP.get_response(uri)
    res

  end

  def reverse_geocode(lat, lng, options = {}) # API Call to Reverse Geocode based on Latitude/Longitude

    postparams = {latlng: "#{lat},#{lng}"}
    postparams.merge!(options) if (!options.empty?)
    sleep(1) if (increment_call_count() % $threshold == 0)
    uri = URI("http://#{@service}#{@api}")
    uri.query = URI.encode_www_form(postparams)
    res = Net::HTTP.get_response(uri)
    result = decode(res.body)
    populate_cache("#{lat},#{lng}", postparams, result)
    result

  end

  def region_biasing(query, region) # API Call to Region Biasing based on optional parameters

    result = lookup_cache(query, "REG", region)
    return result if (!result.empty?)
    queryStr = convert_address_to_query(query)
    postparams = {address: queryStr, region: region}
    sleep(1) if (increment_call_count() % $threshold == 0)
    uri = URI("http://#{@service}#{@api}")
    uri.query = URI.encode_www_form(postparams)
    res = Net::HTTP.get_response(uri)
    result = decode(res.body)
    populate_cache(query, postparams, result)
    result

  end

  def components_filter(query, components) #Components Filter API requests

    result = lookup_cache(query, "COM", components)
    return result if (!result.empty?)
    queryStr = convert_address_to_query(query)
    postparams = {address: queryStr, components: components.gsub(',', '|')}
    sleep(1) if (increment_call_count() % $threshold == 0)
    uri = URI("http://#{@service}#{@api}")
    uri.query = URI.encode_www_form(postparams)
    res = Net::HTTP.get_response(uri)
    result = decode(res.body)
    populate_cache(query, postparams, result)
    result

  end

  def populate_cache(http_addr, api_call, http_resp) #Populate the Localized Cache with the API results

    $request = Hash.new
    $request.merge!(:query_str => http_addr)
    $request.merge!(:params => api_call)
    $request.merge!(:response => http_resp)
    $cache << $request

  end

  def lookup_cache(query, req_type, params={}) #LookUp Cache for the API results

    return_val = Hash.new
    query_str = convert_address_to_query(query)
    if req_type == "COM"
      postparams = {address: query_str, components: params.gsub(',', '|')}
    elsif req_type == "REG"
      postparams = {address: query_str, region: params}
    else
      postparams = {address: query_str}
      postparams.merge!(params) if (!params.empty?)
    end

    $cache.each {|x|
      if (x.values[0]==query && x.values[1]==postparams)
        return_val = x[:response]
        break
      else
        return_val = {}
      end
    }
    return_val
  end

  def print_cache #Prints the results from the Cache
    puts $cache
  end


  def JSONify(response) #Converts the JSON responses into Parsed JSONs

    hash = JSON.parse(response)
    hash

  end

end