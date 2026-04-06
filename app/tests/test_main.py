from fastapi.testclient import TestClient
from app.app import app

client = TestClient(app)

def test_read_root():
    response = client.get("/")
    assert response.status_code == 200
    json_res = response.json()
    assert json_res["message"] == "Hello from AWS DevOps Platform!"
    assert json_res["version"] == "v2.0 (Senior Grade)"

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    json_res = response.json()
    assert json_res["status"] == "healthy"
    assert "database" in json_res["checks"]

def test_heavy_load():
    response = client.get("/heavy-load")
    assert response.status_code == 200
    assert "Processed" in response.json()["message"]
