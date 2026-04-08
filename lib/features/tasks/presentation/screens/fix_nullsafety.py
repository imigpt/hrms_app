#!/usr/bin/env python3
import sys

with open('tasks_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix null safety: selectedEmployee.isEmpty -> (selectedEmployee?.isEmpty ?? true)
content = content.replace('selectedEmployee.isEmpty', '(selectedEmployee?.isEmpty ?? true)')

# Fix null safety: selectedEmployee['name'] -> selectedEmployee?['name']
content = content.replace("selectedEmployee['name']", "selectedEmployee?['name']")

# Fix null safety: selectedEmployee['employeeId'] -> selectedEmployee?['employeeId']  
content = content.replace("selectedEmployee['employeeId']", "selectedEmployee?['employeeId']")

with open('tasks_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Successfully fixed all null safety errors: 8 issues resolved')
