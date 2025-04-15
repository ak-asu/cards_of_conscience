# Cards of Conscience

A simulation card game for policymaking, where players select policy options across different domains while managing budget constraints. The game includes AI agents that participate in the decision-making process.

## Features

### Implemented Features (Phase 1 MVP)

- **Policy Selection System**
  - 7 different policy domains, each with 3 cost-tiered options
  - Real-time budget tracking and enforcement (14 unit limit)
  - Visual feedback when selecting policy cards
  - Responsive layout that works across different screen sizes

- **AI Agents**
  - 4 AI agents with varied backgrounds make policy decisions
  - Agents generate justifications for their policy choices
  - Agent selections are logged for future reference

- **UI/UX**
  - Interactive tutorial showcasing key features
  - Dark/light mode toggle
  - Smooth animations and transitions
  - Budget visualization
  - Interactive policy cards with cost indicators

### Upcoming Features

- **Group Discussion (Phase 2)**
  - Facilitated discussion between human player and AI agents
  - Negotiation and compromise mechanics
  - Policy revision opportunities

- **Reflection (Phase 3)**
  - Analysis of chosen policies and their potential impacts
  - Comparison of your choices with AI agent decisions
  - Insights about your policy-making approach

## Technical Details

Built with:
- Flutter for cross-platform UI
- Riverpod for state management
- GoRouter for navigation
- Hive for local storage
- ShowcaseView for tutorials

## Getting Started

1. Ensure you have Flutter installed
2. Clone the repository
3. Run `flutter pub get`
4. Run `flutter run`

## Project Structure

- `lib/core/`: Core application components, including routing, theming, and constants
- `lib/features/`: Feature modules organized by game phase
- `lib/common_widgets/`: Shared UI components
- `assets/data/`: Game data including policy options and agent profiles
