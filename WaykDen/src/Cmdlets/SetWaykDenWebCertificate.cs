using System;
using System.IO;
using System.Management.Automation;
using WaykDen.Controllers;
using WaykDen.Models;
using WaykDen.Utils;

namespace WaykDen.Cmdlets
{
    [Cmdlet(VerbsCommon.Set, "WaykDenWebCertificate")]
    public class SetWaykDenWebCertificate : WaykDenConfigCmdlet
    {
        private const string BASE64 = "Base64";
        private const string PKCS12 = "Pkcs12";

        [Parameter(Mandatory = true, ParameterSetName = BASE64, HelpMessage = "Path to a x509 certificate or chain in base64 format.")]
        [Parameter(Mandatory = true, ParameterSetName = PKCS12, HelpMessage = "Path to a certificate is in pkcs12 format")]
        public string CertificatePath {get; set;} = string.Empty;
        [Parameter(Mandatory = true, ParameterSetName = BASE64, HelpMessage = "Path to the private key of the given certificate for Traefik. In a case of a chain, the leaf certicate private key")]
        public string PrivateKeyPath {get; set;} = string.Empty;
        [Parameter(ParameterSetName = PKCS12, HelpMessage = "Pkcs12 import password")]
        public string KeyPassword {get; set;} = string.Empty;

        public SetWaykDenWebCertificate()
        {
        }

        protected override void ProcessRecord()
        {
            try
            {
                DenConfigController denConfigController = new DenConfigController(this.Path);
                DenConfig config = denConfigController.GetConfig();

                if(this.ParameterSetName == PKCS12)
                {
                    CertificateObject cert = KeyCertUtils.GetPkcs12CertificateInfo(CertificatePath, this.KeyPassword);
                    config.DenTraefikConfigObject.Certificate = cert.Certificate;
                    config.DenTraefikConfigObject.PrivateKey = cert.Privatekey;
                }
                else
                {
                    config.DenTraefikConfigObject.Certificate = File.ReadAllText(CertificatePath);
                    config.DenTraefikConfigObject.PrivateKey = File.ReadAllText(PrivateKeyPath);
                }

                if(string.IsNullOrEmpty(config.DenTraefikConfigObject.Certificate))
                {
                    this.OnError(new Exception("No certificate found"));
                }

                if(string.IsNullOrEmpty(config.DenTraefikConfigObject.PrivateKey))
                {
                    this.OnError(new Exception("No private key found"));
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