---
name: generate-getx-controller
description: "**CODE GEN SKILL** — Generate a single GetX controller file extending GetxController with a dedicated State class. USE FOR: creating or scaffolding a controller for an existing or new feature. Triggers on: 'generate controller', 'create getx controller', 'generate-getx-controller'. DO NOT USE FOR: full feature scaffold (use create-getx-feature instead)."
---

# Generate GetX Controller

Generate a `{FeatureName}Controller` that extends `GetxController` and delegates state to a `{FeatureName}State` instance.

## Workflow

### Step 1 — Confirm Inputs
- `{feature_name}` — snake_case name
- `{FeatureName}` — UpperCamelCase name (derived automatically)
- Target path (default: `lib/features/{feature_name}/`)

### Step 2 — Generate Controller

```dart
import 'package:get/get.dart';
import '{feature_name}_state.dart';
import '{feature_name}_service.dart';

class {FeatureName}Controller extends GetxController {
  final {FeatureName}State state = {FeatureName}State();
  final {FeatureName}Service _service = Get.find();

  @override
  void onInit() {
    super.onInit();
    // TODO: trigger initial data load
  }

  Future<void> loadData() async {
    state.isLoading.value = true;
    try {
      await _service.fetchData();
    } finally {
      state.isLoading.value = false;
    }
  }
}
```

### Step 3 — Quality Check
- [ ] Extends `GetxController`
- [ ] Has a `{FeatureName}State state` field (not inlined Rx vars)
- [ ] Uses `Get.find<{FeatureName}Service>()` — does not instantiate service directly
- [ ] No direct Flutter widget imports
- [ ] Run `get_errors` to confirm zero errors
