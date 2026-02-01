# Task: 01-01-optimize-performance

## Feature: fix-mobile-menu-grid

## Context

## mobile-menu-research

## Current Mobile Menu Issues Found

### Performance Problems:
1. **Excessive transitions**: Multiple `transition: all 0.3s/0.4s` on menu items cause lag
2. **Heavy animations**: Complex cubic-bezier transitions on every menu item
3. **Transform translateX**: Panel slide uses translateX which can be laggy on mobile

### Layout Issues:
1. **Grid breakpoints**: 
   - Desktop: `minmax(160px, 1fr)` 
   - Tablet: `minmax(140px, 1fr)`
   - Mobile: `minmax(110px, 1fr)` - still too large for small screens
2. **Fixed aspect ratio**: `aspect-ratio: 1.2 / 1` creates uneven sizing

### Touch Interaction Problems:
1. **Hover-dependent**: All interactions use `:hover` pseudo-class
2. **No touch events**: No `:active` or touch-specific states
3. **Small tap targets**: Menu items might be too small for comfortable tapping

### Specific Issues:
- Menu panel slide animation `transform: translateX()` can be janky
- Grid auto-fit may create inconsistent column counts
- No touch optimization for mobile devices
- Heavy box-shadow and backdrop-filter effects impact performance

