import requests
import sys
import argparse
import time

def smoke_test(url):
    print(f"Running smoke tests against {url}...")
    
    # 1. Health Check
    try:
        resp = requests.get(f"{url}/health")
        if resp.status_code == 200 and resp.json().get('status') == 'healthy':
            print("✅ Health check passed")
        else:
            print(f"❌ Health check failed: {resp.status_code} {resp.text}")
            return False
    except Exception as e:
        print(f"❌ Health check failed with exception: {e}")
        return False

    # 2. Add Book
    try:
        new_book = {'title': 'Smoke Test Book', 'author': 'Tester'}
        resp = requests.post(f"{url}/books", json=new_book)
        if resp.status_code == 201 and resp.json().get('title') == 'Smoke Test Book':
            print("✅ Add book passed")
        else:
            print(f"❌ Add book failed: {resp.status_code} {resp.text}")
            return False
    except Exception as e:
        print(f"❌ Add book failed with exception: {e}")
        return False

    # 3. List Books
    try:
        resp = requests.get(f"{url}/books")
        if resp.status_code == 200 and len(resp.json()) > 0:
            print("✅ List books passed")
        else:
            print(f"❌ List books failed: {resp.status_code} {resp.text}")
            return False
    except Exception as e:
        print(f"❌ List books failed with exception: {e}")
        return False

    print("🎉 All smoke tests passed!")
    return True

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Run smoke tests.')
    parser.add_argument('--url', type=str, default='http://localhost:5000', help='Base URL of the app')
    args = parser.parse_args()
    
    success = smoke_test(args.url)
    if not success:
        sys.exit(1)
