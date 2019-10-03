//
//  main.swift
//  LevelGetter
//
//  Created by Dayson Dong on 2019-10-03.
//  Copyright © 2019 Dayson Dong. All rights reserved.
//

import Foundation

class Exercise: Codable {
    
    let imageURLs: [String]
    let mainURL: String
    let name: String
    let equipmentType: String
    let muscleTargeted: String
    let rating: Double
    var level: String = "NA"
    
    init?(withJSONResult json: [String: Any]) {
        guard let imageLinkOne = json["Image_URL_One"] as? String else { print("init one failed"); return nil }
        guard let imageLinkTwo = json["Image_URL_Two"] as? String else { print("init two failed"); return nil }
        guard let url = json["URL"] as? String else { print("init url failed"); return nil }
        guard let equiment = json["Equipment_Type"] as? String else { print("init equi failed"); return nil }
        guard let muscle = json["Muscle_Targeted"] as? String else { print("init mus failed"); return nil }
        guard let name = json["Exercise_Name"] as? String else { print("init name failed"); return nil }
        if (json["Rating"] as? String) != nil {
            self.rating = 0
        } else if let rating = json["Rating"] as? Double {
            self.rating = rating
        } else {
            return nil
        }
        self.imageURLs = [imageLinkOne, imageLinkTwo]
        self.mainURL = url
        self.name = name
        self.equipmentType = equiment
        self.muscleTargeted = muscle
        
    }
    
    
}

extension Exercise: Comparable {
    static func < (lhs: Exercise, rhs: Exercise) -> Bool {
        lhs.rating < rhs.rating
    }
    
    static func == (lhs: Exercise, rhs: Exercise) -> Bool {
        lhs.name == rhs.name
    }
}

var exercises: [Exercise] = []

let path = "/Users/dsn/desktop/BBData/cardio.json"
let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)

var succeedCount = 0

func encodeData() {
    
    let encoder = JSONEncoder()
    do {
        let data = try JSONSerialization.data(withJSONObject: exercises, options: [])
        let jsonString = String(data: data, encoding: .utf8)
        print(jsonString)
    } catch  {
        
    }
    
    
}

if let exercisesArray = jsonResult as? [[String: Any]]  {
    
    
    exercisesArray.forEach { (ex) in
        
        if let exercise = Exercise(withJSONResult: ex) {
            if  !exercises.contains(exercise) {
                exercises.append(exercise)
            }
        }
    }
    
    print("Found \(exercises.count) exercises\n")
    
    if exercises.count != 0 {
        print("About to get HTML of \(exercises.count) exercises")
        
        let group = DispatchGroup()
        exercises.forEach { (ex) in
            group.enter()
            if let url = URL(string: ex.mainURL) {
                let request = URLRequest(url: url)
                
                DispatchQueue.main.async {
                    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                        
                        guard error == nil else {
                            print(error!.localizedDescription)
                            return
                        }
                        guard response != nil else {
                            print("no response")
                            return
                        }
                        
                        guard let data = data else {
                            print("no data")
                            return
                        }
                        //                    print("getting \(index)/\(exercises.count)")
                        if let html  = String(data: data, encoding: .utf8) {
                            let testPattern = "level:[\n]*[ ]+[a-zA-Z]+[\n]"
                            let res = html.range(of: testPattern, options:[.regularExpression, .caseInsensitive])
                            if res != nil {
                                let trimmed = html[res!].replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "Level:", with: "").replacingOccurrences(of: "\n", with: "")
                                ex.level = trimmed
                                succeedCount = succeedCount + 1
                                print("Succeed! \(ex.name) level: \(ex.level)")
                            } else {
                                ex.level = "N/A"
                                print("Failed.")
                            }
                        }
                        group.leave()
                    }
                    task.resume()
                }
            } else {
                print("NO URL of \(ex.name)")
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            encodeData()
            exit(EXIT_SUCCESS)
        }
        dispatchMain()
    }
} else {
    print("no json result")
}





