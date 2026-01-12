# Rook Animation Path Reference

## Animation Scrub Settings
- **Scrub Duration**: 1.5 seconds (higher = smoother, no snapping when stopping mid-scroll)
- **Trigger**: `#root` element
- **Scroll Range**: `top top` to `bottom bottom` (full page scroll)

---

## S-Curve Animation Path

### Starting Position (Initial State)
- **Position**: `{ x: 1.2, y: 2.8, z: 0.3 }` — Right side, visible immediately
- **Rotation**: `{ x: -0.5, y: 0, z: 1.2 }` — Heavily tilted sideways

---

### Phase 1: Top Right → Left Curve (Timeline: 0 → 12)
**Position**:
- `y: 1.8` — About 30% down
- `x: -0.8` — LEFT side (peak of first curve)
- `z: 0`

**Rotation**:
- `y: Math.PI * 0.5`
- `x: -0.2`
- `z: 0.7` — Still tilted

**Easing**: `sine.inOut`

---

### Phase 2: Left → Right Curve (Timeline: 12 → 28)
**Position**:
- `y: 0.4` — About 70% down
- `x: 0.9` — RIGHT side (peak of second curve)
- `z: 0`

**Rotation**:
- `y: Math.PI * 1.2`
- `x: 0.1`
- `z: -0.4` — Tilted other way

**Easing**: `sine.inOut`

---

### Phase 3: Right → Center Bottom (Timeline: 28 → 42)
**Position**:
- `y: rookFinalY + 0.25`
- `x: 0` — CENTER
- `z: 0`

**Rotation**:
- `y: Math.PI * 1.9`
- `x: 0`
- `z: 0` — UPRIGHT

**Easing**: Position `sine.inOut`, Rotation `sine.out`

---

### Board Emergence (Timeline: 30 → 38)
- Board rises from below
- Scales from `0.8` to `1.0`
- **Easing**: `power2.out`

---

### Landing (Timeline: 36 → 44)
- `y: rookFinalY` — Final touchdown
- Continues rotation to `Math.PI * 2`
- **Easing**: `power3.out` (soft landing)

---

## Key Notes for Smooth Scrolling
1. **All position transitions use `sine.inOut`** — Creates smooth S-curves
2. **High scrub value (1.5)** — Prevents snapping when stopping mid-scroll
3. **Overlapping timelines** — Board and landing phases overlap for fluid motion
4. **No power1/power2 on main path** — Only used for final landing deceleration
