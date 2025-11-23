from flask import Flask, jsonify, request

app = Flask(__name__)

# In-memory database
books = []

@app.route('/books', methods=['GET'])
def get_books():
    return jsonify(books), 200

@app.route('/books', methods=['POST'])
def add_book():
    data = request.get_json()
    if not data or 'title' not in data or 'author' not in data:
        return jsonify({'error': 'Invalid book data'}), 400
    
    book = {
        'id': len(books) + 1,
        'title': data['title'],
        'author': data['author']
    }
    books.append(book)
    return jsonify(book), 201

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'healthy'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
