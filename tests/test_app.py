import pytest
from app.app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_health_check(client):
    rv = client.get('/health')
    assert rv.status_code == 200
    assert rv.json == {'status': 'healthy'}

def test_get_books_empty(client):
    rv = client.get('/books')
    assert rv.status_code == 200
    assert rv.json == []

def test_add_book(client):
    new_book = {'title': 'The Hobbit', 'author': 'J.R.R. Tolkien'}
    rv = client.post('/books', json=new_book)
    assert rv.status_code == 201
    assert rv.json['title'] == 'The Hobbit'
    assert rv.json['author'] == 'J.R.R. Tolkien'
    assert 'id' in rv.json

def test_add_book_invalid(client):
    new_book = {'title': 'The Hobbit'} # Missing author
    rv = client.post('/books', json=new_book)
    assert rv.status_code == 400
