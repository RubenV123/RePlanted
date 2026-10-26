# RePlated interface system

## Direction
A calm, trustworthy food-rescue product for Indian kitchens, NGOs, and delivery partners. Use a warm off-white canvas, deep forest green, restrained lime accents, and direct operational language. The role picker uses one editorial meal image; food-evidence images remain real, task-specific camera captures and must never be decorative.

## Color tokens

| Token | Light | Dark | Usage |
|---|---|---|---|
| Background | `#F5F6F1` | `#111713` | App canvas |
| Surface | `#FFFFFF` | `#1A211C` | Cards and fields |
| Raised surface | `#FFFFFF` | `#202A23` | Inputs / elevated content |
| Main text | `#17211B` | `#EDF3EC` | Headings and body |
| Muted text | `#68746C` | `#A4B0A6` | Supporting details |
| Primary | `#183D30` | `#D0F0A5` | Main action and emphasis |
| Accent | `#C5E994` | `#C5E994` | Brand mark highlight |
| Border | `#DCE4DC` | `#344137` | Quiet boundaries |
| Success | `#226C4A` | `#9CD9AF` | Safe/complete state |
| Warning | `#8B5522` | `#F1C27B` | Attention state |
| Danger | `#9C4137` | `#FFB3A8` | Reject/health issue |

Palette source: `components/ui/palette.ts`.

## Typography and spacing
- System sans-serif with strong, compact display headings; avoid decorative typefaces.
- Base spacing rhythm: 4 / 8 / 12 / 16 / 20 / 24 / 32.
- Primary card radius 20–24; control radius 13–15; icon containers use a soft rounded-square shape.
- Body copy should remain concise and scan-friendly. Preserve system font scaling and minimum Android touch targets.

## Components and interaction
- Reusable controls live in `components/ui/Controls.tsx`; palette-aware styling comes from `usePalette()`.
- Use thin borders and soft tinted surfaces; avoid heavy drop shadows and excessive blur.
- Button press feedback is a restrained spring scale plus selection haptic. Screen and list items enter with short, staggered fade/slide motion.
- Respect system light/dark appearance. Keep evidence photos, safety statuses, and handoff actions visually distinct.
- Role-aware bottom navigation uses explicit labels and Lucide icons.

## Accessibility
- All interactive controls need a clear accessible role/name and disabled state.
- Use text labels alongside color and icons for operational statuses.
- Avoid relying on green alone to communicate food safety. The app records evidence but does not certify food safety.

## Image provenance
The role-picker editorial meal photo is local at `assets/replated-meal.jpg`; its source and license note are in `assets/IMAGE_SOURCES.md`. Other food photos are user-captured evidence and should not be replaced with illustrative imagery.
