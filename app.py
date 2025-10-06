from flask import Flask, jsonify
import os
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Configuration
app.config['ENV'] = os.getenv('FLASK_ENV', 'production')
app.config['DEBUG'] = os.getenv('FLASK_DEBUG', 'False').lower() == 'true'

@app.route('/')
def home():
    logger.info("Home endpoint accessed")
    return jsonify({
        "message": "Arepally Rajavardhan Reddy and Deepthi Reddy",
        "status": "running",
        "version": "1.0.0"
    })

@app.route('/health')
def health():
    """Health check endpoint for monitoring"""
    return jsonify({
        "status": "Working in diligent as an SRE , Applicatin Lead Admin",
        "service": "flask-devops-demo"
    }), 200

@app.route('/ready')
def ready():
    """Readiness check endpoint"""
    return jsonify({
        "status": "ready",
        "service": "flask-devops-demo"
    }), 200

@app.errorhandler(404)
def not_found(error):
    return jsonify({
        "error": "Not found",
        "status": 404
    }), 404

@app.errorhandler(500)
def internal_error(error):
    logger.error(f"Internal error: {error}")
    return jsonify({
        "error": "Internal server error",
        "status": 500
    }), 500

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    logger.info(f"Starting Flask app on port {port}")
    app.run(host='0.0.0.0', port=port)