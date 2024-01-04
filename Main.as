[Setting name="Disable edge camera movement"]
bool Setting_DisableEdgeCamera = true;

[Setting name="Show Nadeo developer tools"]
bool Setting_NadeoDeveloperTools = false;

[Setting name="Show offzone button"]
bool Setting_OffzoneButton = true;

#if !TURBO
PatternPatch@ g_patchOffzone;
#endif

bool g_inMapEditor = false;
CControlBase@ g_frameLightTools = null;

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

#if !TURBO
void OnEditorOpen(CGameCtnEditorFree@ editor)
{
	auto scene = editor.EditorInterface.InterfaceScene;
	auto root = cast<CControlContainer>(scene.Mobils[0]);

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

	// Light tools
	@g_frameLightTools = FindControl(root, "FrameLightTools");
}

void OnEditorClose(CGameCtnEditorFree@ editor)
{
	if (g_patchOffzone.IsApplied()) {
		g_patchOffzone.Revert();
	}
}

void OnDestroyed()
{
	if (g_patchOffzone.IsApplied()) {
		g_patchOffzone.Revert();
	}
}

void RenderMenu()
{
	if (!g_inMapEditor) {
		return;
	}

	if (g_frameLightTools !is null && UI::MenuItem("\\$cf9" + Icons::Sun + "\\$z Show light tools bar", "", g_frameLightTools.IsVisible)) {
		g_frameLightTools.IsVisible = !g_frameLightTools.IsVisible;
	}
}

void Main()
{
	if (!Permissions::OpenAdvancedMapEditor()) {
		return;
	}

	auto app = GetApp();

	@g_patchOffzone = PatternPatch(
#if TMNEXT && !LOGS
		"0F 84 ?? ?? ?? ?? 4C 8D 45 00 BA 13",
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

	while (true) {
		auto editor = cast<CGameCtnEditorFree>(app.Editor);
		if (!g_inMapEditor && editor !is null) {
			g_inMapEditor = true;
			OnEditorOpen(editor);
		} else if (g_inMapEditor && editor is null) {
			g_inMapEditor = false;
			OnEditorClose(editor);
		}

		if (editor !is null && editor.OrbitalCameraControl !is null) {
			if (Setting_DisableEdgeCamera) {
				editor.OrbitalCameraControl.m_ParamScrollAreaStart = 1.1f;
				editor.OrbitalCameraControl.m_ParamScrollAreaMax = 1.1f;
			} else {
				editor.OrbitalCameraControl.m_ParamScrollAreaStart = 0.7f;
				editor.OrbitalCameraControl.m_ParamScrollAreaMax = 0.98f;
			}
		}

		yield();
	}
}
#endif
