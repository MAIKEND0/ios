11.14.0 - [FirebaseMessaging][I-FCM001000] FIRMessaging Remote Notifications proxy enabled, will swizzle remote notification receiver handlers. If you'd prefer to manually integrate Firebase Messaging, add "FirebaseAppDelegateProxyEnabled" to your Info.plist, and set it to NO. Follow the instructions at:
https://firebase.google.com/docs/cloud-messaging/ios/client#method_swizzling_in_firebase_messaging
to ensure proper integration.
[FirebaseAppDelegate] Firebase configured and push notifications initialized
[AppContainerView] 🚀 Starting app flow...
[AuthService] 🔍 === LOGIN STATUS CHECK ===
[AuthService] 🔍 Attempting to retrieve saved token...
[KeychainService] 🔍 Attempting to retrieve token...
[KeychainService] ✅ Keychain query successful
[KeychainService] ✅ Token retrieved from keychain
[AuthService] ✅ Token retrieved from keychain: eyJhbGciOi...
[AuthService] ✅ Token length: 199 characters
[AuthService] 🔍 Employee role: chef
[AuthService] ✅ Token and role found
[AuthService] ✅ Role: chef
[AuthService] ✅ Token: eyJhbGciOi...
[KeychainService] 🔍 Attempting to retrieve token...
[KeychainService] ✅ Keychain query successful
[KeychainService] ✅ Token retrieved from keychain
[BaseAPIService] Token załadowany z keychain
[AuthService] ✅ API service token set: true
[AuthService] 🔍 === LOGIN STATUS: TRUE ===
[AppContainerView] 🔐 Auth check result: LOGGED IN
[AuthService] 🔍 Employee name: Admin
[AppContainerView] 👤 User: Admin
[AuthService] 🔍 Employee role: chef
[AppContainerView] 🎭 Role: chef
[AppContainerView] 🔐 Biometric enabled: true
[AppContainerView] 🔐 Has stored credentials: true
[AppContainerView] 🔒 Showing biometric lock screen
[FirebaseAppDelegate] FCM token received: eSkhpHUaI0fopRr7fxgPoD:APA91bHx2DJF4eUYNPxWqZR03TCS3W7XkhCCebtCT9TQrY7rb_xOiWOjVkRFZl5Mt0sCvB0IouzkRCnTxXXCZVJjeEbo2sedrS19IfXyW5CkgYyKcFJrPww
[PushNotificationService] FCM Token stored locally: eSkhpHUaI0fopRr7fxgPoD:APA91bHx2DJF4eUYNPxWqZR03TCS3W7XkhCCebtCT9TQrY7rb_xOiWOjVkRFZl5Mt0sCvB0IouzkRCnTxXXCZVJjeEbo2sedrS19IfXyW5CkgYyKcFJrPww
[AuthService] 🔍 === LOGIN STATUS CHECK ===
[AuthService] 🔍 Attempting to retrieve saved token...
[KeychainService] 🔍 Attempting to retrieve token...
[KeychainService] ✅ Keychain query successful
[KeychainService] ✅ Token retrieved from keychain
[AuthService] ✅ Token retrieved from keychain: eyJhbGciOi...
[AuthService] ✅ Token length: 199 characters
[AuthService] 🔍 Employee role: chef
[AuthService] ✅ Token and role found
[AuthService] ✅ Role: chef
[AuthService] ✅ Token: eyJhbGciOi...
[AuthService] ✅ API service token set: true
[AuthService] 🔍 === LOGIN STATUS: TRUE ===
[AuthService] 🔍 Employee ID: 8
[AuthService] 🔍 Attempting to retrieve saved token...
[KeychainService] 🔍 Attempting to retrieve token...
[KeychainService] ✅ Keychain query successful
[KeychainService] ✅ Token retrieved from keychain
[AuthService] ✅ Token retrieved from keychain: eyJhbGciOi...
[AuthService] ✅ Token length: 199 characters
[PushNotificationService] Auth token found, length: 199
[PushNotificationService] Authorization header set
[PushNotificationService] Request URL: https://ksrcranes.dk/api/app/push/register-token-v2
[PushNotificationService] Request headers: ["Authorization": "Bearer eyJhbGciOiJIUzI1NiJ9.eyJpZCI6OCwiZW1haWwiOiJhZG1pbkBrc3JjcmFuZXMuZGsiLCJuYW1lIjoiQWRtaW4iLCJyb2xlIjoiY2hlZiIsImlhdCI6MTc0OTYzNDQ0OSwiZXhwIjoxNzQ5NzIwODQ5fQ.Lvtp4uUmwnlNwLrntUSp3k5WN0KsTfpRbhpcX0Wvr60", "Content-Type": "application/json"]
[PushNotificationService] HTTP Status: 200
[PushNotificationService] Raw response: {"success":true,"message":"Push token registered successfully","token_id":"1"}
[PushNotificationService] ✅ Token saved to server successfully!
[PushNotificationService] Token ID: 1
[BiometricLock] 🔐 Starting biometric authentication...
[BiometricAuth] Authentication successful
[BiometricLock] ✅ Biometric authentication successful
[AppContainerView] 🔔 Received biometric unlock completion notification
[AppContainerView] 📊 Starting data loading phase for logged in user...
[AppStateManager] 🚀 Starting app initialization...
[AuthService] 🔍 Employee ID: 8
[AuthService] 🔍 Employee name: Admin
[AuthService] 🔍 Employee role: chef
[AppStateManager] 🔄 Refreshing user data from AuthService
[AppStateManager] 👤 New user: Admin (chef)
[AppStateManager] 👤 User info loaded: Admin (chef)
[AppStateManager] 🔧 Initializing profile for role: chef
[AppContainerView] 👀 Starting to observe data loading completion...
[AppContainerView] 🔍 Data check 1/10
[AppContainerView] 🔍 - isAppInitialized: false
[AppContainerView] 🔍 - isLoadingInitialData: true
[AppContainerView] 🔍 - initializationError: false
[AppStateManager] 👨‍💼 Initializing chef leave management...
[KeychainService] 🔍 Attempting to retrieve token...
[KeychainService] ✅ Keychain query successful
[KeychainService] ✅ Token retrieved from keychain
[BaseAPIService] Token załadowany z keychain
[ChefLeaveAPIService] Fetching team leave requests: /api/app/chef/leave/requests?status=PENDING&page=1&limit=100&include_employee=true&include_approver=true&cacheBust=1749635444
[BaseAPIService] Dodano token do żądania: https://ksrcranes.dk/api/app/chef/leave/requests?status=PENDING&page=1&limit=100&include_employee=true&include_approver=true&cacheBust=1749635444
[BaseAPIService] GET https://ksrcranes.dk/api/app/chef/leave/requests?status=PENDING&page=1&limit=100&include_employee=true&include_approver=true&cacheBust=1749635444
[ChefLeaveAPIService] Fetching team leave balances: /api/app/chef/leave/balance?year=2025&cacheBust=1749635444
[BaseAPIService] Dodano token do żądania: https://ksrcranes.dk/api/app/chef/leave/balance?year=2025&cacheBust=1749635444
[BaseAPIService] GET https://ksrcranes.dk/api/app/chef/leave/balance?year=2025&cacheBust=1749635444
[ChefLeaveAPIService] Fetching leave statistics: /api/app/chef/leave/statistics?start_date=2025-05-11&end_date=2025-08-11&cacheBust=1749635444
[BaseAPIService] Dodano token do żądania: https://ksrcranes.dk/api/app/chef/leave/statistics?start_date=2025-05-11&end_date=2025-08-11&cacheBust=1749635444
[BaseAPIService] GET https://ksrcranes.dk/api/app/chef/leave/statistics?start_date=2025-05-11&end_date=2025-08-11&cacheBust=1749635444
[ChefLeaveAPIService] Fetching team calendar: /api/app/chef/leave/calendar?end_date=2025-08-11&start_date=2025-05-11&cacheBust=1749635444
[BaseAPIService] Dodano token do żądania: https://ksrcranes.dk/api/app/chef/leave/calendar?end_date=2025-08-11&start_date=2025-05-11&cacheBust=1749635444
[BaseAPIService] GET https://ksrcranes.dk/api/app/chef/leave/calendar?end_date=2025-08-11&start_date=2025-05-11&cacheBust=1749635444
[ChefLeaveAPIService] Fetching team leave requests: /api/app/chef/leave/requests?status=PENDING&page=1&limit=100&include_employee=true&include_approver=true&cacheBust=1749635444
[BaseAPIService] Dodano token do żądania: https://ksrcranes.dk/api/app/chef/leave/requests?status=PENDING&page=1&limit=100&include_employee=true&include_approver=true&cacheBust=1749635444
[BaseAPIService] GET https://ksrcranes.dk/api/app/chef/leave/requests?status=PENDING&page=1&limit=100&include_employee=true&include_approver=true&cacheBust=1749635444
[ChefLeaveAPIService] Fetching team leave balances: /api/app/chef/leave/balance?year=2025&cacheBust=1749635444
[BaseAPIService] Dodano token do żądania: https://ksrcranes.dk/api/app/chef/leave/balance?year=2025&cacheBust=1749635444
[BaseAPIService] GET https://ksrcranes.dk/api/app/chef/leave/balance?year=2025&cacheBust=1749635444
[ChefLeaveAPIService] Fetching leave statistics: /api/app/chef/leave/statistics?start_date=2025-05-11&end_date=2025-08-11&cacheBust=1749635444
[BaseAPIService] Dodano token do żądania: https://ksrcranes.dk/api/app/chef/leave/statistics?start_date=2025-05-11&end_date=2025-08-11&cacheBust=1749635444
[BaseAPIService] GET https://ksrcranes.dk/api/app/chef/leave/statistics?start_date=2025-05-11&end_date=2025-08-11&cacheBust=1749635444
[ChefLeaveAPIService] Fetching team calendar: /api/app/chef/leave/calendar?end_date=2025-08-11&start_date=2025-05-11&cacheBust=1749635444
[BaseAPIService] Dodano token do żądania: https://ksrcranes.dk/api/app/chef/leave/calendar?end_date=2025-08-11&start_date=2025-05-11&cacheBust=1749635444
[BaseAPIService] GET https://ksrcranes.dk/api/app/chef/leave/calendar?end_date=2025-08-11&start_date=2025-05-11&cacheBust=1749635444
[PushNotificationService] Permission granted: true
[AuthService] 🔍 === LOGIN STATUS CHECK ===
[AuthService] 🔍 Attempting to retrieve saved token...
[KeychainService] 🔍 Attempting to retrieve token...
[KeychainService] ✅ Keychain query successful
[KeychainService] ✅ Token retrieved from keychain
[AuthService] ✅ Token retrieved from keychain: eyJhbGciOi...
[AuthService] ✅ Token length: 199 characters
[AuthService] 🔍 Employee role: chef
[AuthService] ✅ Token and role found
[AuthService] ✅ Role: chef
[AuthService] ✅ Token: eyJhbGciOi...
[AuthService] ✅ API service token set: true
[AuthService] 🔍 === LOGIN STATUS: TRUE ===
[PushNotificationService] Registering stored FCM token after login
[AuthService] 🔍 Employee ID: 8
[AuthService] 🔍 Attempting to retrieve saved token...
[KeychainService] 🔍 Attempting to retrieve token...
[KeychainService] ✅ Keychain query successful
[KeychainService] ✅ Token retrieved from keychain
[AuthService] ✅ Token retrieved from keychain: eyJhbGciOi...
[AuthService] ✅ Token length: 199 characters
[PushNotificationService] Auth token found, length: 199
[PushNotificationService] Authorization header set
[PushNotificationService] Request URL: https://ksrcranes.dk/api/app/push/register-token-v2
[PushNotificationService] Request headers: ["Authorization": "Bearer eyJhbGciOiJIUzI1NiJ9.eyJpZCI6OCwiZW1haWwiOiJhZG1pbkBrc3JjcmFuZXMuZGsiLCJuYW1lIjoiQWRtaW4iLCJyb2xlIjoiY2hlZiIsImlhdCI6MTc0OTYzNDQ0OSwiZXhwIjoxNzQ5NzIwODQ5fQ.Lvtp4uUmwnlNwLrntUSp3k5WN0KsTfpRbhpcX0Wvr60", "Content-Type": "application/json"]
[PushNotificationService] HTTP Status: 200
[PushNotificationService] Raw response: {"success":true,"message":"Push token registered successfully","token_id":"1"}
[PushNotificationService] ✅ Token saved to server successfully!
[PushNotificationService] Token ID: 1
[AppStateManager] 🔔 Push notifications initialized and token registered
[BaseAPIService] Status: 200
[BaseAPIService] Response: [{"date":"2025-06-04","employees_on_leave":[{"employee_id":2,"employee_name":"Maksymilian Marcinowski","leave_type":"SICK","is_half_day":false,"profile_picture_url":"https://ksr-employees.fra1.digital
[BaseAPIService] Status: 200
[BaseAPIService] Response: {"balances":[{"id":4,"employee_id":7,"year":2025,"vacation_days_total":25,"vacation_days_used":5,"sick_days_used":0,"personal_days_total":5,"personal_days_used":0,"carry_over_days":0,"carry_over_expir
[BaseAPIService] Status: 200
[BaseAPIService] Response: {"total_requests":7,"pending_requests":0,"approved_requests":5,"rejected_requests":2,"team_on_leave_today":0,"team_on_leave_this_week":0,"most_common_leave_type":"VACATION","average_response_time_hour
[BaseAPIService] Status: 200
[BaseAPIService] Response: {"balances":[{"id":4,"employee_id":7,"year":2025,"vacation_days_total":25,"vacation_days_used":5,"sick_days_used":0,"personal_days_total":5,"personal_days_used":0,"carry_over_days":0,"carry_over_expir
[BaseAPIService] Status: 200
[BaseAPIService] Response: {"requests":[],"pagination":{"limit":100,"offset":0,"total":0,"has_more":false},"statistics":{"total":0,"pending":0,"approved":6,"rejected":2,"cancelled":0}}
[ChefLeaveAPIService] Decoded 0 leave requests
[BaseAPIService] Status: 200
[BaseAPIService] Response: [{"date":"2025-06-04","employees_on_leave":[{"employee_id":2,"employee_name":"Maksymilian Marcinowski","leave_type":"SICK","is_half_day":false,"profile_picture_url":"https://ksr-employees.fra1.digital
[BaseAPIService] Status: 200
[BaseAPIService] Response: {"requests":[],"pagination":{"limit":100,"offset":0,"total":0,"has_more":false},"statistics":{"total":0,"pending":0,"approved":6,"rejected":2,"cancelled":0}}
[ChefLeaveAPIService] Decoded 0 leave requests
[AppStateManager] ✅ App initialization completed!
[AppStateManager] 📊 Final state:
[AppStateManager]   - User: Admin
[AppStateManager]   - Role: chef
[AppStateManager]   - Worker Profile: None
[AppStateManager]   - Manager Profile: None
[BaseAPIService] Status: 200
[BaseAPIService] Response: {"total_requests":7,"pending_requests":0,"approved_requests":5,"rejected_requests":2,"team_on_leave_today":0,"team_on_leave_this_week":0,"most_common_leave_type":"VACATION","average_response_time_hour
[AppStateManager] ✅ App initialization completed!
[AppStateManager] 📊 Final state:
[AppStateManager]   - User: Admin
[AppStateManager]   - Role: chef
[AppStateManager]   - Worker Profile: None
[AppStateManager]   - Manager Profile: None
[AppContainerView] 🔍 Data check 2/10
[AppContainerView] 🔍 - isAppInitialized: true
[AppContainerView] 🔍 - isLoadingInitialData: false
[AppContainerView] 🔍 - initializationError: false
[AppContainerView] ✅ Data loading completed, transitioning to app...
[AuthService] 🔍 Employee name: Admin
[AuthService] 🔍 Employee ID: 8
[AuthService] 🔍 Employee name: Admin
[BossMainViewFixed] 👨‍💼 Chef interface loaded
[MainAppRouter] 👨‍💼 Showing Boss/Chef interface
[MainAppRouter] 🔄 Showing router for role: 'chef'
[AppStateManager] 🔍 === APP STATE MANAGER DEBUG ===
[AppStateManager] 🔍 isAppInitialized: true
[AppStateManager] 🔍 isLoadingInitialData: false
[AppStateManager] 🔍 initializationError: none
[AppStateManager] 🔍 currentUserRole: 'chef'
[AppStateManager] 🔍 currentUserId: '8'
[AppStateManager] 🔍 currentUserName: 'Admin'
[AppStateManager] 🔍 workerProfileVM: NIL
[AppStateManager] 🔍 managerProfileVM: NIL
[AppStateManager] 🔍 workerLeaveVM: NIL
[AppStateManager] 🔍 chefLeaveVM: EXISTS
[AuthService] 🔍 === LOGIN STATUS CHECK ===
[AuthService] 🔍 Attempting to retrieve saved token...
[KeychainService] 🔍 Attempting to retrieve token...
[KeychainService] ✅ Keychain query successful
[KeychainService] ✅ Token retrieved from keychain
[AuthService] ✅ Token retrieved from keychain: eyJhbGciOi...
[AuthService] ✅ Token length: 199 characters
[AuthService] 🔍 Employee role: chef
[AuthService] ✅ Token and role found
[AuthService] ✅ Role: chef
[AuthService] ✅ Token: eyJhbGciOi...
[AuthService] ✅ API service token set: true
[AuthService] 🔍 === LOGIN STATUS: TRUE ===
[AppStateManager] 🔍 Session validation:
[AuthService] 🔍 === LOGIN STATUS CHECK ===
[AuthService] 🔍 Attempting to retrieve saved token...
[KeychainService] 🔍 Attempting to retrieve token...
[KeychainService] ✅ Keychain query successful
[KeychainService] ✅ Token retrieved from keychain
[AuthService] ✅ Token retrieved from keychain: eyJhbGciOi...
[AuthService] ✅ Token length: 199 characters
[AuthService] 🔍 Employee role: chef
[AuthService] ✅ Token and role found
[AuthService] ✅ Role: chef
[AuthService] ✅ Token: eyJhbGciOi...
[AuthService] ✅ API service token set: true
[AuthService] 🔍 === LOGIN STATUS: TRUE ===
[AppStateManager]   - Auth logged in: true
[AppStateManager]   - User ID: SET
[AppStateManager]   - User Role: chef
[AppStateManager]   - Valid: true
[AppStateManager] 🔍 hasValidUserSession: true
[AppStateManager] 🔍 === END DEBUG ===
[AppContainerView] 🔄 Showing MainAppRouter - user logged in and initialized
[ChefDashboardViewModel] Loading enhanced dashboard with payroll data...
[KeychainService] 🔍 Attempting to retrieve token...
[KeychainService] ✅ Keychain query successful
[KeychainService] ✅ Token retrieved from keychain
[BaseAPIService] Token załadowany z keychain
[BaseAPIService] Dodano token do żądania: https://ksrcranes.dk/api/app/chef/dashboard/stats
[BaseAPIService] GET https://ksrcranes.dk/api/app/chef/dashboard/stats
[KeychainService] 🔍 Attempting to retrieve token...
[KeychainService] ✅ Keychain query successful
[KeychainService] ✅ Token retrieved from keychain
[BaseAPIService] Token załadowany z keychain
[PayrollAPIService] Fetching real dashboard stats from API...
[BaseAPIService] Dodano token do żądania: https://ksrcranes.dk/api/app/chef/payroll/dashboard/stats
[BaseAPIService] GET https://ksrcranes.dk/api/app/chef/payroll/dashboard/stats
[PayrollAPIService] Fetching real dashboard stats from API...
[BaseAPIService] Dodano token do żądania: https://ksrcranes.dk/api/app/chef/payroll/dashboard/stats
[BaseAPIService] GET https://ksrcranes.dk/api/app/chef/payroll/dashboard/stats
[ChefDashboardViewModel] Loading enhanced dashboard with payroll data...
[BaseAPIService] Dodano token do żądania: https://ksrcranes.dk/api/app/chef/dashboard/stats
[BaseAPIService] GET https://ksrcranes.dk/api/app/chef/dashboard/stats
[PayrollAPIService] Fetching real dashboard stats from API...
[BaseAPIService] Dodano token do żądania: https://ksrcranes.dk/api/app/chef/payroll/dashboard/stats
[BaseAPIService] GET https://ksrcranes.dk/api/app/chef/payroll/dashboard/stats
[PayrollAPIService] Fetching real dashboard stats from API...
[BaseAPIService] Dodano token do żądania: https://ksrcranes.dk/api/app/chef/payroll/dashboard/stats
[BaseAPIService] GET https://ksrcranes.dk/api/app/chef/payroll/dashboard/stats
[BaseAPIService] Status: 200
[BaseAPIService] Response: {"overview":{"pending_hours":0,"ready_employees":0,"total_amount":0,"active_batches":0,"current_period":{"id":1,"year":2025,"period_number":12,"start_date":"2025-06-09T09:50:45.823Z","end_date":"2025-
[BaseAPIService] Status: 200
[BaseAPIService] Response: {"overview":{"pending_hours":0,"ready_employees":0,"total_amount":0,"active_batches":0,"current_period":{"id":1,"year":2025,"period_number":12,"start_date":"2025-06-09T09:50:45.831Z","end_date":"2025-
