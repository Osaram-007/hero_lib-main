from flask import Flask, jsonify, request
from flask_cors import CORS
import pandas as pd
import os

app = Flask(__name__)
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

@app.route('/books', methods=['GET'])
def get_books():
    page = int(request.args.get('page', 1))
    limit = int(request.args.get('limit', 20))
    
    df = get_books_dataframe()
    
    if df.empty:
        return jsonify({'data': [], 'total': 0, 'page': page, 'pages': 0}), 200
        
    # Rename columns to be friendlier
    # Assumes columns are "ISBN";"Book-Title";"Book-Author";"Year-Of-Publication";"Publisher";"Image-URL-S";"Image-URL-M";"Image-URL-L"
    # Based on standard Book-Crossing dataset usually found in these CSVs
    # We should normalize column names
    
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

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'healthy'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
