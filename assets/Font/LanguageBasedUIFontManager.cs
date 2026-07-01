using UnityEngine;
using UnityEngine.UI;
using TMPro;
using UnityEngine.SceneManagement;
using System.Collections.Generic;

[System.Serializable]
public class LanguageFontSettings
{
    public string languageCode;

    // ================= LEGACY =================

    [Header("Legacy Character")]
    public Font legacyFont;

    public bool overrideLegacyFontSize;
    public bool useRelativeLegacySize;
    public int legacyFontSize = 30;
    public int legacyFontSizeDelta = 0;

    public bool overrideLegacyLineSpacing;
    public float legacyLineSpacing = 1f;

    [Header("Legacy Paragraph")]
    public bool overrideLegacyAlignment;
    public TextAnchor legacyAlignment = TextAnchor.MiddleCenter;
    public bool alignByGeometry;
    public HorizontalWrapMode horizontalOverflow = HorizontalWrapMode.Wrap;
    public VerticalWrapMode verticalOverflow = VerticalWrapMode.Overflow;

    public bool overrideLegacyBestFit;
    public bool bestFit;
    public int minSize = 10;
    public int maxSize = 40;

    // ================= TMP =================

    [Header("TMP Character")]
    public TMP_FontAsset tmpFont;

    public bool overrideTMPFontSize;
    public bool useRelativeTMPSize;
    public float tmpFontSize = 30;
    public float tmpFontSizeDelta = 0;

    public bool overrideTMPLineSpacing;
    public float tmpLineSpacing = 0;

    [Header("TMP Paragraph")]
    public bool overrideTMPAlignment;
    public TextAlignmentOptions tmpAlignment = TextAlignmentOptions.Center;
    public TextOverflowModes tmpOverflow = TextOverflowModes.Overflow;

    public bool overrideTMPAutoSize;
    public bool tmpAutoSize;
    public float tmpMinSize = 18;
    public float tmpMaxSize = 36;
}

public class LanguageBasedUIFontManager : MonoBehaviour
{
    public List<LanguageFontSettings> languageSettings = new();

    private Dictionary<Text, TextState> legacyDefaults = new();
    private Dictionary<TextMeshProUGUI, TMPState> tmpDefaults = new();

    private bool captured = false;

    private void OnEnable()
    {
        if (LocalizationManager.Instance != null)
            LocalizationManager.Instance.OnLanguageChanged += ApplyCurrentLanguageFont;
    }

    private void OnDisable()
    {
        if (LocalizationManager.Instance != null)
            LocalizationManager.Instance.OnLanguageChanged -= ApplyCurrentLanguageFont;
    }

    private void Start()
    {
        CaptureDefaults();
        ApplyCurrentLanguageFont();
    }

    private void CaptureDefaults()
    {
        if (captured) return;

        Scene scene = SceneManager.GetActiveScene();
        foreach (GameObject root in scene.GetRootGameObjects())
        {
            foreach (Text t in root.GetComponentsInChildren<Text>(true))
                legacyDefaults[t] = new TextState(t);

            foreach (TextMeshProUGUI tmp in root.GetComponentsInChildren<TextMeshProUGUI>(true))
                tmpDefaults[tmp] = new TMPState(tmp);
        }

        captured = true;
    }

    public void ApplyCurrentLanguageFont()
    {
        if (LocalizationManager.Instance == null)
            return;

        string lang = LocalizationManager.Instance.CurrentLanguage;

        RestoreDefaults();

        var settings = languageSettings.Find(x => x.languageCode == lang);
        if (settings == null)
            return;

        Scene scene = SceneManager.GetActiveScene();
        foreach (GameObject root in scene.GetRootGameObjects())
        {
            foreach (Text t in root.GetComponentsInChildren<Text>(true))
                ApplyLegacy(t, settings);

            foreach (TextMeshProUGUI tmp in root.GetComponentsInChildren<TextMeshProUGUI>(true))
                ApplyTMP(tmp, settings);
        }

        Debug.Log($"Applied full UI style for language: {lang}");
    }

    private void RestoreDefaults()
    {
        foreach (var pair in legacyDefaults)
            pair.Value.Restore(pair.Key);

        foreach (var pair in tmpDefaults)
            pair.Value.Restore(pair.Key);
    }

    private void ApplyLegacy(Text t, LanguageFontSettings s)
    {
        if (s.legacyFont != null)
            t.font = s.legacyFont;

        if (s.overrideLegacyFontSize)
        {
            if (s.useRelativeLegacySize)
                t.fontSize += s.legacyFontSizeDelta;
            else
                t.fontSize = s.legacyFontSize;
        }

        if (s.overrideLegacyLineSpacing)
            t.lineSpacing = s.legacyLineSpacing;

        if (s.overrideLegacyAlignment)
        {
            t.alignment = s.legacyAlignment;
            t.alignByGeometry = s.alignByGeometry;
            t.horizontalOverflow = s.horizontalOverflow;
            t.verticalOverflow = s.verticalOverflow;
        }

        if (s.overrideLegacyBestFit)
        {
            t.resizeTextForBestFit = s.bestFit;
            t.resizeTextMinSize = s.minSize;
            t.resizeTextMaxSize = s.maxSize;
        }
    }

    private void ApplyTMP(TextMeshProUGUI tmp, LanguageFontSettings s)
    {
        if (s.tmpFont != null)
            tmp.font = s.tmpFont;

        if (s.overrideTMPFontSize)
        {
            if (s.useRelativeTMPSize)
                tmp.fontSize += s.tmpFontSizeDelta;
            else
                tmp.fontSize = s.tmpFontSize;
        }

        if (s.overrideTMPLineSpacing)
            tmp.lineSpacing = s.tmpLineSpacing;

        if (s.overrideTMPAlignment)
        {
            tmp.alignment = s.tmpAlignment;
            tmp.overflowMode = s.tmpOverflow;
        }

        if (s.overrideTMPAutoSize)
        {
            tmp.enableAutoSizing = s.tmpAutoSize;
            tmp.fontSizeMin = s.tmpMinSize;
            tmp.fontSizeMax = s.tmpMaxSize;
        }
    }

    // ================= STATE HOLDERS =================

    private class TextState
    {
        Font font;
        int fontSize;
        float lineSpacing;
        TextAnchor alignment;
        bool alignByGeometry;
        HorizontalWrapMode hWrap;
        VerticalWrapMode vWrap;
        bool bestFit;
        int min;
        int max;

        public TextState(Text t)
        {
            font = t.font;
            fontSize = t.fontSize;
            lineSpacing = t.lineSpacing;
            alignment = t.alignment;
            alignByGeometry = t.alignByGeometry;
            hWrap = t.horizontalOverflow;
            vWrap = t.verticalOverflow;
            bestFit = t.resizeTextForBestFit;
            min = t.resizeTextMinSize;
            max = t.resizeTextMaxSize;
        }

        public void Restore(Text t)
        {
            if (t == null) return;

            t.font = font;
            t.fontSize = fontSize;
            t.lineSpacing = lineSpacing;
            t.alignment = alignment;
            t.alignByGeometry = alignByGeometry;
            t.horizontalOverflow = hWrap;
            t.verticalOverflow = vWrap;
            t.resizeTextForBestFit = bestFit;
            t.resizeTextMinSize = min;
            t.resizeTextMaxSize = max;
        }
    }

    private class TMPState
    {
        TMP_FontAsset font;
        float fontSize;
        float lineSpacing;
        TextAlignmentOptions alignment;
        TextOverflowModes overflow;
        bool autoSize;
        float min;
        float max;

        public TMPState(TextMeshProUGUI t)
        {
            font = t.font;
            fontSize = t.fontSize;
            lineSpacing = t.lineSpacing;
            alignment = t.alignment;
            overflow = t.overflowMode;
            autoSize = t.enableAutoSizing;
            min = t.fontSizeMin;
            max = t.fontSizeMax;
        }

        public void Restore(TextMeshProUGUI t)
        {
            if (t == null) return;

            t.font = font;
            t.fontSize = fontSize;
            t.lineSpacing = lineSpacing;
            t.alignment = alignment;
            t.overflowMode = overflow;
            t.enableAutoSizing = autoSize;
            t.fontSizeMin = min;
            t.fontSizeMax = max;
        }
    }
}
