require_relative "../common"

class Cleaner
  include LineCleaner
end

describe LineCleaner do
  before :each do
    @cleaner = Cleaner.new
  end

  it "should work with a basic message" do
    res = @cleaner.clean "\x02this is a message\x03"

    res.length.should == 1
    res[0].should == "this is a message"
  end

  it "should split multiple messages" do
    res = @cleaner.clean "\x02this is a message\x03\x02this is another message\x03\x02this is a third message\x03"

    res.length.should == 3
    res[0].should == "this is a message"
    res[1].should == "this is another message"
    res[2].should == "this is a third message"
  end

  it "should carry through different transmissions" do
    res = @cleaner.clean "\x02this is a message\x03\x02this is a second"

    res.length.should == 1
    res[0].should == "this is a message"

    res = @cleaner.clean " message that has been chopped in half\x03\x02this is a final message\x03"

    res.length.should == 2
    res[0].should == "this is a second message that has been chopped in half"
    res[1].should == "this is a final message"
  end

  it "should buffer a big message" do
    res = @cleaner.clean "\x02this is a message that does not"

    res.length.should == 0

    res = @cleaner.clean " end until later\x03"

    res.length.should == 1
    res[0].should == "this is a message that does not end until later"
  end

  it "should not split on end of string" do
    res = @cleaner.clean "\x02this is a message with a split at the end\x03\x02"

    res.length.should == 1
    res[0].should == "this is a message with a split at the end"

    res = @cleaner.clean "and here is the end\x03"

    res.length.should == 1
    res[0].should == "and here is the end"
  end

  it "should not split at the start of the string" do
    res = @cleaner.clean "\x02this is the message with the split at the start"

    res.length.should == 0

    res = @cleaner.clean "\x03\x02and here is the second bit.\x03"

    res.length.should == 2
    res[0].should == "this is the message with the split at the start"
    res[1].should == "and here is the second bit."
  end
end

