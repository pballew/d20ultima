using Godot;
using System;

public partial class DebugLogger : Node
{
    private const string LOG_PATH = "user://debug.log";
    private const string SYS_LOG_PATH = "C:/temp/godot_output.log";

    public override void _Ready()
    {
        EnsureSysDirExists();
    }

    private void EnsureSysDirExists()
    {
        try
        {
            var sysDir = System.IO.Path.GetDirectoryName(SYS_LOG_PATH);
            if (!string.IsNullOrEmpty(sysDir) && !System.IO.Directory.Exists(sysDir))
                System.IO.Directory.CreateDirectory(sysDir);
        }
        catch
        {
            // best-effort, ignore failures
        }
    }

    private void WriteLineToPath(string path, string line)
    {
        try
        {
            // Use Godot's FileAccess where possible
            var fa = FileAccess.Open(path, FileAccess.ModeFlags.WriteRead);
            if (fa == null)
            {
                fa = FileAccess.Open(path, FileAccess.ModeFlags.Write);
                if (fa != null)
                {
                    fa.StoreString(line + "\n");
                    fa.Close();
                    return;
                }
                return;
            }

            fa.SeekEnd();
            fa.StoreString(line + "\n");
            fa.Close();
        }
        catch
        {
            // ignore write failures
        }
    }

    private void WriteLine(string line)
    {
        WriteLineToPath(LOG_PATH, line);
        EnsureSysDirExists();
        WriteLineToPath(SYS_LOG_PATH, line);
    }

    private string Timestamp()
    {
        try { return Time.GetUnixTimeFromSystem().ToString(); } catch { return DateTime.Now.ToString(); }
    }

    public void Log(string message)
    {
        var line = "[LOG] [" + Timestamp() + "] " + message;
        GD.Print(line);
        WriteLine(line);
    }

    public void Info(string message)
    {
        var line = "[INFO] [" + Timestamp() + "] " + message;
        GD.Print(line);
        WriteLine(line);
    }

    public void Warn(string message)
    {
        var line = "[WARN] [" + Timestamp() + "] " + message;
        GD.Print(line);
        WriteLine(line);
    }

    public void Error(string message)
    {
        var line = "[ERROR] [" + Timestamp() + "] " + message;
        GD.Print(line);
        WriteLine(line);
    }

}

// Lower-case wrappers for GDScript compatibility
public partial class DebugLogger
{
    public void log(string message) { Log(message); }
    public void info(string message) { Info(message); }
    public void warn(string message) { Warn(message); }
    public void error(string message) { Error(message); }
}