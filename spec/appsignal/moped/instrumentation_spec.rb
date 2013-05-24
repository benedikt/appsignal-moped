require 'spec_helper'

module AppsignalSpec
  class HashIsh < Hash
  end
end

describe Appsignal::Moped::Instrumentation do
  let(:session) do
    Moped::Session.new(%w[127.0.0.1:27017], database: 'moped_test')
  end
  before(:all) do
    @events = []
    ActiveSupport::Notifications.subscribe('query.moped') do |*args|
      @events << ActiveSupport::Notifications::Event.new(*args)
    end
  end
  let(:event) { @events.last }
  subject { event.payload }

  context "instrument an insert" do
    before { session['users'].insert({:name => 'test'}) }
    subject { event.payload[:ops].first['insert'] }

    its(['database']) { should == 'moped_test' }
    its(['collection']) { should == 'users' }
    its(['documents']) { should == [{:name => 'test'}] }

    after { session['users'].find.remove_all }
  end

  context "instrument a find" do
    before { session['users'].find(:name => 'Pete').skip(1).one }

    it { should == {
      :ops => [
        {'query' => {
          'database' => 'moped_test',
          'collection' => 'users',
          'selector' => {:name => 'Pete'},
          'flags' => [:slave_ok],
          'limit' => -1,
          'skip' => 1
        }}
      ]
    } }
  end

  describe "deep clone" do
    let(:find_hash) { AppsignalSpec::HashIsh.new }
    before { find_hash[:name] = 'Pete' }
    subject {Appsignal::Moped::Instrumentation.deep_clone(find_hash) }

    it "should clone subclassed hashes to a 'normal' hash" do
      should be_a Hash
      should_not be_a AppsignalSpec::HashIsh
    end

    it "should still have the hash values" do
      should == {:name => 'Pete'}
    end
  end

end
