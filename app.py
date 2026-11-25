import os
import socket

import redis
from flask import Flask, jsonify

app = Flask(__name__)

r = redis.Redis(
    host=os.getenv("REDIS_HOST", "redis"),
    port=int(os.getenv("REDIS_PORT", "6379")),
    socket_connect_timeout=2,
    socket_timeout=2,
)


@app.route("/")
def index():
    try:
        count = r.incr("visits")
    except redis.exceptions.RedisError:
        return "Redis unavailable", 503
    return (
        "<h1>Visitor Counter</h1>"
        f"<p>Total visits: {count}</p>"
        f"<p>Served by pod/container: {socket.gethostname()}</p>"
    )


@app.route("/health")
def health():
    return jsonify(status="ok", host=socket.gethostname())


@app.route("/load")
def load():
    # CPU-heavy endpoint used only to trigger HPA autoscaling during the demo
    total = 0
    for i in range(3_000_000):
        total += i * i
    return jsonify(done=True, host=socket.gethostname())


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
