# Adding Ticket Templates

Ticket templates are JSON files in `Templates\Tickets`. The application loads every
`.json` file in that folder when the Ticket template-selection step is displayed.

The current application variables are documented in
[`TEMPLATE_VARIABLES.md`](./TEMPLATE_VARIABLES.md). Keep that file updated
whenever a standard field, additional-input field, or generated value is added,
renamed, or removed.

Template-specific variable naming and the running Unique ID registry are
documented in [`TEMPLATE_UNIQUE_IDS.md`](./TEMPLATE_UNIQUE_IDS.md).
The final four digits are an occurrence number for that variable name, not a
global sequence. For example, eight Action values use suffixes `001` through
`008`.

## Adding issue selections

Edit `Templates\Tickets\Issues.json` and add strings to its `Items` array. The
Ticket Data Input step displays these items in a scrollable multi-select list.
Users can also enter comma-separated values in the `Other` box. All selected
items are combined with `, ` and are available to templates as `{Issues}`.

## Template with additional input

Create a file such as `MyTemplate.json`:

```json
{
  "Name": "My Template",
  "Description": "Short explanation shown during selection.",
  "RequiresAdditionalInput": true,
  "Content": "Device: {DeviceName}\r\nRequest: {RequestNumber}\r\nSolution: {Solution}",
  "AdditionalFields": [
    { "Name": "RequestNumber_Demo_DEM001_001", "Label": "Request number:", "Type": "Text", "Required": true },
    { "Name": "Solution_Demo_DEM001_001", "Label": "Solution:", "Type": "Multiline", "Required": true }
  ]
}
```

Supported field types are `Text`, `Multiline`, `Choice`, and `Date`.
`Choice` fields also need an `Options` array. A field can use
`RequiredWhen` such as `"Action_Demo_DEM001_001=Update"` to make it conditional.

Every placeholder in `Content` must match a standard field name
(`DeviceName`, `UserName`, `ECCode`, `PhoneNumber`, `CompletionDeadDate`,
`LastKnownLocation`, or `Issues`) or an `AdditionalFields` name.

## Template with no additional input

Set `RequiresAdditionalInput` to `false` and omit `AdditionalFields`:

```json
{
  "Name": "Simple Template",
  "Description": "Uses only the standard fields.",
  "RequiresAdditionalInput": false,
  "Content": "Device: {DeviceName}\r\nIssue: {Issues}"
}
```

After saving a JSON file, restart the application and it will appear in the
Ticket template list. The file name is not displayed and does not need to match
the template name.
