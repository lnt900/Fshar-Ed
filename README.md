Fshar-Ed
=
- Author : lnt900@gmail.com
- Tự động lấy link từ tài khoản VIP fshare. Thực hiện đăng nhập, lấy các link rồi logout ngay lập tức. Phù hợp cho các tài khoản VIP chia sẻ theo nhóm.
- Writen and Build by AutoIt at http://www.autoitscript.com/site/autoit/
- Pastebin view : http://pastebin.com/WBREbipC

Changes Log
=
0.3 : Changes

  - Kiểm tra kích thước file khi lấy được link download (ngăn cho link không bị xóa sau 1 khoảng thời gian ngắn nếu không tải ngay sau khi lấy link)
  - Thêm cột "size" vào ô danh sách link download
  - Sửa bắt link từ clipboard, không copy link download khi ấn nút "copy links download"

0.2 : Changes

  - Clipboard Monitor added, tự động lấy link vào danh sách khi copy 1 link fshare.
  - Hỗ trợ link download có mật khẩu
  - Logout và chờ 60 giây khi phát hiện trùng phiên đăng nhập với người khác, thử lại 4 lần. nếu sau 4 lần vẫn chưa download được sẽ ngừng xử lý
  - Vài chỉnh sửa nhỏ
  - Ẩn/hiên các nút khi xử lý

0.1 : Initializing
  
  - Lấy link : đăng nhập -> lấy các link -> logout ngay
  - Hỗ trợ cả link file và thư mục
  - send to IDM : gửi link download vào queue của IDM ( internet download manager )
  - copy links vào clipboard, sẵn sàng để thêm vào các trình download hoặc tùy sử dụng
  - Todo : link có mật khẩu, monitor clipboard, xử lý trùng phiên đăng nhập với người khác ...
