import json
import sys
from dataclasses import asdict, dataclass
from enum import IntEnum, IntFlag
from itertools import chain
from math import ceil
from typing import Literal, Optional, TextIO

import btn_constants as bc


class BackgroundColour(IntEnum):
    BG_SOLID = bc.BG_SOLID
    BG_TRANSPARENT = bc.BG_TRANSPARENT
    BG_RED = bc.BG_RED
    BG_PINK = bc.BG_PINK
    BG_PURPLE = bc.BG_PURPLE
    BG_DEEP_PURPLE = bc.BG_DEEP_PURPLE
    BG_INDIGO = bc.BG_INDIGO
    BG_BLUE = bc.BG_BLUE
    BG_LIGHT_BLUE = bc.BG_LIGHT_BLUE
    BG_CYAN = bc.BG_CYAN
    BG_TEAL = bc.BG_TEAL
    BG_GREEN = bc.BG_GREEN
    BG_LIGHT_GREEN = bc.BG_LIGHT_GREEN
    BG_LIME = bc.BG_LIME
    BG_YELLOW = bc.BG_YELLOW
    BG_AMBER = bc.BG_AMBER
    BG_ORANGE = bc.BG_ORANGE
    BG_DEEP_ORANGE = bc.BG_DEEP_ORANGE
    BG_BROWN = bc.BG_BROWN
    BG_GREY = bc.BG_GREY
    BG_BLUE_GREY = bc.BG_BLUE_GREY
    BG_WHITE = bc.BG_WHITE
    BG_BLACK = bc.BG_BLACK


class IconColour(IntEnum):
    DEFAULT = 0
    TRANSPARENT = BackgroundColour.BG_TRANSPARENT
    RED = BackgroundColour.BG_RED
    PINK = BackgroundColour.BG_PINK
    PURPLE = BackgroundColour.BG_PURPLE
    DEEP_PURPLE = BackgroundColour.BG_DEEP_PURPLE
    INDIGO = BackgroundColour.BG_INDIGO
    BLUE = BackgroundColour.BG_BLUE
    LIGHT_BLUE = BackgroundColour.BG_LIGHT_BLUE
    CYAN = BackgroundColour.BG_CYAN
    TEAL = BackgroundColour.BG_TEAL
    GREEN = BackgroundColour.BG_GREEN
    LIGHT_GREEN = BackgroundColour.BG_LIGHT_GREEN
    LIME = BackgroundColour.BG_LIME
    YELLOW = BackgroundColour.BG_YELLOW
    AMBER = BackgroundColour.BG_AMBER
    ORANGE = BackgroundColour.BG_ORANGE
    DEEP_ORANGE = BackgroundColour.BG_DEEP_ORANGE
    BROWN = BackgroundColour.BG_BROWN
    GREY = BackgroundColour.BG_GREY
    BLUE_GREY = BackgroundColour.BG_BLUE_GREY
    WHITE = BackgroundColour.BG_WHITE
    BLACK = BackgroundColour.BG_BLACK


class Icon(IntEnum):
    NO_ICON = 0
    POWER = bc.ID_POWER
    MUTE = bc.ID_MUTE
    VOL_DOWN = bc.ID_VOL_DOWN
    VOL_UP = bc.ID_VOL_UP
    MENU = bc.ID_MENU
    GUIDE = bc.ID_GUIDE
    NAV_DOWN = bc.ID_NAV_DOWN
    NAV_UP = bc.ID_NAV_UP
    NAV_LEFT = bc.ID_NAV_LEFT
    NAV_RIGHT = bc.ID_NAV_RIGHT
    BACK = bc.ID_BACK
    SRC = bc.ID_SRC
    INFO = bc.ID_INFO
    PLAY = bc.ID_PLAY
    PAUSE = bc.ID_PAUSE
    RWD = bc.ID_RWD
    FFWD = bc.ID_FFWD
    PREV = bc.ID_PREV
    NEXT = bc.ID_NEXT
    REC = bc.ID_REC
    STOP = bc.ID_STOP
    FAN_DOWN = bc.ID_FAN_DOWN
    FAN_UP = bc.ID_FAN_UP
    TEMP_DOWN = bc.ID_TEMP_DOWN
    TEMP_UP = bc.ID_TEMP_UP
    RED = bc.ID_RED
    HOME = bc.ID_HOME
    FAV = bc.ID_FAV
    GAME = bc.ID_GAME
    HELP = bc.ID_HELP
    LANG = bc.ID_LANG
    MSG = bc.ID_MSG
    SETTING = bc.ID_SETTING


class RemoteType(IntEnum):
    TYPE_UNKNOWN = -1
    TYPE_TV = 0
    TYPE_CABLE = 1
    TYPE_CD = 2
    TYPE_DVD = 3
    TYPE_BLU_RAY = 4
    TYPE_AUDIO = 5
    TYPE_CAMERA = 6
    TYPE_AIR_CON = 7


class RemoteFlags(IntFlag):
    FLAG_LEARNED = 1
    FLAG_GC = 1 << 1


@dataclass
class Button:
    uid: int
    """Unique button id; used e.g. for auto-order"""
    text: str
    """Button label; visible if `ic` is `NO_ICON` and possibly if the button is wide enough"""
    code: str
    """
    Code in PRONTO format. For more info see\\
    Barry V. Gordon, "Learned IR Code Display Format"
    """
    x: float
    """Horizontal position: 48.0, 258.0, 468.0, 678.0"""
    y: float
    """Vertical position: `48.0 + N * 210.0`"""
    id: int = bc.ID_UNKNOWN
    """Purpose of the button"""
    ic: Icon = Icon.NO_ICON
    """Icon"""
    bg: BackgroundColour = BackgroundColour.BG_GREY
    """Background colour"""
    fg: IconColour = IconColour.DEFAULT
    """Foreground (text/icon) colour"""
    w: float = 186.0
    """Button width"""
    h: float = 186.0
    """Button height"""
    r: float = 48.0
    """Radius, 300.0 - circle, 48.0 - default"""
    rtl: float = 48.0
    """Radius fallback"""
    ts: int = 16
    """Text size"""


@dataclass
class Remote:
    @dataclass
    class Details:
        h: int
        w: int = 912
        marginLeft: int = 48
        marginTop: int = 48
        organize: bool = True
        type: int = 0
        flags: RemoteFlags = RemoteFlags(0)

    buttons: list[Button]
    name: str
    details: Details


def time_to_pulses(f: int | float, t: int) -> int:
    return round(f * t / 1_000_000)


def _pronto_hz(f: float | int) -> float:
    return 1_000_000 / (f * 0.241246)


def Hz_to_pronto(f: int) -> int:
    """Converts between frequency in Hz abd number of periods in pronto internal frequency"""
    return round(_pronto_hz(f))


def pronto_to_Hz(n: int) -> float:
    """Converts between number of periods in pronto internal frequency and resulting frequency in Hz"""
    return _pronto_hz(n)


def signal_to_pronto(f: int, data: list[int]) -> str:
    assert f > 0 and f <= 0xFFFF, "pronto frequency must be positive 16-bit integer"
    assert (
        len(data) > 0 and len(data) <= 0xFFFF
    ), "non-zero 16-bit number of pulses expected"
    assert all(
        x >= 0 and x <= 0xFFFF for x in data
    ), "every pronto word must be 16-bit unsigned integer"
    data_str = " ".join(f"{x:0>4x}" for x in data)
    return f"0000 {f:0>4x} {len(data)//2:0>4x} 0000 {data_str}"


def command_to_sirc(pulse_count: int, addr: int, cmd: int) -> list[int]:
    assert addr >= 0 and addr <= 0x1F, "address must be 5 bit long"
    assert cmd >= 0 and cmd <= 0x7F, "command must be 7 bit long"
    full_message = (addr << 7) | cmd
    message_words = chain.from_iterable(
        (
            [2 * pulse_count, pulse_count]
            if (full_message >> i) & 1
            else [pulse_count, pulse_count]
        )
        for i in range(12)
    )
    result = [4 * pulse_count, pulse_count]
    result.extend(message_words)
    return result


def command_to_pronto(f: int, pulse_count: int, addr: int, cmd: int) -> str:
    data = command_to_sirc(pulse_count, addr, cmd)
    return signal_to_pronto(f, data)


def idx_to_px(row: int, column: int) -> tuple[float, float]:
    return float(48 + column * 210), float(48 + row * 210)


def buttons_all_on_off(
    f: int,
    pulse_count: int,
    addr: int,
    start_id: int = 1,
    positions: tuple[tuple[int, int], tuple[int, int]] = ((0, 0), (0, 3)),
) -> tuple[int, Button, Button]:
    CMD_RST = 0b110
    CMD_SET = 0b111
    pronto_off = command_to_pronto(f, pulse_count, addr, CMD_RST << 4)
    pronto_on = command_to_pronto(f, pulse_count, addr, CMD_SET << 4)
    x_off, y_off = idx_to_px(*positions[0])
    x_on, y_on = idx_to_px(*positions[1])
    btn_off = Button(
        start_id,
        "OFF",
        pronto_off,
        x_off,
        y_off,
        ic=Icon.POWER,
        bg=BackgroundColour.BG_RED,
        r=300.0,
        rtl=300.0,
    )
    btn_on = Button(
        start_id + 1,
        "ON",
        pronto_on,
        x_on,
        y_on,
        ic=Icon.POWER,
        bg=BackgroundColour.BG_GREEN,
        r=300.0,
        rtl=300.0,
    )
    return start_id + 2, btn_off, btn_on


def buttons_keyboard(
    f: int,
    pulse_count: int,
    addr: int,
    cmd: int,
    start_id: int,
    positions: list[tuple[int, int]],
    bg: BackgroundColour = BackgroundColour.BG_GREY,
    fg: IconColour = IconColour.WHITE,
) -> tuple[int, list[Button]]:
    assert cmd >= 0 and cmd <= 0b111
    buttons: list[Button] = []
    for i in range(10):
        number = (i + 1) % 10
        pronto = command_to_pronto(f, pulse_count, addr, cmd << 4 | number)
        x, y = idx_to_px(*positions[i])
        buttons.append(Button(start_id, str(number), pronto, x, y, bg=bg, fg=fg))
        start_id += 1
    return start_id, buttons


def buttons_shift(
    f: int,
    pulse_count: int,
    addr: int,
    start_id: int,
    dir: Literal["L", "R"],
    positions: list[tuple[int, int]],
) -> tuple[int, list[Button]]:
    CMD_SHL = 0b010
    CMD_SHR = 0b011
    SHIFT_ROT = 0b1000
    SHIFT_C0 = 0b0000
    SHIFT_C1 = 0b0001
    cmd = CMD_SHL if dir == "L" else CMD_SHR
    button_rot = Button(
        start_id,
        "RO" + dir,
        command_to_pronto(f, pulse_count, addr, cmd << 4 | SHIFT_ROT),
        *idx_to_px(*positions[0]),
    )
    button_sh0 = Button(
        start_id + 1,
        "SH" + dir + "0",
        command_to_pronto(f, pulse_count, addr, cmd << 4 | SHIFT_C0),
        *idx_to_px(*positions[1]),
    )
    button_sh1 = Button(
        start_id + 2,
        "SH" + dir + "1",
        command_to_pronto(f, pulse_count, addr, cmd << 4 | SHIFT_C1),
        *idx_to_px(*positions[2]),
    )
    return start_id + 3, [button_rot, button_sh0, button_sh1]


def generate_buttons(f: int, pulse_count: int, addr: int) -> list[Button]:
    CMD_OFF = 0b100
    CMD_ON = 0b101
    CMD_TGL = 0b001
    keyboard_layout: list[tuple[int, int]] = [
        (1, 1),
        (1, 2),
        (1, 3),
        (2, 1),
        (2, 2),
        (2, 3),
        (3, 1),
        (3, 2),
        (3, 3),
        (4, 2),
    ]
    start_id, button_on, button_off = buttons_all_on_off(f, pulse_count, addr)
    buttons_of_all = [button_on, button_off]
    start_id, buttons_tgl = buttons_keyboard(
        f, pulse_count, addr, CMD_TGL, start_id, keyboard_layout
    )
    keyboard_layout = [(x + 4, y) for x, y in keyboard_layout]
    start_id, buttons_off = buttons_keyboard(
        f, pulse_count, addr, CMD_OFF, start_id, keyboard_layout, fg=IconColour.WHITE, bg=BackgroundColour.BG_RED
    )
    keyboard_layout = [(x + 4, y) for x, y in keyboard_layout]
    start_id, buttons_on = buttons_keyboard(
        f, pulse_count, addr, CMD_ON, start_id, keyboard_layout, fg=IconColour.WHITE, bg=BackgroundColour.BG_GREEN
    )
    start_id, buttons_left = buttons_shift(
        f, pulse_count, addr, start_id, "L", [(1, 0), (2, 0), (3, 0)]
    )
    start_id, buttons_right = buttons_shift(
        f, pulse_count, addr, start_id, "R", [(5, 0), (6, 0), (7, 0)]
    )
    return (
        buttons_of_all
        + buttons_tgl
        + buttons_off
        + buttons_on
        + buttons_left
        + buttons_right
    )


def generate_remote(
    name: str,
    f_Hz: int,
    addr: int,
    pulses: Optional[int],
    time: Optional[int],
    verbose: bool = False,
) -> Remote:
    pronto_freq = Hz_to_pronto(f_Hz)
    real_Hz = pronto_to_Hz(pronto_freq)
    if verbose:
        print(
            f"Converted frequency {f_Hz} Hz to pronto frequency {pronto_freq} = {real_Hz} Hz"
        )
    if time is not None:
        pulses = time_to_pulses(real_Hz, time)
        if verbose:
            print(
                f"Period {time} μs converted to {pulses} pulses = {pulses * 1_000_000/real_Hz} μs"
            )
    assert type(pulses) is int, "Either pulses or time must be defined"

    buttons = generate_buttons(pronto_freq, pulses, addr)
    h = ceil(max(b.y for b in buttons) + 234)
    remote = Remote(buttons, name, Remote.Details(h))
    return remote


def save_remote(
    name: str,
    f_Hz: int,
    addr: int,
    pulses: Optional[int],
    time: Optional[int],
    out: TextIO = sys.stdout,
    verbose: bool = False,
):
    remote = generate_remote(name, f_Hz, addr, pulses, time, verbose)
    json.dump(asdict(remote), out)


if __name__ == "__main__":
    from argparse import ArgumentParser, FileType

    parser = ArgumentParser(
        description="JSON remote file generator for the IR Remote (https://gitlab.com/divested-mobile/irremote, https://f-droid.org/packages/us.spotco.ir_remote) app"
    )
    parser.add_argument("-v", "--verbose", action="store_true")
    parser.add_argument(
        "-r", "--remote", "--name", default="JOS project IR", help="name of the remote"
    )
    parser.add_argument(
        "-a",
        "--address",
        type=int,
        default=0x0C,
        help="5-bit device address, 12 (0b01100) by default",
    )
    parser.add_argument(
        "-f",
        "--frequency",
        type=int,
        default=40000,
        help="carrier frequency in Hz, 40000 by default",
    )
    base_len_group = parser.add_mutually_exclusive_group()
    base_len_group.add_argument(
        "-t",
        "--time",
        "--duration",
        type=int,
        default=600,
        help="base pulse duration in μs, 600 by default (0.6 ms)",
    )
    base_len_group.add_argument(
        "-n",
        "--pulses",
        type=int,
        help="base pulse duration represented as number of pulses at the carrier frequency",
    )
    parser.add_argument(
        "outfile",
        nargs="?",
        type=FileType("w", encoding="utf-8"),
        default=sys.stdout,
        help="output file, printing to STDOUT if not provided",
    )
    args = parser.parse_args()
    save_remote(
        args.remote,
        args.frequency,
        args.address,
        args.pulses,
        args.time,
        args.outfile,
        args.verbose,
    )
