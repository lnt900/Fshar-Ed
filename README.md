Fshar-Ed
=
- Author : lnt900@gmail.com
- Auto get download links from Fshare VIP account, simple login,get links,logout. use best for group sharing account
- Pastebin view : http://pastebin.com/WBREbipC

****************** Changes Log ***********************

0.3 : Changes

  - Now check for size of file when got download link (prevent links to be deleted short after get and not download)
  - Also add "size" column at link list box
  - Small fix on clipboard catching, prevent from catching download link it self when click "copy links download"

0.2 : Changes

  - Clipboard Monitor added, now get links from clipboard when copy
  - Support download links with password
  - Added action to wait 60 secs if duplicated login session with other ones, retry for 4 times
  - Some small fixes
  - Disable/Enable buttons when processing

0.1 : Initializing
  
  - get links : login -> get all the links -> logout immediately
  - supported both file or folder link
  - send to IDM : send links to IDM queue
  - copy links to clipboard, ready to add to any download mangager or do whatever you like
  - Todo : links protected by password, monitor clipboard, handle duplicate login session ...
