--@name FFT Loader (use this to import)
--@author AstalNeker
--@client


//IMPORTANT if this script crash, it's maybe be due to change of data
// if you wanna fix the problem you can replace the script of this file by
// this data: https://raw.githubusercontent.com/NekerSqu4w/SF_E2_Radio/main/VISUALISER/FFT%20Loader%20(use%20this%20to%20import).lua


//own library
--@include https://raw.githubusercontent.com/NekerSqu4w/my-starfall-library/main/retro_screen.txt as retro_screen.txt
--@include https://raw.githubusercontent.com/NekerSqu4w/my-starfall-library/main/multiple_screen_lib.txt as multiple_screen_lib.txt
--@include https://raw.githubusercontent.com/NekerSqu4w/my-starfall-library/main/permission_handler.txt as permission_handler.txt
--@include https://raw.githubusercontent.com/NekerSqu4w/SF_E2_Radio/main/loader.lua as loader.lua

//gui library
--@include https://raw.githubusercontent.com/itisluiz/SFUi/main/sfui/sfui.lua as sfui.lua
--@include https://raw.githubusercontent.com/itisluiz/SFUi/main/sfui/components/component.lua as components/component.lua
--@include https://raw.githubusercontent.com/itisluiz/SFUi/main/sfui/components/window.lua as components/window.lua
--@include https://raw.githubusercontent.com/itisluiz/SFUi/main/sfui/components/button.lua as components/button.lua
--@include https://raw.githubusercontent.com/itisluiz/SFUi/main/sfui/components/list.lua as components/list.lua
--@include https://raw.githubusercontent.com/itisluiz/SFUi/main/sfui/components/slider.lua as components/slider.lua
--@include https://raw.githubusercontent.com/itisluiz/SFUi/main/sfui/components/label.lua as components/label.lua


//import some custom visualizer
--@include https://raw.githubusercontent.com/NekerSqu4w/SF_E2_Radio/main/VISUALISER/custom/reactiv.lua as reactiv.lua
--@include https://raw.githubusercontent.com/NekerSqu4w/SF_E2_Radio/main/VISUALISER/custom/monstercat.lua as monstercat.lua

//import visualizer loader
--@include https://raw.githubusercontent.com/NekerSqu4w/SF_E2_Radio/main/VISUALISER/FFT%20Loader.lua as fft.lua

require("fft.lua")
