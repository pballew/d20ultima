using System;
using System.Reflection;

class Program
{
	static int Main(string[] args)
	{
		var dllPath = args.Length > 0 ? args[0] : "..\\..\\..\\.godot\\mono\\temp\\bin\\Debug\\d20ultima.dll";
		Console.WriteLine($"Inspecting: {dllPath}");
		if (!System.IO.File.Exists(dllPath))
		{
			Console.WriteLine("DLL not found");
			return 2;
		}

		try
		{
			var asm = Assembly.LoadFrom(dllPath);
			Console.WriteLine("Assembly loaded. Types:");
			foreach (var t in asm.GetTypes())
			{
				Console.WriteLine("  " + t.FullName);
			}
		}
		catch (ReflectionTypeLoadException ex)
		{
			Console.WriteLine("ReflectionTypeLoadException: " + ex.Message);
			foreach (var le in ex.LoaderExceptions)
			{
				Console.WriteLine("LoaderException: " + le.Message);
				if (le.InnerException != null) Console.WriteLine("  Inner: " + le.InnerException.Message);
			}
			return 3;
		}
		catch (Exception ex)
		{
			Console.WriteLine("Load failed: " + ex.Message);
			if (ex.InnerException != null) Console.WriteLine("  Inner: " + ex.InnerException.Message);
			return 1;
		}

		return 0;
	}
}
