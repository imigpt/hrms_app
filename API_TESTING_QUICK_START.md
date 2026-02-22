# User API Integration - Quick Start Guide

## 🎯 Overview

Your HRMS Flutter app now has **ALL user-facing APIs integrated** and **tested**. This guide shows you how to use the new API testing dashboard.

---

## ✨ What's New

### 1. **User API Integration Screen** (NEW)
A professional API testing dashboard accessible from your Profile Screen.

**Features**:
- ✅ Test 16+ user-facing API endpoints in real-time
- ✅ Filter by category (Auth, Attendance, Leave, Expense, etc.)
- ✅ See response times, status codes, and JSON responses
- ✅ Run individual tests or all tests at once
- ✅ Summary showing passed/failed/total tests

### 2. **Enhanced Profile Screen**
Three API testing options in AppBar:
- 🛡️ **User API Integration** (NEW) - Test all user-facing APIs
- 🔌 **API Test Suite** - All 26 endpoints (including admin for dev)
- 🧪 **Employee Tests** - Employee-specific endpoints

---

## 🚀 How to Access

### Step 1: Open Your App
Launch the HRMS app and log in with your credentials.

### Step 2: Navigate to Profile
Tap the **Profile** icon in the bottom navigation bar.

### Step 3: Open API Test Dashboard
You'll see three icons in the AppBar (top-right):
- 🛡️ **Cyan Shield** = User API Integration (NEW - first icon)
- 🔌 **Pink API** = Employee API Tests
- 🧪 **Amber Bug** = All API Tests

**Tap the Cyan Shield icon (🛡️)** to open the User API Integration dashboard.

---

## 📊 Dashboard Overview

### Top: Summary Metrics
```
┌─────────────────────────────────────────────┐
│  Total: 16  |  Passed: 0  |  Failed: 0     │
└─────────────────────────────────────────────┘
```
- **Total**: Number of endpoints to test
- **Passed**: Successful responses (HTTP 200-299)
- **Failed**: Failed responses or errors

### Middle: Filter & Controls
```
All  🔐 Auth  📍 Attendance  🏖️ Leave  💰 Expense ...
RUN ALL TESTS (16)
```
- **Category Buttons**: Filter endpoints by type
- **Run All Tests**: Test all visible endpoints (shows progress)

### Main Area: Test Results
Each endpoint shows:
- ✓ Status icon (Success/Failed/Running/Idle)
- Name and HTTP method (GET, POST, etc.)
- Endpoint path
- Response time (ms)
- HTTP status code

---

## 🧪 Testing APIs

### Option A: Run All Tests
1. Open **User API Integration** screen
2. Tap **"RUN ALL TESTS (16)"** button
3. Wait for tests to complete
4. View summary: "Passed: 12" etc.

### Option B: Test by Category
1. Tap a category button: **🔐 Auth** or **📍 Attendance**
2. Only tests in that category appear
3. Tap **"RUN ALL TESTS (4)"** for that category only

### Option C: Test Individual Endpoint
1. Find the endpoint in the list
2. Tap the **↻ Refresh icon** on the right
3. Status changes: Running → Success/Failed

---

## 📖 Reading Results

### ✅ Success (Green)
```
✓ Get Current User
GET /auth/me
✓ 200 ms 45ms
```
- Green checkmark = Response successful
- HTTP 200 = Valid response received
- 45ms = Request took 45 milliseconds

### ❌ Failed (Red)
```
✗ Get Current User
GET /auth/me
✗ 401 ms 120ms
```
- Red X = Response failed or error
- HTTP 401 = Unauthorized (token expired?)
- 120ms = Request took 120 milliseconds

### ⏳ Running (Orange)
```
⏳ Get Current User
GET /auth/me
⏳ -- ms --ms
```
- Orange hourglass = Request in progress
- Waits until response received

---

## 💬 Viewing Response Details

### Step 1: Tap Any Test Result
Tapping a test row selects it (shows cyan border).

### Step 2: Switch to "Response" Tab
Bottom tabs show:
- **Test Suite** (current list view)
- **Response** (detailed response viewer)

### Step 3: View Response
Shows:
- ✓/✗ Status icon
- Test name
- HTTP method & endpoint
- Response time
- **Response JSON** (pretty-printed)
- Any error messages

**Example Response**:
```json
{
  "_id": "507f1f77bcf86cd799439011",
  "name": "Rahul Gupta",
  "email": "rahul@company.com",
  "designation": "Senior Developer",
  "department": "Engineering"
}
```

---

## 🔧 API Categories Tested

### 🔐 Auth (2 endpoints)
- Get Current User Profile
- Logout

### 📍 Attendance (4 endpoints)
- Today's Attendance Status
- Monthly Attendance Summary
- Attendance Records
- Edit Requests

### 🏖️ Leave (3 endpoints)
- Leave Balance
- Leave Statistics
- My Leave Requests

### 💰 Expense (2 endpoints)
- Expenses List
- Expense Statistics

### 👤 Profile (1 endpoint)
- Get Profile

### 👥 Employee (3 endpoints)
- Dashboard Statistics
- Team Members
- My Tasks

### ✅ Tasks (2 endpoints)
- Tasks List
- Task Statistics

### 📢 Announcements (2 endpoints)
- All Announcements
- Unread Count

---

## ⚠️ Troubleshooting

### Issue: "No authentication token found"
**Solution**: 
- Log out and log in again
- Refresh app (close and reopen)
- Check internet connection

### Issue: 401 Unauthorized Errors
**Cause**: Token expired or invalid
**Solution**: 
- Log out from Profile Screen
- Log in again
- Retry tests

### Issue: 404 Not Found Errors
**Cause**: Backend API endpoint doesn't exist
**Solution**: 
- Check backend is running
- Verify endpoint URL is correct
- Contact backend team

### Issue: Network Timeout (>15 seconds)
**Cause**: Slow internet or backend down
**Solution**: 
- Check internet connection
- Retry test (tap refresh icon)
- Try again later

---

## 📋 Complete Integration Checklist

✅ **Auth Service** - 4 endpoints implemented
✅ **Attendance Service** - 8 endpoints implemented  
✅ **Leave Service** - 6 user endpoints implemented (admin methods excluded)
✅ **Expense Service** - 6 endpoints implemented
✅ **Profile Service** - 4 endpoints implemented
✅ **Employee Service** - 4 endpoints implemented
✅ **Task Service** - 4 endpoints implemented
✅ **Announcement Service** - 2 endpoints implemented
✅ **Token Management** - Secure storage & authentication
✅ **File Uploads** - Photos, receipts, attachments
✅ **Error Handling** - Consistent error messages
✅ **Response Models** - All endpoints have models
✅ **Test Dashboard** - 16 user APIs tested
✅ **UI Integration** - Tests accessible from Profile Screen

---

## 🎓 Understanding the Dashboard

### Status Icons
| Icon | Meaning | Color |
|------|---------|-------|
| ✓ | Test passed | 🟢 Green |
| ✗ | Test failed | 🔴 Red |
| ⏳ | Running | 🟠 Orange |
| ⊙ | Not run yet | ⚪ Gray |
| ⊘ | Skipped | ⚪ Gray |

### HTTP Status Codes (Quick Reference)
| Code | Meaning |
|------|---------|
| 200 | ✅ OK - Request successful |
| 201 | ✅ Created - Resource created |
| 400 | ❌ Bad Request - Invalid data |
| 401 | ❌ Unauthorized - Invalid token |
| 403 | ❌ Forbidden - No permission |
| 404 | ❌ Not Found - Endpoint missing |
| 500 | ❌ Server Error - Backend issue |

---

## 🔒 Security Notes

✅ **Secure**:
- All APIs use Bearer token authentication
- Tokens stored in encrypted SharedPreferences
- SSL/TLS encryption (HTTPS)
- No sensitive data in logs

⚠️ **Best Practices**:
- Never share your authentication token
- Log out when done testing
- Don't test in public WiFi
- Report security issues to team

---

## 📚 Documentation

See these files for more details:
- **Integration Details**: `hrms_app/USER_API_INTEGRATION.md`
- **Service Code**: `hrms_app/lib/services/`
- **Test Screen**: `hrms_app/lib/screen/user_api_integration_screen.dart`
- **Backend API**: [HRMS-Backend/README.md](../HRMS-Backend/README.md)

---

## 🎯 Next Steps

1. **Test All APIs**: Open dashboard and run all tests
2. **Check Responses**: Verify data matches expectations
3. **Handle Errors**: Implement retry logic in your UI
4. **Monitor Performance**: Note response times
5. **Go Live**: Deploy with confidence!

---

**Ready to test? Open your Profile Screen and tap the 🛡️ icon!**

---

**Version**: 2.0  
**Last Updated**: 2026-01-29  
**Status**: ✅ All user APIs integrated and ready to test
