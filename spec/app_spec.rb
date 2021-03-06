module SirHandel
  describe App, :vcr do

    it 'should allow accessing the home page' do
      get '/'
      expect(last_response.body).to match(/a href='\/signals/)
      expect(last_response.body).to match(/a href='\/stations/)
    end

    it 'varys on the accept header for signals' do
      get '/signals'
      expect(last_response.headers['Vary']).to eq('Accept')
    end

    it 'varys on the accept header for a particular signal' do
      get '/signals/passesnger-load-car-a/2015-08-29T00:00:00.000+00:00/2015-08-30T00:00:00.000+00:00?interval=10m'
      expect(last_response.headers['Vary']).to eq('Accept')
    end

    it 'should list the signals' do
      expect_any_instance_of(described_class).to receive(:groups) {
        {
          'group_1' => [
            'thing_1',
            'thing_2'
          ]
        }
      }

      expect_any_instance_of(described_class).to receive(:lookups) {
        {
          'thing_1' => '1',
          'thing_2' => '2',
          'thing_3' => '3',
          'thing_4' => nil
        }
      }

      get '/signals', {signal: 'thing_3'}

      expect(last_response.body).to match(/a href="http:\/\/example\.org\/signals\/thing-1/)
      expect(last_response.body).to match(/a href="http:\/\/example\.org\/signals\/thing-2/)
      expect(last_response.body).to match(/a href="http:\/\/example\.org\/signals\/thing-3/)
    end

    it 'should group signals' do
      expect_any_instance_of(described_class).to receive(:groups) {
        {
          'group_1' => [
            'line_current',
            'line_voltage'
          ]
        }
      }

      get '/signals'

      body = Nokogiri::HTML.parse(last_response.body)

      expect(body.css('#group_1').first.css('div').count).to eq(3)
      expect(body.css('#group_1').first.css('div').first.to_s).to match /Line Current/

      expect(body.css('#ungrouped').first.to_s).to_not match /Line Current/
    end

    it 'should show a grouped link' do
      expect_any_instance_of(described_class).to receive(:groups) {
        {
          'group_1' => [
            'line_current',
            'line_voltage'
          ]
        }
      }

      get '/signals'

      body = Nokogiri::HTML.parse(last_response.body)
      expect(body.css('#group_1').last.css('div').last.to_s).to match /group_1 Grouped/
    end

    it 'redirects to a RESTful URL' do
      post '/signals/passesnger-load-car-a', {
        from: "2015-09-03 07:00:00",
        to: "2015-09-03 10:00:00",
        interval: '5s' }

      expect(last_response).to be_redirect
      follow_redirect!
      expect(last_request.url).to eq "http://example.org/signals/passesnger-load-car-a/2015-09-03T07:00:00.000+00:00/2015-09-03T10:00:00.000+00:00?interval=5s"
    end

    it 'redirects to a RESTful URL with a group' do
      post '/groups/my-awesome-group', {
        from: "2015-09-03 07:00:00",
        to: "2015-09-03 10:00:00",
        interval: '5s' }

      expect(last_response).to be_redirect
      follow_redirect!
      expect(last_request.url).to eq "http://example.org/groups/my-awesome-group/2015-09-03T07:00:00.000+00:00/2015-09-03T10:00:00.000+00:00?interval=5s"
    end

    it 'redirects with a comparison' do
      post '/signals/passesnger-load-car-a', {
        compare: 'passesnger-load-car-b'
      }

      expect(last_response).to be_redirect
      follow_redirect!
      expect(last_request.url).to eq "http://example.org/signals/passesnger-load-car-a,passesnger-load-car-b/#{ENV['DEFAULT_DATE']}T#{ENV['DEFAULT_FROM']}+00:00/#{ENV['DEFAULT_DATE']}T#{ENV['DEFAULT_TO']}+00:00"
    end

    it 'redirects with a new comparison' do
      post '/signals/passesnger-load-car-a,passesnger-load-car-b', {
        compare: 'passesnger-load-car-c'
      }

      expect(last_response).to be_redirect
      follow_redirect!
      expect(last_request.url).to eq "http://example.org/signals/passesnger-load-car-a,passesnger-load-car-c/#{ENV['DEFAULT_DATE']}T#{ENV['DEFAULT_FROM']}+00:00/#{ENV['DEFAULT_DATE']}T#{ENV['DEFAULT_TO']}+00:00"
    end

    it 'redirects with defaults' do
      post '/signals/passesnger-load-car-a', {
        from: '',
        to: '',
        interval: ''
      }

      expect(last_response).to be_redirect
      follow_redirect!
      expect(last_request.url).to eq "http://example.org/signals/passesnger-load-car-a/#{ENV['DEFAULT_DATE']}T#{ENV['DEFAULT_FROM']}+00:00/#{ENV['DEFAULT_DATE']}T#{ENV['DEFAULT_TO']}+00:00"
    end

    it 'redirects to default datetimes' do
      get '/signals/passesnger-load-car-a'

      expect(last_response).to be_redirect
      follow_redirect!
      expect(last_request.url).to eq "http://example.org/signals/passesnger-load-car-a/#{ENV['DEFAULT_DATE']}T#{ENV['DEFAULT_FROM']}+00:00/#{ENV['DEFAULT_DATE']}T#{ENV['DEFAULT_TO']}+00:00"
    end

    it 'redirects to default datetimes with a group' do
      get '/groups/passesnger-load'

      expect(last_response).to be_redirect
      follow_redirect!
      expect(last_request.url).to eq "http://example.org/groups/passesnger-load/#{ENV['DEFAULT_DATE']}T#{ENV['DEFAULT_FROM']}+00:00/#{ENV['DEFAULT_DATE']}T#{ENV['DEFAULT_TO']}+00:00"
    end

    it 'returns 404 for an unknown redirect type' do
      get '/foobar/passesnger-load'

      expect(last_response.status).to eq(404)
    end

    it 'shows the title of a signal' do
      get '/signals/passesnger-load-car-a/2015-08-29T00:00:00.000+00:00/2015-08-30T00:00:00.000+00:00?interval=10m'
      expect(last_response.body).to match(/Passenger Load Car A \(%\)<\/h1>/)
    end

    it 'shows the title of two signals' do
      get '/signals/passesnger-load-car-a,passesnger-load-car-b/2015-08-29T00:00:00.000+00:00/2015-08-30T00:00:00.000+00:00?interval=10m'
      expect(last_response.body).to match(/Passenger Load Car A \(%\) compared with Passenger Load Car B \(%\)<\/h1>/)
    end

    it 'allows a layout to be specified' do
      expect_any_instance_of(SirHandel::App).to receive(:erb).with(:signal, { layout: :simple })
      get '/signals/passesnger-load-car-a,passesnger-load-car-b/2015-08-29T00:00:00.000+00:00/2015-08-30T00:00:00.000+00:00?layout=simple'
    end

    it 'sets a default datetime at the same local time', :vcr do
      Timecop.freeze('2016-01-01T15:44:00Z')
      expect(Blocktrain::StationCrowding).to receive(:new).with(Time.parse("#{ENV['DEFAULT_DATE']}T15:44:00+00:0"), "seven_sisters", :southbound).and_call_original
      get 'stations/arriving/southbound/seven-sisters.json'
      Timecop.return
    end

    it 'allows the datetime to be set', :vcr do
      to = "2016-01-29T17:10:00Z"
      expect(Blocktrain::StationCrowding).to receive(:new).with(Time.parse(to), "seven_sisters", :southbound).and_call_original
      get "stations/arriving/southbound/seven-sisters/#{to}.json"
    end

    it 'shows all stations' do
      get 'stations'

      body = Nokogiri::HTML.parse(last_response.body)

      expect(body.css('#northbound').first.css('li').count).to eq(16)
      expect(body.css('#southbound').first.css('li').count).to eq(16)
    end

    it 'gets results for heatmap', :vcr do
      get '/heatmap/2015-12-11T17:10:00Z.json'

      json = JSON.parse(last_response.body)

      expect(json.count).to eq(27)
      expect(json).to eq([{"segment"=>1880, "station"=>"stockwell", "direction"=>"northbound", "load"=>24.693536979882015},
        {"segment"=>1964, "station"=>"brixton", "direction"=>"northbound", "load"=>17.095417370699824},
        {"segment"=>1992, "station"=>nil, "direction"=>"northbound", "load"=>18.329726308058518},
        {"segment"=>1917, "station"=>"stockwell", "direction"=>"southbound", "load"=>24.366488606437073},
        {"segment"=>1873, "station"=>"vauxhall", "direction"=>"southbound", "load"=>28.98719850867903},
        {"segment"=>1785, "station"=>"pimlico", "direction"=>"southbound", "load"=>36.73602159776647},
        {"segment"=>1681, "station"=>"victoria", "direction"=>"southbound", "load"=>56.06988627133098},
        {"segment"=>1547, "station"=>"green_park", "direction"=>"southbound", "load"=>56.56282629450064},
        {"segment"=>1475, "station"=>"oxford_circus", "direction"=>"southbound", "load"=>56.538939424921395},
        {"segment"=>1385, "station"=>"warren_street", "direction"=>"southbound", "load"=>48.57996416533404},
        {"segment"=>1309, "station"=>"kings_cross_st_pancras", "direction"=>"southbound", "load"=>38.07107592136177},
        {"segment"=>1125, "station"=>"highbury_and_islington", "direction"=>"southbound", "load"=>32.11768913273878},
        {"segment"=>1019, "station"=>"finsbury_park", "direction"=>"southbound", "load"=>33.125},
        {"segment"=>893, "station"=>"seven_sisters", "direction"=>"southbound", "load"=>28.536587980535902},
        {"segment"=>281, "station"=>"tottenham_hale", "direction"=>"southbound", "load"=>21.004141865079365},
        {"segment"=>195, "station"=>"blackhorse_road", "direction"=>"southbound", "load"=>21.567191324113722},
        {"segment"=>111, "station"=>"walthamstow_central", "direction"=>"southbound", "load"=>22.165366806091015},
        {"segment"=>37, "station"=>nil, "direction"=>"southbound", "load"=>10.715567765567766},
        {"segment"=>140, "station"=>"tottenham_hale", "direction"=>"northbound", "load"=>43.709910864677596},
        {"segment"=>492, "station"=>"finsbury_park", "direction"=>"northbound", "load"=>52.43755024477124},
        {"segment"=>902, "station"=>"highbury_and_islington", "direction"=>"northbound", "load"=>58.4012182147943},
        {"segment"=>1026, "station"=>"kings_cross_st_pancras", "direction"=>"northbound", "load"=>63.339533032226825},
        {"segment"=>1286, "station"=>"warren_street", "direction"=>"northbound", "load"=>74.67550085210414},
        {"segment"=>1412, "station"=>"oxford_circus", "direction"=>"northbound", "load"=>69.93843811024149},
        {"segment"=>1492, "station"=>"green_park", "direction"=>"northbound", "load"=>64.38442669056744},
        {"segment"=>1610, "station"=>"victoria", "direction"=>"northbound", "load"=>45.8240911034118},
        {"segment"=>1766, "station"=>"vauxhall", "direction"=>"northbound", "load"=>29.731479498880667}
      ])
    end

    it 'sets a default datetime at the same local time for heatmap', :vcr do
      Timecop.freeze("2016-01-01T15:44:00")

      expect_any_instance_of(SirHandel::App).to receive(:fake_network).with("#{ENV['DEFAULT_DATE']}T15:44:00").and_call_original
      get 'heatmap.json'
      Timecop.return
    end

    it 'redirects to the correct datetime' do
      post '/heatmap', {
        to: "2015-09-03 10:00:00"
      }

      expect(last_response).to be_redirect
      follow_redirect!
      expect(last_request.url).to eq "http://example.org/heatmap/2015-09-03T10:00:00.000+00:00"
    end

  end
end
