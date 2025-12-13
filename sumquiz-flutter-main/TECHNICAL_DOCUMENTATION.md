# SumQuiz - Technical Documentation

## Architecture Overview

SumQuiz follows a layered architecture pattern with clear separation of concerns:
- **Presentation Layer**: Flutter widgets and UI components
- **Business Logic Layer**: Services that handle application logic
- **Data Layer**: Models and data access services
- **External Services**: Firebase services and AI integration

## State Management

The application uses the Provider package for state management:
- `MultiProvider` at the root level to provide services throughout the app
- `StreamProvider` for Firebase authentication state
- `ProxyProvider` for derived data streams
- `ChangeNotifierProvider` for theme management

## Firebase Integration

### Authentication Flow

1. **Initialization**: Firebase is initialized in `main.dart`
2. **AuthService**: Wraps Firebase Authentication with additional functionality
3. **Google Sign-In**: Uses the `google_sign_in` package with proper credential handling
4. **User Data**: Creates user documents in Firestore upon registration

### Firestore Structure

```
users/
  {userId}/
    daily_usage/
      summaries: int
      quizzes: int
      flashcards: int
    last_reset: timestamp
    name: string
    email: string
    subscription_status: string
    isPro: boolean
    summaries/
      {summaryId}/
        content: string
        timestamp: timestamp
    quizzes/
      {quizId}/
        title: string
        questions: array
        timestamp: timestamp
    flashcard_sets/
      {setId}/
        title: string
        flashcards: array
        timestamp: timestamp
```

## AI Service Implementation

The AI service uses Firebase AI (Gemini) to generate educational content:

### Content Generation Process

1. **Summary Generation**
   - Accepts text input or PDF files
   - Processes PDF content using Syncfusion PDF library
   - Sends prompt to Gemini model for summarization
   - Returns cleaned summary text

2. **Quiz Generation**
   - Sends text to Gemini with specific JSON format instructions
   - Parses returned JSON into QuizQuestion objects
   - Handles error cases and malformed responses

3. **Flashcard Generation**
   - Similar process to quiz generation
   - Returns question/answer pairs in JSON format
   - Converts to Flashcard objects

### Prompt Engineering

The AI service uses carefully crafted prompts to ensure consistent output:
- Specific JSON format requirements
- Clear instructions to avoid markdown formatting
- Focus on educational content quality

## Data Models

### UserModel

Represents a user in the system with:
- UID from Firebase Authentication
- Personal information (name, email)
- Subscription status and Pro flag
- Daily usage tracking for rate limiting
- Last reset timestamp for usage cycles

### Content Models

#### Summary
- Simple model with content and timestamp

#### Quiz
- Title and collection of QuizQuestion objects
- Timestamp for creation date

#### QuizQuestion
- Question text
- Array of 4 options
- Correct answer (must match one of the options)

#### FlashcardSet
- Title and collection of Flashcard objects
- Timestamp for creation date

#### Flashcard
- Simple question/answer pair

## Services

### AuthService

Handles all authentication-related functionality:
- User registration and login
- Google Sign-In integration
- User session management
- User data initialization in Firestore

### FirestoreService

Manages all data operations:
- User data streaming and updates
- Content library management (summaries, quizzes, flashcards)
- Usage tracking and incrementing
- Rate limiting checks

### AIService

Interfaces with Firebase AI:
- Model initialization and configuration
- Content generation methods
- Response parsing and error handling

### UpgradeService

Manages in-app purchases:
- Product querying from app stores
- Purchase initiation
- Purchase status handling
- Subscription validation

## UI Components

### Navigation Structure

The app uses a bottom navigation bar with four main sections:
1. **Library**: Content creation and saved items.
2. **Review**: Spaced repetition review sessions for flashcards to enhance memory retention.
3. **Progress**: Learning analytics and statistics.
4. **Profile**: User settings and subscription management.

### Content Creation Screens

Each content type has a dedicated screen:
- **SummaryScreen**: Text input, PDF upload, generation, and saving
- **QuizScreen**: Text input, quiz generation, interactive quiz taking, and saving
- **FlashcardsScreen**: Text input, flashcard generation, interactive review, and saving

### Reusable Components

- **UpgradeModal**: Consistent subscription upgrade interface
- **Theme Management**: Light/dark mode switching
- **Error Handling**: Consistent error display and recovery

## Rate Limiting Implementation

The app implements a freemium model with daily usage limits:
- Free users: Limited daily generations
- Pro users: Unlimited access
- Usage tracked per feature (summaries, quizzes, flashcards)
- Automatic reset based on a timestamp

## Error Handling Strategy

Comprehensive error handling throughout the application:
- Firebase Authentication errors
- Network connectivity issues
- AI service errors
- Data parsing errors
- File processing errors
- In-app purchase errors

## Testing Considerations

### Unit Tests
- Model serialization/deserialization
- Service method logic
- Business rule validation

### Widget Tests
- UI component rendering
- User interaction flows
- State management verification

### Integration Tests
- Firebase service integration
- AI service responses
- Navigation flows

## Performance Considerations

### Memory Management
- Proper disposal of streams and controllers
- Efficient widget rebuilding
- Image caching for user avatars

### Network Optimization
- Firestore data pagination
- Efficient queries with proper indexing
- Offline data caching

### UI Performance
- Lazy loading for large lists
- Proper use of const constructors
- Efficient state updates

## Security Considerations

### Authentication
- Secure token handling
- Proper session management
- Data access rules in Firestore

### Data Protection
- User data isolation
- Secure storage of sensitive information
- Input validation and sanitization

### AI Integration
- Authenticated access to AI services
- Content filtering
- Rate limiting to prevent abuse

## Future Improvements

### Architecture Enhancements
- Migration to more advanced state management (Riverpod)
- Repository pattern implementation
- Dependency injection

### Feature Enhancements
- Offline-first architecture with local persistence
- Enhanced analytics and progress tracking
- Social features for content sharing
- Collaborative study groups

### Performance Improvements
- Caching strategies for generated content
- Optimized data fetching patterns
- Background synchronization

### Code Quality
- Comprehensive test coverage
- Improved error handling and logging
- Better separation of concerns
- Documentation improvements
