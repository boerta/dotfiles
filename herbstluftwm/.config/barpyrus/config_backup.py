import sys
import contextlib
import multiprocessing
import collections

from barpyrus import lemonbar, conky, trayer, hlwm, core
from barpyrus import widgets as W
from barpyrus.core import Theme

class Gruv:

    # https://github.com/morhetz/gruvbox

    BG0_H = '#1d2021'
    BG0_S = '#32302f'
    BG0 = '#282828'
    BG1 = '#3c3836'
    BG2 = '#504945'
    BG3 = '#665c54'
    BG4 = '#7c6f64'
    FG0 = '#fbf1c7'
    FG1 = '#ebdbb2'
    FG2 = '#d5c4a1'
    FG3 = '#bdae93'
    FG4 = '#a89984'
    FG = FG1
    BG = BG0_H
    RED_DARK = '#cc241d'
    GREEN_DARK = '#98971a'
    YELLOW_DARK = '#d79921'
    BLUE_DARK = '#458588'
    PURPLE_DARK = '#b16286'
    AQUA_DARK = '#689d6a'
    GRAY_DARK = '#a89984'
    ORANGE_DARK = '#d65d0e'
    RED_LIGHT = '#fb4934'
    GREEN_LIGHT = '#b8bb26'
    YELLOW_LIGHT = '#fabd2f'
    BLUE_LIGHT = '#83a598'
    PURPLE_LIGHT = '#d3869b'
    AQUA_LIGHT = '#8ec07c'
    GRAY_LIGHT = '#928374'
    ORANGE_LIGHT = '#fe8019'


ACCENT_COLOR = Gruv.ORANGE_DARK


@contextlib.contextmanager
def highlight_critical(cg, match, predicate='> 90'):
    with cg.if_('match ${%s} %s' % (match, predicate)):
        cg.fg(Gruv.RED_LIGHT)
    yield
    cg.fg(None)


def tag_renderer(taginfo, painter):
    if taginfo.empty:
        return

    painter.fg(Gruv.RED_LIGHT if taginfo.urgent else None)

    if taginfo.here:
        painter.bg(ACCENT_COLOR)
    else:
        painter.set_flag(painter.underline, taginfo.visible)
        painter.ol(ACCENT_COLOR)

    painter.space(3)
    painter += taginfo.name
    painter.space(3)
    painter.bg()
    painter.ol()
    painter.set_flag(painter.underline, False)
    painter.space(2)


def cg_alerts(cg):
    with cg.if_('up vpn0'):
        with cg.temp_fg(Gruv.YELLOW_LIGHT):
            cg.symbol(0xe0a6)
        cg.space(50)

    with cg.if_('match "${execi 20 dunstctl is-paused}" == "true"'):
        with cg.temp_fg(Gruv.YELLOW_LIGHT):
            cg.symbol(0xe0ad)
        cg.space(50)

    with cg.temp_fg(ACCENT_COLOR):
        cg.symbol(0xe01f)
    cg.space(5)
    # cg.var(f'execi 60 cloclify --conky --conky-error-color {Gruv.RED_DARK}')
    # cg.space(5)


def _cg_cpu_perc(cg, num):
    with highlight_critical(cg, f'cpu cpu{num}'):
        cg.var(f'cpu cpu{num}')
        cg.text('% ')


def cg_cpu(cg):
    with cg.temp_fg(ACCENT_COLOR):
        cg.symbol(0xe026)
    cg.space(5)

    cpu_count = multiprocessing.cpu_count()
    if cpu_count <= 4:
        for cpu in range(cpu_count):
            _cg_cpu_perc(cg, cpu + 1)
    else:
        # Too many numbers to digest, show total
        _cg_cpu_perc(cg, 0)


def _cg_space_usage(cg, symbol, command):
    with cg.temp_fg(ACCENT_COLOR):
        cg.symbol(symbol)
    cg.space(5)
    with highlight_critical(cg, command):
        cg.var(command)
        cg.text('% ')


def cg_space(cg):
    _cg_space_usage(cg, 0xe021, 'memperc')
    _cg_space_usage(cg, 0xe1bb, 'fs_used_perc /')


def cg_fan(cg):
    with cg.if_('match ${ibm_fan} != 65535'):
        with cg.temp_fg(ACCENT_COLOR):
            cg.symbol(0xe1c0)
        cg.space(5)
        with highlight_critical(cg, 'ibm_fan', '> 6000'):
            cg.var('ibm_fan')
            cg.text('rpm ')


def cg_temp(cg):
    with cg.temp_fg(ACCENT_COLOR):
        cg.symbol(0xe01b)
    cg.space(5)
    cg.var('acpitemp')
    cg.text('° ')


def _cg_net_icon(cg, iface):
    wifi_icons = [0xe217, 0xe218, 0xe219, 0xe21a]
    wifi_delta = 100 / len(wifi_icons)
    with cg.temp_fg(ACCENT_COLOR):
        if iface == 'wlan':
            with cg.cases():
                for i, icon in enumerate(wifi_icons[:-1]):
                    cg.case('match ${wireless_link_qual_perc wlan} < %d' % ((i+1)*wifi_delta))
                    cg.symbol(icon)

                cg.else_()
                cg.symbol(wifi_icons[-1])  # icon for 100 percent
            cg.space(5)
        elif iface in ['eth', 'dock']:
            cg.symbol(0xe0af)
        elif iface in ['ppp0', 'bnep0']:
            cg.symbol(0xe0f3)
        else:
            assert False


def cg_net(cg):
    for iface in ['eth', 'dock', 'wlan', 'ppp0', 'bnep0']:
        with cg.if_(f'up {iface}'), cg.if_('match "${addr %s}" != "No Address"' % iface):
            _cg_net_icon(cg, iface)

            if iface == 'wlan':
                cg.var('wireless_essid wlan')

            if iface not in ['ppp0', 'bnep0']:
                cg.space(5)
                cg.var(f'addr {iface}')

            cg.space(5)
            with cg.temp_fg(ACCENT_COLOR):
                cg.symbol(0xe13c)
            cg.var(f'downspeedf {iface}')
            cg.text('K ')
            cg.var(f'totaldown {iface}')
            cg.space(5)
            with cg.temp_fg(ACCENT_COLOR):
                cg.symbol(0xe13b)
            cg.var(f'upspeedf {iface}')
            cg.text('K ')
            cg.var(f'totalup {iface}')
            cg.space(5)


def cg_battery(cg):
    # first icon: 0 percent
    # last icon: 100 percent
    bat_icons = [
        0xe242, 0xe243, 0xe244, 0xe245, 0xe246,
        0xe247, 0xe248, 0xe249, 0xe24a, 0xe24b,
    ]
    bat_delta = 100 / len(bat_icons)

    with cg.if_('existing /sys/class/power_supply/BAT0'), cg.if_('match "$battery" != ""'):
        cg.fg(ACCENT_COLOR)

        with cg.if_('match "$battery" != "discharging $battery_percent%"'):
            cg.symbol(0xe0db)

        with cg.cases():
            for i, icon in enumerate(bat_icons[:-1]):
                cg.case('match $battery_percent < %d' % ((i+1)*bat_delta))
                cg.symbol(icon)

            cg.else_()
            cg.symbol(bat_icons[-1])  # icon for 100 percent

        cg.fg(None)
        cg.space(5)

        with highlight_critical(cg, 'battery_percent', '< 10'):
            cg.var('battery_percent')
            cg.text('% ')
            cg.var('battery_time')
            cg.space(5)

    with cg.if_('existing /run/tlp/manual_mode'):
        cg.fg(ACCENT_COLOR)
        cg.symbol(0xe1d8)
        cg.fg(None)
        with cg.cases():
            cg.case('match ${cat /run/tlp/manual_mode} == 0')
            cg.symbol(0xe0db)
            cg.case('match ${cat /run/tlp/manual_mode} == 1')
            cg.space(2)
            cg.symbol(0xe03b)
            cg.else_()
            cg.text("unknown")

        cg.fg(None)
        cg.space(2)


def cg_time(cg):
    with cg.temp_fg(ACCENT_COLOR):
        cg.symbol(0xe015)
    cg.space(5)
    cg.var('time %d. %B, %H:%M')


Geometry = collections.namedtuple('Geometry', ['x', 'y', 'width', 'height'])

grey_frame = Theme(fg = '#dedede', bg = '#454545', padding = (4,4))

def main():
    hc = hlwm.connect()
    monitor = int(sys.argv[1]) if len(sys.argv) >= 2 else 0

    x, y, monitor_w, _monitor_h = hc.monitor_rect(monitor)
    geom = Geometry(x, y, width=monitor_w, height=16)
    hc(['pad', str(monitor), str(geom.height)])

    cg = conky.ConkyGenerator(lemonbar.textpainter())
    cg_alerts(cg)
    cg_cpu(cg)
    cg_space(cg)
    cg_fan(cg)
    cg_temp(cg)
    cg_net(cg)
    cg_battery(cg)
    cg_time(cg)

    conky_config = {
        'update_interval': '1',
        'update_interval_on_battery': '10',
    }

    trayer_config = {
        'tint': Gruv.BG.replace('#', '0x'),
        'iconspacing': '5',
        'padding': '5',
        'monitor': 'primary',
    }

    bar = lemonbar.Lemonbar(geometry=geom, foreground=Gruv.FG, background=Gruv.BG)

    title_theme = core.Theme(fg=Gruv.FG4, padding=(40, 0))

    left_widgets = [
        hlwm.HLWMTags(hc, monitor, tag_renderer=tag_renderer),
        # title_theme(hlwm.HLWMWindowTitle(hc)),
    ]
    center_widgets = W.TabbedLayout(list(enumerate([
        W.ListLayout([ W.RawLabel('%{c}'),
            hlwm.HLWMMonitorFocusLayout(hc, monitor,
                # this widget is shown on the focused monitor:
                grey_frame(hlwm.HLWMWindowTitle(hc, maxlen = 70)),
                # this widget is shown on all unfocused monitors:
                grey_frame(hlwm.HLWMWindowTitle(hc, maxlen = 70)),
            )]),
#        W.ListLayout([ W.RawLabel('%{c}'), conky_widget ]),
    ])), tab_renderer = tab_renderer)
    
    right_widgets = [
        conky.ConkyWidget(text=cg, config=conky_config),
    ]
    if monitor == 0:
        right_widgets.append(trayer.StalonetrayWidget(geom, args=trayer_config, width_factor=1))

    bar.widget = widgets.ListLayout([
        widgets.RawLabel('%{l}'),
        *left_widgets,
        widgets.RawLabel('%{r}'),
        *right_widgets,
    ])
    return bar


bar = main()
