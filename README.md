# crystal-lang-imap

Small imap library written after the RFC 3501 standard for personal use.
Only working over ssl, couple commands missing, only minor error handling, no logging, fetch returns unformatted response...

Pretty much made for personal use so its very work in progress. 
No tests written so far.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     crystal-lang-imap:
       github: annwyl/crystal-lang-imap
   ```

2. Run `shards install`

## Usage


```crystal
client = IMAP::Client.new

# logging in
client.login("xxxx@xxx.xx", "xxx")

# returns list of mailboxes 
list = client.list

# selecting specific mailbox
client.select("INBOX/social")

# select specific mailbox in read-only with examine
client.examine("INBOX/social")

# create new mailbox
client.create("NameOfNewMailbox")

# delete mailbox
client.delete("NameOfMailbox")

# rename mailbox
client.rename("OldMailboxName","NewMailboxName")

# subscribe to a mailbox
client.subscribe("MailboxName")

# unsubscribe a mailbox
client.unsubscribe("MailboxName")

# returns the status of the requested mailbox
# legal flags are: MESSAGES, RECENT, UIDNEXT, UIDVALIDITY, UNSEEN
status = client.status("INBOX/spam", ["MESSAGES", "RECENT"])

# append a new msg to the end of the specified mailbox
# legal flags are: \Seen, \Answered, \Flagged, \Deleted, \Draft, \Recent
client.append("INBOX/social", 
                "Date: Mon, 7 Feb 1994 21:52:25 -0800 (PST)\r\n
                From: Fred Foobar <foobar@Blurdybloop.COM>\r\n
                Subject: hello world\r\n
                To: mooch@owatagu.siam.edu\r\n
                Content-Type: TEXT/PLAIN; CHARSET=US-ASCII\r\n\r\n
                Hello Joe, do you think we can meet at 3:30 tomorrow?\r\n", 
                ["\Recent"])

# requests a checkpoint of the currently selected mailbox
client.check

# removes all messages with the \Deleted flag in the currently select mailbox
client.close

# removes all messages with the \Deleted flag in the currently select mailbox with untagged responses
client.expunge

# searches currently select mailbox and returns ids of matching mails
ids = client.search(["SINCE 1-Feb-1994", "NOT FROM\"SMITH\"", "TO xxxx@xxx.xx"])

# fetches mail data
# returns still unformatted data
data = client.fetch("1", ["ENVELOPE"])
# or
data = client.fetch("2:4", ["FLAGS"])

# sends logout command and closes the socket
client.logout
```
## Contributing

1. Fork it (<https://github.com/annwyl/crystal-lang-imap/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
