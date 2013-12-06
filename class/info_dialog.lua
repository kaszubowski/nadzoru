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
    mt.hbox = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
    mt.hbox:add(mt.image, mt.label)
    mt.vbox:add(mt.hbox)
    mt.vbox:show_all()
end

local function __build2()
    obj = gtk.Dialog.new()
    obj:cast(gtk.InfoDialog)
    mt = getmetatable(obj)
    obj:set("window-position", gtk.WIN_POS_CENTER, "resizable", false, "modal", true,
        "title", "Info", "icon-name", "gtk-info", "width-request", 600, "height-request", 300)
    mt.bOk = obj:add_button("gtk-ok", gtk.RESPONSE_OK)
    mt.vbox = obj:get_content_area()
    mt.image = gtk.Image.new()
    mt.image:set("icon-size", 6, "stock", "gtk-dialog-info")
    mt.label = gtk.Label.new("")
    mt.label:set("selectable", true, "use-markup", true, "xalign", 1)
    mt.hbox = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
    mt.scrolled = gtk.ScrolledWindow.new()
    mt.scrolled:set_shadow_type(gtk.SHADOW_ETCHED_IN)
    mt.scrolled:add( mt.label )
    mt.hbox:pack_start( mt.image, false, false, 0 )
    mt.hbox:pack_start( mt.scrolled, true, true, 0 )
    mt.vbox:pack_start( mt.hbox, true, true, 0)
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
