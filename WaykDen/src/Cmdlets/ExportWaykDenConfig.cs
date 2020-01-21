using System;
using System.IO;
using System.Management.Automation;
using WaykDen.Controllers;
using WaykDen.Models;

namespace WaykDen.Cmdlets
{
    [Cmdlet("Export", "WaykDenConfig")]
    public class ExportWaykDenConfig : WaykDenConfigCmdlet
    {
        private const string DOCKER_COMPOSE_FILENAME = "docker-compose.yml";
        private const string DOCKER_SCRIPT_FILENAME = "wayk-den.ps1";
        private const string TRAEFIK_TOML_FILENAME = "traefik.toml";
        [Parameter(HelpMessage = "Path where to export WaykDen configuration.")]
        public string ExportPath {get; set;} = string.Empty;
        [Parameter(HelpMessage = "Export in a docker-compose.yaml file. (A traefik.toml will also be exported)")]
        public SwitchParameter DockerCompose {get; set;} = false;
        [Parameter(HelpMessage = "Export traefik.toml only for Traefik.")]
        public SwitchParameter TraefikToml {get; set;} = false;
        [Parameter(HelpMessage = "Export in a script using Docker.")]
        public SwitchParameter DockerScript {get; set;} = false;
        [Parameter(HelpMessage = "Export in a script using Podman")]
        public SwitchParameter PodmanScript {get; set;} = false;
        public ExportWaykDenConfig()
        {
        }

        protected override void ProcessRecord()
        {
            try
            {
                DenServicesController denServicesController = new DenServicesController(this.Path, this.DenConfigController);
                denServicesController.OnLog += this.OnLog;
                denServicesController.OnError += this.OnError;

                if(string.IsNullOrEmpty(this.ExportPath))
                {
                    this.ExportPath = this.SessionState.Path.CurrentLocation.Path;
                }

                this.ExportPath = this.ExportPath.TrimEnd(System.IO.Path.DirectorySeparatorChar);

                if(DockerCompose)
                {
                    string traefikExportPath = $"{this.Path}{System.IO.Path.DirectorySeparatorChar}traefik/";
                    Directory.CreateDirectory(traefikExportPath);
                    string[] exports = denServicesController.CreateDockerCompose();
                    File.WriteAllText($"{this.ExportPath}{System.IO.Path.DirectorySeparatorChar}{DOCKER_COMPOSE_FILENAME}", exports[0]);
                    File.WriteAllText($"{traefikExportPath}{TRAEFIK_TOML_FILENAME}", exports[1]);
                }
                else if(this.TraefikToml)
                {
                    File.WriteAllText($"{this.ExportPath}{System.IO.Path.DirectorySeparatorChar}traefik{System.IO.Path.DirectorySeparatorChar}{TRAEFIK_TOML_FILENAME}", denServicesController.CreateTraefikToml());
                }
                else if(this.DockerScript || this.PodmanScript)
                {
                    this.ExportPath = $"{this.ExportPath}{System.IO.Path.DirectorySeparatorChar}WaykDen";
                    
                    if(!Directory.Exists(this.ExportPath))
                    {
                        Directory.CreateDirectory(this.ExportPath);
                    }

                    if(this.DockerScript)
                    {
                        File.WriteAllText($"{this.ExportPath}{System.IO.Path.DirectorySeparatorChar}{DOCKER_SCRIPT_FILENAME}", denServicesController.CreateScript(this.ExportPath, false, string.Equals(denServicesController.DenConfig.DenDockerConfigObject.Platform, "Linux") ? Platforms.Linux : Platforms.Windows));
                    }
                    else File.WriteAllText($"{this.ExportPath}{System.IO.Path.DirectorySeparatorChar}{DOCKER_SCRIPT_FILENAME}", denServicesController.CreateScript(this.ExportPath, true, string.Equals(denServicesController.DenConfig.DenDockerConfigObject.Platform, "Linux") ? Platforms.Linux : Platforms.Windows));
                }
            }
            catch(Exception e)
            {
                this.OnError(e);
            }
        }
    }
}