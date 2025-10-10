using Godot;
using System;

public partial class LoadCharacterPopup : PopupPanel
{
    private VBoxContainer listContainer;
    private Button cancelButton;

    [Signal] public delegate void CharacterSelectedEventHandler(Resource character_data);

    public override void _Ready()
    {
        // Ensure the GDScript-style signal name exists for compatibility
        try { if (!HasSignal("character_selected")) AddUserSignal("character_selected", new Godot.Collections.Array()); } catch { }

        // Try to find expected nodes; if they're missing (e.g. the tscn didn't have the script attached),
        // create the UI programmatically so we always have a working popup.
        listContainer = GetNodeOrNull<VBoxContainer>("Panel/VBoxContainer/Scroll/List");
        cancelButton = GetNodeOrNull<Button>("Panel/VBoxContainer/CancelButton");

        Label topLabel = GetNodeOrNull<Label>("Panel/VBoxContainer/TopLabel");
        Label bottomLabel = GetNodeOrNull<Label>("Panel/VBoxContainer/BottomLabel");

    if (listContainer == null || cancelButton == null)
        {
            // Build UI tree: Panel -> VBoxContainer -> ScrollContainer -> List (VBox)
            var panel = new Panel();
            panel.Name = "Panel";
            AddChild(panel);

            // Make panel fill the popup
            try { panel.AnchorLeft = 0f; panel.AnchorTop = 0f; panel.AnchorRight = 1f; panel.AnchorBottom = 1f; panel.OffsetLeft = 0f; panel.OffsetTop = 0f; panel.OffsetRight = 0f; panel.OffsetBottom = 0f; } catch { }

            var vbox = new VBoxContainer();
            vbox.Name = "VBoxContainer";
            panel.AddChild(vbox);
            try { vbox.AnchorLeft = 0f; vbox.AnchorTop = 0f; vbox.AnchorRight = 1f; vbox.AnchorBottom = 1f; vbox.OffsetLeft = 0f; vbox.OffsetTop = 0f; vbox.OffsetRight = 0f; vbox.OffsetBottom = 0f; } catch { }

            var scroll = new ScrollContainer();
            scroll.Name = "Scroll";
            vbox.AddChild(scroll);
            try { scroll.AnchorLeft = 0f; scroll.AnchorTop = 0f; scroll.AnchorRight = 1f; scroll.AnchorBottom = 1f; scroll.OffsetLeft = 0f; scroll.OffsetTop = 0f; scroll.OffsetRight = 0f; scroll.OffsetBottom = 0f; } catch { }

            listContainer = new VBoxContainer();
            listContainer.Name = "List";
            scroll.AddChild(listContainer);
            try { listContainer.AnchorLeft = 0f; listContainer.AnchorTop = 0f; listContainer.AnchorRight = 1f; listContainer.AnchorBottom = 1f; listContainer.OffsetLeft = 0f; listContainer.OffsetTop = 0f; listContainer.OffsetRight = 0f; listContainer.OffsetBottom = 0f; } catch { }
            // add an informational label above the cancel button
            topLabel = new Label();
            topLabel.Name = "TopLabel";
            topLabel.Text = "Select a saved character:";
            vbox.AddChild(topLabel);

            cancelButton = new Button();
            cancelButton.Name = "CancelButton";
            cancelButton.Text = "Cancel";
            vbox.AddChild(cancelButton);
            try { cancelButton.AnchorLeft = 0f; cancelButton.AnchorTop = 1f; cancelButton.AnchorRight = 1f; cancelButton.AnchorBottom = 1f; } catch { }

            // add an informational label below the cancel button
            bottomLabel = new Label();
            bottomLabel.Name = "BottomLabel";
            bottomLabel.Text = "Press Cancel to close this dialog.";
            vbox.AddChild(bottomLabel);
        }

    if (cancelButton != null) cancelButton.Pressed += () => { Hide(); QueueFree(); };

        // Make the dialog full-screen by expanding the Panel and its children to the viewport size
        try
        {
            var vpSize = GetViewport() != null ? GetViewport().GetVisibleRect().Size : new Vector2(1024, 768);
            var panelNode = GetNodeOrNull<Panel>("Panel");
            if (panelNode != null)
            {
                panelNode.CustomMinimumSize = vpSize;
                panelNode.SizeFlagsVertical = Control.SizeFlags.Expand;
            }

            var vboxNode = GetNodeOrNull<VBoxContainer>("Panel/VBoxContainer");
            if (vboxNode != null) vboxNode.SizeFlagsVertical = Control.SizeFlags.Expand;

            var sc = GetNodeOrNull<ScrollContainer>("Panel/VBoxContainer/Scroll");
            if (sc != null) sc.SizeFlagsVertical = Control.SizeFlags.Expand;

            var lc = GetNodeOrNull<VBoxContainer>("Panel/VBoxContainer/Scroll/List");
            if (lc != null) lc.SizeFlagsVertical = Control.SizeFlags.Expand;
        }
        catch { }

        PopulateList();
    }

    private void PopulateList()
    {
        try
        {
            var files = SaveSystem.ListSavedCharacters();
                if (files == null || files.Count == 0)
                {
                    var lbl = new Label();
                    lbl.Text = "No saved characters found.";
                    if (listContainer != null) listContainer.AddChild(lbl);
                    // also set bottom label to indicate empty state if present
                    try { var b = GetNodeOrNull<Label>("Panel/VBoxContainer/BottomLabel"); if (b != null) b.Text = "No saved characters found."; } catch { }
                    return;
                }

            int added = 0;
            foreach (var f in files)
            {
                string path = f.ToString();
                GD.Print($"LoadCharacterPopup: found file path: {path}");
                if (string.IsNullOrEmpty(path)) continue;
                Resource res = null;
                try { res = GD.Load<Resource>(path); } catch { res = null; }

                // Debug: print resource type and any accessible exported properties
                try
                {
                    if (res == null)
                    {
                        GD.Print($"LoadCharacterPopup: resource at {path} failed to load (null)");
                    }
                    else
                    {
                        GD.Print($"LoadCharacterPopup: loaded resource {res.GetType().Name} from {path}");
                        // Try fetching some common properties and log them
                        string[] keys = new string[] { "character_name", "character_race", "character_class", "level", "experience" };
                        foreach (var k in keys)
                        {
                            try
                            {
                                object valObj = null;
                                try { valObj = res.Get(k); } catch { valObj = null; }
                                if (valObj != null) GD.Print($"  {k} = {valObj}"); else GD.Print($"  {k} = <null or missing>");
                            }
                            catch { GD.Print($"  {k} = <not present>"); }
                        }
                        // If resource supports GetPropertyList (via Godot.Object methods), attempt to iterate
                        try
                        {
                            var props = res.GetPropertyList();
                            if (props != null && props.Count > 0)
                            {
                                GD.Print($"  property_list_count = {props.Count}");
                                for (int pi = 0; pi < props.Count; pi++)
                                {
                                    try
                                    {
                                        var entry = (Godot.Collections.Dictionary)props[pi];
                                        try { var nm = entry["name"]; GD.Print($"    prop: {nm}"); } catch { }
                                    }
                                    catch { }
                                }
                            }
                        }
                        catch { }
                    }
                }
                catch (Exception ex) { GD.PrintErr("LoadCharacterPopup: debug print exception: " + ex.Message); }

                // Extract display fields: name, race, class, level
                string displayName = System.IO.Path.GetFileNameWithoutExtension(path);
                string raceName = "?";
                string className = "?";
                string levelText = "?";

                if (res != null)
                {
                    try { object maybe = res.Get("character_name"); if (maybe != null) displayName = maybe.ToString(); } catch { }
                    try { object r = res.Get("character_race"); if (r != null) raceName = r.ToString(); } catch { }
                    try { object c = res.Get("character_class"); if (c != null) className = c.ToString(); } catch { }
                    try {
                        object lvl = res.Get("level");
                        if (lvl != null) levelText = lvl.ToString();
                        else
                        {
                            // try xp -> derive level if possible (fallback)
                            object xp = res.Get("experience");
                            if (xp != null) levelText = "Unknown"; // leave as a placeholder
                        }
                    } catch { }
                }

                // Build row with Name / Race / Class / Level
                var row = new HBoxContainer();
                row.CustomMinimumSize = new Vector2(0, 36);

                var nameLabel = new Label(); nameLabel.Text = displayName; nameLabel.SizeFlagsHorizontal = Control.SizeFlags.Expand;
                var raceLabel = new Label(); raceLabel.Text = raceName; raceLabel.SizeFlagsHorizontal = Control.SizeFlags.ShrinkCenter;
                var classLabel = new Label(); classLabel.Text = className; classLabel.SizeFlagsHorizontal = Control.SizeFlags.ShrinkCenter;
                var levelLabel = new Label(); levelLabel.Text = levelText; levelLabel.SizeFlagsHorizontal = Control.SizeFlags.ShrinkCenter;

                row.AddChild(nameLabel);
                row.AddChild(raceLabel);
                row.AddChild(classLabel);
                row.AddChild(levelLabel);

                var selectBtn = new Button(); selectBtn.Text = "Select"; selectBtn.SizeFlagsHorizontal = Control.SizeFlags.ShrinkEnd;
                row.AddChild(selectBtn);

                // capture path for closure
                string capturedPath = path;
                selectBtn.Pressed += () =>
                {
                    // load resource and emit
                    Resource chosen = null;
                    try { chosen = GD.Load<Resource>(capturedPath); } catch { chosen = null; }
                    if (chosen != null)
                    {
                        EmitSignal("character_selected", chosen);
                    }
                    else
                    {
                        GD.PrintErr($"LoadCharacterPopup: Failed to load {capturedPath}");
                    }
                    Hide();
                    QueueFree();
                };

                listContainer.AddChild(row);
                added++;
            }
            GD.Print($"LoadCharacterPopup: added rows = {added}");
        }
        catch (Exception ex)
        {
            GD.PrintErr("LoadCharacterPopup.PopulateList exception: " + ex.Message);
            var lbl = new Label(); lbl.Text = "Error listing characters"; if (listContainer != null) listContainer.AddChild(lbl);
        }
    }
}
