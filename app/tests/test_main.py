from fastapi.testclient import TestClient
from app.app import app

client = TestClient(app)

def test_read_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "Hello from AWS DevOps Platform!"}

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}

def test_heavy_load():
    response = client.get("/heavy-load")
    assert response.status_code == 200
    assert "Processed" in response.json()["message"]
