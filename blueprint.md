# SumQuiz Application Blueprint

## Overview

SumQuiz is a mobile application designed to provide users with instant clarity on various topics through a quiz-based learning experience. The app is built with Flutter and leverages Firebase for backend services, including authentication, database, and analytics.

## Style and Design

- **Theme:** The app uses a modern, clean theme with a professional and intuitive design.
- **Layout:** The layout is visually balanced, with clean spacing and a mobile-responsive design that adapts to different screen sizes.
- **Typography:** The app uses the Poppins font for a clean and modern look.

## Implemented Features

- **User Authentication:**
  - Email and password sign-up and sign-in.
  - Google Sign-In.
  - Password reset functionality.

- **Referral System:**
  - Users can enter a referral code during sign-up to receive a 3-day Pro trial.
  - The system validates the referral code and applies the Pro trial to the new user.

- **Onboarding:**
  - A multi-step onboarding process to welcome new users and collect their interests.

- **Quizzes:**
  - Users can take quizzes on various topics.

## Current Plan: Fix Google Sign-In and Referral Code Handling

- [x] **Problem:** The "Continue with Google" button is not working as expected, and the referral code is not being applied during Google Sign-In.
- [x] **Solution:**
  1. Update `lib/views/screens/auth_screen.dart` to pass the referral code to the `signInWithGoogle` method.
  2. Update `lib/services/auth_service.dart` to handle the referral code during Google Sign-In, ensuring that new users receive their Pro trial.
