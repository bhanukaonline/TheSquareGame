import SwiftUI

struct ContentView: View {
    @State private var score = 0 // Track the current score
    @State private var highScore = 0 // Track the high score
    @State private var showAlert = false // Track if the alert should be shown
    @State private var gameOver = false // Track if the game is over
    @State private var scores: [ScoreEntry] = [] // Store all scores with date
    
    var body: some View {
        VStack {
            Text("The Square Game")
                .font(.title)
                .padding()
            
            HStack {
                Text("High Score: \(highScore)") // Display the high score
                    .font(.footnote)
                Text("Score: \(score)") // Display the current score
                    .font(.footnote)
                    .padding()
            }
            
            LazyGridView(score: $score, showAlert: $showAlert, gameOver: $gameOver, scores: $scores, highScore: $highScore) // Pass all required bindings
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Game Over"),
                message: Text("Do you want to start again?"),
                primaryButton: .destructive(Text("Start Again")) {
                    restartGame() // Restart the game when the user presses Start Again
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            loadScores() // Load the scores when the view appears
        }
        .onDisappear {
            saveScoreIfNeeded() // Save the score if the user leaves the game
        }
    }
    
    // Function to restart the game
    func restartGame() {
        score = 0
        gameOver = false
    }
    
    // Load scores from UserDefaults
    func loadScores() {
        if let data = UserDefaults.standard.data(forKey: "scores"),
           let savedScores = try? JSONDecoder().decode([ScoreEntry].self, from: data) {
            scores = savedScores
            highScore = scores.max { $0.score < $1.score }?.score ?? 0
        }
    }
    
    // Save scores to UserDefaults
    func saveScores() {
        if let encodedData = try? JSONEncoder().encode(scores) {
            UserDefaults.standard.set(encodedData, forKey: "scores")
        }
    }
    
    // Save the score when needed (for example when leaving the game)
    func saveScoreIfNeeded() {
        if score > 0 {
            let newScore = ScoreEntry(score: score, date: Date())
            scores.append(newScore)
            saveScores() // Persist the new score
        }
    }
}

struct LazyGridView: View {
    @Binding var score: Int // Score binding
    @Binding var showAlert: Bool // Alert binding
    @Binding var gameOver: Bool // Game Over binding
    @Binding var scores: [ScoreEntry] // Binding to store scores
    @Binding var highScore: Int // Binding to high score
    
    @State private var selectedColors: [NamedColor] = [] // Track user selections
    @State private var colors: [NamedColor] = [] // Dynamic color array
    
    // Define a 3-column layout
    let columns = Array(repeating: GridItem(.fixed(100), spacing: 10), count: 3)
    
    // Predefined 8 unique colors and their names
    let predefinedColors: [NamedColor] = [
        NamedColor(color: .red, name: "Red"),
        NamedColor(color: .blue, name: "Blue"),
        NamedColor(color: .green, name: "Green"),
        NamedColor(color: .yellow, name: "Yellow"),
        NamedColor(color: .orange, name: "Orange"),
        NamedColor(color: .purple, name: "Purple"),
        NamedColor(color: .brown, name: "Brown"),
        NamedColor(color: .gray, name: "Gray")
    ]
    
    init(score: Binding<Int>, showAlert: Binding<Bool>, gameOver: Binding<Bool>, scores: Binding<[ScoreEntry]>, highScore: Binding<Int>) {
        self._score = score
        self._showAlert = showAlert
        self._gameOver = gameOver
        self._scores = scores
        self._highScore = highScore
        // Initialize colors with a duplicate color
        var initialColors = predefinedColors
        let duplicateColor = predefinedColors.randomElement()!
        initialColors.append(NamedColor(color: duplicateColor.color, name: duplicateColor.name))
        _colors = State(initialValue: initialColors.shuffled())
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(colors) { namedColor in
                Button(action: {
                    handleSelection(namedColor: namedColor)
                }) {
                    Rectangle()
                        .fill(namedColor.color)
                        .frame(height: 100) // Square size 100x100
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }
    
    // Handle user selection
    func handleSelection(namedColor: NamedColor) {
        selectedColors.append(namedColor)
        
        // Check if two selections are made
        if selectedColors.count == 2 {
            if selectedColors[0].name == selectedColors[1].name {
                // Names match: Increment score and shuffle colors
                score += 1
                shuffleColors()
            } else {
                // Names don't match: Reset score, shuffle colors, and show alert
                if score > highScore {
                    highScore = score // Update high score if necessary
                }
                // Save the current score with date and time
                let newScore = ScoreEntry(score: score, date: Date())
                scores.append(newScore)
                saveScores() // Persist the new score
                
                score = 0
                shuffleColors()
                gameOver = true // Set the game over state to true
                showAlert = true // Trigger the alert
            }
            // Clear selections for the next round
            selectedColors.removeAll()
        }
    }
    
    // Shuffle the colors array
    func shuffleColors() {
        var newColors = predefinedColors
        let duplicateColor = predefinedColors.randomElement()!
        newColors.append(NamedColor(color: duplicateColor.color, name: duplicateColor.name))
        colors = newColors.shuffled()
    }
    
    // Save scores to UserDefaults
    func saveScores() {
        if let encodedData = try? JSONEncoder().encode(scores) {
            UserDefaults.standard.set(encodedData, forKey: "scores")
        }
    }
}

struct NamedColor: Identifiable {
    let id = UUID() // Ensure unique identity even for duplicates
    let color: Color
    let name: String
}

struct ScoreEntry: Codable {
    let score: Int
    let date: Date
}
