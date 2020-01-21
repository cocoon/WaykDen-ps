using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using WaykDen.Controllers;
using WaykDen.Models;

namespace WaykDen.Cmdlets
{
    [Cmdlet(VerbsCommon.Set, "WaykDenConfig")]
    public class SetWaykDenConfig : WaykDenConfigCmdlet
    {
        [Parameter(HelpMessage = "Url of a running MongoDB instance.")]
        public string MongoUrl {get; set;}= string.Empty;

        [Parameter(HelpMessage = "Name of a domain for WaykDen. (Not a DNS domain)")]
        public string Realm {get; set;}= string.Empty;

        [Parameter(HelpMessage = "WaykDen server external URL."), ValidatePattern("^(?:http(s)?:\\/\\/).*")]
        public string ExternalUrl {get; set;}= string.Empty;

        [Parameter(HelpMessage = "LDAP or AD server URL")]
        public string LDAPServerUrl {get; set;} = string.Empty;

        [Parameter(HelpMessage = "Specify a username with read access on AD.")]
        public string LDAPUsername {get; set;} = string.Empty;

        [Parameter(HelpMessage = "Password of the user with read access on AD.")]
        public string LDAPPassword {get; set;} = string.Empty;

        [Parameter(HelpMessage = " Group of users who can be authenticated on WaykDen.")]
        public string LDAPUserGroup {get; set;} = string.Empty;

        [Parameter(HelpMessage = "Type of LDAP server. ActiveDirectory to use AD integration; JumpCloud to use JumpCloud integration"),
         ValidateSet(new string[]{"ActiveDirectory", "JumpCloud"})]
        public string LDAPServerType {get; set;} = string.Empty;

        [Parameter(HelpMessage = "Base DN is the Distinguished Named (DN) where all users and groups can be found. Example: Exemple : ou=Users,o=YOUR_ORG_ID,dc=jumpcloud,dc=com")]
        public string LDAPBaseDN {get; set;} = string.Empty;

        [Parameter(HelpMessage = "Devolutions Jet URL")]
        public string JetServerUrl {get; set;} = string.Empty;

        [Parameter(HelpMessage = "URL where Devolutions Jet will be listening (http listener).")]
        public string JetRelayUrl { get; set; } = string.Empty;

        [Parameter(HelpMessage = "Docker client endpoint URI.")]
        public string DockerClientUri {get; set;}= string.Empty;

        [Parameter(HelpMessage = "Port where WaykDen server will be listening.")]
        public string WaykDenPort {get; set;}= string.Empty;

        public string Certificate {get; set;} = string.Empty;

        public string PrivateKey {get; set;} = string.Empty;

        [Parameter(HelpMessage = "Force the Wayk client to be logged and authenticated. WaykDen will give an ID only if the user is authenticated."), ValidateSet(new string[]{"True", "False"})]
        public string LoginRequired {get; set;} = string.Empty;

        [Parameter(HelpMessage = "Use Linux or Windows  container."), ValidateSet(new string[]{"Linux", "Windows"})]
        public string Platform {get; set;} = string.Empty;

        [Parameter(HelpMessage = "URL of a syslog server.")]
        public string SyslogServer {get; set;} = string.Empty;

        [Parameter(HelpMessage = "Username for Nats container.")]
        public string NatsUsername { get; set; } = string.Empty;

        [Parameter(HelpMessage = "Password for Nats container.")]
        public string NatsPassword { get; set; } = string.Empty;

        [Parameter(HelpMessage = "Password for Redis container.")]
        public string RedisPassword { get; set; } = string.Empty;

        [Parameter(HelpMessage = "Remove parameter"), ValidateSet(
            new string[]
            {
                "MongoUrl",
                "Realm",
                "ExternalUrl",
                "LDAPServerUrl",
                "LDAPUsername",
                "LDAPPassword",
                "LDAPUserGroup",
                "LDAPServerType",
                "LDAPBaseDN",
                "DockerClientUri",
                "WaykDenPort",
                "Certificate",
                "PrivateKey",
                "SyslogServer",
                "JetServerUrl",
                "JetRelayUrl",
                "NatsUsername",
                "NatsPassword",
                "RedisPassword"

            }
        )]

        public string[] Remove {get; set;} = null;

        private Dictionary<string, (Type, string)> dictionary;

        public SetWaykDenConfig()
        {
            this.dictionary = new Dictionary<string, (Type, string)>
            {
                {nameof(this.DockerClientUri), (typeof(DenDockerConfigObject), "DockerClientUri")},
                {nameof(this.Platform), (typeof(DenDockerConfigObject), "Platform")},
                {nameof(this.SyslogServer), (typeof(DenDockerConfigObject), "SyslogServer")},
                {nameof(this.MongoUrl), (typeof(DenMongoConfigObject), "Url")},
                {nameof(this.Realm), (typeof(DenPickyConfigObject), "Realm")},
                {nameof(this.ExternalUrl), (typeof(DenServerConfigObject), "ExternalUrl")},
                {nameof(this.LDAPPassword), (typeof(DenServerConfigObject), "LDAPPassword")},
                {nameof(this.LDAPUsername), (typeof(DenServerConfigObject), "LDAPUsername")},
                {nameof(this.LDAPServerUrl), (typeof(DenServerConfigObject), "LDAPServerUrl")},
                {nameof(this.LDAPUserGroup), (typeof(DenServerConfigObject), "LDAPUserGroup")},
                {nameof(this.LDAPServerType), (typeof(DenServerConfigObject), "LDAPServerType")},
                {nameof(this.LDAPBaseDN), (typeof(DenServerConfigObject), "LDAPBaseDN")},
                {nameof(this.JetServerUrl), (typeof(DenServerConfigObject), "JetServerUrl")},
                {nameof(this.JetRelayUrl), (typeof(DenServerConfigObject), "JetRelayUrl")},
                {nameof(this.LoginRequired), (typeof(DenServerConfigObject), "LoginRequired")},
                {nameof(this.WaykDenPort), (typeof(DenTraefikConfigObject), "WaykDenPort")},
                {nameof(this.Certificate), (typeof(DenTraefikConfigObject), "Certificate")},
                {nameof(this.PrivateKey), (typeof(DenTraefikConfigObject), "PrivateKey")},
                {nameof(this.NatsUsername), (typeof(DenServerConfigObject), "NatsUsername")},
                {nameof(this.NatsPassword), (typeof(DenServerConfigObject), "NatsPassword")},
                {nameof(this.RedisPassword), (typeof(DenServerConfigObject), "RedisPassword")},

            };
        }

        protected override void ProcessRecord()
        {
            try
            { 
                (string, bool)[] values =
                {
                    (nameof(this.DockerClientUri), !string.IsNullOrEmpty(this.DockerClientUri)),
                    (nameof(this.Platform), !string.IsNullOrEmpty(this.Platform)),
                    (nameof(this.SyslogServer), !string.IsNullOrEmpty(this.SyslogServer)),
                    (nameof(this.MongoUrl), !string.IsNullOrEmpty(this.MongoUrl)),
                    (nameof(this.Realm), !string.IsNullOrEmpty(this.Realm)),
                    (nameof(this.ExternalUrl), !string.IsNullOrEmpty(this.ExternalUrl)),
                    (nameof(this.LDAPPassword), !string.IsNullOrEmpty(this.LDAPPassword)),
                    (nameof(this.LDAPServerUrl), !string.IsNullOrEmpty(this.LDAPServerUrl)),
                    (nameof(this.LDAPUserGroup), !string.IsNullOrEmpty(this.LDAPUserGroup)),
                    (nameof(this.LDAPUsername), !string.IsNullOrEmpty(this.LDAPUsername)),
                    (nameof(this.LDAPServerType), !string.IsNullOrEmpty(this.LDAPServerType)),
                    (nameof(this.LDAPBaseDN), !string.IsNullOrEmpty(this.LDAPBaseDN)),
                    (nameof(this.JetServerUrl), !string.IsNullOrEmpty(this.JetServerUrl)),
                    (nameof(this.JetRelayUrl), !string.IsNullOrEmpty(this.JetRelayUrl)),
                    (nameof(this.LoginRequired), !string.IsNullOrEmpty(this.LoginRequired)),
                    (nameof(this.WaykDenPort), !string.IsNullOrEmpty(this.WaykDenPort)),
                    (nameof(this.NatsUsername), !string.IsNullOrEmpty(this.NatsUsername)),
                    (nameof(this.NatsPassword), !string.IsNullOrEmpty(this.NatsPassword)),
                    (nameof(this.RedisPassword), !string.IsNullOrEmpty(this.RedisPassword)),

                };

                (string, bool)[] names = values.Where(x => x.Item2.Equals(true)).ToArray();

                if(names.Length == 0 && this.Remove == null)
                {
                    return;
                }

                DenConfigController denConfigController = new DenConfigController(this.Path);
                DenConfig config = denConfigController.GetConfig();

                if(this.Remove != null)
                {
                    foreach(string name in this.Remove)
                    {
                        bool ok = this.dictionary.TryGetValue(name, out var value);

                        if(!ok)
                        {
                            continue;
                        }

                        var property = config.GetType().GetProperty(value.Item1.Name).GetValue(config);
                        property.GetType().GetProperty(value.Item2).SetValue(property, null);
                    }
                }
                else
                {
                    foreach((string, bool) name in names)
                    {
                        bool ok = this.dictionary.TryGetValue(name.Item1, out var value);
                        if(!ok)
                        {
                            continue;
                        }

                        var property = config.GetType().GetProperty(value.Item1.Name).GetValue(config);
                        var newValue = this.GetType().GetProperty(name.Item1).GetValue(this);
                        property.GetType().GetProperty(value.Item2).SetValue(property, newValue);
                    }
                }

                denConfigController.StoreConfig(config);
            }
            catch(Exception e)
            {
                this.OnError(e);
            }
        }
    }
}