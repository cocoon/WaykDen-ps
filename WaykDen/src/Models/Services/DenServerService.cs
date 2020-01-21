using System.IO;
using WaykDen.Utils;
using WaykDen.Controllers;
using System;
using System.Management.Automation;
using System.Threading;

namespace WaykDen.Models.Services
{
    public class DenServerService : DenHealthCheckService
    {
        public const string DENSERVER_NAME = "den-server";

        private const string DEN_PRIVATE_KEY_FILE_ENV = "DEN_PRIVATE_KEY_FILE";
        private const string DEN_PUBLIC_KEY_FILE_ENV = "DEN_PUBLIC_KEY_FILE";
        private const string PICKY_REALM_ENV = "PICKY_REALM";
        private const string PICKY_URL_ENV = "PICKY_URL";
        private const string PICKY_API_KEY_ENV = "PICKY_APIKEY";
        private const string AUDIT_TRAILS_ENV = "AUDIT_TRAILS";
        private const string LUCID_AUTHENTICATION_KEY_ENV = "LUCID_AUTHENTICATION_KEY";
        private const string ROUTER_EXTERNAL_URL_ENV = "DEN_ROUTER_EXTERNAL_URL";
        private const string LUCID_INTERNAL_URL_ENV = "LUCID_INTERNAL_URL";
        private const string LUCID_EXTERNAL_URL_ENV = "LUCID_EXTERNAL_URL";
        private const string JET_SERVER_URL_ENV = "JET_SERVER_URL";
        private const string JET_RELAY_URL_ENV = "JET_RELAY_URL";
        private const string LDAP_SERVER_URL_ENV = "LDAP_SERVER_URL";
        private const string LDAP_USERNAME_ENV = "LDAP_USERNAME";
        private const string LDAP_PASSWORD_ENV = "LDAP_PASSWORD";
        private const string LDAP_USER_GROUP_ENV = "LDAP_USER_GROUP";
        private const string LDAP_SERVER_TYPE_ENV = "LDAP_SERVER_TYPE";
        private const string LDAP_BASE_DN_ENV = "LDAP_BASE_DN";
        private const string PICKY_URL = "http://den-picky:12345";
        private const string LUCID_INTERNAL_URL = "http://den-lucid:4242";
        private const string DEN_API_KEY_ENV = "DEN_API_KEY";
        private const string DEN_LOGIN_REQUIRED_ENV = "DEN_LOGIN_REQUIRED";
        private const string DEN_SERVER_LINUX_PATH = "/etc/den-server";
        private const string DEN_SERVER_WINDOWS_PATH = "c:\\den-server";
        private const string NATS_HOST = "NATS_HOST";
        private const string NATS_USERNAME = "NATS_USERNAME";
        private const string NATS_PASSWORD = "NATS_PASSWORD";
        private const string REDIS_HOST = "REDIS_HOST";
        private const string REDIS_PASSWORD = "REDIS_PASSWORD";

        public DenServerService(DenServicesController controller, bool multipleInstance = false, int instanceId = 1) :base(controller, instanceId == 1 ? DENSERVER_NAME : DENSERVER_NAME + "_" + instanceId)
        {
            this.ImageName = this.DenConfig.DenImageConfigObject.DenServerImage;
            string healthCheck = "curl -sS http://" + (instanceId == 1 ? DENSERVER_NAME : DENSERVER_NAME+ "_" + instanceId) + ":10255/health";
            this.HealthCheck.Add(healthCheck);

            string externalRouterUrl = this.DenConfig.DenServerConfigObject.ExternalUrl;
            if(externalRouterUrl.StartsWith("https"))
            {
                externalRouterUrl = externalRouterUrl.Replace("https", "wss");
            } else externalRouterUrl = externalRouterUrl.Replace("http", "ws");

            
            this.Env.Add($"{PICKY_REALM_ENV}={this.DenConfig.DenPickyConfigObject.Realm}");
            this.Env.Add($"{PICKY_URL_ENV}={PICKY_URL}");
            this.Env.Add($"{PICKY_API_KEY_ENV}={this.DenConfig.DenPickyConfigObject.ApiKey}");
            this.Env.Add($"{AUDIT_TRAILS_ENV}={this.DenConfig.DenServerConfigObject.AuditTrails}");
            this.Env.Add($"{LUCID_AUTHENTICATION_KEY_ENV}={this.DenConfig.DenLucidConfigObject.ApiKey}");
            this.Env.Add($"{ROUTER_EXTERNAL_URL_ENV}={externalRouterUrl}/cow");
            this.Env.Add($"{LUCID_INTERNAL_URL_ENV}={LUCID_INTERNAL_URL}");
            this.Env.Add($"{LUCID_EXTERNAL_URL_ENV}={this.DenConfig.DenServerConfigObject.ExternalUrl}/lucid");
            this.Env.Add($"{DEN_LOGIN_REQUIRED_ENV}={this.DenConfig.DenServerConfigObject.LoginRequired.ToLower()}");

            if ((this.DenConfig.DenServerConfigObject.PrivateKey != null && this.DenConfig.DenServerConfigObject.PrivateKey.Length > 0) &&
            (this.DenConfig.DenServerConfigObject.PublicKey != null && this.DenConfig.DenServerConfigObject.PublicKey.Length > 0))
            {
                this.ImportKey();
            }

            if (!string.IsNullOrEmpty(this.DenConfig.DenServerConfigObject.LDAPUsername))
            {
                this.Env.Add($"{LDAP_USERNAME_ENV}={this.DenConfig.DenServerConfigObject.LDAPUsername}");
            }

            if(!string.IsNullOrEmpty(this.DenConfig.DenServerConfigObject.LDAPPassword))
            {
                this.Env.Add($"{LDAP_PASSWORD_ENV}={this.DenConfig.DenServerConfigObject.LDAPPassword}");                
            }

            if(!string.IsNullOrEmpty(this.DenConfig.DenServerConfigObject.LDAPServerUrl))
            {
                this.Env.Add($"{LDAP_SERVER_URL_ENV}={this.DenConfig.DenServerConfigObject.LDAPServerUrl}");    
            }
            
            if(!string.IsNullOrEmpty(this.DenConfig.DenServerConfigObject.LDAPUserGroup))
            {
                this.Env.Add($"{LDAP_USER_GROUP_ENV}={this.DenConfig.DenServerConfigObject.LDAPUserGroup}");   
            }

            if(!string.IsNullOrEmpty(this.DenConfig.DenServerConfigObject.JetServerUrl))
            {
                this.Env.Add($"{JET_SERVER_URL_ENV}={this.DenConfig.DenServerConfigObject.JetServerUrl}");
            }

            if(!string.IsNullOrEmpty(this.DenConfig.DenServerConfigObject.JetRelayUrl))
            {
                this.Env.Add($"{JET_RELAY_URL_ENV}={this.DenConfig.DenServerConfigObject.JetRelayUrl}");
            }

            if(!string.IsNullOrEmpty(this.DenConfig.DenServerConfigObject.LDAPBaseDN))
            {
                this.Env.Add($"{LDAP_BASE_DN_ENV}={this.DenConfig.DenServerConfigObject.LDAPBaseDN}");
            }

            if(!string.IsNullOrEmpty(this.DenConfig.DenServerConfigObject.LDAPServerType))
            {
                this.Env.Add($"{LDAP_SERVER_TYPE_ENV}={this.DenConfig.DenServerConfigObject.LDAPServerType}");
            }

            this.Env.Add($"{DEN_API_KEY_ENV}={this.DenConfig.DenServerConfigObject.ApiKey}");
            this.Cmd.Add("--db_url");
            this.Cmd.Add(this.DenConfig.DenMongoConfigObject.Url);
            this.Cmd.Add("-m");
            this.Cmd.Add("onprem");

            string natsHost = string.Empty;
            string redisHost = string.Empty;

            using (PowerShell PowerShellInstance = PowerShell.Create())
            {
                PowerShellInstance.AddScript("docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' den-nats");
                var result = PowerShellInstance.Invoke();
                foreach (var item in result)
                {
                    natsHost = item.ToString();
                }
            }
            using (PowerShell PowerShellInstance = PowerShell.Create())
            {
                PowerShellInstance.AddScript("docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' den-redis");
                var result = PowerShellInstance.Invoke();
                foreach (var item in result)
                {
                    redisHost = item.ToString();
                }
            }

            if (multipleInstance) {
                if (!string.IsNullOrEmpty(natsHost)
                    && !string.IsNullOrEmpty(this.DenConfig.DenServerConfigObject.NatsUsername)
                    && !string.IsNullOrEmpty(this.DenConfig.DenServerConfigObject.NatsPassword)
                    && !string.IsNullOrEmpty(redisHost)
                    && !string.IsNullOrEmpty(this.DenConfig.DenServerConfigObject.RedisPassword))
                {
                    this.Env.Add($"{NATS_HOST}={natsHost}");
                    this.Env.Add($"{NATS_USERNAME}={this.DenConfig.DenServerConfigObject.NatsUsername}");
                    this.Env.Add($"{NATS_PASSWORD}={this.DenConfig.DenServerConfigObject.NatsPassword}");

                    this.Env.Add($"{REDIS_HOST}={redisHost}");
                    this.Env.Add($"{REDIS_PASSWORD}={this.DenConfig.DenServerConfigObject.RedisPassword}");
                }
                else {
                    throw new Exception("Den server can't be launched with multiple instances. NATS and REDIS configuration have to be provided.");
                }
            }

            this.Cmd.Add("-l");
            this.Cmd.Add("trace");
        }

        private void ImportKey()
        {
            this.DenServicesController.Path = this.DenServicesController.Path.TrimEnd(System.IO.Path.DirectorySeparatorChar);
            string path = $"{this.DenServicesController.Path}{System.IO.Path.DirectorySeparatorChar}den-server";

            if(!Directory.Exists(path))
            {
                Directory.CreateDirectory(path);
            }

            File.WriteAllText($"{path}{System.IO.Path.DirectorySeparatorChar}den-server.key", KeyCertUtils.DerToPem(this.DenConfig.DenServerConfigObject.PrivateKey));
            File.WriteAllText($"{path}{System.IO.Path.DirectorySeparatorChar}den-router.key", KeyCertUtils.DerToPem(this.DenConfig.DenServerConfigObject.PublicKey));
            string mountPoint = this.DenConfig.DenDockerConfigObject.Platform == Platforms.Linux.ToString() ? DEN_SERVER_LINUX_PATH : DEN_SERVER_WINDOWS_PATH;
            this.Volumes.Add($"den-server:{mountPoint}:ro");
            this.Env.Add($"{DEN_PRIVATE_KEY_FILE_ENV}={mountPoint}/den-server.key");
            this.Env.Add($"{DEN_PUBLIC_KEY_FILE_ENV}={mountPoint}/den-router.key");
        }
    }
}