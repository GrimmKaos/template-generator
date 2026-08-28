# Template Unique IDs

Every template-specific variable uses this format:

```text
{VariableName_ShortTemplateName_UniqueID_Sequence}
```

The **Unique ID** belongs to the template, not to an individual variable. The
four-digit suffix identifies an occurrence of that variable within the
template. The same variable name can therefore have suffixes `001` through
`008` when a template needs multiple instances.

## Registered Templates

| Section | Template | Short name | Unique ID | Variable occurrences |
|---|---|---|---|---|
| Tickets | Update Python | `Python` | `PY001` | Per variable name |

## Update Python variables

| Variable occurrence | Purpose | Placeholder |
|---:|---|---|
| 001 | Installed Python version(s) | `{InstalledPython_Python_PY001_001}` |
| 001 | Action | `{Action_Python_PY001_001}` |
| 001 | Target Python version | `{TargetVersion_Python_PY001_001}` |
| 001 | Additional solution details | `{SolutionNotes_Python_PY001_001}` |
| 001 | Generated solution | `{Solution_Python_PY001_001}` |

## Adding a template

Choose a new short name and Unique ID, verify that the ID is not already
registered, then number each repeated variable independently starting at `001`.
For example, eight Action variables would be
`{Action_ShortName_ID_001}` through `{Action_ShortName_ID_008}`. Add the
template and all of its variables to this file. Never change an existing
template Unique ID or reuse a retired occurrence number for the same variable.
