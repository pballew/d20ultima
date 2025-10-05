using Godot;
using System;

public partial class Towndialog : Control
{
    [Signal]
    public delegate void town_entered(object p0);

    [Signal]
    public delegate void dialog_cancelled();

    public override void _Ready()
    {
        // Ported stub for _ready
    }

    public void show_town_dialog(object town_data = null)
    {
        // Ported stub
    }

    public void hide_dialog()
    {
        // Ported stub
    }

    public void _input(object event = null)
    {
        // Ported stub
    }

}