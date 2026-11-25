# Cost Analysis (environment simulated locally on Minikube)

Pricing assumption (write this in your report): 1 vCPU = $0.04/hour, 1 GB RAM = $0.005/hour, 730 hours/month
(typical public-cloud on-demand ballpark; used only to convert measured resources into dollars).

Monthly cost = replicas x (CPU_request x 0.04 + RAM_GB_request x 0.005) x 730

| # | Technique | Metric | Before | After |
|---|-----------|--------|--------|-------|
| 1 | Slim base image + .dockerignore + --no-cache-dir | Image size (docker images) | ___ MB (python:3.12) | ___ MB (python:3.12-slim) |
| 2 | Right-size resource requests | CPU / RAM request per web pod | 150m / 256Mi | 100m / 64Mi |
| 3 | HPA (min 2) instead of fixed replicas | Idle web replicas | 5 | 2 |
| 4 (bonus) | Stop idle secondary cluster | Running clusters | 2 | 1 |

Combined web-tier monthly cost (techniques 2+3):
Before = 5 x (0.15x0.04 + 0.25x0.005) x 730 = $26.46
After  = 2 x (0.10x0.04 + 0.0625x0.005) x 730 = $6.30
Saving = about 76 %

Fill the two "___ MB" cells from your own `docker images` screenshot.
