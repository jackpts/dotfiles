local shouldPlayAnimation = true

-- The ASCII caracters used in the animation
-- ⠀⠁⠂⠃⠄⠅⠆⠇⠈⠉⠊⠋⠌⠍⠎⠏
-- ⠐⠑⠒⠓⠔⠕⠖⠗⠘⠙⠚⠛⠜⠝⠞⠟
-- ⠠⠡⠢⠣⠤⠥⠦⠧⠨⠩⠪⠫⠬⠭⠮⠯
-- ⠰⠱⠲⠳⠴⠵⠶⠷⠸⠹⠺⠻⠼⠽⠾⠿
-- ⡀⡁⡂⡃⡄⡅⡆⡇⡈⡉⡊⡋⡌⡍⡎⡏
-- ⡐⡑⡒⡓⡔⡕⡖⡗⡘⡙⡚⡛⡜⡝⡞⡟
-- ⡠⡡⡢⡣⡤⡥⡦⡧⡨⡩⡪⡫⡬⡭⡮⡯
-- ⡰⡱⡲⡳⡴⡵⡶⡷⡸⡹⡺⡻⡼⡽⡾⡿
-- ⢀⢁⢂⢃⢄⢅⢆⢇⢈⢉⢊⢋⢌⢍⢎⢏
-- ⢐⢑⢒⢓⢔⢕⢖⢗⢘⢙⢚⢛⢜⢝⢞⢟
-- ⢠⢡⢢⢣⢤⢥⢦⢧⢨⢩⢪⢫⢬⢭⢮⢯
-- ⢰⢱⢲⢳⢴⢵⢶⢷⢸⢹⢺⢻⢼⢽⢾⢿
-- ⣀⣁⣂⣃⣄⣅⣆⣇⣈⣉⣊⣋⣌⣍⣎⣏
-- ⣐⣑⣒⣓⣔⣕⣖⣗⣘⣙⣚⣛⣜⣝⣞⣟
-- ⣤⣡⣢⣣⣤⣥⣦⣧⣨⣩⣪⣫⣬⣭⣮⣯
-- ⣰⣱⣲⣳⣴⣵⣶⣷⣸⣹⣺⣻⣼⣽⣾⣿

local frames = {
  [[
  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⡖ ⠀⢀⠀⠀⠀⠀ ⠀⠀⠀⠀⠀ ⠀
  ⠀⠀⠀⠀⠀⠀⠀⠀⠈⢆⠀⠀⠀ ⣹⣷ ⣀⣴⠀⢀⣤⣶⡦⡀⠀⠀⠀⠀ ⠀
  ⠢⣀⠀⠀⠀⠀⠀⢄⠀⠈⣆⣠⣼⣿⣿⣿⣿⣿⣿⣦⣼⣏⠀⠀⠀⠀⠀⠀  ⠀
  ⠀⠈⠻⣶⣄⡀⠀⣨⣷⡿⠟⠋⠉⠉  ⠉⠉⠉⠛⠿⣿⣦⣀⠀⠀⠀⠀⠀ ⠀
  ⠀⠀⠀⠀⠙⢿⣿⡿⠋⠀⠀⠀⠀ ⢠⡄⠀ ⠀⠀ ⠈⢿⣿⣏⢀⡀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⣼⡟⠀⠀⠀⠀⠀ ⣠⣿⣿⣆ ⠀⠀⠀⠀⠈⢿⣿⡁ ⣁⡀⠀⠀
  ⠀⠀⠀⠒⢺⣿⠁⠀⠀⠀⠀ ⡰⠿⠿⠿⠿⢆⠀ ⠀⠀⠀⠸⣿⡿⠛⠉⠀⠀⠀
  ⠀⠀⢀⢠⣾⣿⠀⠀⠀⠀ ⣴⣷⡀⠀⠀⢀⣾⣦⠀⠀ ⠀⠀⣿⣿⡦⠀⠀⠀⠀
  ⠀⠀⠀⠀⣹⣿⠀⠀⠀ ⣼⣿⣿⣷⡀⢀⣾⣿⣿⣧  ⠀⢠⣿⡧⠤ ⠀⠀⠀
  ⠀⠀⠀⠈⠛⢿⣆⠀ ⠈⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠁ ⠀⣼⡿⠀⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠻⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀  ⠀⢀⣾⣿⣷⣄⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠚⢻⣿⣿⣦⣄⡀⠀⠀⠀⠀  ⢀⣠⣶⣿⡋⠀⠈⠙⠻⣄⠀⠀ 
  ⠀⠀⠀⠀⠀⠀⠀⢀⣿⠿⢿⣿⣿⣿⣶⣶⣿⡿⠻⣏⠀⠛⠄⠀⠀⠀⠀⠈⠃⠄ 
  ⠀⠀⠀⠀⠀ ⡰⠛ ⠀⠸⠋⠻⣿⣁⠀⠁⠀⠀⠈⠀  ⠀⠀⠀⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡿⠉⠀⠀⠀⠀⠀⠀⠀⠀  ⠀⠀⠀⠀⠀⠀

]],
  [[
  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⡖ ⠀⢀⠀⠀⠀⠀ ⠀⠀⠀⠀⠀ ⠀
  ⠀⠀⠀⠀⠀⠀⠀⠀⠈⢆⠀⠀⠀ ⣹⣷ ⣀⣴⠀⢀⣤⣶⡦⡀⠀⠀⠀⠀ ⠀
  ⠢⣀⠀⠀⠀⠀⠀⢄⠀⠈⣆⣠⣼⣿⣿⣿⣿⣿⣿⣦⣼⣏⠀⠀⠀⠀⠀⠀  ⠀
  ⠀⠈⠻⣶⣄⡀⠀⣨⣷⡿⠟⠋⠉⠉  ⠉⠉⠉⠛⠿⣿⣦⣀⠀⠀⠀⠀⠀ ⠀
  ⠀⠀⠀⠀⠙⢿⣿⡿⠋⠀⠀⠀⠀ ⢠⡄⠀ ⠀⠀ ⠈⢿⣿⣏⢀⡀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⣼⡟⠀⠀⠀⠀⠀ ⣠⣿⣿⣆ ⠀⠀⠀⠀⠈⢿⣿⡁ ⣁⡀⠀⠀
  ⠀⠀⠀⠒⢺⣿⠁⠀⠀⠀⠀ ⡰⠿⠿⠿⠿⢆⠀ ⠀⠀⠀⠸⣿⡿⠛⠉⠀⠀⠀
  ⠀⠀⢀⢠⣾⣿⠀⠀⠀⠀ ⣴⣷⡀⠀⠀⢀⣾⣦⠀⠀ ⠀⠀⣿⣿⡦⠀⠀⠀⠀
  ⠀⠀⠀⠀⣹⣿⠀⠀⠀ ⣼⣿⣿⣷⡀⢀⣾⣿⣿⣧  ⠀⢠⣿⡧⠤ ⠀⠀⠀
  ⠀⠀⠀⠈⠛⢿⣆⠀ ⠈⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠁ ⠀⣼⡿⠀⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠻⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀  ⠀⢀⣾⣿⣷⣄⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠚⢻⣿⣿⣦⣄⡀⠀⠀⠀⠀  ⢀⣠⣶⣿⡋⠀⠈⠙⠻⣄⠀⠀ 
  ⠀⠀⠀⠀⠀⠀⠀⢀⣿⠿⢿⣿⣿⣿⣶⣶⣿⡿⠻⣏⠀⠛⠄⠀⠀⠀⠀⠈⠃⠄ 
  ⠀⠀⠀⠀⠀ ⡰⠛ ⠀⠸⠋⠻⣿⣁⠀⠁⠀⠀⠈⠀  ⠀⠀⠀⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡿⠉⠀⠀⠀⠀⠀⠀⠀⠀  ⠀⠀⠀⠀⠀⠀

]],
  [[
  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⡖ ⠀⢀⠀⠀⠀⠀ ⠀⠀⠀⠀⠀ ⠀
  ⠀⠀⠀⠀⠀⠀⠀⠀⠈⢆⠀⠀⠀ ⣹⣷ ⣀⣴⠀⢀⣤⣶⡦⡀⠀⠀⠀⠀ ⠀
  ⠢⣀⠀⠀⠀⠀⠀⢄⠀⠈⣆⣠⣼⣿⣿⣿⣿⣿⣿⣦⣼⣏⠀⠀⠀⠀⠀⠀  ⠀
  ⠀⠈⠻⣶⣄⡀⠀⣨⣷⡿⠟⠋⠉⠉  ⠉⠉⠉⠛⠿⣿⣦⣀⠀⠀⠀⠀⠀ ⠀
  ⠀⠀⠀⠀⠙⢿⣿⡿⠋⠀⠀⠀⠀ ⢠⡄⠀ ⠀⠀ ⠈⢿⣿⣏⢀⡀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⣼⡟⠀⠀⠀⠀⠀ ⣠⣿⣿⣆ ⠀⠀⠀⠀⠈⢿⣿⡁ ⣁⡀⠀⠀
  ⠀⠀⠀⠒⢺⣿⠁⠀⠀⠀⠀ ⡰⠿⠿⠿⠿⢆⠀ ⠀⠀⠀⠸⣿⡿⠛⠉⠀⠀⠀
  ⠀⠀⢀⢠⣾⣿⠀⠀⠀⠀ ⣴⣷⡀⠀⠀⢀⣾⣦⠀⠀ ⠀⠀⣿⣿⡦⠀⠀⠀⠀
  ⠀⠀⠀⠀⣹⣿⠀⠀⠀ ⣼⣿⣿⣷⡀⢀⣾⣿⣿⣧  ⠀⢠⣿⡧⠤ ⠀⠀⠀
  ⠀⠀⠀⠈⠛⢿⣆⠀ ⠈⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠁ ⠀⣼⡿⠀⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠻⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀  ⠀⢀⣾⣿⣷⣄⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠚⢻⣿⣿⣦⣄⡀⠀⠀⠀⠀  ⢀⣠⣶⣿⡋⠀⠈⠙⠻⣄⠀⠀ 
  ⠀⠀⠀⠀⠀⠀⠀⢀⣿⠿⢿⣿⣿⣿⣶⣶⣿⡿⠻⣏⠀⠛⠄⠀⠀⠀⠀⠈⠃⠄ 
  ⠀⠀⠀⠀⠀ ⡰⠛ ⠀⠸⠋⠻⣿⣁⠀⠁⠀⠀⠈⠀  ⠀⠀⠀⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡿⠉⠀⠀⠀⠀⠀⠀⠀⠀  ⠀⠀⠀⠀⠀⠀

]],
  [[
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⠀⢀⣴⡖ ⠀⢀⠀⠀⠀⠀ ⠀⠀⠀⠀⠀ ⠀
  ⠀⠀⠀⠀⠀⠀⠀⠀⠈⢆⠀⠀⠀ ⣹⣷ ⣀⣴⠀⢀⣤⣶⡦⡀⠀⠀⠀⠀ ⠀
  ⠢⣀⠀⠀⠀⠀⠀⢄⠀⠈⣆⣠⣼⣿⣿⣿⣿⣿⣿⣦⣼⣏⠀⠀⠀⠀⠀⠀  ⠀
  ⠀⠈⠻⣶⣄⡀⠀⣨⣷⡿⠟⠋⠉⠉  ⠉⠉⠉⠛⠿⣿⣦⣀⠀⠀⠀⠀⠀ ⠀
  ⠀⠀⠀⠀⠙⢿⣿⡿⠋⠀⠀⠀⠀ ⢠ ⠀ ⠀⠀ ⠈⢿⣿⣏⢀⡀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⣼⡟⠀⠀⠀⠀⠀  ⣾⣇ ⠀⠀ ⠀⠀⠈⢿⣿⡁ ⣁⡀⠀⠀
  ⠀⠀⠀⠒⢺⣿⠁⠀⠀⠀⠀  ⡰⠿⠿⢆⠀ ⠀ ⠀⠀⠸⣿⡿⠛⠉⠀⠀⠀
  ⠀⠀⢀⢠⣾⣿⠀⠀⠀⠀  ⣴⣷ ⠀⣾⣦⠀⠀  ⠀⠀⣿⣿⡦⠀⠀⠀⠀
  ⠀⠀⠀⠀⣹⣿⠀⠀⠀  ⣼⣿⣷⡀⢀⣿⣿⣧   ⠀⢠⣿⡧⠤ ⠀⠀⠀
  ⠀⠀⠀⠈⠛⢿⣆⠀  ⠈⠉⠉⠉⠉⠉⠉⠉⠉⠁  ⠀⣼⡿⠀⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠻⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀  ⠀⢀⣾⣿⣷⣄⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠚⢻⣿⣿⣦⣄⡀⠀⠀⠀⠀  ⢀⣠⣶⣿⡋⠀⠈⠙⠻⣄⠀⠀ 
  ⠀⠀⠀⠀⠀⠀⠀⢀⣿⠿⢿⣿⣿⣿⣶⣶⣿⡿⠻⣏⠀⠛⠄⠀⠀⠀⠀⠈⠃⠄ 
  ⠀⠀⠀⠀⠀ ⡰⠛ ⠀⠸⠋⠻⣿⣁⠀⠁⠀⠀⠈⠀  ⠀⠀⠀⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡿⠉⠀⠀⠀⠀⠀⠀⠀⠀  ⠀⠀⠀⠀⠀⠀

]],
  [[
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⠀⢀⣴⡖ ⠀⢀⠀⠀⠀⠀ ⠀⠀⠀⠀⠀  
  ⠀⠀⠀⠀⠀⠀⠀⠀⠈⢆⠀⠀⠀ ⣹⣷ ⣀⣴⠀⢀⣤⣶⡦⡀⠀⠀⠀⠀ ⠀
  ⠢⣀⠀⠀⠀⠀⠀⢄⠀⠈⣆⣠⣼⣿⣿⣿⣿⣿⣿⣦⣼⣏⠀⠀⠀⠀⠀⠀  ⠀
  ⠀⠈⠻⣶⣄⡀⠀⣨⣷⡿⠟⠋⠉⠉  ⠉⠉⠉⠛⠿⣿⣦⣀⠀⠀⠀⠀⠀ ⠀
  ⠀⠀⠀⠀⠙⢿⣿⡿⠋⠀⠀⠀⠀ ⢠⠀ ⠀⠀  ⠈⢿⣿⣏⢀⡀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⣼⡟⠀⠀⠀⠀⠀  ⣾⣇ ⠀⠀ ⠀⠀⠈⢿⣿⡁ ⣁⡀⠀⠀
  ⠀⠀⠀⠒⢺⣿⠁⠀⠀⠀⠀  ⡰⠿⠿⠀ ⠀ ⠀ ⠀⠸⣿⡿⠛⠉⠀⠀⠀
  ⠀⠀⢀⢠⣾⣿⠀⠀⠀⠀  ⢀⣷  ⣷⠀⠀   ⠀⠀⣿⣿⡦⠀⠀⠀⠀
  ⠀⠀⠀⠀⣹⣿⠀⠀⠀   ⣿⣿⡀⢀⣿⣧    ⠀⢠⣿⡧⠤ ⠀⠀⠀
  ⠀⠀⠀⠈⠛⢿⣆⠀   ⠉⠉⠉⠉⠉⠉⠉⠁   ⠀⣼⡿⠀⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠻⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀  ⠀⢀⣾⣿⣷⣄⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠚⢻⣿⣿⣦⣄⡀⠀⠀⠀⠀  ⢀⣠⣶⣿⡋⠀⠈⠙⠻⣄⠀⠀ 
  ⠀⠀⠀⠀⠀⠀⠀⢀⣿⠿⢿⣿⣿⣿⣶⣶⣿⡿⠻⣏⠀⠛⠄⠀⠀⠀⠀⠈⠃⠄ 
  ⠀⠀⠀⠀⠀ ⡰⠛ ⠀⠸⠋⠻⣿⣁⠀⠁⠀⠀⠈⠀  ⠀⠀⠀⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡿⠉⠀⠀⠀⠀⠀⠀⠀⠀  ⠀⠀⠀⠀⠀⠀

]],
  [[
  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⢀⣴⡖ ⠀⢀⠀⠀⠀⠀ ⠀⠀⠀⠀⠀  
  ⠀⠀⠀⠀⠀⠀⠀⠀⠈⢆⠀⠀⠀ ⣹⣷ ⣀⣴⠀⢀⣤⣶⡦⡀⠀⠀⠀⠀ ⠀
  ⠢⣀⠀⠀⠀⠀⠀⢄⠀⠈⣆⣠⣼⣿⣿⣿⣿⣿⣿⣦⣼⣏⠀⠀⠀⠀⠀⠀  ⠀
  ⠀⠈⠻⣶⣄⡀⠀⣨⣷⡿⠟⠋⠉⠉  ⠉⠉⠉⠛⠿⣿⣦⣀⠀⠀⠀⠀⠀ ⠀
  ⠀⠀⠀⠀⠙⢿⣿⡿⠋⠀⠀⠀  ⢠⠀⠀ ⠀  ⠈⢿⣿⣏⢀⡀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⣼⡟⠀⠀⠀⠀⠀  ⣾ ⠀ ⠀ ⠀ ⠈⢿⣿⡁ ⣁⡀⠀⠀
  ⠀⠀⠀⠒⢺⣿⠁⠀⠀⠀⠀  ⡰⠿⠀ ⠀⠀   ⠀⠸⣿⡿⠛⠉⠀⠀⠀
  ⠀⠀⢀⢠⣾⣿⠀⠀⠀⠀   ⣷ ⣷⠀⠀    ⠀⠀⣿⣿⡦⠀⠀⠀⠀
  ⠀⠀⠀⠀⣹⣿⠀⠀⠀   ⡰⣿⢀⣿      ⠀⢠⣿⡧⠤ ⠀⠀⠀
  ⠀⠀⠀⠈⠛⢿⣆⠀    ⠉⠉⠉⠉⠁   ⠀  ⣼⡿⠀⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠻⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀  ⠀⢀⣾⣿⣷⣄⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠚⢻⣿⣿⣦⣄⡀⠀⠀⠀⠀  ⢀⣠⣶⣿⡋⠀⠈⠙⠻⣄⠀⠀ 
  ⠀⠀⠀⠀⠀⠀⠀⢀⣿⠿⢿⣿⣿⣿⣶⣶⣿⡿⠻⣏⠀⠛⠄⠀⠀⠀⠀⠈⠃⠄ 
  ⠀⠀⠀⠀⠀ ⡰⠛ ⠀⠸⠋⠻⣿⣁⠀⠁⠀⠀⠈⠀  ⠀⠀⠀⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡿⠉⠀⠀⠀⠀⠀⠀⠀⠀  ⠀⠀⠀⠀⠀⠀

]],
  [[
  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⡖ ⠀⢀⠀⠀⠀⠀ ⠀⠀⠀⠀⠀ ⠀
  ⠀⠀⠀⠀⠀⠀⠀⠀⠈⢆⠀⠀⠀ ⣹⣷ ⣀⣴⠀⢀⣤⣶⡦⡀⠀⠀⠀⠀ ⠀
  ⠢⣀⠀⠀⠀⠀⠀⢄⠀⠈⣆⣠⣼⣿⣿⣿⣿⣿⣿⣦⣼⣏⠀⠀⠀⠀⠀⠀  ⠀
  ⠀⠈⠻⣶⣄⡀⠀⣨⣷⡿⠟⠋⠉⠉  ⠉⠉⠉⠛⠿⣿⣦⣀⠀⠀⠀⠀⠀ ⠀
  ⠀⠀⠀⠀⠙⢿⣿⡿⠋⠀⠀⠀ ⠀⢠⡄ ⠀ ⠀ ⠈⢿⣿⣏⢀⡀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⣼⡟⠀⠀⠀⠀⠀  ⢸⡇ ⠀ ⠀ ⠀⠈⢿⣿⡁ ⣁⡀⠀⠀
  ⠀⠀⠀⠒⢺⣿⠁⠀⠀⠀⠀   ⠸⠇⠀  ⠀⠀ ⠀⠸⣿⡿⠛⠉⠀⠀⠀
  ⠀⠀⢀⢠⣾⣿⠀⠀⠀⠀    ⢸⡆⠀     ⠀⠀⣿⣿⡦⠀⠀⠀⠀
  ⠀⠀⠀⠀⣹⣿⠀⠀⠀     ⢸⡇      ⠀⢠⣿⡧⠤ ⠀⠀⠀
  ⠀⠀⠀⠈⠛⢿⣆⠀      ⠈⠁    ⠀  ⣼⡿⠀⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠻⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀  ⠀⢀⣾⣿⣷⣄⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠚⢻⣿⣿⣦⣄⡀⠀⠀⠀⠀  ⢀⣠⣶⣿⡋⠀⠈⠙⠻⣄⠀⠀ 
  ⠀⠀⠀⠀⠀⠀⠀⢀⣿⠿⢿⣿⣿⣿⣶⣶⣿⡿⠻⣏⠀⠛⠄⠀⠀⠀⠀⠈⠃⠄ 
  ⠀⠀⠀⠀⠀ ⡰⠛ ⠀⠸⠋⠻⣿⣁⠀⠁⠀⠀⠈⠀  ⠀⠀⠀⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡿⠉⠀⠀⠀⠀⠀⠀⠀⠀  ⠀⠀⠀⠀⠀⠀

]],
  [[
  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⢀⣴⡖ ⠀⢀⠀⠀⠀⠀ ⠀⠀⠀⠀⠀  
  ⠀⠀⠀⠀⠀⠀⠀⠀⠈⢆⠀⠀⠀ ⣹⣷ ⣀⣴⠀⢀⣤⣶⡦⡀⠀⠀⠀⠀ ⠀
  ⠢⣀⠀⠀⠀⠀⠀⢄⠀⠈⣆⣠⣼⣿⣿⣿⣿⣿⣿⣦⣼⣏⠀⠀⠀⠀⠀⠀  ⠀
  ⠀⠈⠻⣶⣄⡀⠀⣨⣷⡿⠟⠋⠉⠉  ⠉⠉⠉⠛⠿⣿⣦⣀⠀⠀⠀⠀⠀ ⠀
  ⠀⠀⠀⠀⠙⢿⣿⡿⠋⠀⠀ ⠀⠀ ⡄⠀⠀   ⠈⢿⣿⣏⢀⡀⠀⠀⠀ ⠀
  ⠀⠀⠀⠀⠀⣼⡟⠀⠀⠀⠀ ⠀  ⣿ ⠀⠀  ⠀⠈⢿⣿⡁ ⣁⡀⠀ ⠀
  ⠀⠀⠀⠒⢺⣿⠁⠀⠀⠀ ⠀   ⠿⢆⠀⠀⠀  ⠀⠸⣿⡿⠛⠉⠀⠀⠀
  ⠀⠀⢀⢠⣾⣿⠀⠀⠀⠀    ⣾ ⣾⠀    ⠀⠀⣿⣿⡦⠀⠀⠀⠀ 
  ⠀⠀⠀⠀⣹⣿⠀⠀⠀     ⣿⡀⣿⢆    ⠀⢠⣿⡧⠤ ⠀⠀⠀
  ⠀⠀⠀⠈⠛⢿⣆⠀      ⠉⠉⠉⠉  ⠀  ⣼⡿⠀⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠻⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀  ⠀⢀⣾⣿⣷⣄⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠚⢻⣿⣿⣦⣄⡀⠀⠀⠀⠀  ⢀⣠⣶⣿⡋⠀⠈⠙⠻⣄⠀⠀ 
  ⠀⠀⠀⠀⠀⠀⠀⢀⣿⠿⢿⣿⣿⣿⣶⣶⣿⡿⠻⣏⠀⠛⠄⠀⠀⠀⠀⠈⠃⠄ 
  ⠀⠀⠀⠀⠀ ⡰⠛ ⠀⠸⠋⠻⣿⣁⠀⠁⠀⠀⠈⠀  ⠀⠀⠀⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡿⠉⠀⠀⠀⠀⠀⠀⠀⠀  ⠀⠀⠀⠀⠀⠀

]],
  [[
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⠀⢀⣴⡖ ⠀⢀⠀⠀⠀⠀ ⠀⠀⠀⠀⠀  
  ⠀⠀⠀⠀⠀⠀⠀⠀⠈⢆⠀⠀⠀ ⣹⣷ ⣀⣴⠀⢀⣤⣶⡦⡀⠀⠀⠀⠀ ⠀
  ⠢⣀⠀⠀⠀⠀⠀⢄⠀⠈⣆⣠⣼⣿⣿⣿⣿⣿⣿⣦⣼⣏⠀⠀⠀⠀⠀⠀  ⠀
  ⠀⠈⠻⣶⣄⡀⠀⣨⣷⡿⠟⠋⠉⠉  ⠉⠉⠉⠛⠿⣿⣦⣀⠀⠀⠀⠀⠀ ⠀
  ⠀⠀⠀⠀⠙⢿⣿⡿⠋⠀⠀⠀⠀  ⡄⠀ ⠀⠀ ⠈⢿⣿⣏⢀⡀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⣼⡟⠀⠀⠀⠀⠀  ⣰⣿ ⠀⠀ ⠀ ⠈⢿⣿⡁ ⣁⡀⠀⠀
  ⠀⠀⠀⠒⢺⣿⠁⠀⠀⠀⠀   ⠿⠿⢆ ⠀ ⠀ ⠀⠸⣿⡿⠛⠉⠀⠀⠀
  ⠀⠀⢀⢠⣾⣿⠀⠀⠀⠀   ⣾  ⣾⡀⠀   ⠀⠀⣿⣿⡦⠀⠀⠀⠀
  ⠀⠀⠀⠀⣹⣿⠀⠀⠀   ⣼⣿⡀⢀⣿⣿    ⠀⢠⣿⡧⠤ ⠀⠀⠀
  ⠀⠀⠀⠈⠛⢿⣆⠀   ⠈⠉⠉⠉⠉⠉⠉⠉   ⠀⣼⡿⠀⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠻⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀  ⠀⢀⣾⣿⣷⣄⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠚⢻⣿⣿⣦⣄⡀⠀⠀⠀⠀  ⢀⣠⣶⣿⡋⠀⠈⠙⠻⣄⠀⠀ 
  ⠀⠀⠀⠀⠀⠀⠀⢀⣿⠿⢿⣿⣿⣿⣶⣶⣿⡿⠻⣏⠀⠛⠄⠀⠀⠀⠀⠈⠃⠄ 
  ⠀⠀⠀⠀⠀ ⡰⠛ ⠀⠸⠋⠻⣿⣁⠀⠁⠀⠀⠈⠀  ⠀⠀⠀⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡿⠉⠀⠀⠀⠀⠀⠀⠀⠀  ⠀⠀⠀⠀⠀⠀

]],
  [[
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⠀⢀⣴⡖ ⠀⢀⠀⠀⠀⠀ ⠀⠀⠀⠀⠀ ⠀
  ⠀⠀⠀⠀⠀⠀⠀⠀⠈⢆⠀⠀⠀ ⣹⣷ ⣀⣴⠀⢀⣤⣶⡦⡀⠀⠀⠀⠀ ⠀
  ⠢⣀⠀⠀⠀⠀⠀⢄⠀⠈⣆⣠⣼⣿⣿⣿⣿⣿⣿⣦⣼⣏⠀⠀⠀⠀⠀⠀  ⠀
  ⠀⠈⠻⣶⣄⡀⠀⣨⣷⡿⠟⠋⠉⠉  ⠉⠉⠉⠛⠿⣿⣦⣀⠀⠀⠀⠀⠀ ⠀
  ⠀⠀⠀⠀⠙⢿⣿⡿⠋⠀⠀⠀⠀  ⡄⠀ ⠀⠀ ⠈⢿⣿⣏⢀⡀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⣼⡟⠀⠀⠀⠀⠀  ⣰⣿ ⠀⠀ ⠀⠀⠈⢿⣿⡁ ⣁⡀⠀⠀
  ⠀⠀⠀⠒⢺⣿⠁⠀⠀⠀⠀  ⡰⠿⠿⢆⠀ ⠀ ⠀⠀⠸⣿⡿⠛⠉⠀⠀⠀
  ⠀⠀⢀⢠⣾⣿⠀⠀⠀⠀  ⣴⣷ ⠀⣾⣦⠀⠀  ⠀⠀⣿⣿⡦⠀⠀⠀⠀
  ⠀⠀⠀⠀⣹⣿⠀⠀⠀  ⣼⣿⣿⡀⢀⣿⣿⣧   ⠀⢠⣿⡧⠤ ⠀⠀⠀
  ⠀⠀⠀⠈⠛⢿⣆⠀  ⠈⠉⠉⠉⠉⠉⠉⠉⠉⠁  ⠀⣼⡿⠀⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠻⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀  ⠀⢀⣾⣿⣷⣄⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠚⢻⣿⣿⣦⣄⡀⠀⠀⠀⠀  ⢀⣠⣶⣿⡋⠀⠈⠙⠻⣄⠀⠀ 
  ⠀⠀⠀⠀⠀⠀⠀⢀⣿⠿⢿⣿⣿⣿⣶⣶⣿⡿⠻⣏⠀⠛⠄⠀⠀⠀⠀⠈⠃⠄ 
  ⠀⠀⠀⠀⠀ ⡰⠛ ⠀⠸⠋⠻⣿⣁⠀⠁⠀⠀⠈⠀  ⠀⠀⠀⠀⠀⠀⠀⠀
  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡿⠉⠀⠀⠀⠀⠀⠀⠀⠀  ⠀⠀⠀⠀⠀⠀

]],
}

local asciiImg = frames[1]

local function ascii(counting, callback)
  if not shouldPlayAnimation then
    return
  end

  -- local frameCount = #frames < math.floor(counting) and frames[#frames] or frames[math.floor(counting)]
  asciiImg = #frames < math.floor(counting) and frames[#frames] or frames[math.floor(counting)]
  Snacks.dashboard.update()

  -- print(counting)

  if counting >= #frames + 1 then
    callback(callback)
  end
end

local function theAnimation(callback)
  require("snacks").animate(1, #frames + 1, function(value, ctx)
    ascii(value, callback)
  end, {
    duration = 300,
    fps = 60,
  })
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "snacks_dashboard",
  callback = function()
    -- Your custom code here that runs when the snacks dashboard filetype is set
    -- print("Snacks Dashboard is open!")
    shouldPlayAnimation = true
    asciiImg = frames[1]
  end,
})

vim.api.nvim_create_autocmd("DirChanged", {
  pattern = "*", -- Match any directory change
  callback = function()
    local new_dir = vim.fn.getcwd()

    -- Same logic as above for project markers
    local project_markers = { ".git", "package.json", "Cargo.toml", ".project_root" }
    local is_project_root = false

    for _, marker in ipairs(project_markers) do
      if vim.fn.findfile(marker, new_dir .. ";") ~= "" then
        is_project_root = true
        break
      end
    end

    if is_project_root then
      -- print("Changed to project directory: " .. new_dir)
      shouldPlayAnimation = false
      -- Your custom code here for when you change into a project directory
    else
      -- print("Changed to non-project directory: " .. new_dir)
      shouldPlayAnimation = false
      -- Optional: Code for when you leave a project directory
    end
  end,
})

return {
  { "nvimdev/dashboard-nvim", enabled = false },

  {
    "folke/snacks.nvim",
    -- priority = 1000,
    -- lazy = false,

    ---@type snacks.Config
    opts = {
      image = { enabled = true },

      -- DASHBOARD
      dashboard = {
        enabled = true,
        preset = {
          header = false,
          pick = nil,
          keys = {
            {
              icon = " ",
              key = "p",
              desc = "Projects",
              action = function()
                Snacks.picker.projects({
                  sort = { fields = { "time:asc", "idx" } },
                  on_close = function(info)
                    shouldPlayAnimation = true
                  end,
                })
                shouldPlayAnimation = false
              end,
            },
            {
              icon = " ",
              key = "s",
              desc = "Restore Session",
              action = function()
                require("persistence").load({ last = true })
                shouldPlayAnimation = false
              end,
            },
            {
              icon = " ",
              key = "c",
              desc = "Config",
              action = function()
                Snacks.dashboard.pick("files", {
                  cwd = vim.fn.stdpath("config"),
                  on_close = function(info)
                    shouldPlayAnimation = true
                  end,
                })
                shouldPlayAnimation = false
              end,
            },
            { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        sections = {
          {
            section = "header",
            padding = 1,
            function()
              return { header = asciiImg }
            end,
          },
          -- { section = "header" },
          -- { section = "terminal", cmd = "fortune -s | cowsay", hl = "header", padding = 1, indent = 8 },
          { section = "keys", gap = 0, padding = 1 },
          { pane = 1, icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
          { pane = 1, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
          {
            pane = 1,
            icon = " ",
            title = "Git Status",
            section = "terminal",
            -- enabled = Snacks.git.get_root() ~= nil,
            cmd = "hub status --short --branch --renames",
            height = 5,
            padding = 1,
            ttl = 5 * 60,
            indent = 3,
          },
          -- { section = "startup" },
          { section = "startup", enabled = false },
        },
        on_close = function()
          shouldPlayAnimation = false
        end,
      },

      bigfile = { enabled = true },
      notifier = {
        enabled = true,
        timeout = 3000,
      },
      quickfile = { enabled = true },
      statuscolumn = { enabled = true },

      -- Terminal
      terminal = {
        enabled = true,
        win = {
          position = "float",
          border = "single",
          keys = {
            exit = { "<ESC>", "<cmd>q<cr>", desc = "Exit", expr = true, mode = { "t", "n" } },
          },
        },
      },

      words = {
        enabled = true,
        debounce = 200,
        notify_jump = false,
        notify_end = true,
        foldopen = true,
        jumplist = true,
        modes = { "n" },
      },
      styles = {
        notification = {
          wo = { wrap = true }, -- Wrap notifications
        },
      },
      keys = {
        {
          "<leader>un",
          function()
            Snacks.notifier.hide()
          end,
          desc = "Dismiss All Notifications",
        },
        {
          "<leader>bd",
          function()
            Snacks.bufdelete()
          end,
          desc = "Delete Buffer",
        },
        {
          "<leader>gg",
          function()
            Snacks.lazygit()
          end,
          desc = "Lazygit",
        },
        {
          "<leader>gb",
          function()
            Snacks.git.blame_line()
          end,
          desc = "Git Blame Line",
        },
        {
          "<leader>gB",
          function()
            Snacks.gitbrowse()
          end,
          desc = "Git Browse",
        },
        {
          "<leader>gf",
          function()
            Snacks.lazygit.log_file()
          end,
          desc = "Lazygit Current File History",
        },
        {
          "<leader>gl",
          function()
            Snacks.lazygit.log()
          end,
          desc = "Lazygit Log (cwd)",
        },
        {
          "<leader>cR",
          function()
            Snacks.rename.rename_file()
          end,
          desc = "Rename File",
        },
        {
          "<c-/>",
          function()
            Snacks.terminal()
          end,
          desc = "Toggle Terminal",
        },
        {
          "<c-_>",
          function()
            Snacks.terminal()
          end,
          desc = "which_key_ignore",
        },
        {
          "]]",
          function()
            Snacks.words.jump(vim.v.count1)
          end,
          desc = "Next Reference",
          mode = { "n", "t" },
        },
        {
          "[[",
          function()
            Snacks.words.jump(-vim.v.count1)
          end,
          desc = "Prev Reference",
          mode = { "n", "t" },
        },
        {
          "<leader>N",
          desc = "Neovim News",
          function()
            Snacks.win({
              file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
              width = 0.6,
              height = 0.6,
              wo = {
                spell = false,
                wrap = false,
                signcolumn = "yes",
                statuscolumn = " ",
                conceallevel = 3,
              },
            })
          end,
        },
      },
    },

    -- INIT   
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          -- Setup some globals for debugging (lazy-loaded)
          _G.dd = function(...)
            Snacks.debug.inspect(...)
          end
          _G.bt = function()
            Snacks.debug.backtrace()
          end
          vim.print = _G.dd -- Override print to use snacks for `:=` command

          -- Create some toggle mappings
          Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
          Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
          Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
          Snacks.toggle.diagnostics():map("<leader>ud")
          Snacks.toggle.line_number():map("<leader>ul")
          Snacks.toggle
            .option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
            :map("<leader>uc")
          Snacks.toggle.treesitter():map("<leader>uT")
          Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
          Snacks.toggle.inlay_hints():map("<leader>uh")
        end,
      })

      vim.defer_fn(function()
        theAnimation(theAnimation)
      end, 100)
    end,
  },
}
