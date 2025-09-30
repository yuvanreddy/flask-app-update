"""
Flask REST API application with health checks and data endpoints.

This module provides a simple REST API with health monitoring,
data retrieval, and data submission capabilities.
"""

import os
import logging

from flask import Flask, jsonify, request

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@app.route('/health', methods=['GET'])
def health():
    """
    Health check endpoint.
    
    Returns:
        tuple: JSON response with health status and HTTP status code 200
    """
    return jsonify({
        'status': 'healthy',
        'service': 'flask-app',
        'version': os.getenv('APP_VERSION', '1.0.0')
    }), 200


@app.route('/', methods=['GET'])
def home():
    """
    Root endpoint providing API information.
    
    Returns:
        tuple: JSON response with welcome message and available endpoints, HTTP 200
    """
    return jsonify({
        'message': 'Welcome to Flask App',
        'version': os.getenv('APP_VERSION', '1.0.0'),
        'endpoints': {
            'health': '/health',
            'api': '/api/data'
        }
    }), 200


@app.route('/api/data', methods=['GET'])
def get_data():
    """
    Retrieve sample data.
    
    Returns:
        tuple: JSON response with data array and count, HTTP status code 200
    """
    return jsonify({
        'data': [
            {'id': 1, 'name': 'Item 1'},
            {'id': 2, 'name': 'Item 2'},
            {'id': 3, 'name': 'Item 3'}
        ],
        'count': 3
    }), 200


@app.route('/api/data', methods=['POST'])
def post_data():
    """
    Accept and process posted data.
    
    Returns:
        tuple: JSON response with success message and submitted data, HTTP 201
    """
    data = request.get_json()
    logger.info("Received data: %s", data)
    return jsonify({
        'message': 'Data received successfully',
        'data': data
    }), 201


@app.errorhandler(404)
def not_found(_error):
    """
    Handle 404 Not Found errors.
    
    Args:
        _error: The error object (unused but required by Flask)
        
    Returns:
        tuple: JSON error response and HTTP status code 404
    """
    return jsonify({'error': 'Not found'}), 404


@app.errorhandler(500)
def internal_error(_error):
    """
    Handle 500 Internal Server Error.
    
    Args:
        _error: The error object (unused but required by Flask)
        
    Returns:
        tuple: JSON error response and HTTP status code 500
    """
    return jsonify({'error': 'Internal server error'}), 500


if __name__ == '__main__':
    port = int(os.getenv('PORT', '5000'))  # pylint: disable=invalid-envvar-default
    # Binding to 0.0.0.0 is required for Docker containers to accept external connections
    # Security is handled by Docker networking, Kubernetes network policies, and security groups
    app.run(host='0.0.0.0', port=port, debug=False)  # nosec B104