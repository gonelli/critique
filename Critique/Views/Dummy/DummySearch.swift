//
//  DummySearch.swift
//  Critique
//
//  Created by Ameya Joshi on 7/9/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit
import InstantSearchClient

class DummySearch: UIViewController {

    let client = Client(appID: "3PCPRD2BHV", apiKey: "e2ab8935cad696d6a4536600d531097b")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let index = client.index(withName: "users")
        
        // Add during account creation
//        let objectJames = ["name": "James Jackson", "objectID": "KhY0f5ophZUdJ2fbXw0DJCabZDx1"]
//        index.addObjects([objectAmeya, objectJames])
        
        
        // Change Name
//        index.partialUpdateObject(["name": "New Ameya"], withID: "MS9lBkmsFIbwifU2cJlrNrUC9A22")
        
        // Search
        index.search(Query(query: "ames")) { (content, error) in
            if error == nil {
                guard let hits = content!["hits"] as? [[String: AnyObject]] else { fatalError("Hits is not json") }
                for hit in hits {
                    print("Hit Name: \(hit["name"] as! String), UID: \(hit["objectID"] as! String)")
                }
            } else {
                print(error!.localizedDescription)
            }
        }
        
    }

}
