# SumQuiz Blueprint

## Overview

This document outlines the architecture, features, and design of the SumQuiz application. It serves as a single source of truth for the project, documenting all style, design, and features implemented from the initial version to the current version.

## Project Structure

The project is organized into the following directories:

- `lib`: Contains the main application code, organized by feature.
- `lib/models`: Contains the data models for the application.
- `lib/services`: Contains the services that interact with external APIs and databases.
- `lib/views`: Contains the UI widgets and screens.
- `lib/view_models`: Contains the view models that manage the state of the UI.

## Features

- **User Authentication**: Users can sign in with Google or email and password.
- **Summarization**: Users can generate summaries from text or PDF files.
- **Quizzes**: Users can generate quizzes from summaries or text.
- **Flashcards**: Users can generate flashcards from summaries or text.
- **Library**: Users can save their summaries, quizzes, and flashcards to a local database for offline access.
- **Spaced Repetition**: The application uses a spaced repetition algorithm to schedule flashcard reviews.
- **Synchronization**: The application synchronizes the local database with Firestore when the user logs in.

## Design

The application uses a modern, clean design with a consistent color scheme and typography. The UI is designed to be intuitive and easy to use.

## Current Plan

### Onboarding Screen Revamp

The onboarding screen is the first impression a user has of the app. The current design is functional, but it can be improved to be more immersive, visually appealing, and persuasive.

**Strategy:**

1.  **Immersive Visuals:** Each onboarding step will feature a full-screen, high-quality, dark-themed image with a subtle noise texture and a vignette effect. This will create a premium and focused atmosphere.

2.  **Strategic Content Alignment:** The headline and subtitle of each step will be repositioned to the top of the screen, ensuring they are the first thing the user reads. This placement immediately communicates the app's value propositions.

3.  **Engaging Titles & subtitles:** The titles will be more benefit-oriented and punchier. I'll use a more premium and authoritative font to match the new visual style.

4.  **Animated Illustrations:** I will add animations to the illustrations to make them more dynamic and engaging.

5.  **Clear & Actionable Buttons:** The buttons will be redesigned for better visibility and to create a stronger call to action.

### Next Steps

- Continue to improve the UI and add new features.
- Add more tests to improve the code coverage.
- Monitor the application for bugs and performance issues.
