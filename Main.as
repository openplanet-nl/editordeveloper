[Setting name="Disable edge camera movement"]
bool Setting_DisableEdgeCamera = true;

#if !FOREVER
[Setting name="Show Nadeo developer tools"]
#endif
bool Setting_NadeoDeveloperTools = false;

#if MP4 || TMNEXT
[Setting name="Show offzone button"]
#endif
bool Setting_OffzoneButton = true;

PatternPatch@ g_patchEnableOffzone;
PatternPatch@ g_patchDisableScroll;

#if MP4 || TMNEXT
CControlBase@ g_frameLightTools;
#endif

void RenderMenu()
{
#if MP4 || TMNEXT
	if (g_frameLightTools !is null && UI::MenuItem("\\$cf9" + Icons::Sun + "\\$z Show light tools bar", "", g_frameLightTools.IsVisible)) {
		g_frameLightTools.IsVisible = !g_frameLightTools.IsVisible;
	}
#endif
}

CControlBase@ FindControl(CControlContainer@ container, const string &in id)
{
	for (uint i = 0; i < container.Childs.Length; i++) {
		auto child = container.Childs[i];
		if (child.IdName == id) {
			return child;
		}

		auto childContainer = cast<CControlContainer>(child);
		if (childContainer !is null) {
			auto ret = FindControl(childContainer, id);
			if (ret !is null) {
				return ret;
			}
		}
	}
	return null;
}

#if FOREVER
void OnEditorOpened(CTrackManiaEditorFree@ editor)
#else
void OnEditorOpened(CGameCtnEditorFree@ editor)
#endif
{
	auto scene = editor.EditorInterface.InterfaceScene;
	auto root = cast<CControlContainer>(scene.Mobils[0]);

#if !FOREVER
	// Nadeo's developer tools
	if (Setting_NadeoDeveloperTools) {
		auto frameDeveloperTools = cast<CControlContainer>(FindControl(root, "FrameDeveloperTools"));
		if (frameDeveloperTools !is null) {
			frameDeveloperTools.Show();

			for (uint i = 0; i < frameDeveloperTools.Childs.Length; i++) {
				frameDeveloperTools.Childs[i].Show();
			}
		}
	}
#endif

#if MP4 || TMNEXT
	// Offzone
	if (Setting_OffzoneButton) {
		auto frameEditTools = cast<CControlContainer>(FindControl(root, "FrameEditTools"));
		if (frameEditTools !is null) {
			auto buttonOffZone = FindControl(frameEditTools, "ButtonOffZone");
			if (buttonOffZone !is null) {
				buttonOffZone.Show();

				try {
					g_patchOffzone.Apply();
				} catch {
					warn("Unable to find offzone patch!");
				}
			}
		}
	}
#endif

	// Editor scrolling
	if (g_patchDisableScroll !is null && Setting_DisableEdgeCamera) {
		g_patchDisableScroll.Apply();
	}

#if MP4 || TMNEXT
	// Light tools
	@g_frameLightTools = FindControl(root, "FrameLightTools");
#endif
}

void OnEditorClosed()
{
	if (g_patchEnableOffzone !is null && g_patchEnableOffzone.IsApplied()) {
		g_patchEnableOffzone.Revert();
	}
	if (g_patchDisableScroll !is null && g_patchDisableScroll.IsApplied()) {
		g_patchDisableScroll.Revert();
	}

#if MP4 || TMNEXT
	@g_frameLightTools = null;
#endif
}

void OnSettingsChanged()
{
	if (g_patchDisableScroll !is null) {
		if (Setting_DisableEdgeCamera && !g_patchDisableScroll.IsApplied()) {
			g_patchDisableScroll.Apply();
		} else if (!Setting_DisableEdgeCamera && g_patchDisableScroll.IsApplied()) {
			g_patchDisableScroll.Revert();
		}
	}
}

void OnDestroyed()
{
	OnEditorClosed();
}

void Main()
{
#if MP4 || TMNEXT
	@g_patchEnableOffzone = PatternPatch(
#if TMNEXT && !LOGS
		"0F 84 ?? ?? ?? ?? 4C 8D 45 ?? BA 13",
		"90 90 90 90 90 90"
#elif TMNEXT && LOGS
		"0F 84 ?? ?? ?? ?? 4C 8D 45 F0 BA ?? ?? ?? ?? 48 8B CF E8 ?? ?? ?? ?? E9 ?? ?? ?? ?? 45 85 FF 0F 84 ?? ?? ?? ?? 83 BF ?? ?? ?? ?? ?? 0F 84 ?? ?? ?? ?? 39",
		"90 90 90 90 90 90"
#elif MP41
		"F6 86 ?? ?? ?? ?? ?? 0F 84 ?? ?? ?? ?? 4C 8D 44 24 70 BA",
		"90 90 90 90 90 90 90 90 90 90 90 90 90"
#else
		"0F 84 ?? ?? ?? ?? 8D ?? ?? ?? ?? ?? ?? 50 6A 12",
		"90 90 90 90 90 90"
#endif
	);
#endif

#if FOREVER
	@g_patchDisableScroll = PatternPatch(
		"83 EC 3C D9 EE",
		"C2 0C 00"
	);
#endif

	bool hadEditor = false;
	while (true) {
#if FOREVER
		auto editor = cast<CTrackManiaEditorFree>(cast<CTrackMania>(GetApp()).Editor);
#else
		auto editor = cast<CGameCtnEditorFree>(cast<CTrackMania>(GetApp()).Editor);
#endif
		bool hasEditorNow = editor !is null;
		if (!hadEditor && hasEditorNow) {
			OnEditorOpened(editor);
		} else if (hadEditor && !hasEditorNow) {
			OnEditorClosed();
		}

#if MP4 || TMNEXT
		if (editor !is null && editor.OrbitalCameraControl !is null) {
			if (Setting_DisableEdgeCamera) {
				editor.OrbitalCameraControl.m_ParamScrollAreaStart = 1.1f;
				editor.OrbitalCameraControl.m_ParamScrollAreaMax = 1.1f;
			} else {
				editor.OrbitalCameraControl.m_ParamScrollAreaStart = 0.7f;
				editor.OrbitalCameraControl.m_ParamScrollAreaMax = 0.98f;
			}
		}
#elif TURBO
		if (editor !is null && editor.OrbitalCameraControl !is null) {
			if (Setting_DisableEdgeCamera) {
				editor.OrbitalCameraControl.ParamScrollAreaStart = 1.1f;
				editor.OrbitalCameraControl.ParamScrollAreaMax = 1.1f;
			} else {
				editor.OrbitalCameraControl.ParamScrollAreaStart = 0.7f;
				editor.OrbitalCameraControl.ParamScrollAreaMax = 0.98f;
			}
		}
#endif
		hadEditor = hasEditorNow;
		yield();
	}
}
