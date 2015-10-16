require 'spec_helper'
require 'tube_client'

describe TubeClient do

  it "returns the correct number of results" do
    client = TubeClient.new

    expect(client.results["hits"]["total"]).to eq(271844)
  end

  it "returns results for a particular day" do
    client = TubeClient.new(date: "2015-09-07")

    results = client.results

    expect(results["aggregations"]["2"]["buckets"].first["key_as_string"]).to eq("2015-09-06T23:00:00.000Z")
    expect(results["aggregations"]["2"]["buckets"].last["key_as_string"]).to eq("2015-09-07T22:50:00.000Z")
  end

  it "returns results for a given car" do
    client = TubeClient.new(car: "A")

    expect(client.address_query).to eq("memoryAddress:2E64930W")
  end

  it "returns a given interval" do
    client = TubeClient.new(interval: "1h")

    results = client.results

    expect(results["aggregations"]["2"]["buckets"][0]["key_as_string"]).to eq("2015-08-31T23:00:00.000Z")
    expect(results["aggregations"]["2"]["buckets"][1]["key_as_string"]).to eq("2015-09-01T00:00:00.000Z")
  end

end
