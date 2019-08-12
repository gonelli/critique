//
//  Critic.swift
//  Critique
//
//  Created by Ameya Joshi on 7/23/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

class Critic: Comparable {
    
    var name: String!
    var following: [String]!
    var followers: [String] = []
    var weight = 0
    
    init(name: String, following: [String]) {
        self.name = name
        self.following = following
    }
    
    static func < (lhs: Critic, rhs: Critic) -> Bool {
        return lhs.weight < rhs.weight
    }
    
    static func == (lhs: Critic, rhs: Critic) -> Bool {
        return lhs.weight == rhs.weight
    }
    
}
