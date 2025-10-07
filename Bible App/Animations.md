## Animations (SwiftUI Deep-Dive)

This guide explains how to add calm, smooth animations to the app while keeping performance, accessibility, and maintainability in mind.

### Principles
- Keep motion subtle and purposeful; prefer clarity over flair.
- Animate state changes that help orientation (what changed and where).
- Favor GPU-friendly properties (opacity, scale, offset) over expensive relayouts.
- Respect Reduce Motion and provide instant or gentler alternatives.

### Terminology: Implicit vs. Explicit
- Implicit: Attach `.animation(_:, value:)` to a view. When `value` changes, SwiftUI animates that change.
- Explicit: Wrap state changes with `withAnimation(_:) { ... }` to animate only those updates.

Prefer explicit animations for predictability; use implicit when a single state drives a view’s animation.

### Core APIs You’ll Use Often
```swift
// Explicit animation for a specific change
withAnimation(.easeInOut(duration: 0.25)) {
    isExpanded.toggle()
}

// Implicit animation tied to state changes of `isExpanded`
.animation(.easeInOut(duration: 0.25), value: isExpanded)

// Springs and preset curves (iOS 17+)
withAnimation(.snappy(duration: 0.25)) { /* state change */ }
withAnimation(.bouncy(duration: 0.5)) { /* state change */ }
withAnimation(.smooth(duration: 0.3)) { /* state change */ }
```

Recommended defaults (calm): `.easeInOut(duration: 0.20–0.30)` or `.snappy(duration: 0.25)`.

### Transitions (View insertion/removal)
Use `.transition` with conditional views. Combine with `withAnimation`.
```swift
if showPalette {
    PaletteView()
        .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.98)),
                                removal: .opacity))
}
```

Common transitions:
- `.opacity`, `.scale`, `.move(edge:)`, `.slide`.
- Asymmetric transitions help avoid “pop” when removing.

### Content Transitions (iOS 17+)
Smoothly animate text/image content changes without full view transitions.
```swift
Text(count.description)
    .contentTransition(.numericText())
```

### Matched Geometry for Seamless Morphs
Use `matchedGeometryEffect` to morph between two views across container boundaries.
```swift
@Namespace private var ns

if isPaletteVisible == false {
    Circle().fill(.ultraThinMaterial)
        .matchedGeometryEffect(id: "playButton", in: ns)
        .frame(width: 56, height: 56)
} else {
    RoundedRectangle(cornerRadius: 16)
        .fill(Color(.secondarySystemBackground))
        .matchedGeometryEffect(id: "playButton", in: ns)
        .frame(height: 84)
}
```

Tips:
- Both views must exist within the same view hierarchy update.
- Keep geometry reasonably similar for the most natural effect.

### Keyframes and Phase Animators (iOS 17+)
Keyframes for staged sequences:
```swift
KeyframeAnimator(initialValue: 0.0) { value in
    Rectangle().scaleEffect(1 + value)
} keyframes: { _ in
    CubicKeyframe(0.2, duration: 0.15)
    CubicKeyframe(0.0, duration: 0.25)
}
```

Phase animator for multi-phase effects:
```swift
PhaseAnimator([false, true]) { isOn in
    Capsule().opacity(isOn ? 1 : 0)
} animation: { isOn in
    isOn ? .snappy(duration: 0.2) : .easeOut(duration: 0.15)
}
```

### Interactivity and Gestures
- Use `DragGesture` to derive state, then animate to a final resting state in `.onEnded`.
- For interactive transitions (e.g., header show/hide), animate only when thresholds are crossed to avoid jitter.

### Lists and Data Changes
- Use stable `id` values to prevent row recreation.
- Wrap insertions/removals in `withAnimation`.
```swift
withAnimation(.easeInOut(duration: 0.2)) {
    items.insert(newItem, at: 0)
}
```

### Performance Guidelines
- Prefer animating: opacity, offset/position, scale, rotation.
- Avoid frequently animating expensive layout changes (deep stacks, complex Lists) when possible.
- Keep animated subviews light; isolate heavy work outside the animating subtree.
- Avoid triggering multiple expensive state updates per frame. Debounce where necessary.
- Test on lower-end devices; verify frame pacing in Instruments.

### Accessibility: Reduce Motion
Respect the user’s setting and provide instant or gentler alternatives.
```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

func calmAnimation(_ duration: Double = 0.25) -> Animation? {
    reduceMotion ? nil : .easeInOut(duration: duration)
}

withAnimation(calmAnimation()) {
    isPaletteVisible.toggle()
}
```

### Recommended App-Wide Conventions
- Define a tiny set of motion tokens:
  - Fast: 0.16s (discrete toggles)
  - Base: 0.24–0.28s (most UI changes)
  - Slow: 0.36–0.42s (large layout shifts)
- Prefer `.snappy` for micro-motion and `.smooth` for content changes.
- Keep damping high to avoid “spring wobble” unless intentionally playful.

### Applying to This App
- Verse list interactions:
  - Show/hide highlight palette with `.snappy(0.22)` and asymmetric transition.
  - Copy toast already fades; keep 0.18–0.24s.
- Header chrome hide/show:
  - Use `.easeInOut(0.2)` when threshold crossed; avoid animating every pixel of scroll.
- Multi-select check toggles:
  - Animate symbol swap with `.contentTransition(.symbolEffect)` or scale/opacity.
- Cross-reference lines view:
  - Insert/delete lines with `.easeInOut(0.2)` and `.transition(.move(edge: .top).combined(with: .opacity))`.
- Tab/route transitions:
  - Favor subtle fades and slides; avoid 3D rotations or large bounces.

### Debugging and Tuning
- Temporarily speed up or disable animations via Xcode environment overrides.
- Use Instruments → Core Animation to check frame drops and overdraw.
- Log animation-driving state changes to ensure only intended updates animate.

### Reusable Helpers (Optional)
```swift
enum Motion {
    static func base(_ duration: Double = 0.25) -> Animation { .easeInOut(duration: duration) }
    static func fast() -> Animation { .easeInOut(duration: 0.16) }
    static func slow() -> Animation { .easeInOut(duration: 0.38) }
}

extension View {
    func animated(_ animation: Animation?, when value: some Equatable) -> some View {
        self.animation(animation, value: value)
    }
}
```

### Checklist
- Tied to meaningful state changes only
- Calm timing (0.2–0.3s typical)
- GPU-friendly properties
- Reduce Motion respected
- Consistent motion tokens across the app



