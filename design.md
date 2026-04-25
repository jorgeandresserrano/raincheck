# RainCheck Design Brief

## Overview

Design a mobile app called `RainCheck`.

RainCheck is not a general weather app. It is a decision-making app that answers one simple, high-value question:

> Is it safe to wash my car now, or will rain ruin it soon?

The UI and UX should reduce uncertainty, give a fast answer, and build trust.

## Core User Problem

People avoid washing their car because they are unsure whether rain is coming in the next few hours or days. Existing weather apps provide raw forecast data, but not a clear recommendation. RainCheck should turn forecast complexity into a simple, confident, actionable decision.

## Primary UX Goal

Within a few seconds of opening the app, the user should understand:

1. Whether it is safe to wash the car.
2. For how long that recommendation is valid.
3. Why the app made that recommendation.

## Desired UX Qualities

- Calm, clear, trustworthy
- Minimal cognitive load
- Fast to scan
- Recommendation-first, details-second
- Helpful without feeling overly technical
- Focused and practical, not like a generic weather dashboard

## Core Features To Reflect In The Design

- Current location or selected location
- User-selectable time window: `1 day`, `3 days`, `5 days`, `1 week`
- Customizable rain tolerance or sensitivity
- Simple recommendation output:
  - `Safe to wash`
  - `Not recommended`
- Short explanation:
  - `Rain expected in 4 hours`
  - `Low precipitation risk for the next day`
  - `High chance of rain tonight`
- Forecast confidence or disclaimer that this is a recommendation, not a guarantee
- Optional notification or “best wash window” suggestion

## Design Direction

Create a mobile-first experience that feels modern and polished, but restrained. The app should feel useful and dependable rather than flashy. Emphasize strong information hierarchy, readable typography, intuitive controls, and a clear visual distinction between safe and unsafe states. Weather context should support the decision, not overwhelm it.

## Avoid

- Generic weather app layouts
- Cluttered dashboards
- Overly playful gimmicks
- Too many charts or dense meteorological details
- Making the user interpret raw forecast data to reach their own conclusion

## Screens And States To Design

- Onboarding or first-use flow
- Main recommendation screen
- Time-window selection interaction
- Settings or preferences for rain sensitivity
- Forecast detail screen or expandable explanation area
- Empty state
- Loading state
- Offline state
- Error state
- Notification opt-in moment

## What The Design Should Also Provide

- The UX rationale behind the main flow
- The emotional tone of the product
- The visual design principles
- A suggested component system
- A clear information hierarchy

## Success Criteria

The final result should make the user feel:

> I can trust this app, and I know exactly whether washing my car is a good idea right now.

## Prompt For A Design AI

```text
Design a mobile app called RainCheck.

Product intent:
RainCheck is not a general weather app. It is a decision-making app that answers one simple, high-value question: “Is it safe to wash my car now, or will rain ruin it soon?” The UI and UX should reduce uncertainty, give a fast answer, and build trust.

Core user problem:
People avoid washing their car because they are unsure whether rain is coming in the next few hours or days. Existing weather apps provide raw forecast data, but not a clear recommendation. RainCheck should turn forecast complexity into a simple, confident, actionable decision.

Primary UX goal:
Within a few seconds of opening the app, the user should understand:
1. whether it is safe to wash the car
2. for how long that recommendation is valid
3. why the app made that recommendation

Desired UX qualities:
- calm, clear, trustworthy
- minimal cognitive load
- fast to scan
- recommendation-first, details-second
- helpful without feeling overly technical
- focused and practical, not like a generic weather dashboard

Core features to reflect in the design:
- current location or selected location
- user-selectable time window: 1 day, 3 days, 5 days, 1 week
- customizable rain tolerance or sensitivity
- simple recommendation output:
  - Safe to wash
  - Not recommended
- short explanation:
  - “Rain expected in 4 hours”
  - “Low precipitation risk for the next day”
  - “High chance of rain tonight”
- forecast confidence / disclaimer that this is a recommendation, not a guarantee
- optional notification or “best wash window” suggestion

Design direction:
Create a mobile-first experience that feels modern and polished, but restrained. The app should feel useful and dependable rather than flashy. Emphasize strong information hierarchy, readable typography, intuitive controls, and a clear visual distinction between “safe” and “not safe” states. Weather context should support the decision, not overwhelm it.

Avoid:
- generic weather app layouts
- cluttered dashboards
- overly playful gimmicks
- too many charts or dense meteorological details
- making the user interpret raw forecast data to reach their own conclusion

Please design:
- onboarding / first-use flow
- main recommendation screen
- time-window selection interaction
- settings or preferences for rain sensitivity
- forecast detail screen or expandable explanation area
- empty, loading, offline, and error states
- notification opt-in moment

Also provide:
- the UX rationale behind the main flow
- the emotional tone of the product
- the visual design principles
- suggested component system and information hierarchy

The final result should make the user feel: “I can trust this app, and I know exactly whether washing my car is a good idea right now.”
```
