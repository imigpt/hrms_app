# Privacy Policy

**Application Name:** HRMS App  
**Developer / Organization:** Aselea  
**Platform:** Android & iOS  
**App Version:** 1.0.0  
**Effective Date:** February 25, 2026  
**Last Updated:** February 25, 2026  

---

## 1. Introduction

Welcome to the HRMS App ("App"), developed and operated by **Aselea** ("we," "our," or "us"). This Privacy Policy explains how we collect, use, disclose, and protect information about you when you use our Human Resource Management System mobile application.

By using the App, you agree to the collection and use of information as described in this policy. If you do not agree with the terms of this Privacy Policy, please do not use the App.

---

## 2. Information We Collect

### 2.1 Personal Information
When you register and use the App, we may collect:
- **Full Name**
- **Email Address**
- **Employee ID**
- **Department and Position**
- **Profile Photo**
- **Phone Number** (if provided)
- **Password** (stored in encrypted form)
- **Role** (Employee, HR, Admin)

### 2.2 Attendance & Location Data
To verify attendance and enforce office location policies, the App collects:
- **GPS Location Coordinates** — captured at the time of check-in and check-out
- **Check-in / Check-out Timestamps** — recorded with each attendance entry
- **Attendance Photos** — a selfie captured via the front camera at the time of check-in to verify physical presence

> Location data is collected **only during check-in and check-out actions** and is not tracked continuously in the background.

### 2.3 Leave & Payroll Information
- Leave requests, types, dates, and approval statuses
- Payroll records, salary details, allowances, and deductions
- Leave balances and usage history

### 2.4 Task & Work Data
- Tasks assigned to you, their status, progress, and due dates
- Subtasks and attachments related to your work

### 2.5 Communication Data
- **Chat Messages** — messages sent within the App's chat feature (personal and group)
- **Media Files** — photos, documents, and files shared in chat
- **Announcements** — company-wide announcements you have read or received

### 2.6 Device & Usage Data
- **Device Type and OS Version** — for compatibility and debugging
- **Login History** — timestamps and IP addresses of login sessions
- **Push Notification Tokens** — for delivering local and push notifications
- **App Usage Logs** — for performance monitoring and error reporting

### 2.7 Files & Documents
- Files uploaded via the App (expense receipts, task attachments, etc.)
- Photos selected from your device gallery using the image picker

---

## 3. How We Use Your Information

We use the information we collect for the following purposes:

| Purpose | Data Used |
|---|---|
| Authenticate and manage your account | Email, password, employee ID |
| Record and verify attendance | GPS location, attendance photo, timestamps |
| Process leave requests | Leave dates, type, reason, leave balance |
| Display payroll and salary information | Salary records, allowances, deductions |
| Manage tasks and assignments | Task data, progress, attachments |
| Enable real-time chat and announcements | Messages, media, notification tokens |
| Enforce office location policies | GPS coordinates |
| Send notifications (attendance, leaves, tasks) | Notification token, device info |
| Provide customer support | Account and usage data |
| Improve app performance and fix bugs | Device logs, error reports |

---

## 4. Permissions We Request

The App requests the following device permissions:

| Permission | Purpose |
|---|---|
| **Camera** | Capture attendance selfie at check-in |
| **Location (Fine & Coarse)** | Verify employee is within office premises during check-in/out |
| **Storage / Media** | Select and upload files, photos, and documents |
| **Notifications** | Send attendance reminders, leave updates, task alerts |
| **Internet** | Communicate with the HRMS backend server |
| **Microphone** | Not used — not requested |

You may revoke any permission from your device settings. Revoking required permissions (Camera, Location) may limit functionality such as attendance check-in.

---

## 5. Data Storage and Security

- All data is transmitted over **HTTPS** with TLS encryption.
- Passwords are stored using **secure hashing** (never in plain text).
- Authentication is managed via **JWT (JSON Web Tokens)** with expiry periods.
- Attendance photos are stored securely on our backend server.
- Location data is associated with your attendance records and stored on our server.
- We implement access controls so that employees can only view their own data; HR and Admin roles have controlled, permission-based access to relevant records.

---

## 6. Data Sharing and Disclosure

We **do not sell, rent, or share** your personal information with third parties for commercial purposes.

We may share data in the following limited circumstances:

- **Within Your Organization:** HR managers and Admins may access attendance, leave, payroll, and task records within your company for management purposes.
- **Service Providers:** We may use trusted third-party services for hosting, cloud storage, or error monitoring. These providers are bound by confidentiality agreements.
- **Legal Requirements:** We may disclose information if required to comply with applicable law, regulation, or legal process.
- **Emergency Situations:** To protect the safety of users or others in urgent situations.

---

## 7. Data Retention

We retain your data for as long as your account is active or as required for legitimate business purposes:

- **Account Data:** Retained for the duration of employment and a reasonable period thereafter.
- **Attendance Records:** Retained as required by your organization's HR policies.
- **Chat Messages:** Retained on the server until deleted by authorized users or the administrator.
- **Payroll Records:** Retained as required by applicable financial and labor laws.

Upon account deletion or deactivation, your data will be removed or anonymized within **30 days**, except where retention is required by law.

---

## 8. Your Rights

Depending on your jurisdiction, you may have the right to:

- **Access** — Request a copy of the personal data we hold about you.
- **Correction** — Request correction of inaccurate or incomplete data.
- **Deletion** — Request deletion of your personal data (subject to legal obligations).
- **Restriction** — Request that we limit how we use your data.
- **Portability** — Request your data in a structured, machine-readable format.
- **Objection** — Object to certain processing activities.

To exercise any of these rights, please contact your HR Administrator or reach out to us at the contact details below.

---

## 9. Children's Privacy

The HRMS App is intended for use by **employees of registered organizations** and is not directed at children under the age of 13. We do not knowingly collect personal information from children. If you believe a child has provided us with personal information, please contact us immediately.

---

## 10. Third-Party Links and Services

The App may contain links to external websites or integrate with third-party services. We are not responsible for the privacy practices of those third parties. We encourage you to review their privacy policies independently.

---

## 11. Push Notifications

The App uses **Flutter Local Notifications** to send on-device alerts related to:
- Attendance reminders
- Leave request status updates
- Task assignments and deadlines
- Company announcements

You may disable notifications at any time in your device settings. Disabling notifications will not affect core app functionality.

---

## 12. Real-Time Communication

The App uses **WebSocket / Socket.IO** for real-time features including chat messaging and live announcements. Messages are transmitted securely over encrypted connections. Chat history is stored on our servers and accessible to authorized parties within your organization.

---

## 13. Changes to This Privacy Policy

We may update this Privacy Policy from time to time. When we do, we will:
- Update the **"Last Updated"** date at the top of this document.
- Notify users via an in-app announcement or notification where appropriate.

Continued use of the App after changes are posted constitutes your acceptance of the revised policy.

---

## 14. Contact Us

If you have any questions, concerns, or requests regarding this Privacy Policy or our data practices, please contact:

**Aselea — HRMS Support**  
📧 Email: support@aselea.com  
🌐 Website: https://aselea.com  

---

*This Privacy Policy was generated for the HRMS App (version 1.0.0) by Aselea.*
