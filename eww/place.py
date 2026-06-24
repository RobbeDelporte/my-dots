#!/usr/bin/env python3
"""Drag-to-place editor for the wallpaper clock (move-only).

A transparent gtk-layer-shell overlay on the focused output shows a proxy of the
clock that you drag to position. Enter prints the chosen top-left "<x> <y>" (in
that output's local logical pixels) to stdout; Esc prints "CANCEL". All file I/O
and applying the result lives in place.sh -- this is pure GUI.

The geometry helpers (seed, clamp) are module-level and gi-free so they can be
unit-tested without a display; the GTK code is imported lazily inside main().
"""
import sys


def _split_anchor(anchor):
    """eww anchors are two words ('top left', 'center right', ...) except the
    lone 'center'. Return (vertical, horizontal)."""
    parts = anchor.split()
    if len(parts) == 2:
        return parts[0], parts[1]
    return "center", "center"


def seed(anchor, xoff, yoff, ow, oh, w, h):
    """Convert an eww :geometry (anchor + inward offset) to the clock's top-left
    pixel on an output of size ow x oh, mirroring eww's placement semantics."""
    vert, horiz = _split_anchor(anchor)
    if horiz == "left":
        x = xoff
    elif horiz == "right":
        x = ow - xoff - w
    else:  # center
        x = (ow - w) // 2 + xoff
    if vert == "top":
        y = yoff
    elif vert == "bottom":
        y = oh - yoff - h
    else:  # center
        y = (oh - h) // 2 + yoff
    return x, y


def clamp(x, y, ow, oh, w, h):
    """Keep the w x h clock fully inside an ow x oh output."""
    cx = min(max(x, 0), max(ow - w, 0))
    cy = min(max(y, 0), max(oh - h, 0))
    return cx, cy


def _hex_rgb(s):
    s = s.lstrip("#")
    return int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16)


def main(argv):
    import argparse
    import time

    ap = argparse.ArgumentParser()
    ap.add_argument("--anchor", default="center right")
    ap.add_argument("--xoff", type=int, default=60)
    ap.add_argument("--yoff", type=int, default=0)
    ap.add_argument("--w", type=int, default=660)
    ap.add_argument("--h", type=int, default=360)
    ap.add_argument("--accent", default="#8bd0f0")
    # Logical layout origin of the output to place the overlay on (from the
    # compositor, via place.sh). GdkMonitor is matched by geometry origin since
    # this GTK build's GdkWaylandMonitor has no get_connector(). Unset -> let the
    # compositor pick and seed from the monitor under the window.
    ap.add_argument("--mon-x", type=int, default=None)
    ap.add_argument("--mon-y", type=int, default=None)
    # Diagnostic only: build the overlay, auto-quit after N ms without grabbing
    # the keyboard, and print "SELFTEST <x> <y>" (the seeded position). Lets an
    # automated smoke test verify GUI/CSS/layer-shell construction headlessly.
    ap.add_argument("--selftest-ms", type=int, default=0)
    a = ap.parse_args(argv)

    import gi
    gi.require_version("Gtk", "3.0")
    gi.require_version("GtkLayerShell", "0.1")
    from gi.repository import Gtk, Gdk, GtkLayerShell, GLib

    W, H = a.w, a.h
    r, g, b = _hex_rgb(a.accent)
    st = {"x": 0, "y": 0, "ow": 0, "oh": 0, "seeded": False,
          "drag": None, "result": None}

    disp = Gdk.Display.get_default()

    # Pick the target monitor by logical-origin match (from --mon-x/--mon-y).
    target_mon = None
    if a.mon_x is not None and a.mon_y is not None:
        for i in range(disp.get_n_monitors()):
            m = disp.get_monitor(i)
            mg = m.get_geometry()
            if mg.x == a.mon_x and mg.y == a.mon_y:
                target_mon = m
                break

    win = Gtk.Window()
    GtkLayerShell.init_for_window(win)
    if target_mon is not None:
        GtkLayerShell.set_monitor(win, target_mon)
    GtkLayerShell.set_layer(win, GtkLayerShell.Layer.OVERLAY)
    GtkLayerShell.set_namespace(win, "clock-place")
    for edge in (GtkLayerShell.Edge.LEFT, GtkLayerShell.Edge.RIGHT,
                 GtkLayerShell.Edge.TOP, GtkLayerShell.Edge.BOTTOM):
        GtkLayerShell.set_anchor(win, edge, True)  # anchor all 4 -> fill output
    GtkLayerShell.set_keyboard_mode(
        win,
        GtkLayerShell.KeyboardMode.NONE if a.selftest_ms
        else GtkLayerShell.KeyboardMode.EXCLUSIVE)

    # Transparent window so the wallpaper shows through.
    win.set_app_paintable(True)
    visual = win.get_screen().get_rgba_visual()
    if visual is not None:
        win.set_visual(visual)

    css = ("""
        window {{ background-color: rgba(0,0,0,0.22); }}
        .proxy {{
            background-color: rgba({r},{g},{b},0.14);
            border: 2px solid rgba({r},{g},{b},0.95);
            border-radius: 4px;
        }}
        .proxy-time {{
            color: rgba({r},{g},{b},0.95);
            font-family: "JetBrains Mono", monospace;
            font-size: 56px;
            font-weight: bold;
        }}
        .hint {{
            color: rgba(255,255,255,0.85);
            background-color: rgba(0,0,0,0.55);
            border-radius: 6px;
            padding: 8px 14px;
            font-size: 15px;
        }}
    """).format(r=r, g=g, b=b)
    prov = Gtk.CssProvider()
    prov.load_from_data(css.encode())
    Gtk.StyleContext.add_provider_for_screen(
        win.get_screen(), prov, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

    root = Gtk.EventBox()
    root.add_events(Gdk.EventMask.BUTTON_PRESS_MASK
                    | Gdk.EventMask.BUTTON_RELEASE_MASK
                    | Gdk.EventMask.POINTER_MOTION_MASK)
    fixed = Gtk.Fixed()
    root.add(fixed)
    win.add(root)

    proxy = Gtk.Box()
    proxy.get_style_context().add_class("proxy")
    proxy.set_size_request(W, H)
    time_lbl = Gtk.Label(label=time.strftime("%H时%M分"))
    time_lbl.get_style_context().add_class("proxy-time")
    time_lbl.set_halign(Gtk.Align.CENTER)
    time_lbl.set_valign(Gtk.Align.CENTER)
    proxy.set_center_widget(time_lbl)
    fixed.put(proxy, 0, 0)

    hint = Gtk.Label(label="drag to place    ·    Enter save    ·    Esc cancel")
    hint.get_style_context().add_class("hint")
    fixed.put(hint, 0, 0)

    def place():
        fixed.move(proxy, st["x"], st["y"])

    def output_size():
        # Logical size of the output the overlay is on. Set at seed time from the
        # monitor geometry (timing-independent); fall back to the allocation.
        if st["ow"] > 1 and st["oh"] > 1:
            return st["ow"], st["oh"]
        return root.get_allocated_width(), root.get_allocated_height()

    def seed_once(*_):
        # Seed from the MONITOR's logical geometry, not the window allocation:
        # under layer-shell the allocation arrives as several transient sizes
        # (content size, then output size, with the open animation in between),
        # so the allocation is an unreliable source for the output dimensions.
        if st["seeded"]:
            return False
        mon = target_mon
        if mon is None:
            gdkwin = win.get_window()
            if gdkwin is None:
                return True  # not mapped yet; retry
            mon = (disp.get_monitor_at_window(gdkwin)
                   or disp.get_primary_monitor() or disp.get_monitor(0))
        geo = mon.get_geometry()
        ow, oh = geo.width, geo.height
        if ow <= 1 or oh <= 1:
            return True
        st["ow"], st["oh"] = ow, oh
        st["x"], st["y"] = clamp(*seed(a.anchor, a.xoff, a.yoff, ow, oh, W, H),
                                 ow, oh, W, H)
        st["seeded"] = True
        place()
        fixed.move(hint, max(20, (ow - hint.get_allocated_width()) // 2), 28)
        return False

    def inside(px, py):
        return st["x"] <= px <= st["x"] + W and st["y"] <= py <= st["y"] + H

    def on_press(_w, ev):
        ow, oh = output_size()
        if inside(ev.x, ev.y):
            st["drag"] = (ev.x - st["x"], ev.y - st["y"])
        else:  # jump the proxy's centre to the cursor, then grab at centre
            st["x"], st["y"] = clamp(int(ev.x) - W // 2, int(ev.y) - H // 2,
                                     ow, oh, W, H)
            st["drag"] = (W // 2, H // 2)
            place()
        return True

    def on_motion(_w, ev):
        if st["drag"] is None:
            return False
        ow, oh = output_size()
        dx, dy = st["drag"]
        st["x"], st["y"] = clamp(int(ev.x - dx), int(ev.y - dy), ow, oh, W, H)
        place()
        return True

    def on_release(_w, _ev):
        st["drag"] = None
        return True

    def on_key(_w, ev):
        if ev.keyval in (Gdk.KEY_Return, Gdk.KEY_KP_Enter):
            st["result"] = "{} {}".format(st["x"], st["y"])
            win.destroy()
        elif ev.keyval == Gdk.KEY_Escape:
            st["result"] = "CANCEL"
            win.destroy()
        return True

    win.connect("map-event", seed_once)
    GLib.timeout_add(30, seed_once)  # backup: retry until the monitor is known
    root.connect("button-press-event", on_press)
    root.connect("motion-notify-event", on_motion)
    root.connect("button-release-event", on_release)
    win.connect("key-press-event", on_key)
    win.connect("destroy", Gtk.main_quit)

    if a.selftest_ms:
        GLib.timeout_add(a.selftest_ms, lambda: (win.destroy(), False)[1])

    win.show_all()
    Gtk.main()

    if a.selftest_ms:
        print("SELFTEST {} {}".format(st["x"], st["y"]))
    else:
        print(st["result"] if st["result"] else "CANCEL")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
