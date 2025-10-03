#!/bin/bash

# Test Backend API Connectivity
# Run this to verify the backend is working before starting the Flutter app

echo "? Testing TeleGramApp Backend API..."
echo ""

# Test 1: Health Check
echo "1?? Testing health endpoint..."
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/)
if [ "$response" == "200" ]; then
    echo "? Backend is running!"
else
    echo "? Backend is not responding (HTTP $response)"
    echo "   Please start the backend first: cd backend && uvicorn app.main:app --reload"
    exit 1
fi

# Test 2: API Documentation
echo ""
echo "2?? Testing API docs..."
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/docs)
if [ "$response" == "200" ]; then
    echo "? API docs available at: http://localhost:8000/api/docs"
else
    echo "??  API docs not available (HTTP $response)"
fi

# Test 3: Register Test User
echo ""
echo "3?? Testing user registration..."
register_response=$(curl -s -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test_'$(date +%s)'@example.com",
    "username": "testuser_'$(date +%s)'",
    "full_name": "Test User",
    "password": "password123",
    "department": "Engineering"
  }')

if echo "$register_response" | grep -q "email"; then
    echo "? User registration successful!"
    echo "   User: $(echo $register_response | jq -r '.email' 2>/dev/null || echo 'test user')"
else
    echo "??  Registration response: $register_response"
fi

# Test 4: Login
echo ""
echo "4?? Testing user login..."
login_response=$(curl -s -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "admin123"
  }')

if echo "$login_response" | grep -q "access_token"; then
    echo "? Login successful!"
    access_token=$(echo $login_response | jq -r '.tokens.access_token' 2>/dev/null)
    if [ ! -z "$access_token" ]; then
        echo "   Access token: ${access_token:0:50}..."
        
        # Test 5: Get Current User
        echo ""
        echo "5?? Testing authenticated endpoint..."
        me_response=$(curl -s -X GET http://localhost:8000/api/users/me \
          -H "Authorization: Bearer $access_token")
        
        if echo "$me_response" | grep -q "email"; then
            echo "? Authenticated request successful!"
            echo "   User: $(echo $me_response | jq -r '.email' 2>/dev/null || echo 'logged in user')"
        else
            echo "??  Authenticated request failed"
        fi
    fi
else
    echo "??  Login failed (try creating admin user first)"
    echo "   Response: $login_response"
fi

echo ""
echo "„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª"
echo "? Backend API test complete!"
echo ""
echo "? Next steps:"
echo "   1. Start Flutter app: cd frontend && flutter run"
echo "   2. Or view API docs: http://localhost:8000/api/docs"
echo "„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª„ª"
