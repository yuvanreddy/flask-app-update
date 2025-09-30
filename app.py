from flask import Flask, jsonify, request
import os
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Configuration
app.config['JSON_SORT_KEYS'] = False
VERSION = os.getenv('APP_VERSION', 'dev')
PORT = int(os.getenv('PORT', 5000))

@app.route('/')
def index():
    """Root endpoint"""
    return jsonify({
        'message': 'Welcome to Flask App on EKS!',
        'version': VERSION,
        'timestamp': datetime.utcnow().isoformat(),
        'endpoints': {
            'health': '/health',
            'info': '/info',
            'api': '/api/hello'
        }
    })

@app.route('/health')
def health():
    """Health check endpoint for K8s probes"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'version': VERSION
    }), 200

@app.route('/info')
def info():
    """Application information"""
    return jsonify({
        'application': 'flask-app',
        'version': VERSION,
        'environment': os.getenv('FLASK_ENV', 'production'),
        'python_version': os.sys.version,
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/api/hello', methods=['GET'])
def hello():
    """Simple API endpoint"""
    name = request.args.get('name', 'World')
    return jsonify({
        'message': f'Hello, {name}!',
        'version': VERSION,
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/api/echo', methods=['POST'])
def echo():
    """Echo endpoint for testing"""
    data = request.get_json()
    return jsonify({
        'received': data,
        'timestamp': datetime.utcnow().isoformat()
    })

@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    return jsonify({
        'error': 'Not Found',
        'status': 404,
        'timestamp': datetime.utcnow().isoformat()
    }), 404

@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    logger.error(f"Internal server error: {error}")
    return jsonify({
        'error': 'Internal Server Error',
        'status': 500,
        'timestamp': datetime.utcnow().isoformat()
    }), 500

if __name__ == '__main__':
    logger.info(f"Starting Flask app version {VERSION} on port {PORT}")
    app.run(
        host='0.0.0.0',
        port=PORT,
        debug=False
    )