require "openssl"

module IMAP

  class Client

    CRLF = "\r\n"
    STATUS = ["MESSAGES", "RECENT", "UIDNEXT", "UIDVALIDITY", "UNSEEN"]
    FLAGS = ["\Seen", "\Answered", "\Flagged", "\Deleted", "\Draft", "\Recent"]
    @socket : TCPSocket | OpenSSL::SSL::Socket::Client

    def initialize(host, port)
      @socket = TCPSocket.new(host, port)
      tls = OpenSSL::SSL::Socket::Client.new(@socket)
      @socket = tls
    end

    def send(command, *params)
      command = "tag #{command}"
      command += " #{params.join(" ")}" if params.size > 0
      @socket << command
      @socket << CRLF
      @socket.flush
      response
    end

    def noop
      send("NOOP")
    end

    def logout
      send("LOGOUT")
      @socket.close
    end

    def login(user, pass)
      send("LOGIN", user, pass)
    end

    def select(inbox)
      send("SELECT", inbox)
    end

    def examine(inbox)
      send("EXAMINE", inbox)
    end

    def create(inbox)
      send("CREATE", inbox)
    end

    def delete(inbox)
      send("DELETE", inbox)
    end

    def rename(inbox, name)
      send("RENAME", inbox, name)
    end

    def subscribe(inbox)
      send("SUBSCRIBE", inbox)
    end

    def unsubscribe(inbox)
      send("UNSUBSCRIBE", inbox)
    end

    def list
      mailboxes = Array(String).new
      inboxes = send("LIST \"\" \"*\"")
      inboxes.each do |box|
        if box =~ /HasNoChildren/
          mailboxes << box.gsub(/\* LIST .* \"\/\" /, "")
        end
      end
      mailboxes
    end

    def status(inbox, flags)
      flags.each do |x|
        unless STATUS.includes?(x)
          raise "Wrong data item #{x}!"
        end
      end
      flags = "(#{flags.join(" ")})"
      resp = send("STATUS", inbox, flags)
      data = Hash(String, Int32).new
      resp[0].scan(/\(([^)]+)\)/) do |i|
        i[1].scan(/\w+ \d+/) do |j|
          k,v = j[0].split(" ")
          data[k] = v.to_i
        end
      end
      data
    end

    def append(inbox, message, flags = [] of String)
      params = String.new
      if !flags.empty?
        flags.each do |x|
          unless FLAGS.includes?(x)
            raise "Wrong flag #{x}!"
          end
        end
        params += "(#{flags.join(" ")}) "
      end
      params += "{#{message.size}+}" + CRLF
      send("APPEND", inbox, params, message)
    end

    def check
      send("CHECK")
    end

    def close
      send("CLOSE")
    end

    def expunge
      data = Array(Int32).new
      resp = send("EXPUNGE")
      resp.each do |i|
        i.scan(/(\d)/) do |j|
          data << j
        end
      end
      data
    end

    def search(params)
      data = Array(Int32).new
      params = "#{params.join(" ")}"
      resp = send("SEARCH", params)
      resp.each do |i|
        if i.match(/^\* SEARCH/)
          data = i.gsub(/^\* SEARCH /,"").split(" ")
        end
      end
      data
    end

    def fetch(seq, params)
      data = Array(String).new
      params = "#{params.join(" ")}"
      resp = send("FETCH", seq, params)
      resp.each do |i|
        if i =~ /^\* (.*) FETCH /
          data << i.gsub(/^\* (.*) FETCH /,"")
        end
      end
      data
    end

    def response
      resp = Array(String).new
      while(i = @socket.gets)
        if i =~ /^tag OK/
          resp << i
          break
        elsif i =~ /^tag NO/
          raise "Command error"
        elsif i =~ /^tag BAD/
          raise "Unknown command or arguments invalid"
        else
          resp << i
        end
      end
      resp
    end

  end

end
