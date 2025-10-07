from flask import Flask, request, jsonify, render_template, redirect, url_for, flash, send_from_directory
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from werkzeug.utils import secure_filename
import os
from datetime import datetime
from PIL import Image
import uuid

# Load environment variables
from dotenv import load_dotenv
load_dotenv()

app = Flask(__name__)

# Configuration
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'your-secret-key-here')
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URL', 'sqlite:///photos.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['UPLOAD_FOLDER'] = os.path.join(os.getcwd(), 'static', 'uploads', 'photos')
app.config['THUMBNAIL_FOLDER'] = os.path.join(os.getcwd(), 'static', 'thumbnails')
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size

# Ensure upload directories exist
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
os.makedirs(app.config['THUMBNAIL_FOLDER'], exist_ok=True)

# Initialize extensions
db = SQLAlchemy(app)
migrate = Migrate(app, db)

# Database Model
class Photo(db.Model):
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    filename = db.Column(db.String(255), nullable=False)
    original_filename = db.Column(db.String(255), nullable=False)
    file_size = db.Column(db.Integer, nullable=False)
    mime_type = db.Column(db.String(100), nullable=False)
    upload_date = db.Column(db.DateTime, default=datetime.utcnow)
    description = db.Column(db.Text)

    def __init__(self, filename, original_filename, file_size, mime_type, description=None):
        self.filename = filename
        self.original_filename = original_filename
        self.file_size = file_size
        self.mime_type = mime_type
        self.description = description

    def to_dict(self):
        return {
            'id': self.id,
            'filename': self.filename,
            'original_filename': self.original_filename,
            'file_size': self.file_size,
            'mime_type': self.mime_type,
            'upload_date': self.upload_date.isoformat(),
            'description': self.description,
            'url': url_for('uploaded_file', filename=self.filename, _external=True),
            'thumbnail_url': url_for('thumbnail', photo_id=self.id, _external=True)
        }

# Helper functions
def allowed_file(filename):
    """Check if file extension is allowed"""
    ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def create_thumbnail(image_path, photo_id):
    """Create a thumbnail for the uploaded image"""
    try:
        with Image.open(image_path) as img:
            # Convert to RGB if necessary (for JPEG compatibility)
            if img.mode != 'RGB':
                img = img.convert('RGB')

            # Calculate thumbnail size (max 300x300)
            img.thumbnail((300, 300))

            # Save thumbnail
            thumbnail_path = os.path.join(app.config['THUMBNAIL_FOLDER'], f"{photo_id}_thumb.jpg")
            img.save(thumbnail_path, 'JPEG', quality=85)

    except Exception as e:
        print(f"Error creating thumbnail: {e}")
        # Continue without thumbnail if creation fails

# Routes
@app.route('/')
def index():
    """Main page with photo gallery"""
    photos_list = Photo.query.order_by(Photo.upload_date.desc()).all()
    return render_template('index.html', photos=photos_list)

@app.route('/upload', methods=['GET', 'POST'])
def upload():
    """Upload photo page and handler"""
    if request.method == 'POST':
        if 'photo' not in request.files:
            flash('No photo file selected', 'error')
            return redirect(request.url)

        file = request.files['photo']
        description = request.form.get('description', '').strip()

        if file.filename == '':
            flash('No photo file selected', 'error')
            return redirect(request.url)

        if file and allowed_file(file.filename):
            try:
                # Generate unique filename
                filename = secure_filename(file.filename)
                unique_filename = f"{uuid.uuid4()}_{filename}"
                file_path = os.path.join(app.config['UPLOAD_FOLDER'], unique_filename)

                # Save the file
                file.save(file_path)

                # Get file info
                file_size = os.path.getsize(file_path)

                # Create thumbnail
                photo_id = unique_filename.split('_')[0]  # Extract UUID
                create_thumbnail(file_path, photo_id)

                # Save to database
                photo = Photo(
                    filename=unique_filename,
                    original_filename=filename,
                    file_size=file_size,
                    mime_type=file.content_type,
                    description=description
                )
                db.session.add(photo)
                db.session.commit()

                flash('Photo uploaded successfully!', 'success')
                return redirect(url_for('view_photo', photo_id=photo.id))

            except Exception as e:
                flash(f'Error uploading photo: {str(e)}', 'error')
                return redirect(request.url)
        else:
            flash('Invalid file type. Please upload JPG, JPEG, PNG, or GIF images.', 'error')
            return redirect(request.url)

    return render_template('upload.html')

@app.route('/photo/<photo_id>')
def view_photo(photo_id):
    """View individual photo"""
    photo = Photo.query.get_or_404(photo_id)
    return render_template('view_photo.html', photo=photo)

@app.route('/photos')
def photos_list():
    """API endpoint to list all photos"""
    photos_list = Photo.query.order_by(Photo.upload_date.desc()).all()
    return jsonify({
        'photos': [photo.to_dict() for photo in photos_list],
        'total': len(photos_list)
    })

@app.route('/photo/<photo_id>/delete', methods=['POST'])
def delete_photo(photo_id):
    """Delete a photo"""
    photo = Photo.query.get_or_404(photo_id)

    try:
        # Delete files
        file_path = os.path.join(app.config['UPLOAD_FOLDER'], photo.filename)
        thumbnail_path = os.path.join(app.config['THUMBNAIL_FOLDER'], f"{photo.id}_thumb.jpg")

        if os.path.exists(file_path):
            os.remove(file_path)
        if os.path.exists(thumbnail_path):
            os.remove(thumbnail_path)

        # Delete from database
        db.session.delete(photo)
        db.session.commit()

        flash('Photo deleted successfully!', 'success')
        return redirect(url_for('index'))

    except Exception as e:
        flash(f'Error deleting photo: {str(e)}', 'error')
        return redirect(url_for('view_photo', photo_id=photo_id))

@app.route('/uploads/photos/<filename>')
def uploaded_file(filename):
    """Serve uploaded files"""
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

@app.route('/thumbnail/<photo_id>')
def thumbnail(photo_id):
    """Serve photo thumbnails"""
    photo = Photo.query.get_or_404(photo_id)
    thumbnail_filename = f"{photo.id}_thumb.jpg"
    thumbnail_path = os.path.join(app.config['THUMBNAIL_FOLDER'], thumbnail_filename)

    if os.path.exists(thumbnail_path):
        return send_from_directory(app.config['THUMBNAIL_FOLDER'], thumbnail_filename)
    else:
        # Return original if thumbnail doesn't exist
        return send_from_directory(app.config['UPLOAD_FOLDER'], photo.filename)

# Create database tables
with app.app_context():
    db.create_all()

# Health check endpoint
@app.route('/health')
def health_check():
    """Health check endpoint for Kubernetes"""
    return jsonify({
        'status': 'healthy',
        'service': 'photo-gallery',
        'timestamp': datetime.utcnow().isoformat()
    }), 200

# Error handlers
@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.getenv('PORT', 5000)), debug=os.getenv('FLASK_DEBUG', 'False').lower() == 'true')