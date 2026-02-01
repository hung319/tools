# Plan: Fix Mobile Menu Grid Performance & UX

## Discovery Summary

**User Issues:** Menu grid bị rít và khó di chuyển trên mobile
**Primary Problem:** Lag khi scroll/hoạt tác
**Scope:** Kết hợp tất cả các giải pháp (performance + touch + layout)

## Research Findings

Current menu has multiple performance and UX issues:
- Excessive CSS transitions causing lag
- Grid layout not optimized for small screens  
- Hover-dependent interactions (no touch support)
- Heavy visual effects impacting mobile performance

## Implementation Plan

### Task 1: Optimize Performance 
- **What:** Reduce CSS transitions and animations that cause lag
- **Must NOT:** Break desktop functionality
- **Verify:** Smooth 60fps interactions on mobile

### Task 2: Improve Touch Interactions
- **What:** Add touch-specific states and increase tap targets
- **Must NOT:** Remove hover effects for desktop
- **Verify:** Easy tapping with finger-sized targets

### Task 3: Fix Mobile Grid Layout
- **What:** Better responsive breakpoints and grid sizing for mobile
- **Must NOT:** Break desktop grid layout
- **Verify:** Proper grid columns on all screen sizes

### Task 4: Mobile-First Menu Panel
- **What:** Optimize panel slide animation and scrolling for mobile
- **Must NOT:** Remove backdrop blur effects entirely
- **Verify:** Smooth panel open/close without lag

## Non-Goals

- Complete redesign of menu structure
- Removing hamburger menu functionality
- Changing menu content/navigation structure

## Ghost Diffs

**Considered but rejected:**
- Removing all transitions entirely (would feel cheap)
- Using JavaScript scroll events instead of CSS (more complex)
- Switching to list layout (loses grid visual appeal)

## Testing Strategy

Test on: 320px, 375px, 414px, 768px widths
Verify: 60fps animations, proper touch targets, smooth scrolling