General Links
=============

- How jq handles NDJSON
  -  https://programminghistorian.org/en/lessons/json-and-jq#json-vs-json-lines

How-To's
========

### String Interpoation for formatted output (ie -simulate `printf`)

The `\(.<field>)` within double-quotes will generate a string with the
`<field>`'s string value interpolated into the string.

Example to create CSV lines:

```sh
 .[] | "\(.type),\(.name),\(.data)"
```

### Run `select()` on ndjson into a JSON array

See: https://stackoverflow.com/questions/49302617/output-the-results-of-select-operation-in-an-array-jq

```sh
cat file.ndjson | jq -s '.' | jq '[ .[] | select(<FILTER>) ]'
```
