---
name: generate-getx-page
description: "**CODE GEN SKILL** — Generate a Flutter page extending GetView<Controller> that uses Obx for reactive UI. USE FOR: creating the UI screen for a GetX feature. Triggers on: 'generate page', 'create getx page', 'generate-getx-page', 'create flutter page'. DO NOT USE FOR: full feature scaffold (use create-getx-feature instead)."
---

# Generate GetX Page

Generate a `{FeatureName}Page` that extends `GetView<{FeatureName}Controller>` and wraps reactive sections in `Obx`.

## Workflow

### Step 1 — Confirm Inputs
- `{feature_name}` — snake_case
- `{FeatureName}` — UpperCamelCase
- Any specific UI sections the user wants scaffolded

### Step 2 — Generate Page

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '{feature_name}_controller.dart';

class {FeatureName}Page extends GetView<{FeatureName}Controller> {
  const {FeatureName}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{FeatureName}')),
      body: Obx(() {
        if (controller.state.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return const Center(child: Text('TODO: build UI'));
      }),
    );
  }
}
```

### Step 3 — Quality Check
- [ ] Extends `GetView<{FeatureName}Controller>` (not `StatelessWidget` / `StatefulWidget`)
- [ ] Uses `controller` (provided by `GetView`) — never calls `Get.find()` inside the page
- [ ] Only reactive sections are wrapped in `Obx` (not the whole build)
- [ ] `const` constructor with `super.key`
- [ ] Run `get_errors` to confirm zero errors
