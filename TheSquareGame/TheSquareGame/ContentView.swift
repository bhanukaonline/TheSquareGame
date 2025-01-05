//
//  ContentView.swift
//  TheSquareGame
//
//  Created by Bhanuka 042 on 2024-12-15.
//

import SwiftUI

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
    
    // Predefined 8 unique colors
    let predefinedColors: [Color] = [
        .red, .blue, .green, .yellow, .orange, .purple, .brown, .gray
    ]
    
    // Generate the colors array for the grid
    var colors: [Color] {
        var colorArray: [Color] = [] // Initialize an empty array
        predefinedColors.forEach { color in
            colorArray.append(color) // Add each color from predefinedColors to colorArray
        }
        let duplicateColor = predefinedColors.randomElement()! // Randomly pick a color to duplicate
        colorArray.append(duplicateColor) // Add the duplicate color to make 9
        return colorArray // Shuffle the array for randomness
    }

    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(0..<colors.count, id: \.self) { index in
                    Button(action: {
                        buttonTapped(index: index)
                    }) {
                        Rectangle()
                            .fill(colors[index])
                            .frame(height: 100) // Square size 100x100
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
    }
    
    // Action for button tap
    func buttonTapped(index: Int) {
        print("Button \(index + 1) tapped!")
    }
}

#Preview {
    ContentView()
}
