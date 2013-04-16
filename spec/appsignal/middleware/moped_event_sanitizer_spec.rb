require 'spec_helper'

describe Appsignal::Middleware::MopedEventSanitizer do
  def sanitize
    moped_event_sanitizer.call(event) { }
  end
  let(:moped_event_sanitizer) { Appsignal::Middleware::MopedEventSanitizer.new }
  let(:session) do
    Moped::Session.new(
      %w[127.0.0.1:27017], :database => 'moped_test', :safe => true
    )
  end
  before(:all) do
    @events = []
    ActiveSupport::Notifications.subscribe do |*args|
      @events << ActiveSupport::Notifications::Event.new(*args)
    end
  end
  let(:event) { @events.last }
  subject { sanitize; event.payload }

  context "sanitizing query.moped events" do
    context "sanitize an insert" do
      before { session['users'].insert({:name => 'test'}) }
      subject { sanitize; event.payload["1 - insert in 'users'"] }

      its(['database']) { should == 'moped_test' }
      its(['collection']) { should == 'users' }
      its(['documents']) { should == [{:name => '?'}] }

      after { session['users'].find.remove_all }
    end

    context "sanitize a find" do
      before do
        session['users'].find(:name => 'Pete').select(:name => 1).skip(1).one
      end

      it { should == {
        "query in 'users'" => {
          'database' => 'moped_test',
          'collection' => 'users',
          'selector' => {:name => '?'},
          'fields' => {:name => 1},
          'flags' => [:slave_ok],
          'limit' => -1,
          'skip' => 1
        }
      } }
    end

    context "sanitize an update" do
      before { session['users'].find(:name => 'Pete').update_all(:age => 33) }

      it { should == {
        "1 - update in 'users'" => {
          'database' => 'moped_test',
          'collection' => 'users',
          'flags' => [:multi],
          'selector' => {:name => '?'},
          'update' => {:age => '?'}
        },
        "2 - command in '$cmd'" => {
          'selector' => {:getlasterror => '?', :safe => '?'},
          'database' => 'moped_test',
          'limit' => -1,
          'collection' => '$cmd',
          'flags' => []
        }
      } }
    end

    context "sanitize a remove" do
      before { session['users'].find(:name => 'Pete').remove_all }

      it { should == {
        "1 - delete in 'users'" => {
          'database' => 'moped_test',
          'collection' => 'users',
          'selector' => {:name => '?'}
        },
        "2 - command in '$cmd'" => {
          'limit' => -1,
          'database' => 'moped_test',
          'flags' => [],
          'collection' => '$cmd',
          'selector' => {:getlasterror => '?', :safe => '?'}
        }
      } }
    end

    context "do not sanitize other events" do
      before do
        ActiveSupport::Notifications.instrument(
          'something else',
          :a => {:deep => {:nested => [:hash]}}
        )
      end

      it { should == {:a => {:deep => {:nested => [:hash]}}} }
    end
  end
end
