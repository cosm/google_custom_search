require 'spec_helper'

describe GoogleCustomSearch::ResultSet do
  describe "parsing single result XML" do
    before(:each) do
      @search = GoogleCustomSearch::ResultSet.new(single_result_xml)
    end

    it "should extract all result attributes" do
      @search.start_index.should == 1
      @search.end_index.should == 1
      @search.per_page.should == 20
      @search.total_entries.should == 1
      @search.current_page.should == 1
      @search.offset.should == 0
      @search.total_pages.should == 1
    end

    it "should create an array of Result objects" do
      @search.results.is_a?(Array).should == true
      @search.results.size.should == 1
      result = @search.results[0]
      result.title.should == "Cosm - Air Quality <b>Banana</b>"
      result.excerpt.should == "This is the air quality <b>banana</b>!"
      result.url.should == "https://cosm.com/feeds/1234"
    end
  end

  describe "parsing multiple result XML" do
    before(:each) do
      @search = GoogleCustomSearch::ResultSet.new(multiple_result_xml)
    end

    it "should extract all result attributes" do
      @search.start_index.should == 11
      @search.end_index.should == 12
      @search.per_page.should == 2
      @search.total_entries.should == 123
      @search.current_page.should == 6
      @search.offset.should == 10
      @search.total_pages.should == 62
    end

    it "should return a spelling suggestion if present" do
      @search.suggestion.should == "raspberry"
    end

    it "should create an array of Result objects" do
      @search.results.is_a?(Array).should == true
      @search.results.size.should == 2
      @search.results.each do |r|
        r.is_a?(GoogleCustomSearch::Result).should == true
      end
    end
  end

  describe "parsing empty result XML" do
    before(:each) do
      @search = GoogleCustomSearch::ResultSet.new(no_result_xml)
    end

    it "should get a page of results" do
      @search.should_not be_nil
    end

    it "should populate the basic attributes" do
      @search.total_entries.should == 0
      @search.results.should == []
      @search.per_page.should == 20
    end

    it "should still return suggestion if present" do
      @search.suggestion.should == "squash"
    end
  end

  describe "parsing bad xml" do
    it "should raise our XML exception" do
      expect {
        GoogleCustomSearch::ResultSet.new("raspberry")
      }.to raise_error(GoogleCustomSearch::InvalidXML)
    end
  end
end
