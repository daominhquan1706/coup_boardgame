---
name: create-getx-feature
description: "**FEATURE SCAFFOLD SKILL** — Scaffold a complete GetX feature module under lib/features/{feature_name}. USE FOR: creating a new screen/feature with page, controller, state, binding, and service files following GetX architecture conventions. Triggers on: 'create feature', 'scaffold feature', 'new feature', 'getx feature', 'create-getx-feature'. DO NOT USE FOR: modifying existing features; creating single-file utilities; non-GetX state management."
---

# Create GetX Feature

Scaffold a fully wired GetX feature module with all 5 required files.

## Workflow

### Step 1 — Clarify Feature Name
Confirm the `{feature_name}` in snake_case from the user's request. If ambiguous, ask once.

### Step 2 — Resolve Target Path
All files go under:
```
lib/features/{feature_name}/
```
If the project uses a different conventions (e.g. `lib/app/modules/`), check `lib/` structure and adjust accordingly.

### Step 3 — Generate Files in Parallel

Create all 5 files simultaneously using the templates below.

---

## File Templates

### `{feature_name}_state.dart`
> Rx variables only. No logic.

```dart
import 'package:get/get.dart';

class {FeatureName}State {
  final RxBool isLoading = false.obs;
  // TODO: add feature-specific Rx fields
}
```

### `{feature_name}_service.dart`
> Responsible for API or repository calls. Pure data layer — no UI or navigation logic.

```dart
import 'package:get/get.dart';

class {FeatureName}Service extends GetxService {
  // TODO: inject repositories or HTTP clients here

  Future<void> fetchData() async {
    // TODO: implement
  }
}
```

### `{feature_name}_controller.dart`
> Extends `GetxController`. Owns an instance of `{FeatureName}State`. Delegates data fetching to `{FeatureName}Service`.

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

### `{feature_name}_binding.dart`
> Registers controller and service with `Get.lazyPut` so they are created on demand and disposed when the route is removed.

```dart
import 'package:get/get.dart';
import '{feature_name}_controller.dart';
import '{feature_name}_service.dart';

class {FeatureName}Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<{FeatureName}Service>(() => {FeatureName}Service());
    Get.lazyPut<{FeatureName}Controller>(() => {FeatureName}Controller());
  }
}
```

### `{feature_name}_page.dart`
> Extends `GetView<{FeatureName}Controller>`. Uses `Obx` for reactive sections only.

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

---

## Step 4 — Wire the Route (Optional, Ask First)

Ask the user if they want the route added to `AppPages` / `AppRoutes`. If yes:
1. Add a route constant to the routes file (e.g. `static const {FEATURE_NAME} = '/{feature_name}';`)
2. Add a `GetPage` entry with `page` and `binding`.

---

## Step 5 — Quality Check

After creating the files, verify:
- [ ] All 5 files exist under `lib/features/{feature_name}/` (or the resolved path)
- [ ] Class names use `UpperCamelCase` matching `{FeatureName}`
- [ ] `{FeatureName}Binding` registers both service **before** controller (dependency order)
- [ ] No logic in `{FeatureName}State` — only `Rx` fields
- [ ] No UI imports in `{FeatureName}Service`
- [ ] Run `get_errors` on all created files to confirm zero compile errors

---

## Naming Convention

| Token | Format | Example |
|-------|--------|---------|
| `{feature_name}` | snake_case | `user_profile` |
| `{FeatureName}` | UpperCamelCase | `UserProfile` |
| File suffix | `_{role}.dart` | `_controller.dart` |
