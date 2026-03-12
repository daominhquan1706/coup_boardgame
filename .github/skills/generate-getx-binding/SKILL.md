---
name: generate-getx-binding
description: "**CODE GEN SKILL** — Generate a GetX Bindings class that registers a controller and service using Get.lazyPut. USE FOR: wiring a feature's dependencies to a route. Triggers on: 'generate binding', 'create binding', 'getx binding', 'generate-getx-binding'. DO NOT USE FOR: full feature scaffold (use create-getx-feature instead)."
---

# Generate GetX Binding

Generate a `{FeatureName}Binding` class that registers dependencies with `Get.lazyPut`.

## Workflow

### Step 1 — Confirm Inputs
- `{feature_name}` — snake_case
- `{FeatureName}` — UpperCamelCase
- Whether this feature has a service (default: yes)

### Step 2 — Generate Binding

```dart
import 'package:get/get.dart';
import '{feature_name}_controller.dart';
import '{feature_name}_service.dart';

class {FeatureName}Binding extends Bindings {
  @override
  void dependencies() {
    // Service MUST be registered before the controller that depends on it
    Get.lazyPut<{FeatureName}Service>(() => {FeatureName}Service());
    Get.lazyPut<{FeatureName}Controller>(() => {FeatureName}Controller());
  }
}
```

### Step 3 — Wire to Route (Ask First)

If a route file exists (e.g. `app_pages.dart`), offer to add:
```dart
GetPage(
  name: Routes.{FEATURE_NAME},
  page: () => const {FeatureName}Page(),
  binding: {FeatureName}Binding(),
),
```

### Step 4 — Quality Check
- [ ] Extends `Bindings` (not `BindingsBuilder`)
- [ ] Service registered **before** controller in `dependencies()`
- [ ] Uses `Get.lazyPut` (not `Get.put`) for lazy instantiation
- [ ] Run `get_errors` to confirm zero errors
