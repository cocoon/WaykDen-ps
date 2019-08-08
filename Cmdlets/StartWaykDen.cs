using System;
using System.Threading;
using System.Threading.Tasks;
using System.Management.Automation;
using WaykDen.Controllers;

namespace WaykDen.Cmdlets
{
    [Cmdlet("Start", "WaykDen")]
    public class StartWaykDen : WaykDenConfigCmdlet
    {
        private Exception error;
        private DenServicesController denServicesController;
        protected override void ProcessRecord()
        {
            try
            {
                this.denServicesController = new DenServicesController(this.Path, this.Key);
                this.denServicesController.OnLog += this.OnLog;
                this.denServicesController.OnError += this.OnError;
                Task<bool> start = this.denServicesController.StartWaykDen();

                while(!start.IsCompleted && !start.IsCanceled)
                {
                    mre.WaitOne();
                    lock(this.mutex)
                    {
                        if(this.record != null)
                        {
                            this.WriteProgress(this.record);
                            this.record = null;
                        }

                        if(this.error != null)
                        {
                            this.WriteWarning(this.error.Message);
                            this.error = null;
                        }
                    }
                }
            }
            catch(Exception e)
            {
                this.OnError(e);
            }
        }

        protected override void OnLog(string message)
        {
            ProgressRecord r = new ProgressRecord(1, "WaykDen", message);
            r.PercentComplete = this.denServicesController.RunningDenServices.Count * 100 / 6;

            lock(this.mutex)
            {
                this.record = r;
                this.mre.Set();
            }
        }

        protected override void OnError(Exception e)
        {
            this.error = e;
            lock(this.mutex)
            {
                this.mre.Set();
            }
        }
    }
}