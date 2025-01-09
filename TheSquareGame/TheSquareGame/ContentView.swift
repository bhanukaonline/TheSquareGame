import SwiftUI

// Define a struct to store color and its name
struct NamedColor: Identifiable {
    let id = UUID() // Ensure unique identity even for duplicates
    let color: Color
    let name: String
}

struct ContentView: View {
    var body: some View {
        VStack {
            Text("The Square Game")
                .font(.title)
                .padding()
            
            HStack {
                Text("High Score: 1005")
                    .font(.footnote)
                Text("Score: 55")
                    .font(.footnote)
                    .padding()
            }
            
            LazyGridView()
        }
        .padding()
    }
}

struct LazyGridView: View {
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
    
    // Generate the colors array for the grid
    var colors: [NamedColor] {
        var colorArray = predefinedColors
        let duplicateColor = predefinedColors.randomElement()! // Randomly pick a color to duplicate
        colorArray.append(NamedColor(color: duplicateColor.color, name: duplicateColor.name)) // Create a new instance
        return colorArray.shuffled() // Shuffle the array for randomness
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(colors) { namedColor in
                    Button(action: {
                        buttonTapped(namedColor: namedColor)
                    }) {
                        Rectangle()
                            .fill(namedColor.color)
                            .frame(height: 100) // Square size 100x100
                            .cornerRadius(8)
                            .overlay(
                                Text(namedColor.name)
                                    .foregroundColor(.white)
                                    .font(.caption)
                                    .bold()
                            )
                    }
                }
            }
            .padding()
        }
    }
    
    // Action for button tap
    func buttonTapped(namedColor: NamedColor) {
        print("Tapped color: \(namedColor.name)")
    }
}

#Preview {
    ContentView()
}
