#!/usr/bin/env bash
# Hybrid cloud failover monitor (SIMULATED locally with two Minikube clusters)
# onprem = PRIMARY site, cloud = SECONDARY site (simulated public cloud)
# Run in Git Bash (Windows), or any terminal on Mac/Linux.

ready() {  # prints number of ready web pods in cluster $1
  n=$(kubectl --context "$1" get deploy web -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  echo "${n:-0}"
}

serve_from_cloud() {  # makes one real request to the cloud site's app
  kubectl --context cloud exec deploy/web -- python -c \
    "import urllib.request,re;print(re.sub('<[^>]+>',' ',urllib.request.urlopen('http://localhost:5000/').read().decode()))" 2>/dev/null
}

echo "Failover monitor started. Primary=onprem, Secondary=cloud (simulated). Ctrl+C to stop."
while true; do
  P=$(ready onprem)
  if [ "$P" -ge 1 ]; then
    echo "$(date +%T) ACTIVE SITE = onprem (primary healthy, ready pods: $P)"
  else
    C=$(ready cloud)
    if [ "$C" -ge 1 ]; then
      echo "$(date +%T) !!! PRIMARY DOWN -> FAILOVER to cloud (ready pods: $C) | response: $(serve_from_cloud)"
    else
      echo "$(date +%T) BOTH SITES DOWN"
    fi
  fi
  sleep 3
done
