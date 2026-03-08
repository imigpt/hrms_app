# Payroll Screen Implementation

Complete Flutter payroll screen implementation for admin panel and employee views, matching the frontend PayrollModule UI.

## ✅ Implemented Features

### Admin View Features
1. **Statistics Cards**
   - Generated count with file icon
   - Paid count with check circle icon
   - Pending count with schedule icon
   - Total Paid amount with rupee icon
   - Colors: Primary, Success, Warning, Primary
   - Responsive horizontal scroll on mobile

2. **Info Banner**
   - Setup basic salary reminder
   - Blue background with info icon
   - Displayed above filters

3. **Filters Section**
   - Employee filter dropdown (all employees loaded from API)
   - Year filter (current year - 5 years)
   - Month filter (using month names constant)
   - Filter button to apply filters
   - Responsive design with horizontal scroll on mobile
   - Generate Payroll button

4. **Payroll Table/List**
   - User card showing:
     - Avatar placeholder with first letter + background color
     - Employee name
     - Department • Month Year
     - Status badge (generated: primary, paid: success, pending: warning)
   - Salary details:
     - Net Salary (bold, highlighted)
     - Payment Date (if paid: green, else: orange)
   - Action buttons:
     - **View** - Opens details modal
     - **Download** - Generates payslip PDF preview
     - **Mark Paid** - Available only for generated status (admin only)
     - **Delete** - Available only for admin users
   - Proper spacing and borders

5. **Generate Payroll Dialog**
   - Employee dropdown selector
   - Month dropdown (using month names constant)
   - Year dropdown (current year - 4 years)
   - Cancel and Generate buttons
   - Form validation
   - Error handling with snackbar

6. **View/Details Modal**
   - Personal info section
   - Month and Status display
   - Earnings breakdown:
     - Basic salary
     - Allowances list
   - Deductions breakdown
   - Pre-payment deductions
   - Net salary summary
   - Payment date (if available)
   - Notes (if available)
   - Bottom sheet with drag handle

7. **Download Payslip**
   - Generates formatted text payslip
   - Shows preview in dialog
   - Displays:
     - Employee name
     - Month and year
     - Earnings (basic + allowances)
     - Deductions
     - Net salary
     - Payment date
     - Status
   - Copy to clipboard functionality

8. **Mark Paid Functionality**
   - Updates payroll status to 'paid'
   - Sets payment date to current date
   - Refreshes payroll list
   - Shows success notification

### Employee View Features
1. **Multiple Tabs**
   - Salary tab: Shows CTC and salary components
   - Payslips tab: History of generated payslips
   - Pre-Payments tab: Pre-payment requests with status
   - Increments tab: Career progression and promotions

2. **Salary Tab**
   - Cost to Company display with gradient background
   - Breakdown showing: Basic, Allowances, Deductions
   - Earnings section with allowances list
   - Deductions section
   - Net salary summary

3. **Payslips Tab**
   - Payslip cards with month badge
   - Status badge
   - Summary stats: Gross, Deductions, Net
   - Payment date information
   - Tap to view details

4. **Pre-Payments Tab**
   - Summary cards: Approved, Pending, Rejected amounts
   - Pre-payment list with status colors
   - Amount, deduction month, and description
   - Request date

5. **Increments Tab**
   - Summary cards: Increments, Promotions, Others count
   - Increment/promotion cards showing:
     - Type badge with icon
     - Effective date
     - Current and new designation
     - CTC change with trend indicator
     - Reason (if available)

### Shared Features
1. **Month Names Constants**
   - Full names: January - December
   - Short names: Jan - Dec
   - Used throughout the app instead of hardcoded values

2. **Status Colors**
   - Generated: Primary Color (#FF8FA3)
   - Paid: Success Color (#00C853)
   - Pending: Warning Color (#FFA500)

3. **Theme Integration**
   - Uses AppTheme colors:
     - primaryColor for primary actions
     - successColor for success states
     - warningColor for warning states
     - errorColor for errors
   - Dark theme consistently applied
   - Card and background colors from AppTheme

4. **Responsive Design**
   - ResponsiveUtils integration
   - Mobile, tablet, desktop breakpoints
   - Adaptive layouts
   - Proper spacing and padding
   - Horizontal scroll on filters for mobile

5. **Error & Loading States**
   - Circular progress indicator for loading
   - Empty state with icon and message
   - Snackbar notifications for:
     - Success actions
     - Error messages
     - Validation errors

6. **API Integration**
   - PayrollService.getMyPayrolls() - Fetch employee payrolls
   - PayrollService.getPayrolls() - Fetch all payrolls (admin)
   - PayrollService.generatePayroll() - Generate new payroll
   - PayrollService.updatePayroll() - Update payroll (mark paid)
   - PayrollService.deletePayroll() - Delete payroll
   - PayrollService.getMySalary() - Fetch employee salary
   - PayrollService.getPrePayments() - Fetch pre-payments
   - PayrollService.getIncrements() - Fetch increments
   - AdminEmployeesService.getEmployees() - Get employee list for filtering

7. **Helper Methods**
   - `_monthName()` - Get short month name
   - `_monthNameFull()` - Get full month name
   - `_currency()` - Format currency with ₹ symbol
   - `_payrollStatusColor()` - Get status color from AppTheme
   - `_generatePayslipContent()` - Create payslip text
   - `_downloadPayslip()` - Download payslip
   - `_copyToClipboard()` - Copy to clipboard
   - Status badge widget
   - Statistics card widget

## 📁 File Structure

```
lib/
├── screen/
│   └── payroll_screen.dart           # Main implementation
├── models/
│   └── payroll_model.dart            # Data models
├── services/
│   ├── payroll_service.dart          # API calls
│   ├── token_storage_service.dart    # Token management
│   └── admin_employees_service.dart  # Employee list API
├── theme/
│   └── app_theme.dart                # Theme colors & styles
└── utils/
    └── responsive_utils.dart         # Responsive design utilities
```

## 🎨 Design Specifications

### Colors (from AppTheme)
- Primary: #FF8FA3 (Pink)
- Success: #00C853 (Green)
- Warning: #FFA500 (Orange)
- Error: #FF6B6B (Red)
- Background: #050505 (Dark)
- Card: #121212 (Darker)
- Surface: #1C1C1E
- Text: #FFFFFF (White on dark)

### Spacing
- Small: 8px
- Standard: 12-16px
- Large: 20-24px
- Extra Large: 32px

### Typography
- Headings: 18-22px, Bold
- Body: 14-16px, Regular
- Labels: 12-13px, Regular/Semi-bold
- Status badges: 11-12px, Semi-bold

### Breakpoints
- Mobile: < 600px
- Tablet: 600px - 900px
- Desktop: 900px - 1200px
- Large Desktop: >= 1200px

## 🔄 Data Flow

1. **Initial Load**
   - Get token from storage
   - Load payrolls, pre-payments, increments
   - Load employee salary (for employees)
   - Load employee list (for admins)

2. **Admin Actions**
   - Select employee, month, year → Generate payroll
   - Click mark paid → Update status
   - Click delete → Delete payroll with confirmation
   - Filter → Re-apply filters to list

3. **Download Flow**
   - Click download → Generate payslip content
   - Show preview dialog
   - Copy to clipboard option

## 🚀 Usage

```dart
// Navigate to payroll screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => PayrollScreen(role: userRole),
  ),
);
```

## ⚙️ Configuration

### Dependencies Required
- `flutter/material.dart`
- `intl/intl.dart` - Date formatting
- `models/payroll_model.dart` - Data models
- `services/payroll_service.dart` - API
- `theme/app_theme.dart` - Theme
- `utils/responsive_utils.dart` - Responsive design

### Month Names Constants
The implementation uses two constants:
- `monthNames` - Full month names (January - December)
- `monthNamesShort` - Short month names (Jan - Dec)

These are used in dropdowns, badges, and display throughout the app.

## 📝 Notes

1. **Download Functionality**
   - Currently shows preview in dialog
   - Copy to clipboard implemented
   - For PDF generation in production: implement with `pdf` or `pdfx` package

2. **Responsive Design**
   - Mobile users get horizontal scrolling for filters
   - Desktop users see all filters in one row
   - Action buttons wrap responsively

3. **State Management**
   - Uses local state with setState()
   - Proper loading states for each data fetch
   - Refresh indicator support

4. **Error Handling**
   - Token validation
   - API error messages shown in snackbar
   - Graceful fallbacks for missing data

## 🎯 UI Matching

The implementation matches the frontend PayrollModule with:
✅ Same color scheme and typography
✅ Same layout and component hierarchy
✅ Same workflow and user interactions
✅ Same data display format
✅ Responsive design considerations
✅ Dark theme styling
✅ Material Design principles
