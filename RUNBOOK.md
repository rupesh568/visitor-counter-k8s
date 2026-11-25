# RUNBOOK - commands in order (screenshot every step marked [SS])

## Task 1: Containerize
docker compose up --build            # [SS] containers running
# open http://localhost:5000 , refresh a few times [SS] counter increasing
docker compose down
docker build -t visitor-counter:v1 .                      # optimized image
docker build -f Dockerfile.before -t visitor-counter:before .
docker images                      # [SS] size comparison (cost technique 1)

## Task 2: Kubernetes
minikube start -p onprem --driver=docker --cpus=2 --memory=2048
minikube -p onprem addons enable metrics-server
minikube -p onprem image load visitor-counter:v1
kubectl config use-context onprem
kubectl apply -f k8s.yaml
kubectl get pods -o wide                                  # [SS] running pods
kubectl get svc
minikube -p onprem service web --url                      # open in browser [SS]
# Self-healing:
kubectl get pods
kubectl delete pod <one-web-pod-name>
kubectl get pods -w                                       # [SS] new pod auto-created

## Task 3: HPA
kubectl apply -f hpa.yaml
kubectl get hpa                                           # [SS] before load
kubectl run load --image=busybox:1.36 --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://web/load; done"
# if replicas do not increase after 2 min, start a 2nd load pod: same command with name load2
kubectl get hpa -w                                        # [SS] CPU rising, replicas increasing
kubectl get pods                                          # [SS] more pods
kubectl delete pod load                                   # scale-down happens after ~5 min [SS]

## Task 4: Hybrid cloud with failover (simulated)
minikube start -p cloud --driver=docker --cpus=2 --memory=2048
minikube -p cloud addons enable metrics-server
minikube -p cloud image load visitor-counter:v1
kubectl --context cloud apply -f k8s.yaml
kubectl --context cloud apply -f hpa.yaml
kubectl --context cloud get pods                          # [SS]
bash failover.sh                                          # terminal A (Git Bash) [SS] ACTIVE SITE = onprem
# terminal B: simulate on-prem outage
kubectl --context onprem scale deploy web --replicas=0
# [SS] terminal A prints PRIMARY DOWN -> FAILOVER to cloud
# recover:
kubectl --context onprem scale deploy web --replicas=2    # [SS] back to onprem

## Task 5: Cost optimization (measure BEFORE, then AFTER)
# Technique 1 (image size): docker images (already captured in Task 1) [SS]
# BEFORE state (on onprem cluster):
kubectl --context onprem delete hpa web-hpa
kubectl --context onprem set resources deploy web --requests=cpu=150m,memory=256Mi --limits=cpu=250m,memory=256Mi
kubectl --context onprem scale deploy web --replicas=5
kubectl --context onprem get pods                         # [SS] 5 pods
kubectl --context onprem top pods                         # [SS] actual usage
kubectl --context onprem get deploy web -o jsonpath="{.spec.template.spec.containers[0].resources}"   # [SS]
# AFTER state:
kubectl --context onprem apply -f k8s.yaml
kubectl --context onprem apply -f hpa.yaml
kubectl --context onprem get pods                         # [SS] 2 pods
kubectl --context onprem top pods                         # [SS]
kubectl --context onprem get deploy web -o jsonpath="{.spec.template.spec.containers[0].resources}"   # [SS]
# Technique 4 (bonus): minikube stop -p cloud ; minikube profile list [SS]

## Cleanup (only AFTER you finish all screenshots)
minikube delete -p onprem ; minikube delete -p cloud
