class GameStatsCollector extends ROMutator
    config(Mutator_GameStatsCollector)
    dependson(GSOPlayerController);

`define MUTATOR(dummy)
`include(Engine\Classes\GameStats.uci);
`undefine(MUTATOR)

var private GSCUtils Utils;

var private FileWriter GFXLogWriter;

var private FileWriter Writer;
var private array<string> WriteQueue;

final function WriteGFXLog(
    const out GSOPlayerController.GSO_TrackedGFXSettings TrackedGFXSettings,
    PlayerReplicationInfo PRI
)
{
    if (WorldInfo.NetMode == NM_DedicatedServer)
    {
        if (GFXLogWriter != None)
        {
            GFXLogWriter.Logf(
                TimeStamp()
                @ "'" $ PRI.PlayerName $ "'"
                @ class'OnlineSubsystem'.static.UniqueNetIdToString(PRI.UniqueID)
                @ "GraphicsQualitySetting=" $ TrackedGFXSettings.GraphicsQualitySetting
                @ "CharacterQualityDetail=" $ TrackedGFXSettings.CharacterQualityDetail
                @ "TextureQualityDetail=" $ TrackedGFXSettings.TextureQualityDetail
                @ "ShadowQualityDetail=" $ TrackedGFXSettings.ShadowQualityDetail
                @ "LightQualityDetail=" $ TrackedGFXSettings.LightQualityDetail
                @ "PostProcessQualityDetail=" $ TrackedGFXSettings.PostProcessQualityDetail
                @ "bFullScreen=" $ TrackedGFXSettings.bFullScreen
                @ "bBorderless=" $ TrackedGFXSettings.bBorderless
                @ "bVSync=" $ TrackedGFXSettings.bVSync
                @ "Brightness=" $ TrackedGFXSettings.Brightness
                @ "UseHardwarePhysics=" $ TrackedGFXSettings.UseHardwarePhysics
                @ "DetailMode=" $ TrackedGFXSettings.DetailMode
                @ "SkeletalMeshLODBias=" $ TrackedGFXSettings.SkeletalMeshLODBias
                @ "bUseSingleCharacterVariant=" $ TrackedGFXSettings.bUseSingleCharacterVariant
                @ "TextureQuality.UI_LODBias=" $ TrackedGFXSettings.TextureQuality.UI_LODBias
                @ "TextureQuality.UI_MinLODSize=" $ TrackedGFXSettings.TextureQuality.UI_MinLODSize
                @ "TextureQuality.UI_MaxLODSize=" $ TrackedGFXSettings.TextureQuality.UI_MaxLODSize
                @ "TextureQuality.LightMap_LODBias=" $ TrackedGFXSettings.TextureQuality.LightMap_LODBias
                @ "TextureQuality.LightMap_MinLODSize=" $ TrackedGFXSettings.TextureQuality.LightMap_MinLODSize
                @ "TextureQuality.LightMap_MaxLODSize=" $ TrackedGFXSettings.TextureQuality.LightMap_MaxLODSize
                @ "TextureQuality.ShadowMap_LODBias=" $ TrackedGFXSettings.TextureQuality.ShadowMap_LODBias
                @ "TextureQuality.ShadowMap_MinLODSize=" $ TrackedGFXSettings.TextureQuality.ShadowMap_MinLODSize
                @ "TextureQuality.ShadowMap_MaxLODSize=" $ TrackedGFXSettings.TextureQuality.ShadowMap_MaxLODSize
                @ "TextureQuality.Character_LODBias=" $ TrackedGFXSettings.TextureQuality.Character_LODBias
                @ "TextureQuality.Character_MinLODSize=" $ TrackedGFXSettings.TextureQuality.Character_MinLODSize
                @ "TextureQuality.Character_MaxLODSize=" $ TrackedGFXSettings.TextureQuality.Character_MaxLODSize
                @ "TextureQuality.World_LODBias=" $ TrackedGFXSettings.TextureQuality.World_LODBias
                @ "TextureQuality.World_MinLODSize=" $ TrackedGFXSettings.TextureQuality.World_MinLODSize
                @ "TextureQuality.World_MaxLODSize=" $ TrackedGFXSettings.TextureQuality.World_MaxLODSize
                @ "TextureQuality.Terrain_LODBias=" $ TrackedGFXSettings.TextureQuality.Terrain_LODBias
                @ "TextureQuality.Terrain_MinLODSize=" $ TrackedGFXSettings.TextureQuality.Terrain_MinLODSize
                @ "TextureQuality.Terrain_MaxLODSize=" $ TrackedGFXSettings.TextureQuality.Terrain_MaxLODSize
                @ "TextureQuality.TerrainSpecular_LODBias=" $ TrackedGFXSettings.TextureQuality.TerrainSpecular_LODBias
                @ "TextureQuality.TerrainSpecular_MinLODSize=" $ TrackedGFXSettings.TextureQuality.TerrainSpecular_MinLODSize
                @ "TextureQuality.TerrainSpecular_MaxLODSize=" $ TrackedGFXSettings.TextureQuality.TerrainSpecular_MaxLODSize
                @ "TextureQuality.TerrainNormalMap_LODBias=" $ TrackedGFXSettings.TextureQuality.TerrainNormalMap_LODBias
                @ "TextureQuality.TerrainNormalMap_MinLODSize=" $ TrackedGFXSettings.TextureQuality.TerrainNormalMap_MinLODSize
                @ "TextureQuality.TerrainNormalMap_MaxLODSize=" $ TrackedGFXSettings.TextureQuality.TerrainNormalMap_MaxLODSize
                @ "TextureQuality.Foliage_LODBias=" $ TrackedGFXSettings.TextureQuality.Foliage_LODBias
                @ "TextureQuality.Foliage_MinLODSize=" $ TrackedGFXSettings.TextureQuality.Foliage_MinLODSize
                @ "TextureQuality.Foliage_MaxLODSize=" $ TrackedGFXSettings.TextureQuality.Foliage_MaxLODSize
                @ "TextureQuality.FoliageSpecular_LODBias=" $ TrackedGFXSettings.TextureQuality.FoliageSpecular_LODBias
                @ "TextureQuality.FoliageSpecular_MinLODSize=" $ TrackedGFXSettings.TextureQuality.FoliageSpecular_MinLODSize
                @ "TextureQuality.FoliageSpecular_MaxLODSize=" $ TrackedGFXSettings.TextureQuality.FoliageSpecular_MaxLODSize
                @ "TextureQuality.FoliageNormalMap_LODBias=" $ TrackedGFXSettings.TextureQuality.FoliageNormalMap_LODBias
                @ "TextureQuality.FoliageNormalMap_MinLODSize=" $ TrackedGFXSettings.TextureQuality.FoliageNormalMap_MinLODSize
                @ "TextureQuality.FoliageNormalMap_MaxLODSize=" $ TrackedGFXSettings.TextureQuality.FoliageNormalMap_MaxLODSize
                @ "TextureQuality.T3PWeapon_LODBias=" $ TrackedGFXSettings.TextureQuality.T3PWeapon_LODBias
                @ "TextureQuality.T3PWeapon_MinLODSize=" $ TrackedGFXSettings.TextureQuality.T3PWeapon_MinLODSize
                @ "TextureQuality.T3PWeapon_MaxLODSize=" $ TrackedGFXSettings.TextureQuality.T3PWeapon_MaxLODSize
                @ "TextureQuality.T3PWeaponSpecular_LODBias=" $ TrackedGFXSettings.TextureQuality.T3PWeaponSpecular_LODBias
                @ "TextureQuality.T3PWeaponSpecular_MinLODSize=" $ TrackedGFXSettings.TextureQuality.T3PWeaponSpecular_MinLODSize
                @ "TextureQuality.T3PWeaponSpecular_MaxLODSize=" $ TrackedGFXSettings.TextureQuality.T3PWeaponSpecular_MaxLODSize
                @ "TextureQuality.T3PWeaponNormalMap_LODBias=" $ TrackedGFXSettings.TextureQuality.T3PWeaponNormalMap_LODBias
                @ "TextureQuality.T3PWeaponNormalMap_MinLODSize=" $ TrackedGFXSettings.TextureQuality.T3PWeaponNormalMap_MinLODSize
                @ "TextureQuality.T3PWeaponNormalMap_MaxLODSize=" $ TrackedGFXSettings.TextureQuality.T3PWeaponNormalMap_MaxLODSize
                @ "TextureQuality.Vehicle_LODBias=" $ TrackedGFXSettings.TextureQuality.Vehicle_LODBias
                @ "TextureQuality.Vehicle_MinLODSize=" $ TrackedGFXSettings.TextureQuality.Vehicle_MinLODSize
                @ "TextureQuality.Vehicle_MaxLODSize=" $ TrackedGFXSettings.TextureQuality.Vehicle_MaxLODSize
                @ "TextureQuality.VehicleSpecular_LODBias=" $ TrackedGFXSettings.TextureQuality.VehicleSpecular_LODBias
                @ "TextureQuality.VehicleSpecular_MinLODSize=" $ TrackedGFXSettings.TextureQuality.VehicleSpecular_MinLODSize
                @ "TextureQuality.VehicleSpecular_MaxLODSize=" $ TrackedGFXSettings.TextureQuality.VehicleSpecular_MaxLODSize
                @ "TextureQuality.VehicleNormalMap_LODBias=" $ TrackedGFXSettings.TextureQuality.VehicleNormalMap_LODBias
                @ "TextureQuality.VehicleNormalMap_MinLODSize=" $ TrackedGFXSettings.TextureQuality.VehicleNormalMap_MinLODSize
                @ "TextureQuality.VehicleNormalMap_MaxLODSize=" $ TrackedGFXSettings.TextureQuality.VehicleNormalMap_MaxLODSize
                @ "TextureQuality.Others_LODBias=" $ TrackedGFXSettings.TextureQuality.Others_LODBias
                @ "TextureQuality.Others_MinLODSize=" $ TrackedGFXSettings.TextureQuality.Others_MinLODSize
                @ "TextureQuality.Others_MaxLODSize=" $ TrackedGFXSettings.TextureQuality.Others_MaxLODSize
                @ "TextureQuality.MinMagFilter=" $ TrackedGFXSettings.TextureQuality.MinMagFilter
                @ "TextureQuality.MipFilter=" $ TrackedGFXSettings.TextureQuality.MipFilter
                @ "TextureQuality.MaxAnisotropy=" $ TrackedGFXSettings.TextureQuality.MaxAnisotropy
                @ "TextureStreamingPoolSize=" $ TrackedGFXSettings.TextureStreamingPoolSize
                @ "ShadowQuality.bAllowWholeSceneDominantShadows=" $ TrackedGFXSettings.ShadowQuality.bAllowWholeSceneDominantShadows
                @ "ShadowQuality.bAllowDynamicShadows=" $ TrackedGFXSettings.ShadowQuality.bAllowDynamicShadows
                @ "ShadowQuality.MaxWholeSceneDominantShadowResolution=" $ TrackedGFXSettings.ShadowQuality.MaxWholeSceneDominantShadowResolution
                @ "ShadowQuality.WholeSceneDynamicShadowRadius=" $ TrackedGFXSettings.ShadowQuality.WholeSceneDynamicShadowRadius
                @ "ShadowQuality.NumWholeSceneDynamicShadowCascades=" $ TrackedGFXSettings.ShadowQuality.NumWholeSceneDynamicShadowCascades
                @ "ShadowQuality.CascadeDistributionExponent=" $ TrackedGFXSettings.ShadowQuality.CascadeDistributionExponent
                @ "ShadowQuality.ShadowFadeResolution=" $ TrackedGFXSettings.ShadowQuality.ShadowFadeResolution
                @ "ShadowQuality.MaxShadowResolution=" $ TrackedGFXSettings.ShadowQuality.MaxShadowResolution
                @ "ShadowQuality.ShadowTexelsPerPixel=" $ TrackedGFXSettings.ShadowQuality.ShadowTexelsPerPixel
                @ "ShadowQuality.bAllowBetterModulatedShadows=" $ TrackedGFXSettings.ShadowQuality.bAllowBetterModulatedShadows
                @ "ShadowQuality.bEnableForegroundShadowsOnWorld=" $ TrackedGFXSettings.ShadowQuality.bEnableForegroundShadowsOnWorld
                @ "ShadowQuality.bEnableForegroundSelfShadowing=" $ TrackedGFXSettings.ShadowQuality.bEnableForegroundSelfShadowing
                @ "ShadowQuality.bAllowShadowGroups=" $ TrackedGFXSettings.ShadowQuality.bAllowShadowGroups
                @ "ShadowQuality.MinShadowGroupRadius=" $ TrackedGFXSettings.ShadowQuality.MinShadowGroupRadius
                @ "ShadowQuality.MaxShadowGroupRadius=" $ TrackedGFXSettings.ShadowQuality.MaxShadowGroupRadius
                @ "ShadowQuality.ShadowGroupRadiusRampUpFactor=" $ TrackedGFXSettings.ShadowQuality.ShadowGroupRadiusRampUpFactor
                @ "ShadowQuality.ShadowGroupRampCutoff=" $ TrackedGFXSettings.ShadowQuality.ShadowGroupRampCutoff
                @ "ParticleLODBias=" $ TrackedGFXSettings.ParticleLODBias
                @ "AASetting=" $ TrackedGFXSettings.AASetting
                @ "DOFBlurValResolutionFactor=" $ TrackedGFXSettings.DOFBlurValResolutionFactor
                @ "PostProcessingPreset=" $ TrackedGFXSettings.PostProcessingPreset
                @ "bEnableBloom=" $ TrackedGFXSettings.bEnableBloom
                @ "LightQuality.bAllowDistortion=" $ TrackedGFXSettings.LightQuality.bAllowDistortion
                @ "LightQuality.bAllowFilteredDistortion=" $ TrackedGFXSettings.LightQuality.bAllowFilteredDistortion
                @ "LightQuality.bAllowLightShafts=" $ TrackedGFXSettings.LightQuality.bAllowLightShafts
                @ "LightQuality.bAllowDynamicLights=" $ TrackedGFXSettings.LightQuality.bAllowDynamicLights
                @ "LightQuality.bRenderLightFunctions=" $ TrackedGFXSettings.LightQuality.bRenderLightFunctions
                @ "FoliageDrawRadiusMultiplier=" $ TrackedGFXSettings.FoliageDrawRadiusMultiplier
                @ "OcclusionCullingQuality=" $ TrackedGFXSettings.OcclusionCullingQuality
                @ "FXQualityDetail=" $ TrackedGFXSettings.FXQualityDetail
                @ "bAllowBloom=" $ TrackedGFXSettings.bAllowBloom
                @ "bMotionBlurNonGameplay=" $ TrackedGFXSettings.bMotionBlurNonGameplay
                @ "bAllowAmbientOcclusion=" $ TrackedGFXSettings.bAllowAmbientOcclusion
                @ "bSmoothFrameRate=" $ TrackedGFXSettings.bSmoothFrameRate
                @ "ResX=" $ TrackedGFXSettings.ResX
                @ "ResY=" $ TrackedGFXSettings.ResY
                @ "bAllowDepthOfField=" $ TrackedGFXSettings.bAllowDepthOfField
                @ "bInstancedRendering=" $ TrackedGFXSettings.bInstancedRendering
                @ "bTextureStreaming=" $ TrackedGFXSettings.bTextureStreaming
                @ "bTextureStreamInOnly=" $ TrackedGFXSettings.bTextureStreamInOnly
                @ "bAllowFluidSimulation=" $ TrackedGFXSettings.bAllowFluidSimulation
                @ "DisplayGamma=" $ TrackedGFXSettings.DisplayGamma
            );
        }
    }
}

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

    WorldInfo.Game.PlayerControllerClass = class'GSOPlayerController';

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
            `gerror("ERROR OPENING STATS FILE WRITER!");
        }

        GFXLogWriter = Spawn(class'FileWriter');
        if (Writer != None)
        {
            FileName = "GFXSettingsLog-" $ WorldInfo.GetMapName(True);
            GFXLogWriter.OpenFile(FileName, FWFT_Log, ".log", True, True);
            GFXLogWriter.Logf(
                WorldInfo.RealTimeSeconds
                @ TimeStamp()
                @ Utils.GetSystemTimeStamp()
                @ "GameStatsCollector_GFX"
            );
        }
        else
        {
            `gerror("ERROR OPENING GFX LOG FILE WRITER!");
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
        // // TODO: potentially expensive check. Is there a better way?
        // if (ClassIsChildOf(DamageType, class'RODmgType_MeleeBlunt')
        //     || ClassIsChildOf(DamageType, class'RODmgType_MeleePierce')
        //     || ClassIsChildOf(DamageType, class'RODmgType_MeleeSlash')
        // )
        // {
        //     `RecordDamage(WEAPON_DAMAGE_MELEE, InstigatedBy, DamageType,
        //         Injured.Controller, Damage);
        // }
        // else
        // {
            `RecordDamage(WEAPON_DAMAGE, InstigatedBy, DamageType,
                Injured.Controller, Damage);
        // }

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

DefaultProperties
{
    TickGroup=TG_DuringAsyncWork
}

// GFX settings tracking, do in ROPC, cache on clientside, send once on login,
// send again if changed.
