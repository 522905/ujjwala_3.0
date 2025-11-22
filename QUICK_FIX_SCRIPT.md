# Quick Fix Script for Compilation Errors

Run this Flutter command to fix remaining errors automatically:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate the Hive type adapters which are causing most enum-related errors.

## After generating adapters, if errors persist:

The Hive generator will create proper enum handling in the generated files.
The enum types (Gender, Caste, MaritalStatus, etc.) are stored as String in Hive
but need to be converted back to enums when reading.

This is handled automatically by the Hive TypeAdapters that will be generated.
