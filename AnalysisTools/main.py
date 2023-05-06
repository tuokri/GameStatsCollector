import argparse
import dataclasses
import datetime
import shlex
from enum import IntEnum
from pathlib import Path
from typing import List
from typing import Optional
from typing import Tuple
from typing import TypeVar

import numpy as np
import orjson
import pandas

test_file = Path(
    r"O:\rs2server\ROGame\Stats\GameStats-VNSK-Compound-20230429.014944.txt")

UDK_TIME_FMT = "%H:%M:%S"
UDK_DATE_FMT = "%Y/%m/%d"

CACHED_DT: datetime.datetime

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
    killer_score: Optional[float] = 0
    # Not tracked in earlier versions.
    killer_match_score: Optional[float] = 0


@dataclasses.dataclass
class LogInEvent(Event):
    id: int
    name: str


@dataclasses.dataclass
class LogOutEvent(Event):
    id: int
    name: str


@dataclasses.dataclass
class DamageEvent(Event):
    damage: int
    injured_id: int
    instigated_by_id: int
    hit_location: np.ndarray
    hit_momentum: np.ndarray
    damage_type: str
    damage_causer: str


@dataclasses.dataclass
class SpawnEvent(Event):
    id: int
    name: str
    location: np.ndarray
    team_index: int
    role: str


@dataclasses.dataclass
class RoundEndEvent(Event):
    winning_team: int


@dataclasses.dataclass
class MatchWonEvent(Event):
    winning_team: int
    win_condition: str
    round_winning_team: int


class WinCondition(IntEnum):
    ROWC_AllObjectiveCaptured = 0
    ROWC_ScoreLimit = 1
    ROWC_TimeLimit = 2
    ROWC_ReinforcementsDepleted = 3
    ROWC_LockDown = 4
    ROWC_OverTime = 5
    ROWC_MostObjectives = 6
    ROWC_BetterTime = 7
    ROWC_MostPoints = 8
    ROWC_SuddenDeath = 9
    ROWC_MatchEndMostRounds = 10
    ROWC_MatchEndScoredPoints = 11
    ROWC_MatchEndNeutralScoredPoints = 12
    ROWC_MatchEndReinforcements = 13
    ROWC_MatchEndObjectivesCaptured = 14
    ROWC_MatchEndTime = 15
    ROWC_MatchEndWonSkirmish = 16


def parse_unique_id(a: str, b: str) -> int:
    ai = int(a)
    bi = int(b)
    return bi << 32 | ai


def handle_login(event: Event, parts: List[str]) -> LogInEvent:
    player_id = parse_unique_id(parts[2], parts[3])
    return LogInEvent(
        **dataclasses.asdict(event),
        id=player_id,
        name=parts[4],
    )


def handle_logout(event: Event, parts: List[str]) -> LogOutEvent:
    player_id = parse_unique_id(parts[2], parts[3])
    return LogOutEvent(
        **dataclasses.asdict(event),
        id=player_id,
        name=parts[4],
    )


def handle_kill(event: Event, parts: List[str]) -> KillEvent:
    killer_id = parse_unique_id(parts[2], parts[3])
    killed_id = parse_unique_id(parts[4], parts[5])
    killer_team_idx = int(parts[6])
    killed_team_idx = int(parts[7])
    hit_loc = np.array([float(x) for x in parts[8].split(",")])
    momentum = np.array([float(x) for x in parts[9].split(",")])
    ldfl = np.array([float(x) for x in parts[13].split(",")])
    len_parts = len(parts)
    killer_score = -1 if len_parts < 15 else float(parts[14])
    killer_match_score = -1 if len_parts < 16 else float(parts[15])

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


def handle_damage(event: Event, parts: List[str]) -> DamageEvent:
    injured_id = parse_unique_id(parts[3], parts[4])
    instigated_by_id = parse_unique_id(parts[5], parts[6])
    hit_loc = np.array([float(x) for x in parts[7].split(",")])
    momentum = np.array([float(x) for x in parts[8].split(",")])
    return DamageEvent(
        **dataclasses.asdict(event),
        damage=int(parts[2]),
        injured_id=injured_id,
        instigated_by_id=instigated_by_id,
        hit_location=hit_loc,
        hit_momentum=momentum,
        damage_type=parts[9],
        damage_causer=parts[10],
    )


def handle_round_end(event: Event, parts: List[str]) -> RoundEndEvent:
    # Earlier versions were missing WorldInfo.RealTimeSeconds.
    # This is a workaround that uses the last line's timestamp.
    if len(parts) < 3:
        event.datetime = CACHED_DT + datetime.timedelta(milliseconds=1)

    return RoundEndEvent(
        **dataclasses.asdict(event),
        winning_team=int(parts[1]),
    )


def handle_match_won(event: Event, parts: List[str]) -> MatchWonEvent:
    # Earlier versions were missing WorldInfo.RealTimeSeconds.
    # This is a workaround that uses the last line's timestamp.
    if len(parts) < 5:
        event.datetime = CACHED_DT + datetime.timedelta(milliseconds=1)

    return MatchWonEvent(
        **dataclasses.asdict(event),
        winning_team=int(parts[1]),
        win_condition=WinCondition(int(parts[2])).name,
        round_winning_team=int(parts[3]),
    )


def handle_spawn(event: Event, parts: List[str]) -> SpawnEvent:
    player_id = parse_unique_id(parts[2], parts[3])
    location = np.array([float(x) for x in parts[5].split(",")])
    return SpawnEvent(
        **dataclasses.asdict(event),
        id=player_id,
        name=parts[4],
        location=location,
        team_index=int(parts[6]),
        role=parts[7],
    )


def handle_game_stats_line(
        line: str,
        start_dt: datetime.datetime,
) -> EventType:
    global CACHED_DT

    parts = shlex.split(line.strip())
    # print(parts)

    e_type = parts[0]
    timestamp = float(parts[1])
    dt = start_dt + datetime.timedelta(seconds=timestamp)
    CACHED_DT = dt
    dt_str = dt.isoformat()

    event: EventType = Event(
        event_type=e_type,
        datetime=dt_str,
    )

    match e_type:
        case "LOGIN":
            event = handle_login(event, parts)
        case "LOGOUT":
            event = handle_logout(event, parts)
        case "DMG" | "DAMAGE":
            event = handle_damage(event, parts)
        case "KILL":
            event = handle_kill(event, parts)
        case "SPAWN":
            event = handle_spawn(event, parts)
        case "ROUNDEND":
            event = handle_round_end(event, parts)
        case "MATCHWON":
            event = handle_match_won(event, parts)

    return event


def handle_header(header: str) -> Tuple[datetime.datetime, Header]:
    parts = header.strip().split(" ")
    # print("header:", parts)
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


def convert_game_stats(path: Path, out: Path) -> dict:
    """Convert raw game stat text files from GameStatsCollector
    to a JSON format. Timestamps are parsed in UTC
    format, regardless of what the actual timezone used by the
    game server running GameStatsCollector was.
    """
    stats = {
        "header": None,
        "events": {
            "LOGIN": [],
            "LOGOUT": [],
            "DMG": [],
            "KILL": [],
            "SPAWN": [],
            "ROUNDEND": [],
            "MATCHWON": [],
        },
    }
    with out.open(mode="wb") as out_file:
        with path.open(encoding="utf-8") as in_file:
            start_dt, header = handle_header(in_file.readline())
            # print(header)
            stats["header"] = header

            for line in in_file:
                event = handle_game_stats_line(line, start_dt=start_dt)
                stats["events"][event.event_type].append(event)

            out_file.write(orjson.dumps(
                stats,
                option=(orjson.OPT_SERIALIZE_DATACLASS
                        | orjson.OPT_INDENT_2
                        | orjson.OPT_SERIALIZE_NUMPY),
            ))

    return stats


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("file", help="input game stats file")
    ap.add_argument("out", help="JSON output file")
    args = ap.parse_args()

    stats = convert_game_stats(
        Path(args.file).absolute(),
        Path(args.out).absolute(),
    )

    kills = pandas.DataFrame(stats["events"]["KILL"])
    print(kills)

    dmgs = pandas.DataFrame(stats["events"]["DMG"])
    print(dmgs)


if __name__ == "__main__":
    main()
