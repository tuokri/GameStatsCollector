import argparse
import dataclasses
import datetime
from pathlib import Path
from typing import List
from typing import Optional
from typing import Tuple
from typing import TypeVar

import numpy as np
import orjson

test_file = Path(
    r"O:\rs2server\ROGame\Stats\GameStats-VNSK-Compound-20230429.014944.txt")

UDK_TIME_FMT = "%H:%M:%S"
UDK_DATE_FMT = "%Y/%m/%d"

EventType = TypeVar("EventType", bound="Event")


@dataclasses.dataclass
class Header:
    world_time_start_seconds: float
    start_datetime: str
    start_timestamp: float
    tag: str


@dataclasses.dataclass
class Event:
    event_type: str
    datetime: str


@dataclasses.dataclass
class KillEvent(Event):
    killer_id: int
    killed_id: int
    killer_team_index: int
    killed_team_index: int
    hit_location: np.ndarray
    hit_momentum: np.ndarray
    damage_type: str
    hit_bone: str
    hit_bone_index: int
    last_damaged_from_location: np.ndarray
    # Not tracked in earlier versions.
    killer_score: Optional[int] = 0
    # Not tracked in earlier versions.
    killer_match_score: Optional[int] = 0


def parse_unique_id(a: str, b: str) -> int:
    ai = int(a)
    bi = int(b)
    return bi << 32 | ai


def handle_login():
    pass


def handle_logout():
    pass


def handle_kill(event: Event, parts: List[str]) -> KillEvent:
    killer_id = parse_unique_id(parts[2], parts[3])
    killed_id = parse_unique_id(parts[4], parts[5])
    killer_team_idx = int(parts[6])
    killed_team_idx = int(parts[7])
    hit_loc = np.array([float(x) for x in parts[8].split(",")])
    momentum = np.array([float(x) for x in parts[9].split(",")])
    ldfl = np.array([float(x) for x in parts[13].split(",")])
    len_parts = len(parts)
    killer_score = -1 if len_parts < 15 else int(parts[14])
    killer_match_score = -1 if len_parts < 16 else int(parts[15])

    return KillEvent(
        **dataclasses.asdict(event),
        killer_id=killer_id,
        killed_id=killed_id,
        killer_team_index=killer_team_idx,
        killed_team_index=killed_team_idx,
        hit_location=hit_loc,
        hit_momentum=momentum,
        damage_type=parts[10],
        hit_bone=parts[11],
        hit_bone_index=int(parts[12]),
        last_damaged_from_location=ldfl,
        killer_score=killer_score,
        killer_match_score=killer_match_score,
    )


def handle_dmg():
    pass


def handle_round_end():
    pass


def handle_game_stats_line(
        line: str,
        start_dt: datetime.datetime,
) -> EventType:
    parts = line.strip().split(" ")
    print(parts)

    e_type = parts[0]
    timestamp = float(parts[1])
    dt = start_dt + datetime.timedelta(seconds=timestamp)
    dt_str = dt.isoformat()

    event: EventType = Event(
        event_type=e_type,
        datetime=dt.isoformat(),
    )

    match e_type:
        case "LOGIN":
            pass
        case "LOGOUT":
            pass
        case "DMG" | "DAMAGE":
            pass
        case "KILL":
            event = handle_kill(event, parts)
        case "SPAWN":
            pass

    return event


def handle_header(header: str) -> Tuple[datetime.datetime, Header]:
    parts = header.strip().split(" ")
    print("header:", parts)
    world_time_start = float(parts[0])
    start_date = datetime.datetime.strptime(parts[1], UDK_DATE_FMT)
    start_time = datetime.datetime.strptime(parts[3], UDK_TIME_FMT).time()
    start_timestamp = float(parts[4])  # Utils.GetSystemTimeStamp().
    tag = parts[5]
    start_dt = datetime.datetime.combine(
        start_date, start_time)

    return start_dt, Header(
        world_time_start_seconds=world_time_start,
        start_datetime=start_dt.isoformat(),
        start_timestamp=start_timestamp,
        tag=tag,
    )


def convert_game_stats(path: Path, out: Path):
    """Convert raw game stat text files from GameStatsCollector
    to a JSON format. Timestamps are parsed in UTC
    format, regardless of what the actual timezone used by the
    game server running GameStatsCollector was.
    """
    stats = {
        "header": None,
        "events": [],
    }
    with out.open(mode="wb") as out_file:
        with path.open(encoding="utf-8") as in_file:
            start_dt, header = handle_header(in_file.readline())
            print(header)
            stats["header"] = header

            for line in in_file:
                event = handle_game_stats_line(line, start_dt=start_dt)
                stats["events"].append(event)

            out_file.write(orjson.dumps(
                stats,
                option=(orjson.OPT_SERIALIZE_DATACLASS
                        | orjson.OPT_INDENT_2
                        | orjson.OPT_SERIALIZE_NUMPY),
            ))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("file", help="input game stats file")
    ap.add_argument("out", help="JSON output file")
    args = ap.parse_args()

    convert_game_stats(
        Path(args.file).absolute(),
        Path(args.out).absolute(),
    )


if __name__ == "__main__":
    main()
