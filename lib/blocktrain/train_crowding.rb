module Blocktrain
  class TrainCrowding
    CAR_LOADS = %w[2E64930W 2E64932W 2E64934W 2E64936W]
    CAR_NAMES = %w[CAR_A CAR_B CAR_C CAR_D]

    BAD_COMBINATIONS = [
      {
        brixton: :northbound
      },
      {
        walthamstow_central: :southbound
      }
    ]

    def initialize(to, station, direction)
      @to, @station, @direction = to, station, direction
      unless eol?
        @results = [0,1,2,3].map do |i|
          to = @to - (86400 * i)
          from = to - 86400
          get_results(from, to)
        end
      end
    end

    def get_results(from, to)
      Blocktrain::ATPQuery.new(from: from.iso8601, to: to.iso8601, station: @station, direction: @direction).results.first
    end

    def eol?
      BAD_COMBINATIONS.include?(@station.to_sym => @direction.to_sym)
    end

    def eol_results
      cars = {}
      CAR_NAMES.each do |car|
        cars[car] = 0
      end

      [
        [
          {
            'number' => 0,
            'timeStamp' => @to.iso8601,
          },
          cars
        ]
      ]
    end

    def results
      return eol_results if eol?
      @results.map do |location|
        train = {
          'number' => location['_source']['trainNumber'],
          'timeStamp' => location['_source']['timeStamp']
        }
        time = Time.parse(train['timeStamp'])
        [train, crowd_results(time, train)]
      end
    end

    def crowd_results time, train = nil
      from, to = time - 60, time + 60
      crowd_query = Aggregations::MultiValueAggregation.new(
        from: from.iso8601, to: to.iso8601, memory_addresses: CAR_LOADS)
      crowd_query.results['results']['buckets'].map do |car_mem_addr, v|
        res = v['results']['buckets'][0]
        [
          CAR_NAMES[CAR_LOADS.index(car_mem_addr)],
          (res ? res['average_value']['value'] : 0)
        ]
      end.to_h
    end
  end
end
