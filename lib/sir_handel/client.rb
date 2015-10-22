require 'curb'
require 'dotenv'
require 'json'
require 'date'

Dotenv.load

module SirHandel
  class Client
    
    CAR_CODES = {
      "A" => "2E64930W",
      "B" => "2E64932W",
      "C" => "2E64934W",
      "D" => "2E64936W"
    }

    def initialize(options = {})
      @url = ENV['ES_URL']
      @car = options[:car]

      options[:from] ||= "2015-09-01T00:00:00"
      options[:to]   ||= "2015-09-02T00:00:00"

      @from = parse_datetime(options[:from])
      @to = parse_datetime(options[:to])

      @interval = options[:interval] || "10m"
    end

    def parse_datetime(datetime)
      utc = Time.parse(datetime).utc
      return utc.to_i * 1000
    end

    def search
      @client = Curl::Easy.http_post("#{@url}/train_data/_search", body.to_json) do |c|
        c.ssl_verify_peer = false
      end
    end

    def results
      search
      JSON.parse(@client.body_str)
    end

    def address_query
      if @car.nil?
        "memoryAddress:2E64930W OR memoryAddress:2E64932W OR memoryAddress:2E64934W OR memoryAddress:2E64936W"
      else
        "memoryAddress:#{CAR_CODES[@car]}"
      end
    end

    def query
      {
        "filtered" => {
          "query" => {
            "query_string" => {
              "analyze_wildcard" =>true,
              "query" =>address_query
            }
          },
          "filter" => {
            "bool" => {
              "must" => [
                {
                  "range" => {
                    "timeStamp" => {
                      "gte" =>@from,
                      "lte" =>@to
                    }
                  }
                }
              ],
              "must_not" => []
            }
          }
        }
      }
    end

    def aggs
      {
         "2" => {
           "date_histogram" => {
             "field" => "timeStamp",
             "interval" => @interval,
             "pre_zone" => "+01:00",
             "pre_zone_adjust_large_interval" =>true,
             "min_doc_count" => 1,
             "extended_bounds" => {
               "min" =>@from,
               "max" =>@to
             }
          },
          "aggs" => {
            "1" => {
              "avg" => {
                "field" => "value"
              }
            }
          }
        },
      }
    end

    def body
      {
        "query" => query,
        "size" =>0,
        "aggs" => aggs,
      }
    end
  end
end
