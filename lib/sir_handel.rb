require 'sinatra/base'
require 'blocktrain'
require 'json'
require 'rack/conneg'

require_relative 'sir_handel/helpers'
require_relative 'sir_handel/racks'

Dotenv.load

module SirHandel
  class App < Sinatra::Base
    set :public_folder, 'public'
    set :views, 'views'

    get '/' do
      @content = '<h1>Hello from TubePi</h1>'
      @title = 'TubePi'
      erb :index, layout: :default
    end

    get '/signal' do
      protected!

      respond_to do |wants|
        wants.html do
          @signals = Blocktrain::Lookups.instance.aliases.delete_if {|k,v| v.nil? }
          @signal = params['signal']
          erb :weight, layout: :default
        end

        wants.json do
          target = "/signal/%s?from=%s&to=%s&interval=%s" % [
            params.fetch('signal', 'train_speed'),
            params.fetch('from', '2015-09-01 00:00:00Z'),
            params.fetch('to', '2015-09-02 00:00:00Z'),
            params.fetch('interval', '1h')
          ]

          redirect to target
        end
      end
    end

    get '/signal/:signal' do
      protected!

      respond_to do |wants|
        wants.html do
          @signals = Blocktrain::Lookups.instance.aliases.delete_if {|k,v| v.nil? }
          @signal = params['signal']
          erb :weight, layout: :default
        end

        wants.json do
          headers 'Access-Control-Allow-Origin' => '*'

          search = {
            from: params.fetch('from', '2015-09-01 00:00:00Z'),
            to: params.fetch('to', '2015-09-02 00:00:00Z'),
            interval: params.fetch('interval', '1h'),
            signals: params.fetch('signal')
          }

          r = Blocktrain::Aggregations::AverageAggregation.new(search).results

          results = r['results']['buckets'].map do |r|
            {
              'timestamp' => DateTime.strptime(r['key'].to_s, '%Q'),
              'value' => r['average_value']['value']
            }
          end

          {
            results: results
          }.to_json
        end
      end
    end

    # start the server if ruby file executed directly
    run! if app_file == $0
  end
end
