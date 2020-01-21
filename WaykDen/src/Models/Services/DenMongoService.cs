using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Docker.DotNet.Models;
using WaykDen.Controllers;

namespace WaykDen.Models.Services
{
    public class DenMongoService : DenService
    {
        public const string MONGO_NAME = "den-mongo";
        private const string MONGO_LINUX_PATH = "/data/db";
        private const string MONGO_WINDOWS_PATH = "c:\\data\\db";
    
        public DenMongoService()
        {
        }

        public DenMongoService(DenServicesController controller):base(controller, MONGO_NAME)
        {
            this.ImageName = this.DenConfig.DenImageConfigObject.DenMongoImage;
            Task.Run(async delegate
            {
                if(!await this.CheckVolumeExist())
                {
                    VolumeResponse volume = await this.CreateVolume();
                }
            });

            string mountPoint = this.DenConfig.DenDockerConfigObject.Platform == Platforms.Linux.ToString() ? MONGO_LINUX_PATH : MONGO_WINDOWS_PATH;

            this.Volumes.Add($"{this.Name}data:{mountPoint}");
        }

        public override async Task<CreateContainerResponse> CreateContainer(string image)
        {
            LogConfig logConfig = new LogConfig();

            return await this.DockerClient.Containers.CreateContainerAsync
            (
                new CreateContainerParameters
                (
                    new Docker.DotNet.Models.Config()
                    {
                        Image = image,
                        Env = this.Env,
                        Cmd = this.Cmd,
                        ExposedPorts = this.ExposedPorts,
                        AttachStderr = false,
                        AttachStdin = false,
                        AttachStdout = true,
                    }
                )
                {
                    Name = this.Name,
                    HostConfig = new HostConfig()
                    {
                        PortBindings = this.PortBindings,
                        AutoRemove = false,
                        Binds = this.Volumes,
                        LogConfig = this.LogConfig,
                        Isolation = this.DenConfig.DenDockerConfigObject.Platform == Platforms.Windows.ToString() ? "process" : string.Empty,
                    },
                    NetworkingConfig = new NetworkingConfig()
                    {
                        EndpointsConfig = new Dictionary<string, EndpointSettings>
                        {
                            {"den-network", new EndpointSettings()
                                {
                                    NetworkID = this.DenServicesController.DenNetwork.NetworkId
                                }
                            }
                        }
                    }
                }
            );
        }

        public bool IsExternal => this.DenConfig.DenMongoConfigObject.IsExternal;
    }
}