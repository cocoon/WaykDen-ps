using System;
using System.IO;
using System.Linq;
using LiteDB;
using WaykDen.Models;
using WaykDen.Utils;

namespace WaykDen.Controllers
{
    public class DenConfigController
    {
        private const string DEFAULT_MONGO_URL = "mongodb://den-mongo:27017";
        private const string DEFAULT_JET_SERVER_URL = "api.jet-relay.net:8080";
        private const string DEFAULT_JET_RELAY_URL = "https://api.jet-relay.net";
        private const string DEN_MONGO_CONFIG_COLLECTION = "DenMongoConfig";
        private const string DEN_PICKY_CONFIG_COLLECTION = "DenPickyConfig";
        private const string DEN_LUCID_CONFIG_COLLECTION = "DenLucidConfig";
        private const string DEN_SERVER_CONFIG_COLLECTION = "DenServerConfig";
        private const string DEN_TRAEFIK_CONFIG_COLLECTION = "DenTraefikConfig";
        private const string DEN_DOCKER_CONFIG_COLLECTION = "DenDockerConfig";
        private const int DB_ID = 1;
        private string path;
        private string connString = string.Empty;
        public DenConfigController(string path)
        {
            this.path = $"{path}/WaykDen.db";
            this.connString = $"Filename={this.path}; Mode=Exclusive";
            if(File.Exists(this.path))
            {
                this.TestConnString();
            }

            BsonMapper.Global.EmptyStringToNull = false;
        }

        private void TestConnString()
        {
            try
            {
                using(var db = new LiteDatabase(this.connString))
                {
                    var collections = db.GetCollectionNames();
                }
            }
            catch(Exception)
            {
                throw new Exception("Invalid database password.");
            }
        }

        public bool DbExists
        {
            get
            {
                if(!File.Exists(this.path))
                {
                    return false;
                }

                using(var db = new LiteDatabase(this.connString))
                {
                    var collections = db.GetCollectionNames().ToArray();
                    if(collections.Length > 0)
                    {
                        return true;
                    }
                    return false;
                }
            }
        }

        public void StoreConfig(DenConfig config)
        {
            using(var db = new LiteDatabase(this.connString))
            {
                if(db.CollectionExists(DEN_MONGO_CONFIG_COLLECTION))
                {
                    this.Update(db, config);
                } else this.Store(db ,config);
            }
        }

        private void Store(LiteDatabase db, DenConfig config)
        {
            var col_mongo = db.GetCollection<DenMongoConfigObject>(DEN_MONGO_CONFIG_COLLECTION);
            col_mongo.Insert(DB_ID, config.DenMongoConfigObject);

            var col_picky = db.GetCollection<DenPickyConfigObject>(DEN_PICKY_CONFIG_COLLECTION);
            col_picky.Insert(DB_ID, config.DenPickyConfigObject);

            var col_lucid = db.GetCollection<DenLucidConfigObject>(DEN_LUCID_CONFIG_COLLECTION);
            col_lucid.Insert(DB_ID, config.DenLucidConfigObject);

            var col_server = db.GetCollection<DenServerConfigObject>(DEN_SERVER_CONFIG_COLLECTION);
            col_server.Insert(DB_ID, config.DenServerConfigObject);

            var col_traefik = db.GetCollection<DenTraefikConfigObject>(DEN_TRAEFIK_CONFIG_COLLECTION);
            col_traefik.Insert(DB_ID, config.DenTraefikConfigObject);

            var col_docker = db.GetCollection<DenDockerConfigObject>(DEN_DOCKER_CONFIG_COLLECTION);
            col_docker.Insert(DB_ID, config.DenDockerConfigObject);
        }

        private void Update(LiteDatabase db, DenConfig config)
        {
            var col_mongo = db.GetCollection<DenMongoConfigObject>(DEN_MONGO_CONFIG_COLLECTION);
            col_mongo.Update(DB_ID, config.DenMongoConfigObject);

            var col_picky = db.GetCollection<DenPickyConfigObject>(DEN_PICKY_CONFIG_COLLECTION);
            col_picky.Update(DB_ID, config.DenPickyConfigObject);

            var col_lucid = db.GetCollection<DenLucidConfigObject>(DEN_LUCID_CONFIG_COLLECTION);
            col_lucid.Update(DB_ID, config.DenLucidConfigObject);

            var col_server = db.GetCollection<DenServerConfigObject>(DEN_SERVER_CONFIG_COLLECTION);
            col_server.Update(DB_ID, config.DenServerConfigObject);

            var col_traefik = db.GetCollection<DenTraefikConfigObject>(DEN_TRAEFIK_CONFIG_COLLECTION);
            col_traefik.Update(DB_ID, config.DenTraefikConfigObject);

            var col_docker = db.GetCollection<DenDockerConfigObject>(DEN_DOCKER_CONFIG_COLLECTION);
            col_docker.Update(DB_ID, config.DenDockerConfigObject);
        }

        public DenConfig GetConfig()
        {
            if(!this.DbExists)
            {
                throw new Exception("Could not find WaykDen configuration in given path. Use New-WaykDenConfig or make sure WaykDen configuration is in current folder or set WAYK_DEN_HOME to the path of WaykDen configuration");
            }

            using(var db = new LiteDatabase(this.connString))
            {
                return new DenConfig()
                {
                    DenLucidConfigObject = this.GetLucid(db),
                    DenPickyConfigObject = this.GetPicky(db),
                    DenMongoConfigObject = this.GetMongo(db),
                    DenServerConfigObject = this.GetServer(db),
                    DenTraefikConfigObject = this.GetTraefik(db),
                    DenDockerConfigObject = this.GetDocker(db)
                };
            }
        }

        private DenMongoConfigObject GetMongo(LiteDatabase db)
        {
            var coll = db.GetCollection(DEN_MONGO_CONFIG_COLLECTION);
            var values = coll.FindById(DB_ID);
            bool urlOk = values.TryGetValue(nameof(DenMongoConfigObject.Url), out var url);
            url = string.IsNullOrEmpty((string)url) ? DEFAULT_MONGO_URL : ((string)url);
            return new DenMongoConfigObject()
            {
                Url = url,
                IsExternal = (string)url != DEFAULT_MONGO_URL
            };
        }

        private DenPickyConfigObject GetPicky(LiteDatabase db)
        {
            var coll = db.GetCollection(DEN_PICKY_CONFIG_COLLECTION);
            var values = coll.FindById(DB_ID);
            bool realmOk = values.TryGetValue(nameof(DenPickyConfigObject.Realm), out var realm);
            bool apiKeyOk = values.TryGetValue(nameof(DenPickyConfigObject.ApiKey), out var apikey);
            bool backendOk = values.TryGetValue(nameof(DenPickyConfigObject.Backend), out var backend);
            return new DenPickyConfigObject()
            {
                Realm = realmOk ? ((string)realm) : string.Empty,
                ApiKey = apiKeyOk ? ((string)apikey) : string.Empty,
                Backend = backendOk ? ((string)backend) : string.Empty
            };
        }

        private DenLucidConfigObject GetLucid(LiteDatabase db)
        {
            var coll = db.GetCollection(DEN_LUCID_CONFIG_COLLECTION);
            var values = coll.FindById(DB_ID);
            bool apiKeyOk = values.TryGetValue(nameof(DenLucidConfigObject.ApiKey), out var apikey);
            bool adminSecretOk = values.TryGetValue(nameof(DenLucidConfigObject.AdminSecret), out var adminsecret);
            bool adminUsernameOk = values.TryGetValue(nameof(DenLucidConfigObject.AdminUsername), out var adminusername);
            return new DenLucidConfigObject()
            {
                ApiKey = apiKeyOk ? ((string)apikey) : string.Empty,
                AdminSecret = adminSecretOk ? ((string)adminsecret) : string.Empty,
                AdminUsername = adminUsernameOk ? ((string)adminusername) : string.Empty
            };
        }

        private DenServerConfigObject GetServer(LiteDatabase db)
        {
            var coll = db.GetCollection(DEN_SERVER_CONFIG_COLLECTION);
            var values = coll.FindById(DB_ID);
            bool apiKeyOk = values.TryGetValue(nameof(DenServerConfigObject.ApiKey), out var apikey);
            bool auditTrailsOK = values.TryGetValue(nameof(DenServerConfigObject.AuditTrails), out var auditTrails);
            bool externalUrlOk = values.TryGetValue(nameof(DenServerConfigObject.ExternalUrl), out var externalUrl);
            bool ldapServerTypeOk = values.TryGetValue(nameof(DenServerConfigObject.LDAPServerType), out var ldapservertype);
            bool ldapPasswordOk = values.TryGetValue(nameof(DenServerConfigObject.LDAPPassword), out var ldappassword);
            bool ldapServerUrlOk = values.TryGetValue(nameof(DenServerConfigObject.LDAPServerUrl), out var ldapserverurl);
            bool ldapUserGroupOk = values.TryGetValue(nameof(DenServerConfigObject.LDAPUserGroup), out var ldapusergroup);
            bool ldapUsernameOk = values.TryGetValue(nameof(DenServerConfigObject.LDAPUsername), out var ldapusername);
            bool ldapBaseDnOk = values.TryGetValue(nameof(DenServerConfigObject.LDAPBaseDN), out var ldapbasedn);
            values.TryGetValue(nameof(DenServerConfigObject.PrivateKey), out var privatekey);
            values.TryGetValue(nameof(DenServerConfigObject.PublicKey), out var publicKey);
            bool jetServerUrlOk = values.TryGetValue(nameof(DenServerConfigObject.JetServerUrl), out var jetServerUrl);
            bool jetRelayUrlOk = values.TryGetValue(nameof(DenServerConfigObject.JetRelayUrl), out var jetRelayUrl);
            bool loginRequiredOk = values.TryGetValue(nameof(DenServerConfigObject.LoginRequired), out var loginRequired);
            bool natsUsernameOK = values.TryGetValue(nameof(DenServerConfigObject.NatsUsername), out var natsUsername);
            bool natsPasswordOK = values.TryGetValue(nameof(DenServerConfigObject.NatsPassword), out var natsPAssword);
            bool redisPasswordOK = values.TryGetValue(nameof(DenServerConfigObject.RedisPassword), out var redisPassword);

            return new DenServerConfigObject()
            {
                ApiKey = apiKeyOk ? ((string)apikey) : string.Empty,
                AuditTrails = auditTrailsOK ? ((string) auditTrails) : string.Empty,
                ExternalUrl = externalUrlOk ? ((string) externalUrl).TrimEnd('/') : string.Empty,
                LDAPServerType = ldapServerTypeOk ? ((string) ldapservertype) : string.Empty,
                LDAPBaseDN = ldapBaseDnOk? ((string) ldapbasedn) : string.Empty,
                LDAPPassword = ldapPasswordOk ? ((string) ldappassword) : string.Empty,
                LDAPServerUrl = ldapServerUrlOk ? ((string) ldapserverurl) : string.Empty,
                LDAPUserGroup = ldapUserGroupOk ? ((string) ldapusergroup) : string.Empty,
                LDAPUsername = ldapUsernameOk ? ((string) ldapusername) : string.Empty,
                PrivateKey = privatekey,
                JetServerUrl = jetServerUrlOk && !string.IsNullOrEmpty((string) jetServerUrl) ? ((string) jetServerUrl) : DEFAULT_JET_SERVER_URL,
                JetRelayUrl = jetRelayUrlOk && !string.IsNullOrEmpty((string) jetRelayUrl) ? ((string) jetRelayUrl) : DEFAULT_JET_RELAY_URL,
                LoginRequired = loginRequiredOk ? ((string) loginRequired) : "false",
                PublicKey = publicKey,
                NatsUsername = natsUsernameOK ? ((string)natsUsername) : string.Empty,
                NatsPassword = natsPasswordOK ? ((string)natsPAssword) : string.Empty,
                RedisPassword = redisPasswordOK ? ((string)redisPassword) : string.Empty,
            };
        }

        private DenTraefikConfigObject GetTraefik(LiteDatabase db)
        {
            var coll = db.GetCollection(DEN_TRAEFIK_CONFIG_COLLECTION);
            var values = coll.FindById(DB_ID);
            bool waykDenPortOk =  values.TryGetValue(nameof(DenTraefikConfigObject.WaykDenPort), out var waykDenPort);
            bool certificateOk = values.TryGetValue(nameof(DenTraefikConfigObject.Certificate), out var certificate);
            bool privateKeyOk = values.TryGetValue(nameof(DenTraefikConfigObject.PrivateKey), out var privateKey);
            return new DenTraefikConfigObject
            {
                WaykDenPort = waykDenPortOk ? ((string)waykDenPort) : "4000",
                Certificate = certificateOk ? (string)certificate : string.Empty,
                PrivateKey = privateKeyOk ? (string)privateKey : string.Empty
            };
        }

        private DenDockerConfigObject GetDocker(LiteDatabase db)
        {
            var coll = db.GetCollection(DEN_DOCKER_CONFIG_COLLECTION);
            var values = coll.FindById(DB_ID);
            bool dockerclientUriOk = values.TryGetValue(nameof(DenDockerConfigObject.DockerClientUri), out var dockerclienturi);
            bool platformOk = values.TryGetValue(nameof(DenDockerConfigObject.Platform), out var platform);
            bool syslogOk = values.TryGetValue(nameof(DenDockerConfigObject.SyslogServer), out var syslog);
            return new DenDockerConfigObject()
            {
                DockerClientUri = dockerclientUriOk ? ((string) dockerclienturi) : string.Empty,
                Platform = platformOk ? ((string)platform) : "Linux",
                SyslogServer = syslogOk ? ((string)syslog) : string.Empty
            };
        }
    }
}