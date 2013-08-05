require File.expand_path('../lib/xapian_fu.rb', File.dirname(__FILE__))

tmp_dir = '/tmp/xapian_fu_test.db'

describe "Facets support" do

  before do
    FileUtils.rm_rf(tmp_dir)

    @xdb = XapianFu::XapianDb.new(
      :dir => tmp_dir, :create => true, :overwrite => true,
      :fields => {
        :name      => { :index => true },
        :age       => { :type => Integer, :sortable => true },
        :height    => { :type => Float, :sortable => true },
        :city      => { :store => true }
      }
    )

    @xdb.write do
      @xdb << {:name => "John A",   :age => 30, :height => 1.8, city: "NY"}
      @xdb << {:name => "John B",   :age => 35, :height => 1.8, city: "NY"}
      @xdb << {:name => "John C",   :age => 40, :height => 1.7, city: "SF"}
      @xdb << {:name => "John D",   :age => 40, :height => 1.7, city: "NY"}
      @xdb << {:name => "Markus",   :age => 35, :height => 1.7, city: "LA"}
    end
  end

  it "should expose facets when searching" do
    results = @xdb.search("john", {:facets => [:age, :height]})

    results.facets[:age].should == [[30, 1], [35, 1], [40, 2]]
    results.facets[:height].should == [[1.7, 2], [1.8, 2]]

    results.facets.keys.map(&:to_s).sort == %w(age height)
  end

  it "should allow to set the minimum amount of documents to check" do
    @xdb.write do
      100.times do |i|
        @xdb << {:name => "John A #{i}", :age => 30, :height => 1.8}
        @xdb << {:name => "John B #{i}", :age => 35, :height => 1.8}
        @xdb << {:name => "John C #{i}", :age => 40, :height => 1.7}
        @xdb << {:name => "John D #{i}", :age => 40, :height => 1.7}
        @xdb << {:name => "Markus #{i}", :age => 35, :height => 1.7}
      end
    end

    results = @xdb.search("john", :facets => [:age, :height], :check_at_least => :all)

    results.facets[:age].map(&:last).inject(0) { |t,i| t + i }.should == 404

    results = @xdb.search(:all, :facets => [:age, :height], :check_at_least => :all)

    results.facets[:age].map(&:last).inject(0) { |t,i| t + i }.should == 505
  end

  it "should return facet values in UTF-8" do
    results = @xdb.search("john", {:facets => [:city]})

    results.facets[:city].should == [["NY", 3], ["SF", 1]]

    results.facets[:city].first.first.encoding.should == Encoding::UTF_8
  end
end
