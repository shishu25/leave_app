# Office Leave Management — Flutter App

Responsive Flutter implementation of the Home/Login, Employee Dashboard,
and Request-New-Leave screens, matching the earlier design mockups.

## Project structure

```
leave_app/
├── pubspec.yaml
├── assets/
│   └── data/
│       └── mock_data.json        # mock employee + leave-history data
└── lib/
    ├── main.dart                  # app entry point
    ├── theme/
    │   └── app_theme.dart         # colors, type, spacing, breakpoints
    ├── models/
    │   └── leave_models.dart      # Employee, LeaveApplication, enums
    ├── utils/
    │   └── leave_data_service.dart# loads mock_data.json (swap for a real API)
    ├── widgets/
    │   ├── responsive_grid.dart   # breakpoint-aware grid for summary cards
    │   ├── summary_card.dart      # leave-balance stat card
    │   └── status_badge.dart      # Pending/Approved/Rejected pill
    └── screens/
        ├── home_screen.dart            # dual Admin/Employee login
        ├── employee_dashboard_screen.dart
        └── request_leave_screen.dart   # leave request form
```

## How to run in VS Code

1. Create a new Flutter project (or use this folder directly):
   ```
   flutter create leave_app
   ```
2. Replace the generated `pubspec.yaml`, `lib/`, and add the `assets/` folder
   with the files from this codebase.
3. Fetch packages:
   ```
   flutter pub get
   ```
4. Run:
   ```
   flutter run -d chrome      # web, easiest for checking responsiveness
   flutter run                # or any connected device/emulator
   ```

## Responsiveness

Breakpoints are defined in `lib/theme/app_theme.dart`:
- **Mobile** (`< 600px`): single-column login cards, stacked profile card,
  history shown as cards instead of a table, full-screen request form.
- **Tablet** (`600–1024px`): 2-column summary grid.
- **Desktop** (`> 1024px`): side-by-side login cards, 4-column summary grid,
  data table for history, and the request form renders as a centered modal
  card over a dimmed background (closest to the original mockup).

`ResponsiveGrid` (in `lib/widgets/responsive_grid.dart`) and `screenSizeOf()`
(in `lib/theme/app_theme.dart`) are the two reusable pieces driving this —
reuse them for any future screens (e.g. the admin dashboard).

## Mock data / going to a real backend

`assets/data/mock_data.json` holds a sample employee profile and four leave
applications (Approved / Pending / Rejected). `LeaveDataService` in
`lib/utils/leave_data_service.dart` loads this asset and is the single
seam to replace with real HTTP calls:

```dart
Future<DashboardData> fetchDashboardData() async {
  // Replace the asset-loading body with, e.g.:
  // final res = await http.get(Uri.parse('$apiBase/employees/me/dashboard'));
  // return DashboardData.fromJson(jsonDecode(res.body));
}
```

The `submitLeaveApplication` method is the other seam — currently it just
simulates a network delay and returns a new `Pending` record; point it at
your POST endpoint for leave submissions (including file upload for the
signature and generated/manual document).

## What's included vs. what's stubbed

- **Included:** full responsive UI for Home/Login, Employee Dashboard
  (profile, 4 summary cards, history list/table), and the Request Leave
  form (leave type, dates with auto-calculated duration, reason, signature
  upload via `file_picker`, manual document upload, confirm-before-submit
  dialog).
- **Stubbed / next steps:** actual authentication, real .docx generation
  (server-side or via a package like `docx_template`), file storage, and
  the admin-side dashboard (approve/reject, employee records, policy
  config) — call this out if you want that scaffolded next.
