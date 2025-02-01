import SwiftUI
import Combine

// MARK: - Difficulty Enum

enum Difficulty: String, CaseIterable, Identifiable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    var id: String { self.rawValue }
    
    /// Returns the grid dimension (rows/columns) for the difficulty.
    var gridDimension: Int {
        switch self {
        case .easy: return 3
        case .medium: return 5
        case .hard: return 7
        }
    }
    
    /// Returns a unique key suffix for storing high scores.
    var highScoreKey: String {
        "HighScore_\(self.rawValue)"
    }
    
    /// Returns a unique key for storing score entries.
    var scoresKey: String {
        "Scores_\(self.rawValue)"
    }
}

// MARK: - Models

struct NamedColor: Identifiable, Codable, Equatable {
    let id: UUID
    let colorData: ColorData
    let name: String
    
    init(color: Color, name: String) {
        self.id = UUID()
        self.colorData = ColorData(color: color)
        self.name = name
    }
    
    static func == (lhs: NamedColor, rhs: NamedColor) -> Bool {
        lhs.name == rhs.name
    }
}

struct ColorData: Codable {
    let red: Double, green: Double, blue: Double, opacity: Double
    
    init(color: Color) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        red = Double(r); green = Double(g); blue = Double(b); opacity = Double(a)
    }
    
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
}

struct Tile: Identifiable {
    let id = UUID()
    let namedColor: NamedColor
    var isMatched: Bool = false
    var isSelected: Bool = false
}

struct ScoreEntry: Codable, Identifiable {
    let id: UUID
    let name: String
    let score: Int
    let date: Date
    
    init(name: String, score: Int, date: Date) {
        self.id = UUID()
        self.name = name
        self.score = score
        self.date = date
    }
}

// MARK: - LandingPage
// Assume your actual LandingPage is defined elsewhere.


// MARK: - DifficultySelectionView
struct DifficultySelectionView: View {
    @State private var selectedDifficulty: Difficulty = .easy
    @State private var startGame: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Text("Select Difficulty")
                    .font(.largeTitle)
                
                Picker("Difficulty", selection: $selectedDifficulty) {
                    ForEach(Difficulty.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                NavigationLink(
                    destination: GameView(difficulty: selectedDifficulty),
                    isActive: $startGame,
                    label: {
                        Button("Start Game") {
                            startGame = true
                        }
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    })
            }
            .padding()
        }
    }
}

// MARK: - GameView
struct GameView: View {
    let difficulty: Difficulty
    
    // Game score & high scores
    @State private var score = 0
    @State private var highScore = 0
    @State private var scores: [ScoreEntry] = []
    
    // Game over & restart states.
    @State private var showGameOverAlert = false
    @State private var gameOver = false
    @State private var restartID = UUID()
    
    // Navigation to LandingPage after final stage high score.
    @State private var navigateToLandingPage = false
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            Text("The Square Game")
                .font(.title)
                .padding(.top)
            
            HStack(spacing: 20) {
                Text("Difficulty: \(difficulty.rawValue)")
                    .font(.footnote)
                Text("High Score: \(highScore)")
                    .font(.footnote)
                Text("Score: \(score)")
                    .font(.footnote)
            }
            
            // Game grid view.
            LazyGridView(score: $score,
                         gameOver: $gameOver,
                         showGameOverAlert: $showGameOverAlert,
                         scores: $scores,
                         highScore: $highScore,
                         navigateToLandingPage: $navigateToLandingPage,
                         difficulty: difficulty)
                .id(restartID)
                .padding()
            
            // Hidden NavigationLink to LandingPage.
            NavigationLink(
                destination: LandingPage(),
                isActive: $navigateToLandingPage,
                label: { EmptyView() }
            )
        }
        .padding()
        .alert(isPresented: $showGameOverAlert) {
            Alert(
                title: Text("Game Over"),
                message: Text("Time's up! Do you want to start again?"),
                primaryButton: .destructive(Text("Start Again")) {
                    restartGame()
                },
                secondaryButton: .cancel(Text("Main Menu")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            loadScores()
        }
    }
    
    func restartGame() {
        restartID = UUID()
        score = 0
        gameOver = false
    }
    
    func loadScores() {
        if let data = UserDefaults.standard.data(forKey: difficulty.scoresKey),
           let savedScores = try? JSONDecoder().decode([ScoreEntry].self, from: data) {
            scores = savedScores
            highScore = savedScores.map { $0.score }.max() ?? 0
        }
    }
}

// MARK: - LazyGridView
struct LazyGridView: View {
    // Bindings from GameView.
    @Binding var score: Int
    @Binding var gameOver: Bool
    @Binding var showGameOverAlert: Bool
    @Binding var scores: [ScoreEntry]
    @Binding var highScore: Int
    @Binding var navigateToLandingPage: Bool
    
    // Difficulty & grid settings.
    let difficulty: Difficulty
    var gridDimension: Int { difficulty.gridDimension }
    var totalTiles: Int { gridDimension * gridDimension }
    
    // Timer & stage management.
    @State private var timeRemaining: Int = 15
    @State private var currentStage: Int = 0
    private let stageTimeouts = [15, 10, 5]  // Timeouts for stages 1, 2, 3.
    
    // Local game state.
    @State private var board: [Tile] = []
    @State private var selectedIndices: [Int] = []
    @State private var remainingPairs = 0
    
    // For prompting high score name entry on final stage win.
    @State private var showNameInputSheet = false
    @State private var playerName = ""
    
    // Timer publisher.
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Stage \(currentStage + 1) of \(stageTimeouts.count)")
                    .font(.headline)
                Spacer()
                Text("Time: \(timeRemaining)s")
                    .font(.headline)
            }
            .padding(.horizontal)
            
            Text("Remaining Pairs: \(remainingPairs)")
                .font(.subheadline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: gridDimension), spacing: 6) {
                ForEach(board.indices, id: \.self) { index in
                    let tile = board[index]
                    Button(action: {
                        handleSelection(at: index)
                    }) {
                        Rectangle()
                            .fill(tile.namedColor.colorData.color)
                            .frame(height: CGFloat(400 / gridDimension))
                            .opacity(tile.isMatched ? 0.3 : 1.0)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedIndices.contains(index) ? Color.black : Color.clear, lineWidth: 3)
                            )
                            .cornerRadius(8)
                    }
                    .disabled(tile.isMatched)
                }
            }
        }
        .onAppear {
            currentStage = 0
            setupBoard()
        }
        .onReceive(timer) { _ in
            guard !gameOver else { return }
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                // Timeout reached in current stage.
                if remainingPairs > 0 {
                    gameOver = true
                    showGameOverAlert = true
                    // Save score as "Anonymous" for this stage.
//                    let newScore = ScoreEntry(name: "Anonymous", score: score, date: Date())
//                    scores.append(newScore)
//                    saveScores()
                }
            }
        }
        .sheet(isPresented: $showNameInputSheet) {
            nameInputSheet
        }
    }
    
    // Generate a random NamedColor.
    func randomNamedColor() -> NamedColor {
        let red = Double.random(in: 0...1)
        let green = Double.random(in: 0...1)
        let blue = Double.random(in: 0...1)
        let name = String(UUID().uuidString.prefix(6))
        return NamedColor(color: Color(red: red, green: green, blue: blue), name: name)
    }
    
    // Setup a new board for the current stage.
    func setupBoard() {
        timeRemaining = stageTimeouts[currentStage]
        
        let pairCount = totalTiles / 2
        let remainder = totalTiles - (pairCount * 2)
        var tiles: [Tile] = []
        for _ in 0..<pairCount {
            let colorPair = randomNamedColor()
            tiles.append(Tile(namedColor: colorPair))
            tiles.append(Tile(namedColor: colorPair))
        }
        if remainder > 0 {
            tiles.append(Tile(namedColor: randomNamedColor()))
        }
        board = tiles.shuffled()
        selectedIndices = []
        remainingPairs = pairCount
    }
    
    // Handle tile selection.
    func handleSelection(at index: Int) {
        guard !gameOver else { return }
        if board[index].isMatched || selectedIndices.contains(index) { return }
        
        selectedIndices.append(index)
        if selectedIndices.count == 2 {
            let firstIndex = selectedIndices[0]
            let secondIndex = selectedIndices[1]
            let firstTile = board[firstIndex]
            let secondTile = board[secondIndex]
            
            if firstTile.namedColor.name == secondTile.namedColor.name {
                board[firstIndex].isMatched = true
                board[secondIndex].isMatched = true
                score += 1
                remainingPairs -= 1
                selectedIndices.removeAll()
                
                if remainingPairs == 0 {
                    // Stage cleared.
                    if currentStage < stageTimeouts.count - 1 {
                        currentStage += 1
                        setupBoard()
                    } else {
                        // Final stage completed.
                        gameOver = true
                        if score >= highScore {
                            highScore = score
                            showNameInputSheet = true
                        } else {
                            let newScore = ScoreEntry(name: "Anonymous", score: score, date: Date())
                            scores.append(newScore)
                            saveScores()
                        }
                    }
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    selectedIndices.removeAll()
                }
            }
        }
    }
    
    func saveScores() {
        if let encodedData = try? JSONEncoder().encode(scores) {
            UserDefaults.standard.set(encodedData, forKey: difficulty.scoresKey)
        }
    }
    
    // A view for entering the player's name when a new high score is achieved.
    var nameInputSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("New High Score!")
                    .font(.title2)
                    .padding()
                TextField("Enter your name", text: $playerName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                Button("Save Score") {
                    let finalName = playerName.isEmpty ? "Anonymous" : playerName
                    let newScore = ScoreEntry(name: finalName, score: score, date: Date())
                    scores.append(newScore)
                    saveScores()
                    showNameInputSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        navigateToLandingPage = true
                    }
                }
                .padding()
                Spacer()
            }
            .navigationTitle("High Score")
            .navigationBarItems(trailing: Button("Cancel") {
                showNameInputSheet = false
            })
        }
    }
}

// MARK: - App Entry Point
struct ContentView: View {
    var body: some View {
        DifficultySelectionView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
