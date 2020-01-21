using System.Collections.Generic;
using System.IO;
using Docker.DotNet.Models;
using WaykDen.Controllers;
using WaykDen.Utils;

namespace WaykDen.Models.Services
{
    public class DenTraefikService : DenService
    {
        private const string TRAEFIK_NAME = "traefik";
        private const string TRAEFIK_FILE_CMD = "--file";
        private const string TRAEFIK_FILE_PATH_CMD_LINUX = "--configFile=/etc/traefik/traefik.toml";
        private const string TRAEFIK_FILE_PATH_CMD_WINDOWS = "--configFile=c:\\etc\\traefik\\traefik.toml";
        private const string TRAEFIK_LINUX_PATH = "/etc/traefik";
        private const string TRAEFIK_WINDOWS_PATH = "c:\\etc\\traefik";
        public string Tls = string.Empty;
        public string Entrypoints = "ws";
        public string WaykDenPort => this.DenConfig.DenTraefikConfigObject.WaykDenPort;

        public DenTraefikService(DenServicesController controller, int instanceCount = 1) :base(controller, TRAEFIK_NAME)
        {
            this.ImageName = this.DenConfig.DenImageConfigObject.DenTraefikImage;
            this.ExposedPorts.Add(this.WaykDenPort, new EmptyStruct());
            this.PortBindings.Add(this.WaykDenPort, new List<PortBinding>(){new PortBinding(){HostIP = "0.0.0.0", HostPort = this.WaykDenPort}});
            
            string mountPoint = this.DenConfig.DenDockerConfigObject.Platform == Platforms.Linux.ToString() ? TRAEFIK_LINUX_PATH : TRAEFIK_WINDOWS_PATH;
            string configFile = this.DenConfig.DenDockerConfigObject.Platform == Platforms.Linux.ToString() ? TRAEFIK_FILE_PATH_CMD_LINUX : TRAEFIK_FILE_PATH_CMD_WINDOWS;
            string path = $"{this.DenServicesController.Path}{System.IO.Path.DirectorySeparatorChar}traefik";
            this.Volumes.Add($"traefik:{mountPoint}");
            if(Directory.Exists(path))
            {
              Directory.Delete(path, true);
            }

            Directory.CreateDirectory(path);

            if(!string.IsNullOrEmpty(this.DenConfig.DenTraefikConfigObject.Certificate) && !string.IsNullOrEmpty(this.DenConfig.DenTraefikConfigObject.PrivateKey))
            {
              this.Entrypoints = "https";
              this.ImportCertificate();
            }

            string traefikToml = ExportDenConfigUtils.CreateTraefikToml(this, instanceCount);
            File.WriteAllText($"{path}{System.IO.Path.DirectorySeparatorChar}traefik.toml", traefikToml);
            
            
            this.Cmd.Add(TRAEFIK_FILE_CMD);
            this.Cmd.Add(configFile);
        }

        private void ImportCertificate()
        {
          this.DenServicesController.Path.TrimEnd(System.IO.Path.DirectorySeparatorChar);
          string path = $"{this.DenServicesController.Path}{System.IO.Path.DirectorySeparatorChar}traefik";
          File.WriteAllText($"{path}{System.IO.Path.DirectorySeparatorChar}traefik.pem", this.DenConfig.DenTraefikConfigObject.Certificate);
          File.WriteAllText($"{path}{System.IO.Path.DirectorySeparatorChar}traefik.key", this.DenConfig.DenTraefikConfigObject.PrivateKey);
          string https = 
@"[entryPoints.https.tls]
          [entryPoints.https.tls.defaultCertificate]
          certFile = ""{0}{1}traefik.pem""
          keyFile = ""{0}{1}traefik.key""
    ";
              string mountPoint = this.DenConfig.DenDockerConfigObject.Platform == Platforms.Linux.ToString() ? TRAEFIK_LINUX_PATH : TRAEFIK_WINDOWS_PATH;
              this.Tls = string.Format(https, mountPoint, System.IO.Path.DirectorySeparatorChar);
        }
    }
}