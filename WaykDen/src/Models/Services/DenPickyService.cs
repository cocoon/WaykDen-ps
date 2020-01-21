using System.Collections.Generic;
using System.Management.Automation;
using Docker.DotNet.Models;
using WaykDen.Controllers;

namespace WaykDen.Models.Services
{
    [Cmdlet("Start", "Picky")]
    public class DenPickyService : DenService
    {
        public const string DENPICKY_NAME = "den-picky";
        private const string PICKY_DB_URL_ENV = "PICKY_DATABASE_URL";
        private const string PICKY_API_KEY_ENV = "PICKY_API_KEY";
        private const string PICKY_REALM_ENV = "PICKY_REALM";

        public DenPickyService(DenServicesController controller):base(controller, DENPICKY_NAME)
        {
            this.ImageName = this.DenConfig.DenImageConfigObject.DenPickyImage;

            List<string> env = new List<string>{
                $"{PICKY_REALM_ENV}={this.DenConfig.DenPickyConfigObject.Realm}",
                $"{PICKY_API_KEY_ENV}={this.DenConfig.DenPickyConfigObject.ApiKey}",
                $"{PICKY_DB_URL_ENV}={this.DenConfig.DenMongoConfigObject.Url}"};

            this.Env = env;
        }
    }
}