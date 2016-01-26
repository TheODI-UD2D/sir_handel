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
      get '/signals/passesnger-load-car-a/2015-08-29T00:00:00+00:00/2015-08-30T00:00:00+00:00?interval=10m'
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
        from: '2015-09-03 07:00:00',
        to: '2015-09-03 10:00:00',
        interval: '5s' }

      expect(last_response).to be_redirect
      follow_redirect!
      expect(last_request.url).to eq 'http://example.org/signals/passesnger-load-car-a/2015-09-03T07:00:00+00:00/2015-09-03T10:00:00+00:00?interval=5s'
    end

    it 'redirects to a RESTful URL with a group' do
      post '/groups/my-awesome-group', {
        from: '2015-09-03 07:00:00',
        to: '2015-09-03 10:00:00',
        interval: '5s' }

      expect(last_response).to be_redirect
      follow_redirect!
      expect(last_request.url).to eq 'http://example.org/groups/my-awesome-group/2015-09-03T07:00:00+00:00/2015-09-03T10:00:00+00:00?interval=5s'
    end

    it 'redirects with a comparison' do
      post '/signals/passesnger-load-car-a', {
        compare: 'passesnger-load-car-b'
      }

      expect(last_response).to be_redirect
      follow_redirect!
      expect(last_request.url).to eq 'http://example.org/signals/passesnger-load-car-a,passesnger-load-car-b/2015-08-29T00:00:00+00:00/2015-08-30T00:00:00+00:00'
    end

    it 'redirects with a new comparison' do
      post '/signals/passesnger-load-car-a,passesnger-load-car-b', {
        compare: 'passesnger-load-car-c'
      }

      expect(last_response).to be_redirect
      follow_redirect!
      expect(last_request.url).to eq 'http://example.org/signals/passesnger-load-car-a,passesnger-load-car-c/2015-08-29T00:00:00+00:00/2015-08-30T00:00:00+00:00'
    end

    it 'redirects with defaults' do
      post '/signals/passesnger-load-car-a', {
        from: '',
        to: '',
        interval: ''
      }

      expect(last_response).to be_redirect
      follow_redirect!
      expect(last_request.url).to eq 'http://example.org/signals/passesnger-load-car-a/2015-08-29T00:00:00+00:00/2015-08-30T00:00:00+00:00'
    end

    it 'redirects to default datetimes' do
      get '/signals/passesnger-load-car-a'

      expect(last_response).to be_redirect
      follow_redirect!
      expect(last_request.url).to eq 'http://example.org/signals/passesnger-load-car-a/2015-08-29T00:00:00+00:00/2015-08-30T00:00:00+00:00'
    end

    it 'redirects to default datetimes with a group' do
      get '/groups/passesnger-load'

      expect(last_response).to be_redirect
      follow_redirect!
      expect(last_request.url).to eq 'http://example.org/groups/passesnger-load/2015-08-29T00:00:00+00:00/2015-08-30T00:00:00+00:00'
    end

    it 'returns 404 for an unknown redirect type' do
      get '/foobar/passesnger-load'

      expect(last_response.status).to eq(404)
    end

    it 'shows the title of a signal' do
      get '/signals/passesnger-load-car-a/2015-08-29T00:00:00+00:00/2015-08-30T00:00:00+00:00?interval=10m'
      expect(last_response.body).to match(/Passenger Load Car A \(%\)<\/h1>/)
    end

    it 'shows the title of two signals' do
      get '/signals/passesnger-load-car-a,passesnger-load-car-b/2015-08-29T00:00:00+00:00/2015-08-30T00:00:00+00:00?interval=10m'
      expect(last_response.body).to match(/Passenger Load Car A \(%\) compared with Passenger Load Car B \(%\)<\/h1>/)
    end

    it 'allows a layout to be specified' do
      expect_any_instance_of(SirHandel::App).to receive(:erb).with(:signal, { layout: :simple })
      get '/signals/passesnger-load-car-a,passesnger-load-car-b/2015-08-29T00:00:00+00:00/2015-08-30T00:00:00+00:00?layout=simple'
    end

    it 'sets a default datetime at the same local time', :vcr do
      Timecop.freeze('2016-01-01T15:44:00Z')
      expect(Blocktrain::StationCrowding).to receive(:new).with(Time.parse("2015-09-23T15:44:00+00:0"), "seven_sisters", :southbound).and_call_original
      get 'stations/arriving/southbound/seven-sisters.json'
      Timecop.return
    end

    it 'allows the datetime to be set', :vcr do
      to = "2015-09-23T17:10:00Z"
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
      get '/heatmap/2015-09-23T17:10:00Z.json'

      json = JSON.parse(last_response.body)

      expect(json.count).to eq(20)
      expect(json).to eq([
        {"segment"=>1794, "station"=>"vauxhall", "direction"=>"northbound", "load"=>14.666694206512755},
        {"segment"=>1892, "station"=>"stockwell", "direction"=>"northbound", "load"=>11.681944444444444},
        {"segment"=>1999, "station"=>"stockwell", "direction"=>"southbound", "load"=>30.084578161003556},
        {"segment"=>1881, "station"=>"vauxhall", "direction"=>"southbound", "load"=>43.350831430318934},
        {"segment"=>1793, "station"=>"pimlico", "direction"=>"southbound", "load"=>53.23052300174797},
        {"segment"=>1681, "station"=>"victoria", "direction"=>"southbound", "load"=>57.001145337653135},
        {"segment"=>1565, "station"=>"green_park", "direction"=>"southbound", "load"=>97.07543448715087},
        {"segment"=>1487, "station"=>"oxford_circus", "direction"=>"southbound", "load"=>94.94368275515336},
        {"segment"=>893, "station"=>"seven_sisters", "direction"=>"southbound", "load"=>24.849155220589473},
        {"segment"=>297, "station"=>"tottenham_hale", "direction"=>"southbound", "load"=>10.826860508464282},
        {"segment"=>195, "station"=>"blackhorse_road", "direction"=>"southbound", "load"=>5.4407673395445135},
        {"segment"=>119, "station"=>"walthamstow_central", "direction"=>"southbound", "load"=>4.4395012689378595},
        {"segment"=>600, "station"=>"finsbury_park", "direction"=>"northbound", "load"=>70.67649122807018},
        {"segment"=>870, "station"=>"highbury_and_islington", "direction"=>"northbound", "load"=>86.94923155737705},
        {"segment"=>1026, "station"=>"kings_cross_st_pancras", "direction"=>"northbound", "load"=>89.4342820479},
        {"segment"=>1282, "station"=>"euston", "direction"=>"northbound", "load"=>82.932464411741},
        {"segment"=>1358, "station"=>"warren_street", "direction"=>"northbound", "load"=>86.75000130493461},
        {"segment"=>1444, "station"=>"green_park", "direction"=>"northbound", "load"=>71.93170006408403},
        {"segment"=>1522, "station"=>"victoria", "direction"=>"northbound", "load"=>62.61486433754038},
        {"segment"=>1642, "station"=>"pimlico", "direction"=>"northbound", "load"=>29.57324973182908}
      ])
    end
  end
end
