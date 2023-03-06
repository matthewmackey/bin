#!/usr/bin/env python3

#-------------------------------------------------------------------------------
# Inspired From:
#    - https://github.com/kantord/i3-gnome-pomodoro/blob/8c2d075bcb607f9b734ecd581955601d70190d4b/pomodoro-client.py
# Install:
#   sudo apt install libgirepository1.0-dev gcc libcairo2-dev pkg-config python3-dev gir1.2-gtk-3.0
#   pip install pydbus pycairo PyGObject
#
# To uninstall packages that were installed to system:
#
#   sudo apt-get purge -y gobject-introspection libblkid-dev libcairo-script-interpreter2 libcairo2-dev \
#     libgirepository1.0-dev libglib2.0-dev libglib2.0-dev-bin libmount-dev libpcre16-3 libpcre2-dev \
#     libpcre2-posix2 libpcre3-dev libpcre32-3 libpcrecpp0v5 libpixman-1-dev libselinux1-dev libsepol1-dev \
#     libxcb-shm0-dev python3-markdown python3-packaging
#
# Install notes:
#   - https://pygobject.readthedocs.io/en/latest/getting_started.html#ubuntu-logo-ubuntu-debian-logo-debian
#
#-------------------------------------------------------------------------------
import datetime
import sys

from pydbus import SessionBus

bus = SessionBus()

# def get_notification_proxy():
#     return bus.get(
#         "org.freedesktop.Notifications", "/org/freedesktop/Notifications")

def get_pomodoro_proxy():
    return bus.get("org.gnome.Pomodoro", "/org/gnome/Pomodoro")

def format_state(state: str):
    if state == 'pomodoro':
        return 'In Session (or ready to start)'
    else:
        return ' '.join([s.capitalize() for s in state.split('-')])

def main():
    pomodoro = get_pomodoro_proxy()

    if len(sys.argv) != 2:
        print("Usage: pomo.py CMD")
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == 'introspect':
        print(pomodoro.Introspect())

    elif cmd == 'list':
        l = [x for x in dir(pomodoro) if '__' not in x]
        print('\n'.join(l))

    elif cmd == 'pause':
        pomodoro.Pause()

    elif cmd == 'resume':
        pomodoro.Resume()

    elif cmd == 'start':
        pomodoro.Start()

    elif cmd == 'status':
        state = format_state(pomodoro.State)
        duration_secs = pomodoro.StateDuration
        elapsed_secs = pomodoro.Elapsed
        time_left_secs = duration_secs - elapsed_secs

        duration_pretty = str(datetime.timedelta(seconds=duration_secs)).partition('.')
        time_left_pretty = str(datetime.timedelta(seconds=time_left_secs)).partition('.')
        elapsed_pretty = str(datetime.timedelta(seconds=elapsed_secs)).partition('.')

        print("State:           %s" % state)
        print()
        print("Time Left:       %s" % time_left_pretty[0])
        print("Pomo Duration:   %s" % duration_pretty[0])
        # print("Elapsed:     %s" % elapsed_pretty[0])

    elif cmd == 'stop':
        pomodoro.Stop()

    elif cmd == 'toggle':
        if pomodoro.IsPaused:
            pomodoro.Resume()
        else:
            pomodoro.Pause()

    else:
        print("Invalid command provided: [%s]" % cmd)


if __name__ == '__main__':
    main()
