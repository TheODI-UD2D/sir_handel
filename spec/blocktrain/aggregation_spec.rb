module Blocktrain
  describe Aggregation do

    it 'gets the interval' do
      subject = described_class.new(from: '2015-12-10 10:00:00Z', to: '2015-12-10 11:00:00Z', interval: '10m', memory_addresses: '2E491EEW')

      expect(subject.instance_variable_get("@interval")).to eq('10m')
    end

    it "can't be used by itself" do
      a = Aggregation.new
      expect { a.aggs }.to raise_error(RuntimeError,"Aggregation cannot be used directly. Use a derived class instead like AverageAggregation.")
    end

  end
end

RSpec.shared_examples "histogram aggregations" do |described_class|

  it "returns 0 results", :vcr do
    agg = described_class.new(from: '2015-12-10 10:00:00Z', to: '2015-12-10 11:00:00Z', memory_addresses: '2E491EEW')
    expect(agg.send(:result)['hits']['hits'].count).to eq(0)
  end

  it "returns 0 results even if a limit is specified", :vcr do
    agg = described_class.new(from: '2015-12-10 10:00:00Z', to: '2015-12-10 11:00:00Z', memory_addresses: '2E491EEW', limit: 1000)
    expect(agg.send(:result)['hits']['hits'].count).to eq(0)
  end

end
