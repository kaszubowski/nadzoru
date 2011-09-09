gtk.InfoDialog = {}
setmetatable(gtk.InfoDialog, {__index = gtk.Dialog})

local obj, mt

local function __build()
	obj = gtk.Dialog.new()
	obj:cast(gtk.InfoDialog)
	mt = getmetatable(obj)
	obj:set("window-position", gtk.WIN_POS_CENTER, "resizable", false, "modal", true,
		"title", "Info", "icon-name", "gtk-info")
	mt.bOk = obj:add_button("gtk-ok", gtk.RESPONSE_OK)
	mt.vbox = obj:get_content_area()
	mt.image = gtk.Image.new()
	mt.image:set("icon-size", 6, "stock", "gtk-dialog-info")
	mt.label = gtk.Label.new("")
	mt.label:set("selectable", true, "use-markup", true, "xalign", 1)
	mt.hbox = gtk.HBox.new(false, 10)
	mt.hbox:add(mt.image, mt.label)
	mt.vbox:add(mt.hbox)
	mt.vbox:show_all()
end

function gtk.InfoDialog.showInfo(message)
	if not obj then
		__build()
	end

	mt.label:set("label", message)
	local res = obj:run()
	obj:hide()

	return res
end
