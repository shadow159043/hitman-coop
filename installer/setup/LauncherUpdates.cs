// Artur Edition setup self-updater. No third-party packages or background installation.
// Checks the fork's latest GitHub release, then verifies the release's matching .sha256
// before launching its Windows installer. It never overwrites or runs the current EXE.
using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Web.Script.Serialization;

namespace HitmanCoopSetup
{
    sealed class LauncherRelease
    {
        public string Number;
        public string FileName;
        public string InstallerUrl;
        public string ChecksumUrl;
    }

    static class LauncherUpdates
    {
        const string RepoApi = "https://api.github.com/repos/shadow159043/hitman-coop/releases/latest";
        const string Releases = "https://github.com/shadow159043/hitman-coop/releases/download/";
        const long MaxInstallerBytes = 150L * 1024 * 1024;

        static string DownloadText(string url, int maxChars)
        {
            ServicePointManager.SecurityProtocol |= (SecurityProtocolType)3072; // TLS 1.2 on .NET 4
            var request = (HttpWebRequest)WebRequest.Create(url);
            request.UserAgent = "ArturEdition-Setup/" + Program.Version;
            request.Accept = "application/vnd.github+json, text/plain, */*";
            request.Timeout = 15000;
            request.ReadWriteTimeout = 15000;
            request.AutomaticDecompression = DecompressionMethods.GZip | DecompressionMethods.Deflate;
            using (var response = (HttpWebResponse)request.GetResponse())
            using (var stream = response.GetResponseStream())
            using (var reader = new StreamReader(stream, Encoding.UTF8))
            {
                char[] buffer = new char[8192];
                var value = new StringBuilder();
                int length;
                while ((length = reader.Read(buffer, 0, buffer.Length)) > 0)
                {
                    if (value.Length + length > maxChars)
                        throw new SetupException("GitHub's update response was unexpectedly large.", "Download the latest installer manually from this project's Releases page.");
                    value.Append(buffer, 0, length);
                }
                return value.ToString();
            }
        }

        internal static LauncherRelease ParseRelease(string json, string currentVersion)
        {
            var data = new JavaScriptSerializer().DeserializeObject(json) as Dictionary<string, object>;
            if (data == null) throw new SetupException("GitHub returned an invalid release response.");
            if (object.Equals(Util.Get(data, "draft"), true) || object.Equals(Util.Get(data, "prerelease"), true))
                return null;

            string tag = Util.Get(data, "tag_name") as string;
            var match = Regex.Match(tag ?? "", @"^artur-v([0-9]+\.[0-9]+\.[0-9]+)$", RegexOptions.CultureInvariant);
            if (!match.Success)
                throw new SetupException("The latest GitHub release has an unexpected version.", "Use the Artur Edition Releases page to install manually.");
            string number = match.Groups[1].Value;
            Version latest, current;
            if (!Version.TryParse(number, out latest) || !Version.TryParse(currentVersion, out current))
                throw new SetupException("The GitHub release version couldn't be read.");
            if (latest <= current) return null;

            string installer = "Windows-PC-Artur-Edition-" + number + "-Setup.exe";
            string checksum = installer + ".sha256";
            string prefix = Releases + tag + "/";
            string installerUrl = prefix + installer;
            string checksumUrl = prefix + checksum;
            var assets = Util.Get(data, "assets") as object[];
            if (assets == null)
                throw new SetupException("GitHub didn't provide the release download list.");

            bool foundInstaller = false, foundChecksum = false;
            foreach (object item in assets)
            {
                var asset = item as Dictionary<string, object>;
                if (asset == null) continue;
                string name = Util.Get(asset, "name") as string;
                string url = Util.Get(asset, "browser_download_url") as string;
                // Never follow a release-supplied URL to a different GitHub repository.
                if (name == installer && String.Equals(url, installerUrl, StringComparison.Ordinal))
                    foundInstaller = true;
                if (name == checksum && String.Equals(url, checksumUrl, StringComparison.Ordinal))
                    foundChecksum = true;
            }
            if (!foundInstaller || !foundChecksum)
                throw new SetupException("The new Artur Edition release is missing its Windows installer or checksum.",
                    "Download the release manually from the project's GitHub Releases page.");

            return new LauncherRelease { Number = number, FileName = installer,
                InstallerUrl = installerUrl, ChecksumUrl = checksumUrl };
        }

        public static LauncherRelease Check()
        {
            return ParseRelease(DownloadText(RepoApi, 512 * 1024), Program.Version);
        }

        static string ParseChecksum(string text, string expectedName)
        {
            var m = Regex.Match(text.Trim(), @"^([a-fA-F0-9]{64})[ \t]+\*?([A-Za-z0-9_.-]+)$", RegexOptions.CultureInvariant);
            if (!m.Success || !String.Equals(m.Groups[2].Value, expectedName, StringComparison.Ordinal))
                throw new SetupException("The release checksum doesn't match the update file name.",
                    "The launcher refused to run an unverified download.");
            return m.Groups[1].Value.ToLowerInvariant();
        }

        public static string DownloadVerified(LauncherRelease release, Action<int> progress)
        {
            if (release == null) throw new ArgumentNullException("release");
            // The only accepted filename comes from ParseRelease, not from arbitrary user input.
            if (release.FileName != "Windows-PC-Artur-Edition-" + release.Number + "-Setup.exe" ||
                release.InstallerUrl != Releases + "artur-v" + release.Number + "/" + release.FileName ||
                release.ChecksumUrl != release.InstallerUrl + ".sha256")
                throw new SetupException("The update URL couldn't be verified.");

            string expectedSha = ParseChecksum(DownloadText(release.ChecksumUrl, 2048), release.FileName);
            string baseDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "ArturEdition", "InstallerUpdates", release.Number + "-" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(baseDir);
            string partial = Path.Combine(baseDir, release.FileName + ".partial");
            string ready = Path.Combine(baseDir, release.FileName);
            try
            {
                var request = (HttpWebRequest)WebRequest.Create(release.InstallerUrl);
                request.UserAgent = "ArturEdition-Setup/" + Program.Version;
                request.Timeout = 30000;
                request.ReadWriteTimeout = 30000;
                using (var response = (HttpWebResponse)request.GetResponse())
                using (var source = response.GetResponseStream())
                using (var output = new FileStream(partial, FileMode.CreateNew, FileAccess.Write, FileShare.None))
                {
                    if (response.ContentLength > MaxInstallerBytes)
                        throw new SetupException("The update is larger than expected.");
                    byte[] buffer = new byte[64 * 1024];
                    long total = 0;
                    int n;
                    while ((n = source.Read(buffer, 0, buffer.Length)) > 0)
                    {
                        total += n;
                        if (total > MaxInstallerBytes)
                            throw new SetupException("The update exceeded the allowed file size.");
                        output.Write(buffer, 0, n);
                        if (progress != null && response.ContentLength > 0)
                            progress((int)Math.Min(99, total * 100 / response.ContentLength));
                    }
                    if (total == 0 || (response.ContentLength > 0 && total != response.ContentLength))
                        throw new SetupException("The update download was incomplete.");
                }
                using (var sha = SHA256.Create())
                using (var stream = File.OpenRead(partial))
                {
                    string actualSha = BitConverter.ToString(sha.ComputeHash(stream)).Replace("-", "").ToLowerInvariant();
                    if (!String.Equals(actualSha, expectedSha, StringComparison.Ordinal))
                        throw new SetupException("The downloaded installer failed its SHA-256 check.",
                            "The launcher refused to run the file. Try again or use the GitHub Releases page.");
                }
                File.Move(partial, ready);
                if (progress != null) progress(100);
                return ready;
            }
            catch
            {
                try { Directory.Delete(baseDir, true); } catch { }
                throw;
            }
        }

        // Offline regression tests: no GitHub access and no process launch.
        public static int SelfTest()
        {
            try
            {
                string tag = "artur-v0.14.4";
                string file = "Windows-PC-Artur-Edition-0.14.4-Setup.exe";
                string url = Releases + tag + "/" + file;
                var release = new Dictionary<string, object> {
                    { "tag_name", tag },
                    { "draft", false },
                    { "prerelease", false },
                    { "assets", new object[] {
                        new Dictionary<string, object> { { "name", file }, { "browser_download_url", url } },
                        new Dictionary<string, object> { { "name", file + ".sha256" }, { "browser_download_url", url + ".sha256" } }
                    } }
                };
                var js = new JavaScriptSerializer();
                string data = js.Serialize(release);
                LauncherRelease newest = ParseRelease(data, "0.14.3");
                if (newest == null || newest.Number != "0.14.4" || newest.InstallerUrl != url)
                    throw new Exception("New release wasn't recognized.");
                if (ParseRelease(data, "0.14.4") != null || ParseRelease(data, "0.14.5") != null)
                    throw new Exception("An old/equal release was offered.");
                release["prerelease"] = true;
                if (ParseRelease(js.Serialize(release), "0.14.3") != null)
                    throw new Exception("A prerelease was offered.");
                release["prerelease"] = false;
                var entries = (object[])release["assets"];
                var installer = (Dictionary<string, object>)entries[0];
                installer["browser_download_url"] = url.Replace("shadow159043", "someoneelse");
                bool rejected = false;
                try { ParseRelease(js.Serialize(release), "0.14.3"); }
                catch (SetupException) { rejected = true; }
                if (!rejected) throw new Exception("Untrusted repository URL was accepted.");
                string hash = new string('a', 64);
                if (ParseChecksum(hash + "  " + file + "\n", file) != hash)
                    throw new Exception("Valid checksum failed.");
                rejected = false;
                try { ParseChecksum(hash + "  wrong-file.exe", file); }
                catch (SetupException) { rejected = true; }
                if (!rejected) throw new Exception("Mismatched checksum filename was accepted.");
                return 0;
            }
            catch (Exception error)
            {
                System.Diagnostics.Debug.WriteLine("Launcher update self-test failed: " + error);
                return 1;
            }
        }
    }
}
