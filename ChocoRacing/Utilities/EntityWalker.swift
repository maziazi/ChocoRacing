//
//  EntityWalker.swift
//  ChocoRacing
//
//  Created by Muhamad Azis on 20/07/25.
//

import RealityKit

struct EntityWalker {
    static func walkThroughEntities(entity: Entity, action: (Entity) -> Void) {
        action(entity)
        for child in entity.children {
            walkThroughEntities(entity: child, action: action)
        }
    }
}
