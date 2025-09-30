import pytest
import json
import sys
import os

# Add parent directory to path to import app module
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app import app

@pytest.fixture
def client():
    """Create test client"""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_index(client):
    """Test root endpoint"""
    response = client.get('/')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert 'message' in data
    assert 'version' in data
    assert 'endpoints' in data

def test_health_check(client):
    """Test health endpoint"""
    response = client.get('/health')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'healthy'
    assert 'timestamp' in data
    assert 'version' in data

def test_info(client):
    """Test info endpoint"""
    response = client.get('/info')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert 'application' in data
    assert data['application'] == 'flask-app'
    assert 'version' in data

def test_hello_default(client):
    """Test hello endpoint with default name"""
    response = client.get('/api/hello')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert 'Hello, World!' in data['message']

def test_hello_with_name(client):
    """Test hello endpoint with custom name"""
    response = client.get('/api/hello?name=John')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert 'Hello, John!' in data['message']

def test_echo(client):
    """Test echo endpoint"""
    test_data = {'test': 'data', 'number': 42}
    response = client.post(
        '/api/echo',
        data=json.dumps(test_data),
        content_type='application/json'
    )
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['received'] == test_data

def test_not_found(client):
    """Test 404 error handling"""
    response = client.get('/nonexistent')
    assert response.status_code == 404
    data = json.loads(response.data)
    assert data['status'] == 404
    assert 'error' in data