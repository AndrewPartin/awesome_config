local gears = require("gears")
local lain  = require("lain")
local awful = require("awful")
local wibox = require("wibox")
local dpi   = require("beautiful.xresources").apply_dpi
local theme_assets = require("beautiful.theme_assets")

local math = math
local os = os
local my_table = awful.util.table or gears.table -- 4.{0,1} compatibility

local theme                                     = {}
theme.confdir                                   = os.getenv("HOME") .. "/.config/awesome/themes/blarvis"
theme.wallpaper                                 = theme.confdir .. "/wall.png"
theme.font                                      = "BigBlueTermPlus Nerd Font 14"
theme.menu_bg_normal                            = "#11111b" -- crust
theme.menu_bg_focus                             = "#11111b"
theme.bg_normal                                 = "#000000" -- "#181825"
theme.bg_focus                                  = "#11111b"
theme.bg_urgent                                 = "#11111b"
theme.fg_normal                                 = "#6c7086" -- overlay0
theme.fg_focus                                  = "#f38ba8" -- red 
theme.fg_urgent                                 = "#f38ba8" -- red
theme.fg_minimize                               = "#f5e0dc" -- rosewater
theme.border_width                              = dpi(1)
theme.border_normal                             = "#313244" -- surface0
theme.border_focus                              = "#f38ba8" -- red
theme.border_marked                             = "#89b4fa" -- blue
theme.menu_border_width                         = 0
theme.menu_width                                = dpi(130)
theme.menu_fg_normal                            = "#aaaaaa"
theme.menu_fg_focus                             = "#ff8c00"
theme.menu_bg_normal                            = "#050505dd"
theme.menu_bg_focus                             = "#050505dd"

theme.taglist_squares_sel = theme_assets.taglist_squares_sel(5, "#f38ba8")
theme.taglist_squares_unsel = theme_assets.taglist_squares_sel(4, "#6c7086")

theme.tasklist_plain_task_name                  = true
theme.tasklist_disable_icon                     = true
theme.useless_gap                               = dpi(8)

theme.layout_tile                               = theme.confdir .. "/icons/tile.png"
theme.layout_floating                           = theme.confdir .. "/icons/floating.png"
theme.layout_max				= theme.confdir .. "/icons/max.png"

local markup = lain.util.markup

-- Textclock
os.setlocale(os.getenv("LANG")) -- to localize the clock
local clockicon = wibox.widget.imagebox(theme.widget_clock)
local mytextclock = wibox.widget.textclock(markup("#89b4fa", "%A %d %B ") .. markup("#a6e3a1", "-") .. markup("#fab387", " %H:%M "))
mytextclock.font = theme.font

-- CPU
local cpu = lain.widget.cpu({
	settings = function()
		widget:set_markup(markup.fontfg(theme.font, "#f38ba8", "󰍛 " .. cpu_now.usage .. "% "))
	end
})

-- Coretemp
local temp = lain.widget.temp({
	settings = function()
		widget:set_markup(markup.fontfg(theme.font, "#fab387", " " .. coretemp_now .. "°C "))
	end
})

-- Battery
local bat = lain.widget.bat({
	settings = function()
		local perc = bat_now.perc .. "%"
		local bat_icons = {"󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁿", "󰁿", "󰂀", "󰂂", "󰂂", "󰁹", "󰂄"}
		local i

		if (bat_now.ac_status == 1) then
			i = 12
		elseif ( bat_now.perc == "N/A" ) then
			i = 11
			perc = "--%"
		else
			i = math.floor(bat_now.perc / 10) + 1
		end

		perc = bat_icons[i] .. " " .. perc

		widget:set_markup(markup.fontfg(theme.font, theme.fg_normal, perc .. " "))
	end
})

-- ALSA volume
theme.volume = lain.widget.alsa({
	settings = function()
		if volume_now.status == "off" then
			volume_now.level = "󰖁 " .. volume_now.level
		else
			volume_now.level = "󰕾 " .. volume_now.level
		end

		widget:set_markup(markup.fontfg(theme.font, "#89b4fa", volume_now.level .. "% "))
	end
})

-- MEM
local memory = lain.widget.mem({
	settings = function()
		widget:set_markup(markup.fontfg(theme.font, "#f9e2af", " " .. mem_now.used .. "M "))
	end
})

-- Brightness
local brightness = awful.widget.watch(
    'brightnessctl g -d "intel_backlight"',
    2,
    function(widget, stdout)
        local brightness = tonumber(stdout)
        local brightness_percentage = math.floor(brightness / 19393 * 100)
        widget:set_markup(markup.fontfg(theme.font, "#f5e0dc", "󰃞 " .. brightness_percentage .. "% "))
    end
)

-- Seperators
local bspace20 = wibox.widget.textbox()
bspace20.forced_width = dpi(20)

local bspace10 = wibox.widget.textbox()
bspace10.forced_width = dpi(10)

function theme.at_screen_connect(s)
	-- Quake application
	s.quake = lain.util.quake({ app = awful.util.terminal })
	
	-- If wallpaper is a function, call it with the screen
	local wallpaper = theme.wallpaper
	if type(wallpaper) == "function" then
		wallpaper = wallpaper(s)
	end
	gears.wallpaper.maximized(wallpaper, s, true)

	-- Tags
	awful.tag(awful.util.tagnames, s, awful.layout.layouts[1])

	-- Create a promptbox for each screen
	s.mypromptbox = awful.widget.prompt()
	-- Create an imagebox widget which will contains an icon indicating which layout we're using.
	-- We need one layoutbox per screen.
	s.mylayoutbox = awful.widget.layoutbox(s)
	s.mylayoutbox:buttons(my_table.join(
		awful.button({}, 1, function () awful.layout.inc( 1) end),
		awful.button({}, 2, function () awful.layout.set( awful.layout.layouts[1] ) end),
                awful.button({}, 3, function () awful.layout.inc(-1) end),
                awful.button({}, 4, function () awful.layout.inc( 1) end),
                awful.button({}, 5, function () awful.layout.inc(-1) end)))

	-- Create a taglist widget
	s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, awful.util.taglist_buttons)

	-- Create a tasklist widget
	s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, awful.util.tasklist_buttons)

	-- Create the wibox
	s.mywibox = awful.wibar({ position = "top", screen = s, height = dpi(30), bg = theme.bg_normal, fg = theme.fg_normal })

	-- Add widgets to the wibox
	s.mywibox:setup {
		layout = wibox.layout.stack,
		{
			layout = wibox.layout.align.horizontal,
			{ -- Left widgets
				layout = wibox.layout.fixed.horizontal,
				s.mylayoutbox,
				s.mytaglist,
				bspace20,
				s.mypromptbox,
			},
			nil,
			{ -- Right widgets
				layout = wibox.layout.fixed.horizontal,
				brightness,
				bspace10,
				theme.volume.widget,
				bspace10,
				memory.widget,
				bspace10,
				cpu.widget,
				bspace10,
				temp.widget,
				bspace10,
				bat.widget,
			},
		},
		{
			mytextclock,
			valign = "center",
			halign = "center",
			layout = wibox.container.place
		},
	}
end

return theme
