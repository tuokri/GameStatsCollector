class GSOPlayerController extends ROPlayerController;

var private ROUISceneSettings GSO_FakeSettingsScene;
var private ROUISceneSettings GSO_RealSettingsScene;
var private GameUISceneClient GSO_GameSceneClient;

var private GameStatsCollector GSO;

struct GSO_TrackedGFXSettings extends ROUISceneSettings.GFXSettings
{
    var float DisplayGamma;
};

var private GSO_TrackedGFXSettings GSO_CachedGFXSettings;
var private GSO_TrackedGFXSettings GSO_NewGFXSettings;

simulated event PostBeginPlay()
{
    super.PostBeginPlay();

    GSO = GetGSO();

    if (WorldInfo.NetMode == NM_Client)
    {
        CheckGFXSettings(True);
        SetTimer(5.0, True, nameof(CheckGFXSettings));
    }
}

final private simulated function GetGFXSettings()
{
    // `glog("GSO_FakeSettingsScene:" @ GSO_FakeSettingsScene);
    // `glog("GSO_RealSettingsScene:" @ GSO_RealSettingsScene);

    // Use real scene if it's available.
    if (GSO_RealSettingsScene != None)
    {
        GSO_RealSettingsScene.GetGFXSettings();
        CopyGFXSettings(GSO_RealSettingsScene.CurrentGFXSettings, GSO_NewGFXSettings);
        return;
    }

    if (GSO_FakeSettingsScene != None)
    {
        GSO_FakeSettingsScene.GetGFXSettings();
        CopyGFXSettings(GSO_FakeSettingsScene.CurrentGFXSettings, GSO_NewGFXSettings);
    }

    if (GSO_GameSceneClient == None)
    {
        GSO_GameSceneClient = class'UIRoot'.static.GetSceneClient();
    }

    if (GSO_GameSceneClient != None && GSO_RealSettingsScene == None)
    {
        // Try to find directly with scene tag. Only works if the settings menu is currently open.
        GSO_RealSettingsScene = ROUISceneSettings(GSO_GameSceneClient.FindSceneByTag('ROUIScene_Settings'));

        if (GSO_RealSettingsScene == None)
        {
            // Search active scenes. Only works if the settings menu is currently open.
            ForEach GSO_GameSceneClient.AllActiveScenes(class'ROUISceneSettings', GSO_RealSettingsScene)
            {
                break;
            }
        }
    }

    if (GSO_FakeSettingsScene == None && GSO_GameSceneClient != None)
    {
        GSO_FakeSettingsScene = GSO_GameSceneClient.CreateScene(
            class'ROUISceneSettings', 'Fake_ROUIScene_Settings');
        GSO_FakeSettingsScene.GetGFXSettings();
        CopyGFXSettings(GSO_FakeSettingsScene.CurrentGFXSettings, GSO_NewGFXSettings);
    }
}

final private simulated function CopyGFXSettings(
    const out GFXSettings Src,
    out GSO_TrackedGFXSettings Dst
)
{
    Dst.GraphicsQualitySetting = Src.GraphicsQualitySetting;
    Dst.CharacterQualityDetail = Src.CharacterQualityDetail;
    Dst.TextureQualityDetail = Src.TextureQualityDetail;
    Dst.ShadowQualityDetail = Src.ShadowQualityDetail;
    Dst.LightQualityDetail = Src.LightQualityDetail;
    Dst.PostProcessQualityDetail = Src.PostProcessQualityDetail;
    Dst.bFullScreen = Src.bFullScreen;
    Dst.bBorderless = Src.bBorderless;
    Dst.bVSync = Src.bVSync;
    Dst.Brightness = Src.Brightness;
    Dst.UseHardwarePhysics = Src.UseHardwarePhysics;
    Dst.DetailMode = Src.DetailMode;
    Dst.SkeletalMeshLODBias = Src.SkeletalMeshLODBias;
    Dst.bUseSingleCharacterVariant = Src.bUseSingleCharacterVariant;
    Dst.TextureQuality = Src.TextureQuality;
    Dst.TextureStreamingPoolSize = Src.TextureStreamingPoolSize;
    Dst.ShadowQuality = Src.ShadowQuality;
    Dst.ParticleLODBias = Src.ParticleLODBias;
    Dst.AASetting = Src.AASetting;
    Dst.DOFBlurValResolutionFactor = Src.DOFBlurValResolutionFactor;
    Dst.PostProcessingPreset = Src.PostProcessingPreset;
    Dst.bEnableBloom = Src.bEnableBloom;
    Dst.LightQuality = Src.LightQuality;
    Dst.FoliageDrawRadiusMultiplier = Src.FoliageDrawRadiusMultiplier;
    Dst.OcclusionCullingQuality = Src.OcclusionCullingQuality;
    Dst.FXQualityDetail = Src.FXQualityDetail;
    Dst.bAllowBloom = Src.bAllowBloom;
    Dst.bMotionBlurNonGameplay = Src.bMotionBlurNonGameplay;
    Dst.bAllowAmbientOcclusion = Src.bAllowAmbientOcclusion;
    Dst.bSmoothFrameRate = Src.bSmoothFrameRate;
    Dst.ResX = Src.ResX;
    Dst.ResY = Src.ResY;
    Dst.bAllowDepthOfField = Src.bAllowDepthOfField;
    Dst.bInstancedRendering = Src.bInstancedRendering;
    Dst.bTextureStreaming = Src.bTextureStreaming;
    Dst.bTextureStreamInOnly = Src.bTextureStreamInOnly;
    Dst.bAllowFluidSimulation = Src.bAllowFluidSimulation;
}

final private simulated function GameStatsCollector GetGSO()
{
    local Mutator Mut;

    for (Mut = WorldInfo.Game.BaseMutator; Mut != None; Mut = Mut.NextMutator)
    {
        if (GameStatsCollector(Mut) != None)
        {
            return GameStatsCollector(Mut);
        }
    }

    return None;
}

final private reliable server function ServerLogGFXSettings(
    GSO_TrackedGFXSettings GFXSettingsToSend,
    PlayerReplicationInfo PRI
)
{
    if (GSO != None)
    {
        GSO.WriteGFXLog(GFXSettingsToSend, PRI);
    }
    else
    {
        `gwarn("error logging GFX settings");
    }
}

final private simulated function float GetGamma()
{
    return class'Engine'.static.GetEngine().Client.DisplayGamma;
}

final private simulated function bool SettingsChanged()
{
    return (
        GSO_CachedGFXSettings.GraphicsQualitySetting != GSO_NewGFXSettings.GraphicsQualitySetting
        || GSO_CachedGFXSettings.CharacterQualityDetail != GSO_NewGFXSettings.CharacterQualityDetail
        || GSO_CachedGFXSettings.TextureQualityDetail != GSO_NewGFXSettings.TextureQualityDetail
        || GSO_CachedGFXSettings.ShadowQualityDetail != GSO_NewGFXSettings.ShadowQualityDetail
        || GSO_CachedGFXSettings.LightQualityDetail != GSO_NewGFXSettings.LightQualityDetail
        || GSO_CachedGFXSettings.PostProcessQualityDetail != GSO_NewGFXSettings.PostProcessQualityDetail
        || GSO_CachedGFXSettings.bFullScreen != GSO_NewGFXSettings.bFullScreen
        || GSO_CachedGFXSettings.bBorderless != GSO_NewGFXSettings.bBorderless
        || GSO_CachedGFXSettings.bVSync != GSO_NewGFXSettings.bVSync
        || GSO_CachedGFXSettings.Brightness != GSO_NewGFXSettings.Brightness
        || GSO_CachedGFXSettings.UseHardwarePhysics != GSO_NewGFXSettings.UseHardwarePhysics
        || GSO_CachedGFXSettings.DetailMode != GSO_NewGFXSettings.DetailMode
        || GSO_CachedGFXSettings.SkeletalMeshLODBias != GSO_NewGFXSettings.SkeletalMeshLODBias
        || GSO_CachedGFXSettings.bUseSingleCharacterVariant != GSO_NewGFXSettings.bUseSingleCharacterVariant
        || GSO_CachedGFXSettings.TextureQuality != GSO_NewGFXSettings.TextureQuality
        || GSO_CachedGFXSettings.TextureStreamingPoolSize != GSO_NewGFXSettings.TextureStreamingPoolSize
        || GSO_CachedGFXSettings.ShadowQuality != GSO_NewGFXSettings.ShadowQuality
        || GSO_CachedGFXSettings.ParticleLODBias != GSO_NewGFXSettings.ParticleLODBias
        || GSO_CachedGFXSettings.AASetting != GSO_NewGFXSettings.AASetting
        || GSO_CachedGFXSettings.DOFBlurValResolutionFactor != GSO_NewGFXSettings.DOFBlurValResolutionFactor
        || GSO_CachedGFXSettings.PostProcessingPreset != GSO_NewGFXSettings.PostProcessingPreset
        || GSO_CachedGFXSettings.bEnableBloom != GSO_NewGFXSettings.bEnableBloom
        || GSO_CachedGFXSettings.LightQuality != GSO_NewGFXSettings.LightQuality
        || GSO_CachedGFXSettings.FoliageDrawRadiusMultiplier != GSO_NewGFXSettings.FoliageDrawRadiusMultiplier
        || GSO_CachedGFXSettings.OcclusionCullingQuality != GSO_NewGFXSettings.OcclusionCullingQuality
        || GSO_CachedGFXSettings.FXQualityDetail != GSO_NewGFXSettings.FXQualityDetail
        || GSO_CachedGFXSettings.bAllowBloom != GSO_NewGFXSettings.bAllowBloom
        || GSO_CachedGFXSettings.bMotionBlurNonGameplay != GSO_NewGFXSettings.bMotionBlurNonGameplay
        || GSO_CachedGFXSettings.bAllowAmbientOcclusion != GSO_NewGFXSettings.bAllowAmbientOcclusion
        || GSO_CachedGFXSettings.bSmoothFrameRate != GSO_NewGFXSettings.bSmoothFrameRate
        || GSO_CachedGFXSettings.ResX != GSO_NewGFXSettings.ResX
        || GSO_CachedGFXSettings.ResY != GSO_NewGFXSettings.ResY
        || GSO_CachedGFXSettings.bAllowDepthOfField != GSO_NewGFXSettings.bAllowDepthOfField
        || GSO_CachedGFXSettings.bInstancedRendering != GSO_NewGFXSettings.bInstancedRendering
        || GSO_CachedGFXSettings.bTextureStreaming != GSO_NewGFXSettings.bTextureStreaming
        || GSO_CachedGFXSettings.bTextureStreamInOnly != GSO_NewGFXSettings.bTextureStreamInOnly
        || GSO_CachedGFXSettings.bAllowFluidSimulation != GSO_NewGFXSettings.bAllowFluidSimulation
        || GSO_CachedGFXSettings.DisplayGamma != GSO_NewGFXSettings.DisplayGamma
    );
}

final private simulated function CheckGFXSettings(optional bool bForceLog = False)
{
    // WorldInfo.Game.ConsoleCommand("get SystemSettings DirectionalLightmaps");

    GetGFXSettings();
    GSO_NewGFXSettings.DisplayGamma = GetGamma();

    if (bForceLog || SettingsChanged())
    {
        ServerLogGFXSettings(GSO_NewGFXSettings, PlayerReplicationInfo);
    }

    GSO_CachedGFXSettings = GSO_NewGFXSettings;
}

DefaultProperties
{

}
