using System.Collections.Generic;
using Docker.DotNet.Models;
using WaykDen.Controllers;

namespace WaykDen.Models.Services
{
    public class DenLucidService : DenHealthCheckService
    {
        private const string DENLUCID_NAME = "den-lucid";
        private const string LUCID_TOKEN_ISSUER_ENV = "LUCID_TOKEN__ISSUER";
        private const string LUCID_ADMIN_USERNAME_ENV = "LUCID_ADMIN__USERNAME";
        private const string LUCID_ADMIN_SECRET_ENV = "LUCID_ADMIN__SECRET";
        private const string LUCID_DATABASE_URL_ENV = "LUCID_DATABASE__URL";
        private const string LUCID_AUTHENTICATION_KEY_ENV = "LUCID_AUTHENTICATION__KEY";
        private const string LUCID_ACCOUNT_APIKEY_ENV = "LUCID_ACCOUNT__APIKEY";
        private const string LUCID_ACCOUNT_REFRESH_USER_URL_ENV = "LUCID_ACCOUNT__REFRESH_USER_URL";
        private const string LUCID_ACCOUNT_LOGIN_URL_ENV =  "LUCID_ACCOUNT__LOGIN_URL";
        private const string LUCID_ACCOUNT_FORGOT_PASSWORD_URL_ENV = "LUCID_ACCOUNT__FORGOT_PASSWORD_URL";
        private const string LUCID_ACCOUNT_SEND_ACTIVATION_EMAIL_URL_ENV = "LUCID_ACCOUNT__SEND_ACTIVATION_EMAIL_URL";
        private const string LUCID_HEALTHCHECK = "curl -sS http://den-lucid:4242/health";
        private string ApiKey => this.DenConfig.DenLucidConfigObject.ApiKey;

        public DenLucidService(DenServicesController controller):base(controller, DENLUCID_NAME)
        {
            this.ImageName = this.DenConfig.DenImageConfigObject.DenLucidImage;
            this.HealthCheck.Add(LUCID_HEALTHCHECK);

            string[] environment = new string[]
            {
                $"{LUCID_ADMIN_SECRET_ENV}={this.DenConfig.DenLucidConfigObject.AdminSecret}",
                $"{LUCID_ADMIN_USERNAME_ENV}={this.DenConfig.DenLucidConfigObject.AdminUsername}",
                $"{LUCID_AUTHENTICATION_KEY_ENV}={this.ApiKey}",
                $"{LUCID_DATABASE_URL_ENV}={this.DenConfig.DenMongoConfigObject.Url}",
                $"{LUCID_TOKEN_ISSUER_ENV}={this.DenConfig.DenServerConfigObject.ExternalUrl}/lucid",
                $"{LUCID_ACCOUNT_APIKEY_ENV}={this.DenConfig.DenServerConfigObject.ApiKey}",
                $"{LUCID_ACCOUNT_LOGIN_URL_ENV}=http://den-server:10255/account/login",
                $"{LUCID_ACCOUNT_REFRESH_USER_URL_ENV}=http://den-server:10255/account/refresh",
                $"{LUCID_ACCOUNT_FORGOT_PASSWORD_URL_ENV}=http://den-server:10255/account/forgot",
                $"{LUCID_ACCOUNT_SEND_ACTIVATION_EMAIL_URL_ENV}=http://den-server:10255/account/activation",
            };

            this.Env.AddRange(environment);
        }
    }
}