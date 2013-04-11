require 'spec_helper'

describe Appsignal::Moped::Instrumentation do
  let(:session) do
    Moped::Session.new(
      %w[127.0.0.1:27017], database: 'moped_test', safe: true
    )
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
    subject { event.payload["1 - insert in 'users'"] }

    its(['database']) { should == 'moped_test' }
    its(['collection']) { should == 'users' }
    its(['documents']) { should == [{:name => 'test'}] }

    after { session['users'].find.remove_all }
  end

  context "instrument a find" do
    before { session['users'].find(:name => 'Pete').skip(1).one }

    it { should == {
      "query in 'users'" => {
        'database' => 'moped_test',
        'collection' => 'users',
        'selector' => {:name => 'Pete'},
        'flags' => [:slave_ok],
        'limit' => -1,
        'skip' => 1
      }
    } }
  end

  context "instrument an update" do
    before { session['users'].find(:name => 'Pete').update_all(:age => 33) }

    it { should == {
      "1 - update in 'users'" => {
        'database' => 'moped_test',
        'collection' => 'users',
        'flags' => [:multi],
        'selector' => {:name => 'Pete'},
        'update' => {:age => 33}
      },
      "2 - command in '$cmd'" => {
        'database'=>'moped_test',
        'selector'=>{:getlasterror=>1, :safe=>true},
        'limit'=>-1,
        'collection'=>'$cmd',
        'flags'=>[]
      }
    } }
  end
end
