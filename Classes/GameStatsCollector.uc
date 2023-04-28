class GameStatsCollector extends ROMutator
    config(Mutator_GameStatsCollector);

`define MUTATOR(dummy)
`include(Engine\Classes\GameStats.uci);
`undefine(MUTATOR)

var private GSCUtils Utils;

var private FileWriter Writer;
var private array<string> WriteQueue;

// ID.A ID.B 'Name' Location Team
final private function LogSpawn(ROPawn ROP, ROPlayerController ROPC,
    ROPlayerReplicationInfo ROPRI)
{
    if (ROP != None && ROPC != None)
    {
        WriteQueue.AddItem(
            "SPAWN"
            @ WorldInfo.RealTimeSeconds
            @ ROPRI.UniqueId.Uid.A
            @ ROPRI.UniqueId.Uid.B
            @ "'" $ ROPRI.PlayerName $ "'"
            @ ROP.Location
            @ ROPRI.Team.TeamIndex
        );
    }
}

// KillerID.A KillerID.B KilledID.A KilledID.B KillerTeam KilledTeam
// HitLocation Momentum DamageType HitBone HitBoneIndex LastDamagedFromLocation
final private function LogKill(ROPlayerController Killer, ROPlayerController Killed,
    ROPawn KilledPawn)
{
    WriteQueue.AddItem(
        "KILL"
        @ WorldInfo.RealTimeSeconds
        @ Killer.PlayerReplicationInfo.UniqueId.Uid.A
        @ Killer.PlayerReplicationInfo.UniqueId.Uid.B
        @ Killed.PlayerReplicationInfo.UniqueId.Uid.A
        @ Killed.PlayerReplicationInfo.UniqueId.Uid.B
        @ Killer.PlayerReplicationInfo.Team.TeamIndex
        @ Killed.PlayerReplicationInfo.Team.TeamIndex
        @ KilledPawn.LastTakeHitInfo.HitLocation
        @ KilledPawn.LastTakeHitInfo.Momentum
        @ KilledPawn.LastTakeHitInfo.DamageType
        @ KilledPawn.LastTakeHitInfo.HitBone
        @ KilledPawn.LastTakeHitInfo.HitBoneIndex
        @ KilledPawn.LastDamagedFromLocation
    );
}

// Damage InjuredID.A InjuredID.B InstigatedByID.A InstigatedByID.A
// HitLocation Momentum DamageType DamageCauser
final private function LogDamage(int Damage, Pawn Injured,
    Controller InstigatedBy, vector HitLocation, vector Momentum,
    class<DamageType> DamageType, Actor DamageCauser)
{
    WriteQueue.AddItem(
        "DAMAGE"
        @ WorldInfo.RealTimeSeconds
        @ Damage
        @ Injured.PlayerReplicationInfo.UniqueId.Uid.A
        @ Injured.PlayerReplicationInfo.UniqueId.Uid.B
        @ InstigatedBy.PlayerReplicationInfo.UniqueId.Uid.A
        @ InstigatedBy.PlayerReplicationInfo.UniqueId.Uid.B
        @ HitLocation
        @ Momentum
        @ DamageType
        @ DamageCauser
    );
}

final private function LogLogout(ROPlayerReplicationInfo ROPRI)
{
    WriteQueue.AddItem(
        "LOGOUT"
        @ WorldInfo.RealTimeSeconds
        @ ROPRI.UniqueId.Uid.A
        @ ROPRI.UniqueId.Uid.B
        @ "'" $ ROPRI.PlayerName $ "'"
    );
}

final private function LogLogin(ROPlayerReplicationInfo ROPRI)
{
    WriteQueue.AddItem(
        "LOGIN"
        @ WorldInfo.RealTimeSeconds
        @ ROPRI.UniqueId.Uid.A
        @ ROPRI.UniqueId.Uid.B
        @ "'" $ ROPRI.PlayerName $ "'"
    );
}

final private function LogRoundEnd(byte WinningTeamIndex)
{
    WriteQueue.AddItem("ROUNDEND" @ WinningTeamIndex);
}

final private function LogMatchWon(byte WinningTeam, byte WinCondition,
    byte RoundWinningTeam)
{
    WriteQueue.AddItem("MATCHWON" @ WinningTeam @ WinCondition @ RoundWinningTeam);
}

final private function ProcessWriteQueue()
{
    if (Writer != None && WriteQueue.Length > 0)
    {
        Writer.Logf(WriteQueue[0]);
        WriteQueue.Remove(0, 1);
    }
}

simulated event PreBeginPlay()
{
    Utils = new (self) class'GSCUtils';

    WorldInfo.Game.GameplayEventsWriterClassName = "Engine.GameplayEventsWriter";
    WorldInfo.Game.bLogGameplayEvents = True;
    WorldInfo.Game.SaveConfig();

    // Enable balance stats logging.
    class'System'.default.Suppress.RemoveItem('DevBalanceStats');
    class'System'.static.StaticSaveConfig();

    // Check chat log status.
    if (!class'WebAdmin'.default.bChatLog)
    {
        class'WebAdmin'.default.bChatLog = True;
        class'WebAdmin'.static.StaticSaveConfig();
        class'ChatLog'.default.bUnique = True;
        class'ChatLog'.default.bIncludeTimeStamp = True;
        class'ChatLog'.static.StaticSaveConfig();
    }

    super.PreBeginPlay();
}

simulated event PostBeginPlay()
{
    local string FileName;

    super.PostBeginPlay();

    if (Role == ROLE_Authority)
    {
        Writer = Spawn(class'FileWriter');
        if (Writer != None)
        {
            FileName = "GameStats-" $ WorldInfo.GetMapName(True);
            Writer.OpenFile(FileName, FWFT_Stats, ".txt", True, True);
            Writer.Logf(
                WorldInfo.RealTimeSeconds
                @ TimeStamp()
                @ Utils.GetSystemTimeStamp()
                @ "GameStatsCollector"
            );
        }
        else
        {
            `gerror("ERROR OPENING FILE WRITER!");
        }
    }

    SetTimer(0.1, True, nameof(ProcessWriteQueue));
}

function bool MutatorIsAllowed()
{
    return True;
}

// function ScoreObjective(PlayerReplicationInfo Scorer, int Score)
// {
//     super.ScoreObjective(Scorer, Score);
// }

function ModifyPlayer(Pawn Other)
{
    local ROPlayerReplicationInfo ROPRI;

    // We can indirectly log spawning here since this function
    // is called after successfully spawning the pawn.
    if (Other != None
        && Other.Controller != None
        && Other.Controller.PlayerReplicationInfo != None
    )
    {
        ROPRI = ROPlayerReplicationInfo(Other.PlayerReplicationInfo);
        if (ROPRI != None
            && ROPRI.Team != None
            && ROPRI.Team.TeamIndex != INDEX_NONE
        )
        {
            `RecordPlayerSpawn(Other.Controller, Other.Class, ROPRI.Team.TeamIndex);
            LogSpawn(ROPawn(Other), ROPlayerController(Other.Controller), ROPRI);
        }
    }

    super.ModifyPlayer(Other);
}

function ScoreKill(Controller Killer, Controller Killed)
{
    local class<DamageType> LastHitDamageType;
    local ROPawn ROP;

    LastHitDamageType = class'RODamageType';
    if (Killer != None && Killed != None)
    {
        if (Killed.Pawn != None)
        {
            ROP = ROPawn(Killed.Pawn);
            if (ROP != None)
            {
                LastHitDamageType = ROP.LastTakeHitInfo.DamageType;
            }
        }
        `RecordKillEvent(NORMAL, Killer, LastHitDamageType, Killed);
        LogKill(ROPlayerController(Killer), ROPlayerController(Killed), ROP);
    }

    super.ScoreKill(Killer, Killed);
}

function NetDamage(int OriginalDamage, out int Damage, Pawn Injured,
    Controller InstigatedBy, vector HitLocation, out vector Momentum,
    class<DamageType> DamageType, Actor DamageCauser)
{
    if (InstigatedBy != None && Injured != None && Injured.Controller != None)
    {
        // TODO: potentially expensive check. Is there a better way?
        if (ClassIsChildOf(DamageType, class'RODmgType_MeleeBlunt')
            || ClassIsChildOf(DamageType, class'RODmgType_MeleePierce')
            || ClassIsChildOf(DamageType, class'RODmgType_MeleeSlash')
        )
        {
            `RecordDamage(WEAPON_DAMAGE_MELEE, InstigatedBy, DamageType,
                Injured.Controller, Damage);
        }
        else
        {
            `RecordDamage(WEAPON_DAMAGE, InstigatedBy, DamageType,
                Injured.Controller, Damage);
        }

        LogDamage(Damage, Injured, InstigatedBy, HitLocation,
            Momentum, DamageType, DamageCauser);
    }

    super.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy,
        HitLocation, Momentum, DamageType, DamageCauser);
}

function NotifyLogout(Controller Exiting)
{
    local ROPlayerReplicationInfo ROPRI;

    ROPRI = ROPlayerReplicationInfo(Exiting.PlayerReplicationInfo);
    if (ROPRI != None)
    {
        `RecordLoginChange(LOGOUT, Exiting, ROPRI.PlayerName, ROPRI.UniqueId, False);
        LogLogout(ROPRI);
    }

    super.NotifyLogout(Exiting);
}

function NotifyLogin(Controller NewPlayer)
{
    local ROPlayerReplicationInfo ROPRI;

    ROPRI = ROPlayerReplicationInfo(NewPlayer.PlayerReplicationInfo);
    if (ROPRI != None)
    {
        `RecordLoginChange(LOGIN, NewPlayer, ROPRI.PlayerName, ROPRI.UniqueId, False);
        LogLogin(ROPRI);
    }

    super.NotifyLogin(NewPlayer);
}

function NotifyRoundEnd(byte WinningTeamIndex)
{
    LogRoundEnd(WinningTeamIndex);

    super.NotifyRoundEnd(WinningTeamIndex);
}

function ModifyMatchWon(out byte out_WinningTeam, out byte out_WinCondition,
    optional out byte out_RoundWinningTeam)
{
    LogMatchWon(out_WinningTeam, out_WinCondition, out_RoundWinningTeam);

    super.ModifyMatchWon(out_WinningTeam, out_WinCondition, out_RoundWinningTeam);
}

final private simulated function float GetGamma()
{
    return class'Engine'.static.GetEngine().Client.DisplayGamma;
}

final private reliable client function ClientStartTracking()
{

}

DefaultProperties
{
    TickGroup=TG_DuringAsyncWork
}
