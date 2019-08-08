using System;
using System.IO;
using WaykDen.Utils;
using WaykDen.Controllers;

namespace WaykDen.Models.Services
{
    public class DenRouterService : DenService
    {
        public const string DENROUTER_NAME = "den-router";
        private const string DEN_PUBLIC_KEY_FILE_ENV = "DEN_PUBLIC_KEY_FILE";
        private const string DEN_ROUTER_LINUX_PATH = "/etc/den-router";
        private const string DEN_ROUTER_WINDOWS_PATH = "c:\\den-router";

        public DenRouterService(DenServicesController controller):base(controller, DENROUTER_NAME)
        {
            this.ImageName = this.DenConfig.DenImageConfigObject.DenRouterImage;

            if(this.DenConfig.DenRouterConfigObject.PublicKey != null && this.DenConfig.DenRouterConfigObject.PublicKey.Length > 0)
            {
                this.ImportKey();
            }
        }

        private void ImportKey()
        {
            this.DenServicesController.Path = this.DenServicesController.Path.TrimEnd(System.IO.Path.DirectorySeparatorChar);
            string path = $"{this.DenServicesController.Path}{System.IO.Path.DirectorySeparatorChar}den-router";
            
            if(!Directory.Exists(path))
            {
                Directory.CreateDirectory(path);
            }

            File.WriteAllText($"{path}{System.IO.Path.DirectorySeparatorChar}den-router.key", RsaKeyutils.DerToPem(this.DenConfig.DenRouterConfigObject.PublicKey));
            string mountPoint = this.DenConfig.DenDockerConfigObject.Platform == Platforms.Linux.ToString() ? DEN_ROUTER_LINUX_PATH : DEN_ROUTER_WINDOWS_PATH;
            this.Volumes.Add($"den-router:{mountPoint}");
            this.Env.Add($"{DEN_PUBLIC_KEY_FILE_ENV}={mountPoint}{System.IO.Path.DirectorySeparatorChar}den-router.key");
        }
    }
}