# Manuscript scene workflow verification

Requires macOS and Xcode 27, matching the project's deployment target. This Linux
workspace has no Swift compiler or Apple SDK; the checks below have not been run.

## Disk-backed persistence check

From the repository root:

```sh
xcrun swiftc -parse-as-library -o /tmp/storyteller-scene-check \
  Storyteller/App/Model/Storybank.Model.swift \
  Storyteller/Features/Manuscript/Model/ManuscriptGroup.Model.swift \
  Storyteller/Features/Manuscript/Model/ManuscriptDocument.Model.swift \
  Storyteller/Features/Characters/Model/Character.Model.swift \
  Tests/Manuscript/ScenePersistenceCheck.swift
/tmp/storyteller-scene-check
```

This uses the production models and a temporary on-disk store, with autosave
disabled. It checks creation, inverse ownership/tree membership, lookup by selected
UUID, explicit title/content saving, and loading through a new container. It does
not exercise SwiftUI or DocumentGroup file saving.

## Build and running-app check

```sh
xcodebuild -project Storyteller.xcodeproj -scheme Storyteller \
  -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
```

1. Launch from Xcode and create a storybank. Its preexisting opening scene should
   be selected and visible in the editor and expanded manuscript tree.
2. Collapse the book group; click Create Document once. Exactly one additional
   scene should appear, the book should expand, and the new scene's editor should
   open. Repeat under a nested chapter to check expansion of every ancestor.
3. Change the editor title and body. Check that the tree title updates. Select
   the other scene and return; confirm the correct title/body and editor selection.
4. Rename the scene inline in the tree and confirm the editor title updates.
5. Save the storybank document to disk using the app's normal File > Save flow.
   Close and reopen that file. Select the scene and confirm title/body and tree
   membership. ModelContext.save writes the model store; this check also verifies
   DocumentGroup's document-file lifecycle.
6. Open another storybank window; confirm selection and content stay within their
   own windows. Select a group: the existing manuscript overview should remain.

No model relationships or schema version changes are made. Existing Storybank ↔
ManuscriptDocument and ManuscriptGroup ↔ ManuscriptDocument inverses are reused.
Deletion, reorder behavior, metadata editing, characters, export, and restoration
of the last selected scene across launches are out of scope.
