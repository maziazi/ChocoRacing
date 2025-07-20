//
//  PlayerControlExtensions.swift
//  ChocoRacing
//
//  Created by Muhamad Azis on 20/07/25.
//

import SwiftUI

extension PlayerController {
    var horizontalGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let horizontalMovement = abs(value.translation.width)
                let verticalMovement = abs(value.translation.height)
                
                if horizontalMovement > verticalMovement {
                    if !self.isDragging {
                        self.handleDragStart()
                    }
                    self.handleHorizontalDrag(value.translation)
                }
            }
            .onEnded { _ in
                self.handleDragEnd()
            }
    }
}
