from flask import Flask, jsonify, request
import os
import logging
from werkzeug.exceptions import BadRequest

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Health check endpoint
@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        'status': 'healthy',
        'service': 'flask-app',
        'version': os.getenv('APP_VERSION', '1.0.0')
    }), 200

# Root endpoint
@app.route('/', methods=['GET'])
def home():
    return jsonify({
        'message': 'Welcome to Flask App',
        'version': os.getenv('APP_VERSION', '1.0.0'),
        'endpoints': {
            'health': '/health',
            'api': '/api/data'
        }
    }), 200

# API endpoint
@app.route('/api/data', methods=['GET'])
def get_data():
    return jsonify({
        'data': [
            {'id': 1, 'name': 'Item 1'},
            {'id': 2, 'name': 'Item 2'},
            {'id': 3, 'name': 'Item 3'}
        ],
        'count': 3
    }), 200

# POST endpoint
@app.route('/api/data', methods=['POST'])
def post_data():
    try:
        data = request.get_json()

        if data is None:
            return jsonify({'error': 'Invalid JSON data'}), 400

        # Log received data safely (avoid log injection)
        logger.info("Received POST data", extra={'data_size': len(str(data)) if data else 0})

        return jsonify({
            'message': 'Data received successfully',
            'data': data
        }), 201

    except BadRequest as e:
        # Handle malformed JSON requests
        logger.warning(f"Bad request: {request.method} {request.path}")
        return jsonify({'error': 'Invalid JSON data'}), 400

    except Exception as e:
        logger.error(f"Error processing POST data: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

# Error handler
@app.errorhandler(404)
def not_found(error):
    logger.warning(f"404 error: {request.method} {request.path}")
    return jsonify({'error': 'Not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    logger.error(f"500 error: {request.method} {request.path}", exc_info=True)
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)