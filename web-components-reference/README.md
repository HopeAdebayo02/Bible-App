# Cross Reference Animation Components

Beautiful, smooth animations for connecting Bible verses with cross-references. Includes both React and vanilla JavaScript implementations.

## 🎬 Features

- **Smooth Zoom/Pan**: Automatically focuses on verses being connected
- **Glowing Effects**: Pulsing highlights on source and destination verses
- **Animated Line Drawing**: SVG path animation with stroke-dasharray technique
- **Glowing Trail**: Moving glow dot follows the line as it draws
- **Smooth Easing**: Uses easeInOutQuad and easeOutCubic for natural motion
- **Mobile Optimized**: Performs smoothly on mobile devices
- **Reusable Functions**: Trigger animations for any verse pair

## 📁 Files

- `CrossReferenceAnimation.jsx` - React component (recommended)
- `cross-reference-animation.html` - Standalone HTML/JS (no dependencies)

## 🚀 Quick Start

### React Version

```jsx
import CrossReferenceAnimation from './CrossReferenceAnimation';

function App() {
  return <CrossReferenceAnimation width={800} height={600} />;
}
```

**Props:**
- `width` (number, default: 800) - Canvas width
- `height` (number, default: 600) - Canvas height

### Vanilla JS Version

Simply open `cross-reference-animation.html` in a browser, or integrate the code into your HTML page.

## 🎯 Usage

### Triggering Animations

**React:**
```javascript
// Inside the component, call:
animateCrossReference(
  { id: 1, x: 200, y: 150, text: 'John 3:16' },
  { id: 2, x: 600, y: 200, text: 'Romans 5:8' },
  '#6366f1' // Color (optional)
);
```

**Vanilla JS:**
```javascript
animateConnection(
  0, // Start verse ID
  1, // End verse ID
  '#6366f1' // Color (optional)
);
```

### Adding Your Own Verses

**React:** Update the `useEffect` hook that initializes `verses`:
```javascript
useEffect(() => {
  const myVerses = [
    { id: 1, x: 200, y: 150, text: 'Genesis 1:1', reference: 'Genesis 1:1' },
    { id: 2, x: 600, y: 200, text: 'John 1:1', reference: 'John 1:1' },
    // ... more verses
  ];
  setVerses(myVerses);
}, []);
```

**Vanilla JS:** Modify the `verses` array at the top:
```javascript
const verses = [
  { id: 0, x: 250, y: 200, reference: 'Genesis 1:1', color: '#6366f1' },
  { id: 1, x: 750, y: 250, reference: 'John 1:1', color: '#6366f1' },
  // ... more verses
];
```

## 🎨 Customization

### Colors

Change the line colors by passing a different color to `animateCrossReference()`:
- Blue: `#6366f1` (default)
- Purple: `#a855f7`
- Green: `#10b981`
- Red: `#ef4444`

### Animation Timing

Adjust durations in the code:
```javascript
// Zoom duration
await animateViewBox(targetX, targetY, zoomLevel, 800); // 800ms

// Line animation duration
const lineAnimationDuration = 1200; // 1200ms

// Glow pulse duration
await new Promise(resolve => setTimeout(resolve, 600)); // 600ms
```

### Easing Functions

Available easing functions:
- `easeInOutQuad` - Smooth acceleration/deceleration
- `easeOutCubic` - Quick start, slow end
- `easeInOutCubic` - Very smooth S-curve

## 📱 Mobile Optimization

Both implementations are optimized for mobile:
- Hardware-accelerated SVG animations
- Efficient requestAnimationFrame loops
- Minimal DOM manipulation
- Responsive controls that adapt to screen size

## 🔧 Integration with Swift/SwiftUI

While these are web components, you can integrate them into your iOS app:

### Option 1: WKWebView
Load the HTML file in a WKWebView:
```swift
import WebKit

let webView = WKWebView()
if let url = Bundle.main.url(forResource: "cross-reference-animation", withExtension: "html") {
    webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
}
```

### Option 2: SwiftUI Native Implementation
Use the animations as reference to implement in SwiftUI:

```swift
struct CrossReferenceView: View {
    @State private var animationProgress: CGFloat = 0
    
    var body some View {
        Canvas { context, size in
            // Draw verse nodes
            // Draw animated path with animationProgress
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2)) {
                animationProgress = 1.0
            }
        }
    }
}
```

For SwiftUI paths:
```swift
Path { path in
    path.move(to: startPoint)
    path.addQuadCurve(to: endPoint, control: controlPoint)
}
.trim(from: 0, to: animationProgress) // Animate stroke
.stroke(Color.blue, lineWidth: 3)
.shadow(color: .blue.opacity(0.6), radius: 8)
```

## 🎓 Animation Breakdown

### Step-by-Step Flow

1. **Zoom to Start** (800ms)
   - ViewBox animates to focus on starting verse
   - Uses easeInOutQuad for smooth motion

2. **Pulse Start Verse** (600ms)
   - CSS animation creates pulsing glow
   - Drop-shadow filter creates the glow effect

3. **Show Both Verses** (600ms)
   - ViewBox expands to show start and end
   - Calculates optimal zoom level based on distance

4. **Draw Animated Line** (1200ms)
   - SVG path uses stroke-dasharray technique
   - Glowing dot follows the line
   - easeInOutCubic for natural drawing motion

5. **Pulse End Verse** (1000ms)
   - Destination verse glows to confirm connection
   - Animation completes and fades

6. **Reset View** (800ms)
   - Returns to overview showing all verses

## 🐛 Troubleshooting

**Animation feels laggy:**
- Reduce `stroke-dasharray` calculations (use approximations)
- Lower blur radius in filters (from 4 to 2)
- Reduce number of animated elements

**Lines don't appear:**
- Check that verse coordinates are within viewBox
- Verify SVG defs (filters, gradients) are loaded
- Ensure stroke color has opacity > 0

**Zoom doesn't work:**
- Verify viewBox updates are being applied to SVG
- Check that target coordinates are valid
- Ensure animation isn't already in progress

## 📚 Technical Details

**SVG Filters:**
- `feGaussianBlur` creates the glow effect
- `feMerge` combines blur with original graphic
- Blur radius of 4-6 for optimal performance

**Animation Technique:**
- `stroke-dasharray` sets pattern length
- `stroke-dashoffset` controls how much is visible
- Animating offset from length → 0 reveals the path

**Performance:**
- Uses `requestAnimationFrame` for 60fps
- Hardware-accelerated CSS transforms
- Minimal reflows/repaints

## 📄 License

Free to use for your Bible app project.

## 💡 Tips

- Keep verse node count under 50 for best performance
- Use colors with good contrast against dark background
- Test on actual mobile devices for performance
- Consider adding haptic feedback on iOS
- Cache calculated path lengths for repeated animations

---

**Need help?** Check the inline comments in the code for detailed explanations of each function.

