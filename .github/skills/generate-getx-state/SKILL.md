---
name: generate-getx-state
description: "**CODE GEN SKILL** — Generate a GetX state class containing only Rx observable fields. USE FOR: creating the state holder for a GetX feature. Triggers on: 'generate state', 'create state class', 'getx state', 'generate-getx-state'. DO NOT USE FOR: business logic or service calls (those go in the controller/service)."
---

# Generate GetX State

Generate a pure `{FeatureName}State` class with `Rx` variables only. No methods, no logic.

## Workflow

### Step 1 — Confirm Inputs
- `{feature_name}` — snake_case name
- Fields the user needs (if not specified, scaffold with `isLoading` as placeholder)

### Step 2 — Generate State

```dart
import 'package:get/get.dart';

class {FeatureName}State {
  final RxBool isLoading = false.obs;
  // TODO: add feature-specific Rx fields, e.g.:
  // final RxList<Item> items = <Item>[].obs;
  // final Rx<User?> currentUser = Rx<User?>(null);
}
```

### Common Rx Types Reference

| Type | Declaration |
|------|-------------|
| `bool` | `RxBool isLoading = false.obs;` |
| `int` | `RxInt count = 0.obs;` |
| `String` | `RxString title = ''.obs;` |
| `double` | `RxDouble price = 0.0.obs;` |
| `List<T>` | `RxList<T> items = <T>[].obs;` |
| `T?` (nullable) | `Rx<T?> item = Rx<T?>(null);` |
| `T` (object) | `Rx<T> item = T().obs;` |

### Step 3 — Quality Check
- [ ] Only `Rx` fields — no plain `var`, no methods
- [ ] No imports except `get/get.dart` (and model files if needed)
- [ ] Run `get_errors` to confirm zero errors
