using Godot;
using System;
using System.Linq;

public partial class MapPanel : Control
{
    public override void _Ready()
    {
        // Ensure panel is hidden initially; MainMenu will toggle visibility
        Hide();
    }

    public void ShowMap()
    {
        // Rebuild minimap before showing
        BuildMinimap();
        Show();
        // Bring to front
        this.ZIndex = 1000;
    }

    public void HideMap()
    {
        Hide();
    }

    public void ToggleMap()
    {
        if (Visible)
            HideMap();
        else
            ShowMap();
    }

    // Try to build a simple minimap texture from EnhancedTerrainTileMap (legacy node)
    public void BuildMinimap()
    {
        // Look for EnhancedTerrainTileMap in the current scene (Main is a sibling root node)
        var root = GetTree()?.Root;
        if (root == null)
            return;

        Node main = root.GetChildren().OfType<Node>().FirstOrDefault(n => n.Name == "Main");
        if (main == null)
            main = root.GetChildOrNull<Node>(0);
        if (main == null)
            return;

        var terrain = main.GetNodeOrNull("EnhancedTerrainTileMap") as Node;
        if (terrain == null)
        {
            // Nothing to draw; keep placeholder label visible
            var mapTex = GetNodeOrNull<TextureRect>("Panel/MapTexture");
            if (mapTex != null)
                mapTex.Visible = false;
            return;
        }

        try
        {
            var method = terrain.GetType().GetMethod("GetUsedRect");
            if (method == null)
                return;

            var usedRectObj = method.Invoke(terrain, null);
            if (usedRectObj == null)
                return;

            var usedRect = (Rect2)usedRectObj;
            int w = (int)usedRect.Size.X;
            int h = (int)usedRect.Size.Y;
            if (w <= 0 || h <= 0)
                return;

            var img = Image.Create(w, h, false, Image.Format.Rgba8);

            // fill transparent
            for (int yy = 0; yy < h; yy++)
                for (int xx = 0; xx < w; xx++)
                    img.SetPixel(xx, yy, new Color(0, 0, 0, 0));

            var getUsedCellsMethod = terrain.GetType().GetMethod("GetUsedCells");
            var getCellMethod = terrain.GetType().GetMethod("GetCell");

            if (getUsedCellsMethod != null)
            {
                var cells = getUsedCellsMethod.Invoke(terrain, new object[] { 0 });
                if (cells is Godot.Collections.Array arr)
                {
                    foreach (object v in arr)
                    {
                        if (v is Vector2I vi)
                        {
                            int px = vi.X - (int)usedRect.Position.X;
                            int py = vi.Y - (int)usedRect.Position.Y;
                            if (px >= 0 && px < w && py >= 0 && py < h)
                                img.SetPixel(px, py, new Color(0.8f, 0.8f, 0.8f, 1f));
                        }
                        else if (v is Vector2 vf)
                        {
                            var vi2 = new Vector2I((int)vf.X, (int)vf.Y);
                            int px = vi2.X - (int)usedRect.Position.X;
                            int py = vi2.Y - (int)usedRect.Position.Y;
                            if (px >= 0 && px < w && py >= 0 && py < h)
                                img.SetPixel(px, py, new Color(0.8f, 0.8f, 0.8f, 1f));
                        }
                    }
                }
            }
            else if (getCellMethod != null)
            {
                for (int yy = 0; yy < h; yy++)
                {
                    for (int xx = 0; xx < w; xx++)
                    {
                        var cell = getCellMethod.Invoke(terrain, new object[] { 0, new Vector2I((int)usedRect.Position.X + xx, (int)usedRect.Position.Y + yy) });
                        if (cell is int cid && cid != -1)
                            img.SetPixel(xx, yy, new Color(0.8f, 0.8f, 0.8f, 1f));
                    }
                }
            }

            // Image.Unlock not available in current bindings; skip explicit locking

            var tex = ImageTexture.CreateFromImage(img);
            var mapTex = GetNodeOrNull<TextureRect>("Panel/MapTexture");
            if (mapTex != null)
            {
                mapTex.Texture = tex;
                mapTex.Visible = true;
                var lbl = GetNodeOrNull<Label>("Panel/MapLabel");
                if (lbl != null)
                    lbl.Visible = false;
            }
        }
        catch
        {
            // fail silently
        }
    }
}
