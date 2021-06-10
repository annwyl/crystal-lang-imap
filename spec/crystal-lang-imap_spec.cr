require "./spec_helper"

host = ""
port = 
user = ""
pass = ""

describe Crystal::Lang::Imap do
  # TODO: Write more tests

  describe "connection to server" do
  
    it "connects properly and gives a Client instance back." do
      test = IMAP::Client.new(host, port)
      test.class.should eq(IMAP::Client)
    end
    
    it "doesn't connect properly and raises a ConnectError exception." do
      expect_raises(Socket::ConnectError) do 
        IMAP::Client.new("127.0.0.1", 65535)
      end
    end
    
    it "doesn't connect properly cause of invalid address." do
      expect_raises(Socket::Addrinfo::Error) do
        IMAP::Client.new("this.shouldnt.work.at.all", 65536)
      end
    end
    
  end
  
  describe "login to server" do
    
    it "authentication succeeds" do 
      test = IMAP::Client.new(host, port)
      test.login(user, pass)
      test = test.inspect.includes?("@in_buffer=Pointer(UInt8)") && test.inspect.includes?("@out_buffer=Pointer(UInt8)")
      test.should eq(true)
    end
    
    it "authentication fails" do 
      expect_raises(Exception, "Command error") do 
        test = IMAP::Client.new(host, port)
        test.login("xxx", "xxx")
      end
    end
    
  end
  
  describe "logout" do
    
    it "logs out properly and closes socket" do
      expect_raises(IO::Error, "Closed stream") do
        test = IMAP::Client.new(host, port)
        test.login(user, pass)
        test.logout
        test.noop
      end
    end
    
  end
  
  describe "Command" do
    
    it "does nothing" do
      test = IMAP::Client.new(host, port)
      test.login(user, pass)
      test = test.noop
      test[0].should eq("tag OK Completed")
    end
    
    it "returns a list of mailboxes." do
      test = IMAP::Client.new(host, port)
      test.login(user, pass)
      test = test.list
      (test.is_a?(Array) && !test.empty?).should eq(true)
    end
    
    it "selects a mailbox." do 
      test = IMAP::Client.new(host, port)
      test.login(user, pass)
      mailbox = test.select(test.list[0])
      mailbox[-1].includes?("tag OK").should eq(true)
    end
    
    it "selects a mailbox which doesn't exist." do
      expect_raises(Exception, "Command error") do
        test = IMAP::Client.new(host, port)
        test.login(user, pass)
        test.select("qwerty")
      end
    end
    
    it "selects a mailbox in readonly" do 
      test = IMAP::Client.new(host, port)
      test.login(user, pass)
      mailbox = test.select(test.list[0])
      mailbox[-1].includes?("tag OK").should eq(true)
    end
    
    it "selects a mailbox in readonly which doesn't exist." do
      expect_raises(Exception, "Command error") do
        test = IMAP::Client.new(host, port)
        test.login(user, pass)
        test.select("qwerty")
      end
    end
    
    it "checks the connection to a mailbox and keeps it alive." do
      test = IMAP::Client.new(host, port)
      test.login(user, pass)
      test.select(test.list[0])
      test = test.check
      test[0].should eq("tag OK Completed")
    end
    
    it "checks the connection, but fails cause no mailbox is selected." do
      expect_raises(Exception, "Unknown command or arguments invalid") do 
        test = IMAP::Client.new(host, port)
        test.login(user, pass)
        test = test.check
      end
    end
    
    # Mailbox names may have naming restrictions depending on the host.
    it "creates and deletes a mailbox." do
      test = IMAP::Client.new(host, port)
      test.login(user, pass)
      test.create("INBOX/NewMailbox")
      test.list.includes?("INBOX/NewMailbox").should eq(true) 
      test.delete("INBOX/NewMailbox")
      test.list.includes?("INBOX/NewMailbox").should eq(false)
    end
    
    # Mailbox names may have naming restrictions depending on the host.
    it "renames a mailbox." do 
      test = IMAP::Client.new(host, port)
      test.login(user, pass)
      test.create("INBOX/NewMailbox")
      test.rename("INBOX/NewMailbox","INBOX/VeryNewMailbox")
      test.list.includes?("INBOX/VeryNewMailbox").should eq(true)
      test.delete("INBOX/VeryNewMailbox")
    end
    
    it "subscribe to a mailbox." do 
      test = IMAP::Client.new(host, port)
      test.login(user, pass)
      test.subscribe(test.list[0])[0].should eq("tag OK Completed")
    end
    
    it "subscribes from a mailbox which doesn't exist." do
      expect_raises(Exception, "Command error") do
        test = IMAP::Client.new(host, port)
        test.login(user, pass)
        test.subscribe("SubImaginaryMailbox")
      end
    end
    
    it "unsubscribes from a mailbox." do
      test = IMAP::Client.new(host, port)
      test.login(user, pass)
      test.unsubscribe(test.list[0])[0].should eq("tag OK Completed")
    end
    
    it "unsubscribes from a mailbox which doesn't exist." do
      test = IMAP::Client.new(host, port)
      test.login(user, pass)
      # Even if the mailbox doesn't exist, we get a "tag OK Completed" response
      test.unsubscribe("UnsubImaginaryMailbox")[0].should eq("tag OK Completed")
    end
    
    it "shows status of specific mailbox." do
      test = IMAP::Client.new(host, port)
      test.login(user, pass)
      status = test.status(test.list[0], ["MESSAGES","RECENT"])
      (status.is_a?(Hash) && status.has_key?("MESSAGES") && status.has_key?("RECENT")).should eq(true)
    end
    
    it "shows status of specific mailbox with wrong flags." do
      expect_raises(Exception, "Wrong data item SOMEDAYANDSOMEWHERE!") do
        test = IMAP::Client.new(host, port)
        test.login(user, pass)
        status = test.status(test.list[0], ["MESSAGES","SOMEDAYANDSOMEWHERE"])
      end
    end
    
  end
  
end
