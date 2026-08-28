# Template Variables

Use these placeholders in template JSON `Content` values. The application
replaces each placeholder with the user's entered data.

## Standard Ticket Variables

| Variable | Placeholder | Available when | Description |
|---|---|---|---|
| Device name | `{DeviceName}` | Always | The device name. |
| User name | `{UserName}` | Assigned user is known | The assigned user's name. |
| E/C code | `{ECCode}` | Assigned user is known | The user's E/C code. |
| Phone number | `{PhoneNumber}` | Assigned user is known | The user's phone number. |
| Completion deadline | `{CompletionDeadDate}` | Always | Selected date, formatted as `yyyy-MM-dd`. |
| Last known location | `{LastKnownLocation}` | User/location is not known | The device's last known location. |
| Issues | `{Issues}` | Always | Selected issues and Other entries joined with `, `. |

## Template-Specific Variables

These variables are currently used by the **Update Python** ticket template.
Their unique naming and occurrence suffixes are documented in
[`TEMPLATE_UNIQUE_IDS.md`](./TEMPLATE_UNIQUE_IDS.md).

| Variable | Placeholder | Description |
|---|---|---|
| Installed Python | `{InstalledPython_Python_PY001_001}` | Installed Python version or versions. |
| Action | `{Action_Python_PY001_001}` | Update to a target version or remove affected versions. |
| Target version | `{TargetVersion_Python_PY001_001}` | Target Python version when updating. |
| Solution notes | `{SolutionNotes_Python_PY001_001}` | Optional additional solution details. |

## Generated Variables

| Variable | Placeholder | Description |
|---|---|---|
| Solution | `{Solution_Python_PY001_005}` | Solution text generated for the Update Python template. |

## Maintenance

Update this file whenever a standard field, additional-input field, or generated
value is added, renamed, or removed.
