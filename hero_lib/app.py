from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
import pandas as pd
import os

app = Flask(__name__, static_folder='static')
CORS(app)  # Enable CORS for all routes

# Load data
BOOKS_PATH = os.path.join(os.path.dirname(__file__), '..', 'books_data', 'books.csv')

def get_books_dataframe():
    try:
        # Read CSV with semicolon delimiter, handling bad lines if necessary
        df = pd.read_csv(BOOKS_PATH, sep=';', on_bad_lines='skip', encoding='latin-1')
        return df
    except Exception as e:
        print(f"Error reading CSV: {e}")
        return pd.DataFrame()

# Serve static files from the 'static' directory
@app.route('/', defaults={'path': ''})
@app.route('/<path:path>')
def serve_static(path):
    if path != "" and os.path.exists(os.path.join(app.static_folder, path)):
        return send_from_directory(app.static_folder, path)
    else:
        # For Next.js/React routing, serve index.html for unknown paths
        return send_from_directory(app.static_folder, 'index.html')

@app.route('/api/books', methods=['GET']) # Prefix with /api to avoid collision with frontend
def get_books():
    page = int(request.args.get('page', 1))
    limit = int(request.args.get('limit', 20))
    
    df = get_books_dataframe()
    
    if df.empty:
        return jsonify({'data': [], 'total': 0, 'page': page, 'pages': 0}), 200
    
    total_books = len(df)
    total_pages = (total_books + limit - 1) // limit
    
    start = (page - 1) * limit
    end = start + limit
    
    # Slice the dataframe
    paginated_df = df.iloc[start:end]
    
    # Replace NaN with None/empty string for JSON serialization
    paginated_df = paginated_df.fillna('')
    
    books_list = paginated_df.to_dict(orient='records')
    
    return jsonify({
        'data': books_list,
        'total': total_books,
        'page': page,
        'pages': total_pages
    }), 200

@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'healthy'}), 200

if __name__ == '__main__':
    # Use PORT from environment variable or default to 5000
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)
