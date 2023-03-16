using AlwaysOn.Shared;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Net;
using System.Threading;
using System.Threading.Tasks;

namespace AlwaysOn.HealthService
{
    /// <summary>
    /// Background job that performs the health checks on a regular interval and caches the result in memory
    /// Initial source: https://stackoverflow.com/a/68630985/1537195
    /// </summary>
    public class HealthJob : BackgroundService
    {
        private readonly TimeSpan _checkInterval;

        private readonly ILogger<HealthJob> _logger;
        private readonly HealthCheckService _healthCheckService;
        private readonly SysConfiguration _sysConfig;
        private readonly TelemetryClient _telemetryClient;

        public static HealthReport LastReport { get; private set; }
        public static DateTime LastExecution { get; private set; }

        public HealthJob(ILogger<HealthJob> logger, SysConfiguration sysConfig, HealthCheckService healthCheckService, TelemetryClient telemetryClient)
        {
            _logger = logger;
            _sysConfig = sysConfig;
            _healthCheckService = healthCheckService;
            _telemetryClient = telemetryClient;
            _checkInterval = TimeSpan.FromSeconds(_sysConfig.HealthServiceCacheDurationSeconds);
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                var requestTelemetry = new RequestTelemetry { Name = $"HealthJob cycle" };

                using (_telemetryClient.StartOperation(requestTelemetry))
                {
                    _logger.LogDebug("Running all health checks");
                    var cts = new CancellationTokenSource(TimeSpan.FromSeconds(_sysConfig.HealthServiceOverallTimeoutSeconds));
                    try
                    {
                        // Run all health checks
                        LastReport = await _healthCheckService.CheckHealthAsync(cts.Token);
                        LastExecution = DateTime.Now;
                        _logger.LogDebug("Finished all health checks. LastReport.Result={result}", LastReport.Status);
                        requestTelemetry.Success = true;
                        requestTelemetry.ResponseCode = HttpStatusCode.OK.ToString();
                    }
                    catch (TaskCanceledException e)
                    {
                        // Ignored
                        _logger.LogError(e, "TaskCanceledException during health check(s) execution");
                        requestTelemetry.Success = false;
                        requestTelemetry.ResponseCode = HttpStatusCode.InternalServerError.ToString();
                    }
                    catch (Exception e)
                    {
                        _logger.LogError(e, "Exception during health check(s) execution {message}", e.Message);
                        requestTelemetry.Success = false;
                        requestTelemetry.ResponseCode = HttpStatusCode.InternalServerError.ToString();

                        var exceptionEntry = new HealthReportEntry(HealthStatus.Unhealthy, "Exception on running health checks", TimeSpan.Zero, e, null);
                        var entries = new Dictionary<string, HealthReportEntry>
                        {
                            { "HealthCheckerError", exceptionEntry }
                        };

                        LastReport = new HealthReport(entries, TimeSpan.Zero);
                    }
                    finally
                    {
                        cts.Dispose();
                    }
                }
                await Task.Delay(_checkInterval, stoppingToken);
            }
        }
    }
}
