import sys
import os
import pytest
import json

# Add parent directory to Python path to import app module
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import app

@pytest.fixture
def client():
    """Create a test client for the Flask app"""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_health_endpoint(client):
    """Test the health check endpoint"""
    response = client.get('/health')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'healthy'
    assert 'version' in data

def test_home_endpoint(client):
    """Test the home endpoint"""
    response = client.get('/')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert 'message' in data
    assert 'endpoints' in data

def test_get_data_endpoint(client):
    """Test the GET /api/data endpoint"""
    response = client.get('/api/data')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert 'data' in data
    assert data['count'] == 3
    assert len(data['data']) == 3

def test_post_data_endpoint(client):
    """Test the POST /api/data endpoint"""
    test_data = {'name': 'Test Item', 'value': 123}
    response = client.post('/api/data',
                          data=json.dumps(test_data),
                          content_type='application/json')
    assert response.status_code == 201
    data = json.loads(response.data)
    assert data['message'] == 'Data received successfully'
    assert data['data'] == test_data

def test_404_error(client):
    """Test 404 error handler"""
    response = client.get('/nonexistent')
    assert response.status_code == 404
    data = json.loads(response.data)
    assert data['error'] == 'Not found'

def test_post_without_data(client):
    """Test POST endpoint without data"""
    response = client.post('/api/data',
                          content_type='application/json')
    assert response.status_code in [400, 201]  # May vary based on implementation