# Test Plan

 This is a solution for testing the Geocode API. Here we analyse the results, convert them to readable JSON,
 create the parameters for the said apis, create a cache for results where the queries get stored into a local cache,
 so that whenever a set of apis+param option is called, the results get stored into the cache and before we do an api call,
 we check the cache to ensure that the results are returned frim there. This helps the scalability of this solution.

 We also ensure that every 12 requests, we put a sleep time of 1 second to respect Google's API Query Limit


## How to run the program?

After checking out the repository, just change directory to geocode_exercise and then run the command:
bundle exec rspec spec/test/unit_test_spec.rb

This should run all the assertions given in the file for testing the google maps geocoding api.

## Tests and Expected Results:

1.) test_longitude: Test Longitude Values of the Input given to the geocoding request along with request parameters

2.) test_latitude: Test Latitude Values of the Input given to the request

3.) test_bad_inputs: Test for various kind of bad inputs to the geocoding api like empty strings, repeated inputs, incorrect values, ambigous addresses etc

4.) test_valid_inputs: Test for valid inputs like airport locations, addresses etc to see the responses

5.) test_geocoding_requests: Test all the fields that are returned as api values to  a simple geocoding request to see that they give the correct responses

6.) test_bounds: Look for addresses within a certain bounds of lat/longitude values to see that the addresses get returned

7.) test_region_bias: Test for a geocoding request with a region bias to see how it affects the results with additional params like country etc

8.) test_reverse_geocoding_request: Test for reverse geocoding api to see that it returns a list of addresses on a pair of lat/lng values

9.) test_reverse_geocoding_request_without_key: Test rev geocode API with location type to ensure it gives an error without the API key

10.) test_reverse_geocoding_combined: Geocode and Reverse Geocode an address to see that it gives the same values for the specified address/lat,lng

11.) test_reverse_geocoding_request_diff_languages: Test geocode requests with language preferences give results based on language chosen as parameter

12.) test_components_filter: Test the components api that geocodes with additional parameters

#Things To Do:

1.) Parametrize the tests to give values from a File

2.) Add Performance Tests of various types to see response times, OVER_QUERY_LIMITS, cache performance etc

3.) Add an RSPEC to test plan converter within the code to maintain which tests passed and failed in a report format

4.) Add Rake Tasks to run the code every hour where the code runs and stores the results and the caches refreshes the stored result values every hour


