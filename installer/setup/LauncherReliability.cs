// Offline diagnosis and reversible Artur Edition upgrades.
// Native game files are never modified by diagnostics. Restore points contain only
// Artur-owned loader/mod files, mods.ini and this installer's manifest.
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;

namespace HitmanCoopSetup
{
    static class LauncherReliability
    {
        public static bool SupportedPair(string game, string sdk)
        {
            if (game == null || sdk == null) return false;
            if (game.StartsWith("3.290.1", StringComparison.Ordinal))
                return sdk == "4.2.1.0";
            if (game.StartsWith("3.280.", StringComparison.Ordinal))
                return sdk == "4.1.1.0";
            return false;
        }

        public static string ExpectedSdk(string game)
        {
            if (game != null && game.StartsWith("3.290.1", StringComparison.Ordinal)) return "4.2.1.0";
            if (game != null && game.StartsWith("3.280.", StringComparison.Ordinal)) return "4.1.1.0";
            return null;
        }

        public static List<string> Diagnose(GameInstall game)
        {
            var problems = new List<string>();
            if (game == null || !Games.IsGameDir(game.Path))
            {
                problems.Add("Choose a valid HITMAN folder with Retail/HITMAN3.exe.");
                return problems;
            }
            string expectedSdk = ExpectedSdk(game.Version);
            if (expectedSdk == null)
                problems.Add("Unsupported HITMAN game version " + game.Version + ". No compatible Artur build is available.");
            string retail = game.Retail;
            string sdk = Path.Combine(retail, "ZHMModSDK.dll");
            Version installedSdk = Util.FullFileVersion(sdk);
            if (installedSdk == null)
                problems.Add("Missing or unreadable ZHMModSDK.dll.");
            else if (expectedSdk != null && installedSdk.ToString() != expectedSdk)
                problems.Add("SDK mismatch: found " + installedSdk + "; game " + game.Version + " needs " + expectedSdk + ".");
            if (!File.Exists(Path.Combine(retail, "dinput8.dll")))
                problems.Add("Missing dinput8.dll (the mod loader).");
            if (!File.Exists(Path.Combine(retail, "mods", "HitmanCoop.dll")))
                problems.Add("Missing mods/HitmanCoop.dll.");
            string ini = Path.Combine(retail, "mods.ini");
            if (!File.Exists(ini) || !File.ReadAllLines(ini).Any(line =>
                    line.Trim().Equals("[HitmanCoop]", StringComparison.OrdinalIgnoreCase)))
                problems.Add("The [HitmanCoop] entry is missing from mods.ini.");

            InstallManifest manifest = InstallManifest.Load(retail);
            if (manifest == null)
                problems.Add("Missing or damaged Artur install manifest. Repair will rebuild it.");
            else
            {
                if (manifest.Version != Program.Version)
                    problems.Add("Installed Artur version " + manifest.Version + "; this launcher carries " + Program.Version + ".");
                if (expectedSdk != null && manifest.Build != game.Build)
                    problems.Add("This install's build target doesn't match HITMAN " + game.Version + ".");
            }

            if (expectedSdk != null)
            {
                string payload = Payload.FilesFor(game.Build);
                if (!File.Exists(Path.Combine(payload, "mods", "HitmanCoop.dll")))
                    problems.Add("This launcher is missing the matching Artur payload.");
                else
                {
                    foreach (string file in Directory.GetFiles(payload, "*", SearchOption.AllDirectories))
                    {
                        string relative = Util.RelativeTo(payload, file);
                        if (!RestorePoints.SafeModFile(relative)) continue;
                        string installed = Path.Combine(retail, relative);
                        if (File.Exists(installed) && !String.Equals(Util.Sha256File(file),
                                Util.Sha256File(installed), StringComparison.OrdinalIgnoreCase))
                            problems.Add("Different or damaged mod file: " + relative + ".");
                    }
                }
            }
            return problems;
        }

        public static int SelfTest()
        {
            string tmp = Path.Combine(Path.GetTempPath(), "artur-rollback-test-" + Guid.NewGuid().ToString("N"));
            try
            {
                if (!SupportedPair("3.290.1", "4.2.1.0") || !SupportedPair("3.280.2", "4.1.1.0") ||
                    SupportedPair("3.290.1", "4.2.0.0") || SupportedPair("3.280.2", "4.2.1.0") ||
                    SupportedPair("unknown", "4.2.1.0"))
                    throw new Exception("Game/SDK version compatibility regression.");
                if (RestorePoints.SafeModFile("../HITMAN3.exe") || RestorePoints.SafeModFile("HITMAN3.exe") ||
                    RestorePoints.SafeModFile("mods/OtherMod.dll") ||
                    !RestorePoints.SafeModFile("mods/HitmanCoop.dll"))
                    throw new Exception("Unsafe file accepted by rollback.");
                string retail = Path.Combine(tmp, "Retail");
                string mods = Path.Combine(retail, "mods");
                Directory.CreateDirectory(mods);
                string dll = Path.Combine(mods, "HitmanCoop.dll");
                File.WriteAllText(dll, "previous release");
                File.WriteAllText(Path.Combine(retail, "mods.ini"), "[HitmanCoop]\n");
                var m = new InstallManifest { Version = "0.14.3", Build = "3.290" };
                m.Files["mods/HitmanCoop.dll"] = Util.Sha256File(dll);
                m.Save(retail);
                RestorePoints.RootOverride = Path.Combine(tmp, "snapshots");
                RestorePoints.Capture(retail, delegate(string s) { });
                File.WriteAllText(dll, "broken update");
                File.WriteAllText(Path.Combine(retail, "mods.ini"), "[OtherMod]\n");
                var newer = new InstallManifest { Version = "0.14.4", Build = "3.290" };
                newer.Files["mods/HitmanCoop.dll"] = Util.Sha256File(dll);
                newer.Save(retail);
                if (!RestorePoints.CanRestore(retail)) throw new Exception("No usable restore point.");
                RestorePoints.RestoreLatest(retail, delegate(string s) { });
                if (File.ReadAllText(dll) != "previous release" ||
                    File.ReadAllText(Path.Combine(retail, "mods.ini")) != "[HitmanCoop]\n" ||
                    InstallManifest.Load(retail).Version != "0.14.3")
                    throw new Exception("Rollback did not restore exact previous files.");

                return 0;
            }
            catch (Exception e)
            {
                System.Diagnostics.Debug.WriteLine("Launcher reliability tests: " + e);
                return 1;
            }
            finally
            {
                RestorePoints.RootOverride = null;
                try { Directory.Delete(tmp, true); } catch { }
            }
        }
    }

    static class RestorePoints
    {
        // Test-only replacement; production snapshots stay outside the game folder.
        internal static string RootOverride;
        static readonly string[] OwnedRootFiles = {
            "dinput8.dll", "ZHMModSDK.dll", "crashpad_handler.exe",
            "discord_game_sdk.dll", "ResourceLib_HM3.dll"
        };
        static string GameRoot(string retail)
        {
            string root = RootOverride ?? Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "HitmanCoopArtur", "RestorePoints");
            string normal = Path.GetFullPath(retail).TrimEnd('\\').ToUpperInvariant();
            using (var sha = SHA256.Create())
            {
                byte[] hash = sha.ComputeHash(Encoding.UTF8.GetBytes(normal));
                string key = BitConverter.ToString(hash).Replace("-", "").Substring(0, 20);
                return Path.Combine(root, key);
            }
        }

        public static bool SafeModFile(string rel)
        {
            if (String.IsNullOrEmpty(rel) || Path.IsPathRooted(rel)) return false;
            string path = rel.Replace('\\', '/');
            if (path.Contains("..") || path.Contains(":") || path.Contains("//") ||
                path.StartsWith("/", StringComparison.Ordinal)) return false;
            if (OwnedRootFiles.Any(x => x.Equals(path, StringComparison.OrdinalIgnoreCase))) return true;
            return path.StartsWith("mods/HitmanCoop.", StringComparison.OrdinalIgnoreCase) &&
                path.IndexOf('/', 5) < 0;
        }

        static string Dest(string retail, string rel)
        {
            if (!SafeModFile(rel) && rel != Games.ManifestName && rel != "mods.ini")
                throw new SetupException("A restore point contains an unsafe file path.");
            return Path.Combine(retail, rel.Replace('/', Path.DirectorySeparatorChar));
        }

        static List<string> ValidSnapshots(string retail)
        {
            string root = GameRoot(retail);
            if (!Directory.Exists(root)) return new List<string>();
            return Directory.GetDirectories(root).Where(dir => File.Exists(Path.Combine(dir, "snapshot.json")))
                .OrderByDescending(dir => Path.GetFileName(dir), StringComparer.Ordinal).ToList();
        }

        public static bool CanRestore(string retail)
        {
            return ValidSnapshots(retail).Count > 0;
        }

        public static void Capture(string retail, Action<string> log)
        {
            InstallManifest manifest = InstallManifest.Load(retail);
            if (manifest == null || String.IsNullOrEmpty(manifest.Version)) return; // fresh install
            string root = GameRoot(retail);
            Directory.CreateDirectory(root);
            string temp = Path.Combine(root, ".staging-" + Guid.NewGuid().ToString("N"));
            string final = Path.Combine(root, DateTime.UtcNow.ToString("yyyyMMdd-HHmmss-fffffff") + "-" +
                Guid.NewGuid().ToString("N").Substring(0, 8));
            Directory.CreateDirectory(temp);
            try
            {
                var files = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                var paths = manifest.Files.Keys.Where(SafeModFile)
                    .Concat(new[] { Games.ManifestName, "mods.ini" }).Distinct(StringComparer.OrdinalIgnoreCase);
                foreach (string rel in paths)
                {
                    string file = Dest(retail, rel);
                    if (!File.Exists(file)) continue;
                    string destination = Path.Combine(temp, rel.Replace('/', Path.DirectorySeparatorChar));
                    Directory.CreateDirectory(Path.GetDirectoryName(destination));
                    File.Copy(file, destination, true);
                    files[rel] = Util.Sha256File(destination);
                }
                if (!files.ContainsKey(Games.ManifestName))
                    throw new SetupException("Cannot back up the existing install manifest.");
                var data = new Dictionary<string, object> {
                    { "version", manifest.Version }, { "retail", Path.GetFullPath(retail) }, { "files", files }
                };
                File.WriteAllText(Path.Combine(temp, "snapshot.json"), Util.ToJson(data), new UTF8Encoding(false));
                Directory.Move(temp, final); // incomplete snapshots are never shown
                log("Created rollback point for Artur " + manifest.Version + " in " + final);
                // Keep the newest four recoverable versions per game.
                foreach (string excess in ValidSnapshots(retail).Skip(4))
                    try { Directory.Delete(excess, true); } catch { }
            }
            catch
            {
                try { Directory.Delete(temp, true); } catch { }
                throw; // never start the upgrade if we could not preserve the old installation
            }
        }

        public static void RestoreLatest(string retail, Action<string> log)
        {
            if (Games.GameRunning())
                throw new SetupException("Close HITMAN before restoring an older mod.");
            var snapshots = ValidSnapshots(retail);
            if (snapshots.Count == 0) throw new SetupException("No previous Artur installation is backed up.");
            string selected = snapshots[0];
            var meta = Util.Json(File.ReadAllText(Path.Combine(selected, "snapshot.json")))
                as Dictionary<string, object>;
            if (meta == null || !String.Equals(Util.Get(meta, "retail") as string,
                    Path.GetFullPath(retail), StringComparison.OrdinalIgnoreCase))
                throw new SetupException("The selected restore point belongs to another game folder.");
            var records = Util.Get(meta, "files") as Dictionary<string, object>;
            if (records == null || records.Count == 0)
                throw new SetupException("The selected restore point is incomplete.");
            var saved = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (var item in records)
            {
                string path = Dest(retail, item.Key); // allow-listed, no traversal
                string snapshotFile = Path.Combine(selected, item.Key.Replace('/', Path.DirectorySeparatorChar));
                string hash = item.Value as string;
                if (String.IsNullOrEmpty(hash) || !File.Exists(snapshotFile) ||
                    !String.Equals(Util.Sha256File(snapshotFile), hash, StringComparison.OrdinalIgnoreCase))
                    throw new SetupException("A rollback file is missing or damaged: " + item.Key);
                saved[item.Key] = snapshotFile;
            }
            if (!saved.ContainsKey(Games.ManifestName))
                throw new SetupException("The restore point does not contain an install manifest.");
            // Keep the current version as its own fallback before replacing any files.
            Capture(retail, log);
            InstallManifest current = InstallManifest.Load(retail);
            if (current != null)
            {
                foreach (var pair in current.Files)
                {
                    if (!SafeModFile(pair.Key) || saved.ContainsKey(pair.Key)) continue;
                    string file = Dest(retail, pair.Key);
                    // Don't erase a file another mod replaced after Artur installed.
                    if (File.Exists(file) && String.Equals(Util.Sha256File(file), pair.Value,
                            StringComparison.OrdinalIgnoreCase))
                        File.Delete(file);
                }
            }
            foreach (var pair in saved)
            {
                string dest = Dest(retail, pair.Key);
                Directory.CreateDirectory(Path.GetDirectoryName(dest));
                Util.CopyWithRetry(pair.Value, dest);
            }
            log("Restored Artur Edition " + (Util.Get(meta, "version") as string) + ". Start HITMAN again.");
        }
    }
}
