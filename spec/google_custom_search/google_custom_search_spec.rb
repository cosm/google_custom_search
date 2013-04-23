require 'spec_helper'

describe GoogleCustomSearch do
  before(:each) do
    GoogleCustomSearch.configuration.reset!
  end

  context "when not configured" do
    before(:each) do
      GoogleCustomSearch.instance_variable_set(:@configuration, nil)
    end

    it "should return a config object" do
      GoogleCustomSearch.configuration.should_not be_nil
      GoogleCustomSearch.configuration.cx.should be_nil
      GoogleCustomSearch.configuration.default_params.should be_nil
    end

    it "should allow setting instance variables immediately" do
      GoogleCustomSearch.configuration.cx = "4567"
      GoogleCustomSearch.configuration.cx.should == "4567"
    end
  end

  context "when configured" do
    before(:each) do
      GoogleCustomSearch.configure do |config|
        config.cx = "1234"
        config.default_params = { :ie => 'utf8' }
      end
    end

    context "configuration" do
      it "should be configured correctly using defaults if required" do
        GoogleCustomSearch.configuration.cx.should == "1234"
        GoogleCustomSearch.configuration.default_params.should == { :ie => 'utf8' }
        GoogleCustomSearch.configuration.timeout.should == 3
        GoogleCustomSearch.configuration.secure.should == true
      end
    end

    context "build_uri" do
      it "should build the correct search uri" do
        uri = GoogleCustomSearch.send(:build_uri, "raspberry", { :offset => 10, :per_page => 10 })
        uri.to_s.should == "https://www.google.com:443/cse?client=google-csbe&cx=1234&ie=utf8&num=10&output=xml_no_dtd&q=raspberry&start=10"
      end

      it "should return non https if secure is false" do
        GoogleCustomSearch.configuration.secure = false
        uri = GoogleCustomSearch.send(:build_uri, "raspberry", { :offset => 10, :per_page => 10 })
        uri.to_s.should == "http://www.google.com/cse?client=google-csbe&cx=1234&ie=utf8&num=10&output=xml_no_dtd&q=raspberry&start=10"
      end
    end

    context "search" do
      it "should make basic request using our default parameters" do
        request_stub = stub_request(:get, "https://www.google.com:443/cse?client=google-csbe&cx=1234&ie=utf8&num=10&output=xml_no_dtd&q=banana&start=0").
          with(:headers => {'User-Agent' => GoogleCustomSearch.send(:user_agent) }).
          to_return(:status => 200, :body => single_result_xml)

        GoogleCustomSearch.search("banana")
        request_stub.should have_been_made
      end

      it "should use default per_page if passed nil value" do
        request_stub = stub_request(:get, "https://www.google.com:443/cse?client=google-csbe&cx=1234&ie=utf8&num=10&output=xml_no_dtd&q=banana&start=0").
          with(:headers => {'User-Agent' => GoogleCustomSearch.send(:user_agent) }).
          to_return(:status => 200, :body => single_result_xml)

        GoogleCustomSearch.search("banana", :per_page => nil)
        request_stub.should have_been_made
      end

      context "page parameter" do
        it "should set start to 0 if page is 0" do
          request_stub = stub_request(:get, "https://www.google.com:443/cse?client=google-csbe&cx=1234&ie=utf8&num=10&output=xml_no_dtd&q=banana&start=0").
            with(:headers => {'User-Agent' => GoogleCustomSearch.send(:user_agent) }).
            to_return(:status => 200, :body => single_result_xml)

          GoogleCustomSearch.search("banana", :page => 0)
          request_stub.should have_been_made
        end

        it "should set start to 0 if page is nil" do
          request_stub = stub_request(:get, "https://www.google.com:443/cse?client=google-csbe&cx=1234&ie=utf8&num=10&output=xml_no_dtd&q=banana&start=0").
            with(:headers => {'User-Agent' => GoogleCustomSearch.send(:user_agent) }).
            to_return(:status => 200, :body => single_result_xml)

          GoogleCustomSearch.search("banana", :page => nil)
          request_stub.should have_been_made
        end

        it "should set start to 0 if page is 1" do
          request_stub = stub_request(:get, "https://www.google.com:443/cse?client=google-csbe&cx=1234&ie=utf8&num=10&output=xml_no_dtd&q=banana&start=0").
            with(:headers => {'User-Agent' => GoogleCustomSearch.send(:user_agent) }).
            to_return(:status => 200, :body => single_result_xml)

          GoogleCustomSearch.search("banana", :page => 1)
          request_stub.should have_been_made
        end

        it "should set start to correct offset if page is 2" do
          request_stub = stub_request(:get, "https://www.google.com:443/cse?client=google-csbe&cx=1234&ie=utf8&num=10&output=xml_no_dtd&q=banana&start=10").
            with(:headers => {'User-Agent' => GoogleCustomSearch.send(:user_agent) }).
            to_return(:status => 200, :body => single_result_xml)

          GoogleCustomSearch.search("banana", :page => 2)
          request_stub.should have_been_made
        end

        it "should handle string parameters correctly" do
          request_stub = stub_request(:get, "https://www.google.com:443/cse?client=google-csbe&cx=1234&ie=utf8&num=10&output=xml_no_dtd&q=banana&start=0").
            with(:headers => {'User-Agent' => GoogleCustomSearch.send(:user_agent) }).
            to_return(:status => 200, :body => single_result_xml)

          GoogleCustomSearch.search("banana", :page => "0")
          request_stub.should have_been_made
        end

        it "should respect the per_page setting" do
          request_stub = stub_request(:get, "https://www.google.com:443/cse?client=google-csbe&cx=1234&ie=utf8&num=7&output=xml_no_dtd&q=banana&start=14").
            with(:headers => {'User-Agent' => GoogleCustomSearch.send(:user_agent) }).
            to_return(:status => 200, :body => single_result_xml)

          GoogleCustomSearch.search("banana", :page => "3", :per_page => "7")
          request_stub.should have_been_made
        end
      end

      context "with http errors" do
        it "should raise InvalidRequest on a 300 type response" do
          stub_request(:get, "https://www.google.com:443/cse?client=google-csbe&cx=1234&ie=utf8&num=10&output=xml_no_dtd&q=raspberry&start=0").
            with(:headers => {'User-Agent' => GoogleCustomSearch.send(:user_agent) }).
            to_return(:status => 302)

          expect {
            GoogleCustomSearch.search("raspberry")
          }.to raise_error(GoogleCustomSearch::InvalidRequest)
        end

        it "should raise InvalidRequest on a 400 type response" do
          stub_request(:get, "https://www.google.com:443/cse?client=google-csbe&cx=1234&ie=utf8&num=10&output=xml_no_dtd&q=raspberry&start=0").
            with(:headers => {'User-Agent' => GoogleCustomSearch.send(:user_agent) }).
            to_return(:status => 404)

          expect {
            GoogleCustomSearch.search("raspberry")
          }.to raise_error(GoogleCustomSearch::InvalidRequest)
        end

        it "should raise ServerError on a 500 type response" do
          stub_request(:get, "https://www.google.com:443/cse?client=google-csbe&cx=1234&ie=utf8&num=10&output=xml_no_dtd&q=raspberry&start=0").
            with(:headers => {'User-Agent' => GoogleCustomSearch.send(:user_agent) }).
            to_return(:status => 500)

          expect {
            GoogleCustomSearch.search("raspberry")
          }.to raise_error(GoogleCustomSearch::ServerError)
        end
      end

      context "with a network timeout" do
        it "should raise our timeout exception on timeout" do
          stub_request(:get, "https://www.google.com:443/cse?client=google-csbe&cx=1234&ie=utf8&num=10&output=xml_no_dtd&q=raspberry&start=0").
            with(:headers => {'User-Agent' => GoogleCustomSearch.send(:user_agent) }).
            to_timeout

          expect {
            GoogleCustomSearch.search("raspberry")
          }.to raise_error(GoogleCustomSearch::TimeoutError)
        end
      end
    end
  end
end
